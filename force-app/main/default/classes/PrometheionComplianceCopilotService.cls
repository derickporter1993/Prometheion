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
    public static ComplianceRecommendation analyzeEventPattern(List<String> eventIds) {
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
            List<Prometheion_Evidence_Item__c> items = [
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
            List<AggregateResult> typeDistribution = [
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
    public static List<RiskPrediction> predictComplianceRisks(String framework) {
        if (String.isBlank(framework)) {
            throw new AuraHandledException('Framework is required');
        }
        
        // Check cache
        String cacheKey = 'risks_' + framework;
        List<RiskPrediction> cached = getCachedRiskPredictions(cacheKey);
        if (cached != null) {
            return cached;
        }
        
        try {
            // Get recent evidence for analysis
            List<Prometheion_Evidence_Item__c> recentEvidence = [
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
            List<RiskPrediction> predictions = parseRiskPredictions(response);
            
            // Cache result
            cacheRiskPredictions(cacheKey, predictions);
            
            return predictions;
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error predicting risks: ' + e.getMessage());
            return new List<RiskPrediction>();
        }
    }
    
    /**
     * @description Auto-categorize events to framework controls
     * @param eventIds List of evidence item IDs
     * @param framework The target compliance framework
     * @return Map of event ID to control ID
     */
    @AuraEnabled
    public static Map<String, String> categorizeEvents(List<String> eventIds, String framework) {
        Map<String, String> mappings = new Map<String, String>();
        
        if (eventIds == null || eventIds.isEmpty() || String.isBlank(framework)) {
            return mappings;
        }
        
        try {
            // Query events
            List<Prometheion_Evidence_Item__c> items = [
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
        Map<String, Object> requestBody = new Map<String, Object>{
            'model' => CLAUDE_MODEL,
            'max_tokens' => MAX_TOKENS,
            'system' => SYSTEM_PROMPT,
            'messages' => new List<Map<String, Object>>{
                new Map<String, Object>{
                    'role' => 'user',
                    'content' => userPrompt
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
    
    private static String buildAnalysisPrompt(List<Prometheion_Evidence_Item__c> items) {
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
                                             List<AggregateResult> typeDistribution) {
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
    
    private static String buildPredictionPrompt(String framework, List<Prometheion_Evidence_Item__c> evidence) {
        Map<String, Integer> typeCounts = new Map<String, Integer>();
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
    
    private static String buildCategorizationPrompt(List<Prometheion_Evidence_Item__c> items, String framework) {
        List<Map<String, String>> simpleItems = new List<Map<String, String>>();
        for (Prometheion_Evidence_Item__c item : items) {
            simpleItems.add(new Map<String, String>{
                'id' => item.Id,
                'type' => item.Evidence_Type__c,
                'description' => item.Description__c
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
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            List<Object> content = (List<Object>)responseMap.get('content');
            
            if (content != null &amp;&amp; !content.isEmpty()) {
                Map<String, Object> firstContent = (Map<String, Object>)content[0];
                String text = (String)firstContent.get('text');
                
                // Parse the JSON response
                Map<String, Object> recData = (Map<String, Object>)JSON.deserializeUntyped(text);
                
                rec.recommendation = (String)recData.get('recommendation');
                rec.severity = (String)recData.get('severity');
                rec.relatedControls = new List<String>();
                rec.suggestedActions = new List<String>();
                
                List<Object> controls = (List<Object>)recData.get('relatedControls');
                if (controls != null) {
                    for (Object ctrl : controls) {
                        rec.relatedControls.add(String.valueOf(ctrl));
                    }
                }
                
                List<Object> actions = (List<Object>)recData.get('suggestedActions');
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
            Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response);
            List<Object> content = (List<Object>)responseMap.get('content');
            
            if (content != null &amp;&amp; !content.isEmpty()) {
                Map<String, Object> firstContent = (Map<String, Object>)content[0];
                return (String)firstContent.get('text');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Error extracting text: ' + e.getMessage());
        }
        
        return 'Unable to generate summary.';
    }
    
    private static List<RiskPrediction> parseRiskPredictions(String response) {
        List<RiskPrediction> predictions = new List<RiskPrediction>();
        
        try {
            String text = extractTextFromResponse(response);
            List<Object> predList = (List<Object>)JSON.deserializeUntyped(text);
            
            for (Object predObj : predList) {
                Map<String, Object> pred = (Map<String, Object>)predObj;
                
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
    
    private static Map<String, String> parseCategorizationResponse(String response, 
                                                                    List<Prometheion_Evidence_Item__c> items) {
        Map<String, String> mappings = new Map<String, String>();
        
        try {
            String text = extractTextFromResponse(response);
            Map<String, Object> catMap = (Map<String, Object>)JSON.deserializeUntyped(text);
            
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
    
    private static List<RiskPrediction> getCachedRiskPredictions(String key) {
        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(CACHE_PARTITION);
            return (List<RiskPrediction>)partition.get(key);
        } catch (Exception e) {
            return null;
        }
    }
    
    private static void cacheRiskPredictions(String key, List<RiskPrediction> predictions) {
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
        rec.relatedControls = new List<String>();
        rec.suggestedActions = new List<String>{'Review event logs manually', 'Consult compliance team'};
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
        @AuraEnabled public List<String> relatedControls;
        @AuraEnabled public List<String> suggestedActions;
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
