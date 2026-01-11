/**
 * @description Unit tests for RootCauseAnalysisEngine
 * @group Tests
 */
@isTest
private class RootCauseAnalysisEngineTest {
    
    @testSetup
    static void setupTestData() {
        Prometheion_Audit_Package__c pkg = PrometheionTestDataFactory.createAuditPackage('HIPAA');
        PrometheionTestDataFactory.createEvidenceItems(pkg.Id, 10);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // analyzeRootCause Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testAnalyzeRootCause_ReturnsResult() {
        Prometheion_Evidence_Item__c item = [
            SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 1
        ];
        
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        RootCauseAnalysisEngine.RootCauseResult result = 
            RootCauseAnalysisEngine.analyzeRootCause(item.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result');
        System.assertEquals('SUCCESS', result.status, 'Status should be SUCCESS');
        System.assertNotEquals(null, result.rootCause, 'Should have root cause');
        System.assert(result.confidence &gt;= 0 &amp;&amp; result.confidence &lt;= 100, 'Confidence should be 0-100');
    }
    
    @isTest
    static void testAnalyzeRootCause_NullId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        try {
            RootCauseAnalysisEngine.analyzeRootCause(null);
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAnalyzeRootCause_BlankId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        try {
            RootCauseAnalysisEngine.analyzeRootCause('');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should mention required');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testAnalyzeRootCause_InvalidId_ThrowsException() {
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        try {
            RootCauseAnalysisEngine.analyzeRootCause('a0x000000000001AAA');
            System.assert(false, 'Should throw exception');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('not found'), 'Should mention not found');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // batchAnalyze Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBatchAnalyze_ReturnsMultipleResults() {
        List&lt;Prometheion_Evidence_Item__c&gt; items = [
            SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 3
        ];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Prometheion_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        List&lt;RootCauseAnalysisEngine.RootCauseResult&gt; results = 
            RootCauseAnalysisEngine.batchAnalyze(eventIds);
        Test.stopTest();
        
        System.assertEquals(eventIds.size(), results.size(), 'Should return result for each event');
    }
    
    @isTest
    static void testBatchAnalyze_EmptyList() {
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        List&lt;RootCauseAnalysisEngine.RootCauseResult&gt; results = 
            RootCauseAnalysisEngine.batchAnalyze(new List&lt;String&gt;());
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }
    
    @isTest
    static void testBatchAnalyze_NullList() {
        Test.setMock(HttpCalloutMock.class, new RootCauseAPIMock());
        
        Test.startTest();
        List&lt;RootCauseAnalysisEngine.RootCauseResult&gt; results = 
            RootCauseAnalysisEngine.batchAnalyze(null);
        Test.stopTest();
        
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getAnalysisSummary Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetAnalysisSummary_ReturnsSummary() {
        List&lt;Prometheion_Evidence_Item__c&gt; items = [SELECT Id FROM Prometheion_Evidence_Item__c LIMIT 5];
        
        List&lt;String&gt; eventIds = new List&lt;String&gt;();
        for (Prometheion_Evidence_Item__c item : items) {
            eventIds.add(item.Id);
        }
        
        Test.startTest();
        RootCauseAnalysisEngine.AnalysisSummary summary = 
            RootCauseAnalysisEngine.getAnalysisSummary(eventIds);
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Should return summary');
        System.assertEquals(eventIds.size(), summary.totalEvents, 'Should have correct total');
    }
    
    @isTest
    static void testGetAnalysisSummary_EmptyList() {
        Test.startTest();
        RootCauseAnalysisEngine.AnalysisSummary summary = 
            RootCauseAnalysisEngine.getAnalysisSummary(new List&lt;String&gt;());
        Test.stopTest();
        
        System.assertEquals(0, summary.totalEvents, 'Should have 0 total events');
    }
    
    @isTest
    static void testGetAnalysisSummary_NullList() {
        Test.startTest();
        RootCauseAnalysisEngine.AnalysisSummary summary = 
            RootCauseAnalysisEngine.getAnalysisSummary(null);
        Test.stopTest();
        
        System.assertEquals(0, summary.totalEvents, 'Should have 0 total events for null');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class RootCauseAPIMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            Map&lt;String, Object&gt; response = new Map&lt;String, Object&gt;{
                'content' =&gt; new List&lt;Map&lt;String, Object&gt;&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'text',
                        'text' =&gt; JSON.serialize(new Map&lt;String, Object&gt;{
                            'rootCause' =&gt; 'Unauthorized access attempt from suspicious IP',
                            'confidence' =&gt; 85,
                            'contributingFactors' =&gt; new List&lt;String&gt;{
                                'Non-standard login hours',
                                'Foreign IP address'
                            },
                            'evidenceChain' =&gt; new List&lt;String&gt;{
                                'Login attempt at 2 AM',
                                'Multiple failed attempts before success'
                            },
                            'remediation' =&gt; new List&lt;String&gt;{
                                'Enable MFA for this user',
                                'Review access policies'
                            },
                            'preventionMeasures' =&gt; new List&lt;String&gt;{
                                'Implement geo-blocking',
                                'Add time-based access controls'
                            }
                        })
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
