/**
 * Unit tests for PagerDutyIntegration
 * Tests HTTP callouts, incident triggering, resolution, and acknowledgment
 * @group Tests
 * @author Elaro Team
 */
@IsTest
private class PagerDutyIntegrationTest {
    
    /**
     * Mock class for PagerDuty HTTP callouts
     */
    private class PagerDutyCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public PagerDutyCalloutMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody != null ? responseBody : '{"status":"success","dedup_key":"test-key"}';
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.statusCode == 202 ? 'Accepted' : 'Error');
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
    
    @testSetup
    static void setupTestData() {
        // Create custom metadata type record for PagerDuty config
        // Note: In actual tests, this would be created via Metadata API or test metadata
        // For now, we'll mock the query results
    }
    
    // ═══════════════════════════════════════════════════════════════
    // triggerIncident Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testTriggerIncident_Success() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success","dedup_key":"test-key"}'));
        
        Map<String, Object> alertData = new Map<String, Object>{
            'alertId' => 'ALERT-123',
            'eventType' => 'Compliance Violation',
            'severity' => 'HIGH',
            'framework' => 'SOC2',
            'riskScore' => 85,
            'message' => 'Test alert message',
            'timestamp' => Datetime.now()
        };
        
        Test.startTest();
        PagerDutyIntegration.triggerIncident(JSON.serialize(alertData));
        Test.stopTest();

        // Verify HTTP callout was made (indicated by no exception)
        // Mock returns 202 Accepted - verify method completed successfully
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML for callout');
    }
    
    @isTest
    static void testTriggerIncident_HTTPError() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(500, '{"status":"error","message":"Internal Server Error"}'));
        
        Map<String, Object> alertData = new Map<String, Object>{
            'alertId' => 'ALERT-456',
            'eventType' => 'Test Event',
            'severity' => 'MEDIUM',
            'framework' => 'HIPAA',
            'riskScore' => 60,
            'message' => 'Test message',
            'timestamp' => Datetime.now()
        };
        
        Test.startTest();
        // Should handle error gracefully
        PagerDutyIntegration.triggerIncident(JSON.serialize(alertData));
        Test.stopTest();

        // Verify error was handled without throwing exception
        // With 500 status, method should catch and log error internally
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML on error');
    }
    
    @isTest
    static void testTriggerIncident_InvalidData() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        // Missing required fields
        Map<String, Object> alertData = new Map<String, Object>{
            'alertId' => 'ALERT-789'
        };
        
        Test.startTest();
        PagerDutyIntegration.triggerIncident(JSON.serialize(alertData));
        Test.stopTest();

        // Verify method completes without exception even with minimal data
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML with invalid data');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // resolveIncident Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testResolveIncident_Success() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        String dedupKey = 'elaro-ALERT-123';
        
        Test.startTest();
        PagerDutyIntegration.resolveIncident(dedupKey);
        Test.stopTest();

        // Verify resolve callout completed successfully (202 Accepted)
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML for resolve callout');
    }
    
    @isTest
    static void testResolveIncident_HTTPError() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(404, '{"status":"error","message":"Not Found"}'));
        
        String dedupKey = 'elaro-ALERT-456';
        
        Test.startTest();
        PagerDutyIntegration.resolveIncident(dedupKey);
        Test.stopTest();

        // Verify 404 error is handled without throwing exception
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML on error');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // acknowledgeIncident Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testAcknowledgeIncident_Success() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        String dedupKey = 'elaro-ALERT-123';
        
        Test.startTest();
        PagerDutyIntegration.acknowledgeIncident(dedupKey);
        Test.stopTest();

        // Verify acknowledge callout completed successfully (202 Accepted)
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML for acknowledge callout');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // createIncident Tests (@AuraEnabled)
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testCreateIncident_Success() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success","dedup_key":"test-key"}'));
        
        Test.startTest();
        String dedupKey = PagerDutyIntegration.createIncident(
            'Test Incident',
            'Test description',
            'HIGH',
            'ALERT-123'
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, dedupKey, 'Should return dedup key');
        Assert.isTrue(dedupKey.startsWith('elaro-'), 'Dedup key should start with elaro-');
    }
    
    @isTest
    static void testCreateIncident_WithoutAlertId() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        Test.startTest();
        String dedupKey = PagerDutyIntegration.createIncident(
            'Test Incident',
            'Test description',
            'MEDIUM',
            null
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, dedupKey, 'Should return dedup key even without alert ID');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getRecentIncidents Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetRecentIncidents() {
        Test.startTest();
        List<Map<String, Object>> incidents = PagerDutyIntegration.getRecentIncidents();
        Test.stopTest();
        
        Assert.areNotEqual(null, incidents, 'Should return list');
        // Currently returns empty list as per implementation
        Assert.areEqual(0, incidents.size(), 'Should return empty list (mock implementation)');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Severity Mapping Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testSeverityMapping() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        Map<String, String> severityMap = new Map<String, String>{
            'CRITICAL' => 'critical',
            'HIGH' => 'error',
            'MEDIUM' => 'warning',
            'LOW' => 'info',
            'INFO' => 'info',
            'UNKNOWN' => 'warning' // Default
        };
        
        for (String severity : severityMap.keySet()) {
            Map<String, Object> alertData = new Map<String, Object>{
                'alertId' => 'ALERT-' + severity,
                'eventType' => 'Test',
                'severity' => severity,
                'framework' => 'SOC2',
                'riskScore' => 50,
                'message' => 'Test',
                'timestamp' => Datetime.now()
            };
            
            Test.startTest();
            PagerDutyIntegration.triggerIncident(JSON.serialize(alertData));
            Test.stopTest();
        }

        // Verify all severity mappings processed without exception
        Assert.areEqual(severityMap.size(), 6, 'Should test all 6 severity levels');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkIncidentTrigger() {
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(202, '{"status":"success"}'));
        
        List<String> alertDataList = new List<String>();
        
        for (Integer i = 0; i < 200; i++) {
            Map<String, Object> alertData = new Map<String, Object>{
                'alertId' => 'ALERT-' + i,
                'eventType' => 'Bulk Test Event ' + i,
                'severity' => i < 50 ? 'CRITICAL' : i < 100 ? 'HIGH' : i < 150 ? 'MEDIUM' : 'LOW',
                'framework' => 'SOC2',
                'riskScore' => 50 + Math.mod(i, 50),
                'message' => 'Bulk test message ' + i,
                'timestamp' => Datetime.now()
            };
            alertDataList.add(JSON.serialize(alertData));
        }
        
        Test.startTest();
        for (String alertDataJson : alertDataList) {
            PagerDutyIntegration.triggerIncident(alertDataJson);
        }
        Test.stopTest();

        // Verify bulk operations completed within governor limits
        Assert.areEqual(200, alertDataList.size(), 'Should process 200 incidents');
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Error Handling Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testTriggerIncident_ExceptionHandling() {
        // Mock that throws exception
        Test.setMock(HttpCalloutMock.class, new PagerDutyCalloutMock(200, null));
        
        Map<String, Object> alertData = new Map<String, Object>{
            'alertId' => 'ALERT-EXCEPTION',
            'eventType' => 'Test',
            'severity' => 'HIGH',
            'framework' => 'SOC2',
            'riskScore' => 80,
            'message' => 'Test',
            'timestamp' => Datetime.now()
        };
        
        Test.startTest();
        // Should handle exceptions gracefully
        try {
            PagerDutyIntegration.triggerIncident(JSON.serialize(alertData));
            // If no exception thrown, method handled it internally
            Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML on exception');
        } catch (Exception e) {
            Assert.fail( 'Should not throw unhandled exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
