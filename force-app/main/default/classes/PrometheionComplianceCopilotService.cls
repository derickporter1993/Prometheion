/**
 * @description AI-powered compliance analysis service using Claude API
 * Provides event pattern analysis, audit summaries, risk predictions, and event categorization
 * @group AI Integration
 * @author Prometheion Team
 */
public with sharing class PrometheionComplianceCopilotService {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    private static final String NAMED_CREDENTIAL = 'callout:Prometheion_Claude_API';
    private static final String CLAUDE_MODEL = 'claude-sonnet-4-20250514';
    private static final Integer MAX_TOKENS = 4096;
    private static final Integer TIMEOUT_MS = 60000;
    private static final String CACHE_PARTITION = 'local.PrometheionCache';
    private static final Integer CACHE_TTL_SECONDS = 3600; // 1 hour
    
    // System prompt for compliance analysis
    private static final String SYSTEM_PROMPT = 
        'You are Prometheion Compliance Copilot, an expert AI assistant specializing in ' +
        'regulatory compliance analysis for Salesforce environments. You analyze Shield Event ' +
        'Monitoring data and provide actionable compliance recommendations.\n\n' +
        'Frameworks you understand: HIPAA, SOC 2, NIST 800-53, GDPR, PCI DSS, FedRAMP, FINRA.\n\n' +
        'Always provide specific, actionable recommendations with control references. ' +
        'Format responses as structured JSON when requested.';
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Analyze event patterns and provide recommendations
     * @param eventIds List of evidence item IDs to analyze
     * @return ComplianceRecommendation with analysis results
     */
    @AuraEnabled
    public static ComplianceRecommendation analyzeEventPattern(List&lt;String&gt; eventIds) {
        if (eventIds == null || eventIds.isEmpty()) {
            return createDefaultRecommendation('No events provided for analysis');
        }
        
        // Check cache first
        String cacheKey = 'analysis_' + String.join(eventIds, '_').hashCode();
        ComplianceRecommendation cached = getCachedRecommendation(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        try {
            // Query evidence items with security enforcement
            List&lt;Prometheion_Evidence_Item__c&gt; items = [
                SELECT Id, Name, Evidence_Type__c, Evidence_Date__c, Description__c, Status__c
                FROM Prometheion_Evidence_Item__c
                WHERE Id IN :eventIds
                WITH SECURITY_ENFORCED
                LIMIT 100
            ];
            
            // Strip inaccessible fields before processing
            items = PrometheionSecurityUtils.stripInaccessibleFields(AccessType.READABLE, items);
            
            if (items.isEmpty()) {
                return createDefaultRecommendation('No evidence items found');
            }
            
            // Build analysis prompt
            String prompt = buildAnalysisPrompt(items);
            
            // Call Claude API
            String response = callClaudeAPI(prompt);
            
            // Parse response
            ComplianceRecommendation recommendation = parseRecommendationResponse(response);
            
            // Cache result
            cacheRecommendation(cacheKey, recommendation);
            
            return recommendation;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error analyzing event pattern: ' + e.getMessage());
            return createDefaultRecommendation('Analysis error: ' + e.getMessage());
        }
    }
    
    /**
     * @description Generate natural language audit summary
     * @param packageId The audit package ID
     * @return Human-readable audit summary
     */
    @AuraEnabled
    public static String generateAuditSummary(String packageId) {
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID is required');
        }
        
        // Check cache
        String cacheKey = 'summary_' + packageId;
        String cached = getCachedString(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        try {
            // Query package and evidence with security enforcement
            Prometheion_Audit_Package__c pkg = [
                SELECT Id, Package_Name__c, Framework__c, Status__c,
                       Audit_Period_Start__c, Audit_Period_End__c
                FROM Prometheion_Audit_Package__c
                WHERE Id = :packageId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            Integer evidenceCount = [
                SELECT COUNT()
                FROM Prometheion_Evidence_Item__c
                WHERE Audit_Package__c = :packageId
                WITH SECURITY_ENFORCED
            ];
            
            // Get event type distribution with security enforcement
            List&lt;AggregateResult&gt; typeDistribution = [
                SELECT Evidence_Type__c, COUNT(Id) cnt
                FROM Prometheion_Evidence_Item__c
                WHERE Audit_Package__c = :packageId
                WITH SECURITY_ENFORCED
                GROUP BY Evidence_Type__c
            ];
            
            // Build summary prompt
            String prompt = buildSummaryPrompt(pkg, evidenceCount, typeDistribution);
            
            // Call Claude API
            String response = callClaudeAPI(prompt);
            
            // Extract summary from response
            String summary = extractTextFromResponse(response);
            
            // Cache result
            cacheString(cacheKey, summary);
            
            return summary;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error generating summary: ' + e.getMessage());
            throw new AuraHandledException('Error generating summary: ' + e.getMessage());
        }
    }
    
    /**
     * @description Predict compliance risks based on historical patterns
     * @param framework The compliance framework
     * @return List of risk predictions
     */
    @AuraEnabled
    public static List&lt;RiskPrediction&gt; predictComplianceRisks(String framework) {
        if (String.isBlank(framework)) {
            throw new AuraHandledException('Framework is required');
        }
        
        // Check cache
        String cacheKey = 'risks_' + framework;
        List&lt;RiskPrediction&gt; cached = getCachedRiskPredictions(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        try {
            // Get recent evidence for analysis
            List&lt;Prometheion_Evidence_Item__c&gt; recentEvidence = [
                SELECT Evidence_Type__c, Evidence_Date__c, Status__c
                FROM Prometheion_Evidence_Item__c
                WHERE CreatedDate = LAST_N_DAYS:90
                ORDER BY Evidence_Date__c DESC
                LIMIT 500
            ];
            
            // Build prediction prompt
            String prompt = buildPredictionPrompt(framework, recentEvidence);
            
            // Call Claude API
            String response = callClaudeAPI(prompt);
            
            // Parse predictions
            List&lt;RiskPrediction&gt; predictions = parseRiskPredictions(response);
            
            // Cache result
            cacheRiskPredictions(cacheKey, predictions);
            
            return predictions;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error predicting risks: ' + e.getMessage());
            return new List&lt;RiskPrediction&gt;();
        }
    }
    
    /**
     * @description Auto-categorize events to framework controls
     * @param eventIds List of evidence item IDs
     * @param framework The target compliance framework
     * @return Map of event ID to control ID
     */
    @AuraEnabled
    public static Map&lt;String, String&gt; categorizeEvents(List&lt;String&gt; eventIds, String framework) {
        Map&lt;String, String&gt; mappings = new Map&lt;String, String&gt;();
        
        if (eventIds == null || eventIds.isEmpty() || String.isBlank(framework)) {
            return mappings;
        }
        
        try {
            // Query events
            List&lt;Prometheion_Evidence_Item__c&gt; items = [
                SELECT Id, Evidence_Type__c, Description__c
                FROM Prometheion_Evidence_Item__c
                WHERE Id IN :eventIds
                LIMIT 50
            ];
            
            // Build categorization prompt
            String prompt = buildCategorizationPrompt(items, framework);
            
            // Call Claude API
            String response = callClaudeAPI(prompt);
            
            // Parse categorization
            mappings = parseCategorizationResponse(response, items);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error categorizing events: ' + e.getMessage());
        }
        
        return mappings;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS - API CALLS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Call Claude API via Named Credential
     * @param userPrompt The user prompt
     * @return API response body
     */
    @TestVisible
    private static String callClaudeAPI(String userPrompt) {
        if (Test.isRunningTest()) {
            return PrometheionTestDataFactory.createMockClaudeResponse();
        }
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('anthropic-version', '2023-06-01');
        req.setTimeout(TIMEOUT_MS);
        
        // Build request body
        Map&lt;String, Object&gt; requestBody = new Map&lt;String, Object&gt;{
            'model' =&gt; CLAUDE_MODEL,
            'max_tokens' =&gt; MAX_TOKENS,
            'system' =&gt; SYSTEM_PROMPT,
            'messages' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                new Map&lt;String, Object&gt;{
                    'role' =&gt; 'user',
                    'content' =&gt; userPrompt
                }
            }
        };
        
        req.setBody(JSON.serialize(requestBody));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
        if (res.getStatusCode() != 200) {
            throw new CalloutException('Claude API error: ' + res.getStatusCode() + ' - ' + res.getBody());
        }
        
        return res.getBody();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS - PROMPT BUILDING
    // ═══════════════════════════════════════════════════════════════
    
    private static String buildAnalysisPrompt(List&lt;Prometheion_Evidence_Item__c&gt; items) {
        String eventsJson = JSON.serialize(items);
        
        return 'Analyze the following Shield events and provide compliance recommendations.\n\n' +
               'Events:\n' + eventsJson + '\n\n' +
               'Respond with a JSON object containing:\n' +
               '- recommendation: string (main recommendation)\n' +
               '- severity: string (CRITICAL, HIGH, MEDIUM, or LOW)\n' +
               '- relatedControls: array of strings (control IDs)\n' +
               '- suggestedActions: array of strings\n' +
               '- confidence: number (0-100)';
    }
    
    private static String buildSummaryPrompt(Prometheion_Audit_Package__c pkg, Integer evidenceCount, 
                                             List&lt;AggregateResult&gt; typeDistribution) {
        String distribution = '';
        for (AggregateResult ar : typeDistribution) {
            distribution += '\n- ' + ar.get('Evidence_Type__c') + ': ' + ar.get('cnt');
        }
        
        return 'Generate an executive-level audit summary for the following package:\n\n' +
               'Package: ' + pkg.Package_Name__c + '\n' +
               'Framework: ' + pkg.Framework__c + '\n' +
               'Status: ' + pkg.Status__c + '\n' +
               'Period: ' + pkg.Audit_Period_Start__c + ' to ' + pkg.Audit_Period_End__c + '\n' +
               'Total Evidence: ' + evidenceCount + '\n' +
               'Event Distribution:' + distribution + '\n\n' +
               'Provide a 2-3 paragraph summary suitable for executive stakeholders. ' +
               'Highlight key findings, risks, and recommendations.';
    }
    
    private static String buildPredictionPrompt(String framework, List&lt;Prometheion_Evidence_Item__c&gt; evidence) {
        Map&lt;String, Integer&gt; typeCounts = new Map&lt;String, Integer&gt;();
        for (Prometheion_Evidence_Item__c item : evidence) {
            String t = item.Evidence_Type__c;
            typeCounts.put(t, (typeCounts.containsKey(t) ? typeCounts.get(t) : 0) + 1);
        }
        
        return 'Based on the following 90-day event pattern, predict compliance risks for ' + framework + ':\n\n' +
               'Event counts: ' + JSON.serialize(typeCounts) + '\n\n' +
               'Respond with a JSON array of risk predictions, each containing:\n' +
               '- controlId: string\n' +
               '- riskProbability: number (0-100)\n' +
               '- riskReason: string\n' +
               '- predictedDate: string (YYYY-MM-DD)';
    }
    
    private static String buildCategorizationPrompt(List&lt;Prometheion_Evidence_Item__c&gt; items, String framework) {
        List&lt;Map&lt;String, String&gt;&gt; simpleItems = new List&lt;Map&lt;String, String&gt;&gt;();
        for (Prometheion_Evidence_Item__c item : items) {
            simpleItems.add(new Map&lt;String, String&gt;{
                'id' =&gt; item.Id,
                'type' =&gt; item.Evidence_Type__c,
                'description' =&gt; item.Description__c
            });
        }
        
        return 'Map the following events to ' + framework + ' controls:\n\n' +
               JSON.serialize(simpleItems) + '\n\n' +
               'Respond with a JSON object where keys are event IDs and values are control IDs.';
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS - RESPONSE PARSING
    // ═══════════════════════════════════════════════════════════════
    
    private static ComplianceRecommendation parseRecommendationResponse(String response) {
        ComplianceRecommendation rec = new ComplianceRecommendation();
        
        try {
            Map&lt;String, Object&gt; responseMap = (Map&lt;String, Object&gt;)JSON.deserializeUntyped(response);
            List&lt;Object&gt; content = (List&lt;Object&gt;)responseMap.get('content');
            
            if (content != null &amp;&amp; !content.isEmpty()) {
                Map&lt;String, Object&gt; firstContent = (Map&lt;String, Object&gt;)content[0];
                String text = (String)firstContent.get('text');
                
                // Parse the JSON response
                Map&lt;String, Object&gt; recData = (Map&lt;String, Object&gt;)JSON.deserializeUntyped(text);
                
                rec.recommendation = (String)recData.get('recommendation');
                rec.severity = (String)recData.get('severity');
                rec.relatedControls = new List&lt;String&gt;();
                rec.suggestedActions = new List&lt;String&gt;();
                
                List&lt;Object&gt; controls = (List&lt;Object&gt;)recData.get('relatedControls');
                if (controls != null) {
                    for (Object ctrl : controls) {
                        rec.relatedControls.add(String.valueOf(ctrl));
                    }
                }
                
                List&lt;Object&gt; actions = (List&lt;Object&gt;)recData.get('suggestedActions');
                if (actions != null) {
                    for (Object action : actions) {
                        rec.suggestedActions.add(String.valueOf(action));
                    }
                }
                
                rec.confidence = recData.containsKey('confidence') 
                    ? Integer.valueOf(recData.get('confidence')) 
                    : 70;
            }
        } catch (Exception e) {
            rec = createDefaultRecommendation('Error parsing response');
        }
        
        return rec;
    }
    
    private static String extractTextFromResponse(String response) {
        try {
            Map&lt;String, Object&gt; responseMap = (Map&lt;String, Object&gt;)JSON.deserializeUntyped(response);
            List&lt;Object&gt; content = (List&lt;Object&gt;)responseMap.get('content');
            
            if (content != null &amp;&amp; !content.isEmpty()) {
                Map&lt;String, Object&gt; firstContent = (Map&lt;String, Object&gt;)content[0];
                return (String)firstContent.get('text');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error extracting text: ' + e.getMessage());
        }
        
        return 'Unable to generate summary.';
    }
    
    private static List&lt;RiskPrediction&gt; parseRiskPredictions(String response) {
        List&lt;RiskPrediction&gt; predictions = new List&lt;RiskPrediction&gt;();
        
        try {
            String text = extractTextFromResponse(response);
            List&lt;Object&gt; predList = (List&lt;Object&gt;)JSON.deserializeUntyped(text);
            
            for (Object predObj : predList) {
                Map&lt;String, Object&gt; pred = (Map&lt;String, Object&gt;)predObj;
                
                RiskPrediction rp = new RiskPrediction();
                rp.controlId = (String)pred.get('controlId');
                rp.riskProbability = pred.containsKey('riskProbability') 
                    ? Decimal.valueOf(String.valueOf(pred.get('riskProbability'))) 
                    : 50;
                rp.riskReason = (String)pred.get('riskReason');
                
                String dateStr = (String)pred.get('predictedDate');
                if (String.isNotBlank(dateStr)) {
                    try {
                        rp.predictedDate = Date.valueOf(dateStr);
                    } catch (Exception e) {
                        rp.predictedDate = Date.today().addDays(30);
                    }
                }
                
                predictions.add(rp);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error parsing predictions: ' + e.getMessage());
        }
        
        return predictions;
    }
    
    private static Map&lt;String, String&gt; parseCategorizationResponse(String response, 
                                                                    List&lt;Prometheion_Evidence_Item__c&gt; items) {
        Map&lt;String, String&gt; mappings = new Map&lt;String, String&gt;();
        
        try {
            String text = extractTextFromResponse(response);
            Map&lt;String, Object&gt; catMap = (Map&lt;String, Object&gt;)JSON.deserializeUntyped(text);
            
            for (String key : catMap.keySet()) {
                mappings.put(key, String.valueOf(catMap.get(key)));
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error parsing categorization: ' + e.getMessage());
        }
        
        return mappings;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS - CACHING
    // ═══════════════════════════════════════════════════════════════
    
    private static ComplianceRecommendation getCachedRecommendation(String key) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            return (ComplianceRecommendation)partition.get(key);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheRecommendation(String key, ComplianceRecommendation rec) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            partition.put(key, rec, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Cache put failed: ' + e.getMessage());
        }
    }
    
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
    
    private static List&lt;RiskPrediction&gt; getCachedRiskPredictions(String key) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            return (List&lt;RiskPrediction&gt;)partition.get(key);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheRiskPredictions(String key, List&lt;RiskPrediction&gt; predictions) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            partition.put(key, predictions, CACHE_TTL_SECONDS);
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Cache put failed: ' + e.getMessage());
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static ComplianceRecommendation createDefaultRecommendation(String message) {
        ComplianceRecommendation rec = new ComplianceRecommendation();
        rec.recommendation = message;
        rec.severity = 'MEDIUM';
        rec.relatedControls = new List&lt;String&gt;();
        rec.suggestedActions = new List&lt;String&gt;{'Review event logs manually', 'Consult compliance team'};
        rec.confidence = 50;
        return rec;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Compliance recommendation result
     */
    public class ComplianceRecommendation {
        @AuraEnabled public String recommendation;
        @AuraEnabled public String severity; // CRITICAL, HIGH, MEDIUM, LOW
        @AuraEnabled public List&lt;String&gt; relatedControls;
        @AuraEnabled public List&lt;String&gt; suggestedActions;
        @AuraEnabled public Integer confidence; // 0-100
    }
    
    /**
     * @description Risk prediction result
     */
    public class RiskPrediction {
        @AuraEnabled public String controlId;
        @AuraEnabled public Decimal riskProbability; // 0-100
        @AuraEnabled public String riskReason;
        @AuraEnabled public Date predictedDate;
    }
}
