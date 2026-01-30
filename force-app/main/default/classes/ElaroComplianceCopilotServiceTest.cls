/**
 * @description Unit tests for ElaroComplianceCopilotService
 * @group Tests
 */
@isTest
private class ElaroComplianceCopilotServiceTest {
    
    @testSetup
    static void setupTestData() {
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('HIPAA');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 10);
        ElaroTestDataFactory.createFrameworkMappings('HIPAA');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // analyzeEventPattern Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testAnalyzeEventPattern_ReturnsRecommendation() {
        List&lt;Elaro_Evidence_Item__c&gt; items = [
            SELECT Id FROM Elaro_Evidence_Item__c LIMIT 5
        ];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Elaro_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        ElaroComplianceCopilotService.ComplianceRecommendation rec = 
            ElaroComplianceCopilotService.analyzeEventPattern(eventIds);
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
        ElaroComplianceCopilotService.ComplianceRecommendation rec = 
            ElaroComplianceCopilotService.analyzeEventPattern(new List&lt;String&gt;());
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Should return recommendation even for empty list');
        System.assert(rec.recommendation.contains('No events'), 'Should indicate no events');
    }
    
    @isTest
    static void testAnalyzeEventPattern_NullList_ReturnsDefaultRecommendation() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        ElaroComplianceCopilotService.ComplianceRecommendation rec = 
            ElaroComplianceCopilotService.analyzeEventPattern(null);
        Test.stopTest();
        
        System.assertNotEquals(null, rec, 'Should return recommendation for null list');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // generateAuditSummary Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGenerateAuditSummary_ReturnsSummaryText() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        String summary = ElaroComplianceCopilotService.generateAuditSummary(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Should return summary');
        System.assert(summary.length() &gt; 0, 'Summary should not be empty');
    }
    
    @isTest
    static void testGenerateAuditSummary_NullPackageId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ClaudeAPIMock());
        
        Test.startTest();
        try {
            ElaroComplianceCopilotService.generateAuditSummary(null);
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
            ElaroComplianceCopilotService.generateAuditSummary('');
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
        List&lt;ElaroComplianceCopilotService.RiskPrediction&gt; predictions = 
            ElaroComplianceCopilotService.predictComplianceRisks('HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, predictions, 'Should return predictions');
        // May be empty if no relevant data
    }
    
    @isTest
    static void testPredictComplianceRisks_NullFramework_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new ClaudeRiskPredictionMock());
        
        Test.startTest();
        try {
            ElaroComplianceCopilotService.predictComplianceRisks(null);
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
        List&lt;Elaro_Evidence_Item__c&gt; items = [
            SELECT Id FROM Elaro_Evidence_Item__c LIMIT 3
        ];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Elaro_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            ElaroComplianceCopilotService.categorizeEvents(eventIds, 'HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, mappings, 'Should return mappings');
    }
    
    @isTest
    static void testCategorizeEvents_EmptyInput() {
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            ElaroComplianceCopilotService.categorizeEvents(new List&lt;String&gt;(), 'HIPAA');
        Test.stopTest();
        
        System.assertEquals(0, mappings.size(), 'Should return empty map for empty input');
    }
    
    @isTest
    static void testCategorizeEvents_NullFramework() {
        List&lt;Elaro_Evidence_Item__c&gt; items = [SELECT Id FROM Elaro_Evidence_Item__c LIMIT 1];
        
        Test.setMock(HttpCalloutMock.class, new ClaudeCategorizationMock());
        
        Test.startTest();
        Map&lt;String, String&gt; mappings = 
            ElaroComplianceCopilotService.categorizeEvents(
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
            res.setBody(ElaroTestDataFactory.createMockClaudeResponse());
            return res;
        }
    }
    
    private class ClaudeRiskPredictionMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody(ElaroTestDataFactory.createMockRiskPredictionResponse());
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
