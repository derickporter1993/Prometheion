/**
 * @description Natural language to SOQL conversion service
 * Uses AI to convert natural language queries to SOQL and execute them
 * @group AI Integration
 * @author Prometheion Team
 */
public with sharing class NaturalLanguageQueryService {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    private static final String CACHE_PARTITION = 'local.PrometheionCache';
    private static final Integer CACHE_TTL_SECONDS = 1800; // 30 min for queries
    
    // Allowed objects for querying (security)
    private static final Set&lt;String&gt; ALLOWED_OBJECTS = new Set&lt;String&gt;{
        'Prometheion_Audit_Package__c',
        'Prometheion_Evidence_Item__c',
        'Prometheion_Framework_Mapping__c',
        'User'
    };
    
    // Example queries for suggestions
    private static final List&lt;String&gt; EXAMPLE_QUERIES = new List&lt;String&gt;{
        'Show me all admin privilege escalations in the last 30 days',
        'Which users accessed data outside business hours?',
        'What controls are failing for HIPAA?',
        'Show critical events from last week',
        'List all LoginAs events this month',
        'Find report exports with more than 1000 rows',
        'Show evidence items pending review'
    };
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Execute natural language query
     * @param query The natural language query
     * @return QueryResult with generated SOQL and results
     */
    @AuraEnabled
    public static QueryResult executeNaturalLanguageQuery(String query) {
        if (String.isBlank(query)) {
            throw new AuraHandledException('Query is required');
        }
        
        QueryResult result = new QueryResult();
        result.originalQuery = query;
        
        try {
            // Generate SOQL from natural language
            String generatedSOQL = generateSOQL(query);
            result.generatedSOQL = generatedSOQL;
            
            // Validate SOQL security
            if (!isSOQLSafe(generatedSOQL)) {
                result.confidence = 0;
                result.naturalLanguageSummary = 'Query rejected for security reasons.';
                result.results = new List&lt;SObject&gt;();
                return result;
            }
            
            // Execute query
            result.results = Database.query(generatedSOQL);
            result.confidence = 85;
            
            // Generate summary
            result.naturalLanguageSummary = generateResultSummary(query, result.results.size());
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'NL Query error: ' + e.getMessage());
            result.confidence = 0;
            result.naturalLanguageSummary = 'Error executing query: ' + e.getMessage();
            result.results = new List&lt;SObject&gt;();
        }
        
        return result;
    }
    
    /**
     * @description Get query suggestions based on partial input
     * @param partialQuery The partial query string
     * @return List of suggested queries
     */
    @AuraEnabled(cacheable=true)
    public static List&lt;String&gt; getQuerySuggestions(String partialQuery) {
        List&lt;String&gt; suggestions = new List&lt;String&gt;();
        
        if (String.isBlank(partialQuery)) {
            // Return example queries
            return EXAMPLE_QUERIES;
        }
        
        String lowerQuery = partialQuery.toLowerCase();
        
        // Filter examples that match
        for (String example : EXAMPLE_QUERIES) {
            if (example.toLowerCase().contains(lowerQuery)) {
                suggestions.add(example);
            }
        }
        
        // Add context-aware suggestions
        suggestions.addAll(getContextualSuggestions(partialQuery));
        
        // Limit results
        if (suggestions.size() &gt; 10) {
            suggestions = new List&lt;String&gt;(suggestions.subList(0, 10));
        }
        
        return suggestions;
    }
    
    /**
     * @description Validate a natural language query before execution
     * @param query The query to validate
     * @return Validation result with generated SOQL preview
     */
    @AuraEnabled
    public static ValidationResult validateQuery(String query) {
        ValidationResult result = new ValidationResult();
        result.isValid = false;
        result.originalQuery = query;
        
        if (String.isBlank(query)) {
            result.message = 'Query cannot be empty';
            return result;
        }
        
        try {
            String generatedSOQL = generateSOQL(query);
            result.generatedSOQL = generatedSOQL;
            
            if (!isSOQLSafe(generatedSOQL)) {
                result.message = 'Query targets unauthorized objects or fields';
                return result;
            }
            
            // Estimate row count
            result.estimatedRowCount = estimateRowCount(generatedSOQL);
            result.isValid = true;
            result.message = 'Query is valid and ready to execute';
            
        } catch (Exception e) {
            result.message = 'Unable to parse query: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * @description Get recently executed queries for current user
     * @return List of recent queries
     */
    @AuraEnabled(cacheable=true)
    public static List&lt;String&gt; getRecentQueries() {
        // In production, this would query a custom object storing query history
        // For now, return empty list
        return new List&lt;String&gt;();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Generate SOQL from natural language using AI
     */
    private static String generateSOQL(String naturalLanguageQuery) {
        // Check cache
        String cacheKey = 'soql_' + naturalLanguageQuery.hashCode();
        String cached = getCachedString(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        String soql;
        
        if (Test.isRunningTest()) {
            soql = getMockSOQL(naturalLanguageQuery);
        } else {
            soql = callAIForSOQL(naturalLanguageQuery);
        }
        
        // Cache result
        cacheString(cacheKey, soql);
        
        return soql;
    }
    
    /**
     * @description Call AI to generate SOQL
     */
    private static String callAIForSOQL(String query) {
        String prompt = buildSOQLPrompt(query);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Prometheion_Claude_API');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('anthropic-version', '2023-06-01');
        req.setTimeout(30000);
        
        Map&lt;String, Object&gt; body = new Map&lt;String, Object&gt;{
            'model' =&gt; 'claude-sonnet-4-20250514',
            'max_tokens' =&gt; 1024,
            'messages' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                new Map&lt;String, Object&gt;{
                    'role' =&gt; 'user',
                    'content' =&gt; prompt
                }
            }
        };
        
        req.setBody(JSON.serialize(body));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new CalloutException('AI API error');
        }
        
        return extractSOQLFromResponse(res.getBody());
    }
    
    /**
     * @description Build SOQL generation prompt
     */
    private static String buildSOQLPrompt(String query) {
        return 'Convert the following natural language query to Salesforce SOQL.\n\n' +
               'Available objects:\n' +
               '- Prometheion_Audit_Package__c (fields: Package_Name__c, Framework__c, Status__c, Audit_Period_Start__c, Audit_Period_End__c)\n' +
               '- Prometheion_Evidence_Item__c (fields: Evidence_Type__c, Evidence_Date__c, Description__c, Status__c, Audit_Package__c)\n' +
               '- Prometheion_Framework_Mapping__c (fields: Framework__c, Requirement_Code__c, Requirement_Description__c)\n\n' +
               'Query: ' + query + '\n\n' +
               'Respond with ONLY the SOQL query, no explanation. Include LIMIT 1000 at the end.';
    }
    
    /**
     * @description Extract SOQL from AI response
     */
    private static String extractSOQLFromResponse(String response) {
        try {
            Map&lt;String, Object&gt; responseMap = (Map&lt;String, Object&gt;)JSON.deserializeUntyped(response);
            List&lt;Object&gt; content = (List&lt;Object&gt;)responseMap.get('content');
            
            if (content != null &amp;&amp; !content.isEmpty()) {
                Map&lt;String, Object&gt; firstContent = (Map&lt;String, Object&gt;)content[0];
                String text = (String)firstContent.get('text');
                
                // Clean up the response
                text = text.trim();
                if (text.startsWith('```')) {
                    text = text.replaceAll('```(sql|soql)?', '').trim();
                }
                
                return text;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error extracting SOQL: ' + e.getMessage());
        }
        
        throw new AuraHandledException('Unable to generate SOQL from query');
    }
    
    /**
     * @description Check if SOQL is safe to execute
     */
    private static Boolean isSOQLSafe(String soql) {
        if (String.isBlank(soql)) {
            return false;
        }
        
        String upperSOQL = soql.toUpperCase();
        
        // Check for DML operations
        if (upperSOQL.contains('INSERT') || upperSOQL.contains('UPDATE') || 
            upperSOQL.contains('DELETE') || upperSOQL.contains('MERGE')) {
            return false;
        }
        
        // Check for allowed objects only
        Boolean hasAllowedObject = false;
        for (String obj : ALLOWED_OBJECTS) {
            if (upperSOQL.contains(obj.toUpperCase())) {
                hasAllowedObject = true;
                break;
            }
        }
        
        if (!hasAllowedObject) {
            return false;
        }
        
        // Ensure LIMIT is present
        if (!upperSOQL.contains('LIMIT')) {
            return false;
        }
        
        return true;
    }
    
    /**
     * @description Estimate row count for query
     */
    private static Integer estimateRowCount(String soql) {
        try {
            // Convert to COUNT query
            String countQuery = soql.replaceFirst('(?i)SELECT.*?FROM', 'SELECT COUNT() FROM');
            countQuery = countQuery.replaceFirst('(?i)LIMIT\\s+\\d+', '');
            countQuery = countQuery.replaceFirst('(?i)ORDER BY.*', '');
            
            return Database.countQuery(countQuery);
        } catch (Exception e) {
            return -1;
        }
    }
    
    /**
     * @description Generate human-readable result summary
     */
    private static String generateResultSummary(String query, Integer resultCount) {
        if (resultCount == 0) {
            return 'No results found for your query.';
        } else if (resultCount == 1) {
            return 'Found 1 record matching your query.';
        } else {
            return 'Found ' + resultCount + ' records matching your query.';
        }
    }
    
    /**
     * @description Get contextual query suggestions
     */
    private static List&lt;String&gt; getContextualSuggestions(String partialQuery) {
        List&lt;String&gt; suggestions = new List&lt;String&gt;();
        String lower = partialQuery.toLowerCase();
        
        if (lower.contains('admin') || lower.contains('privilege')) {
            suggestions.add('Show admin privilege escalations in the last 30 days');
            suggestions.add('List all LoginAs events by admin users');
        }
        
        if (lower.contains('export') || lower.contains('report')) {
            suggestions.add('Find report exports with more than 1000 rows');
            suggestions.add('Show all report exports from last week');
        }
        
        if (lower.contains('hipaa') || lower.contains('compliance')) {
            suggestions.add('What HIPAA controls have no evidence?');
            suggestions.add('Show HIPAA audit packages in progress');
        }
        
        if (lower.contains('login') || lower.contains('access')) {
            suggestions.add('Show failed login attempts');
            suggestions.add('List users with suspicious login patterns');
        }
        
        return suggestions;
    }
    
    /**
     * @description Get mock SOQL for testing
     */
    private static String getMockSOQL(String query) {
        // Return appropriate mock SOQL based on query keywords
        String lower = query.toLowerCase();
        
        if (lower.contains('evidence') || lower.contains('event')) {
            return 'SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, Description__c, Status__c FROM Prometheion_Evidence_Item__c ORDER BY Evidence_Date__c DESC LIMIT 100';
        }
        
        if (lower.contains('package') || lower.contains('audit')) {
            return 'SELECT Id, Name, Package_Name__c, Framework__c, Status__c FROM Prometheion_Audit_Package__c ORDER BY CreatedDate DESC LIMIT 100';
        }
        
        // Default query
        return 'SELECT Id, Name FROM Prometheion_Audit_Package__c LIMIT 10';
    }
    
    // ═══════════════════════════════════════════════════════════════
    // CACHING
    // ═══════════════════════════════════════════════════════════════
    
    private static String getCachedString(String key) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            return (String)partition.get(key);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheString(String key, String value) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            partition.put(key, value, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Cache put failed: ' + e.getMessage());
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Query result wrapper
     */
    public class QueryResult {
        @AuraEnabled public String originalQuery;
        @AuraEnabled public String generatedSOQL;
        @AuraEnabled public List&lt;SObject&gt; results;
        @AuraEnabled public String naturalLanguageSummary;
        @AuraEnabled public Integer confidence; // 0-100
    }
    
    /**
     * @description Validation result wrapper
     */
    public class ValidationResult {
        @AuraEnabled public String originalQuery;
        @AuraEnabled public String generatedSOQL;
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String message;
        @AuraEnabled public Integer estimatedRowCount;
    }
}
