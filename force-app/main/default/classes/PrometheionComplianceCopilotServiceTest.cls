/**
 * @description Unit tests for PrometheionComplianceCopilotService
 * @group Tests
 */
@isTest
private class PrometheionComplianceCopilotServiceTest {
    
    @testSetup
    static void setupTestData() {
        Prometheion_Audit_Package__c pkg = PrometheionTestDataFactory.createAuditPackage('HIPAA');
        PrometheionTestDataFactory.createEvidenceItems(pkg.Id, 10);
        PrometheionTestDataFactory.createFrameworkMappings('HIPAA');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // analyzeEventPattern Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testAnalyzeEventPattern_ReturnsRecommendation() {
        List&lt;Prometheion_Evidence_Item__c&gt; items = [
            SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 5
        ];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Prometheion_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        PrometheionComplianceCopilotService.ComplianceRecommendation rec = 
            PrometheionComplianceCopilotService.analyzeEventPattern(eventIds);
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Should return recommendation');
        System.assertNotEquals(null, rec.recommendation, 'Should have recommendation text');
        System.assertNotEquals(null, rec.severity, 'Should have severity');
        System.assert(rec.confidence &gt;= 0 &amp;&amp; rec.confidence &lt;= 100, 'Confidence should be 0-100');
    }
    
    @isTest
    static void testAnalyzeEventPattern_EmptyList_ReturnsDefaultRecommendation() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        PrometheionComplianceCopilotService.ComplianceRecommendation rec = 
            PrometheionComplianceCopilotService.analyzeEventPattern(new List&lt;String&gt;());
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Should return recommendation even for empty list');
        System.assert(rec.recommendation.contains('No events'), 'Should indicate no events');
    }
    
    @isTest
    static void testAnalyzeEventPattern_NullList_ReturnsDefaultRecommendation() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        PrometheionComplianceCopilotService.ComplianceRecommendation rec = 
            PrometheionComplianceCopilotService.analyzeEventPattern(null);
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Should return recommendation for null list');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateAuditSummary Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateAuditSummary_ReturnsSummaryText() {
        Prometheion_Audit_Package__c pkg = [SELECT Id FROM Prometheion_Audit_Package__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        String summary = PrometheionComplianceCopilotService.generateAuditSummary(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Should return summary');
        System.assert(summary.length() &gt; 0, 'Summary should not be empty');
    }
    
    @isTest
    static void testGenerateAuditSummary_NullPackageId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        try {
            PrometheionComplianceCopilotService.generateAuditSummary(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testGenerateAuditSummary_BlankPackageId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        try {
            PrometheionComplianceCopilotService.generateAuditSummary('');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // predictComplianceRisks Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testPredictComplianceRisks_ReturnsPredictions() {
        Test.setMock(HttpCalloutMock.class, new ClaudeRiskPredictionMock());
        
        Test.startTest();
        List&lt;PrometheionComplianceCopilotService.RiskPrediction&gt; predictions = 
            PrometheionComplianceCopilotService.predictComplianceRisks('HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, predictions, 'Should return predictions');
        // May be empty if no relevant data
    }
    
    @isTest
    static void testPredictComplianceRisks_NullFramework_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ClaudeRiskPredictionMock());
        
        Test.startTest();
        try {
            PrometheionComplianceCopilotService.predictComplianceRisks(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // categorizeEvents Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testCategorizeEvents_ReturnsMappings() {
        List&lt;Prometheion_Evidence_Item__c&gt; items = [
            SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 3
        ];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Prometheion_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            PrometheionComplianceCopilotService.categorizeEvents(eventIds, 'HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, mappings, 'Should return mappings');
    }
    
    @isTest
    static void testCategorizeEvents_EmptyInput() {
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            PrometheionComplianceCopilotService.categorizeEvents(new List&lt;String&gt;(), 'HIPAA');
        Test.stopTest();
        
        System.assertEquals(0, mappings.size(), 'Should return empty map for empty input');
    }
    
    @isTest
    static void testCategorizeEvents_NullFramework() {
        List&lt;Prometheion_Evidence_Item__c&gt; items = [SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            PrometheionComplianceCopilotService.categorizeEvents(
                new List&lt;String&gt;{items[0].Id}, null);
        Test.stopTest();
        
        System.assertEquals(0, mappings.size(), 'Should return empty map for null framework');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class ClaudeAPIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(PrometheionTestDataFactory.createMockClaudeResponse());
            return res;
        }
    }
    
    private class ClaudeRiskPredictionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(PrometheionTestDataFactory.createMockRiskPredictionResponse());
            return res;
        }
    }
    
    private class ClaudeCategorizationMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            Map&lt;String, Object&gt; response = new Map&lt;String, Object&gt;{
                'content' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'text',
                        'text' =&gt; '{}'
                    }
                }
            };
            
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(JSON.serialize(response));
            return res;
        }
    }
}
