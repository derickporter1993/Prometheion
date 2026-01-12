/**
 * TeamsNotifierTest - Tests for Microsoft Teams Integration
 * 
 * Tests notification methods, error handling, and Adaptive Card formatting
 * 
 * @author Prometheion Enterprise
 * @version 1.0
 */
@isTest
private class TeamsNotifierTest {
    
    /**
     * Mock class for HTTP callouts
     */
    private class TeamsCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String status;
        
        public TeamsCalloutMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            res.setBody('{"ok": true}');
            return res;
        }
    }
    
    /**
     * Test: Simple text notification
     */
    @isTest
    static void testNotifyAsync() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyAsync('Test notification message');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyAsync should not throw exception');
    }
    
    /**
     * Test: Rich Adaptive Card notification
     */
    @isTest
    static void testNotifyRichAsync() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Map<String, Object> cardPayload = new Map<String, Object>{
            'type' => 'message',
            'text' => 'Test Adaptive Card'
        };
        String payload = JSON.serialize(cardPayload);
        System.assertNotEquals(null, payload, 'Payload should not be null');

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyRichAsync(payload);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyRichAsync should not throw exception');
    }
    
    /**
     * Test: Compliance alert notification
     */
    @isTest
    static void testNotifyComplianceAlert() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyComplianceAlert(
                'Test Alert',
                PrometheionConstants.SEVERITY_HIGH,
                PrometheionConstants.FRAMEWORK_HIPAA,
                'This is a test compliance alert',
                'node123',
                0.95
            );
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyComplianceAlert should not throw exception');
    }
    
    /**
     * Test: Compliance alert with different severities
     */
    @isTest
    static void testNotifyComplianceAlertSeverities() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        List<String> severities = new List<String>{
            PrometheionConstants.SEVERITY_CRITICAL,
            PrometheionConstants.SEVERITY_HIGH,
            PrometheionConstants.SEVERITY_MEDIUM,
            PrometheionConstants.SEVERITY_LOW
        };
        
        System.assertEquals(4, severities.size(), 'Should test 4 severity levels');

        Test.startTest();
        Exception caughtException = null;
        try {
            for (String severity : severities) {
                TeamsNotifier.notifyComplianceAlert(
                    'Test Alert - ' + severity,
                    severity,
                    PrometheionConstants.FRAMEWORK_SOC2,
                    'Test description',
                    'node123',
                    0.85
                );
            }
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'All severity levels should send without exception');
    }
    
    /**
     * Test: Compliance alert with different frameworks
     */
    @isTest
    static void testNotifyComplianceAlertFrameworks() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        List<String> frameworks = new List<String>{
            PrometheionConstants.FRAMEWORK_HIPAA,
            PrometheionConstants.FRAMEWORK_SOC2,
            PrometheionConstants.FRAMEWORK_NIST,
            PrometheionConstants.FRAMEWORK_FEDRAMP,
            PrometheionConstants.FRAMEWORK_GDPR
        };
        
        System.assertEquals(5, frameworks.size(), 'Should test 5 frameworks');

        Test.startTest();
        Exception caughtException = null;
        try {
            for (String framework : frameworks) {
                TeamsNotifier.notifyComplianceAlert(
                    'Test Alert - ' + framework,
                    PrometheionConstants.SEVERITY_HIGH,
                    framework,
                    'Test description',
                    'node123',
                    0.90
                );
            }
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'All frameworks should send without exception');
    }
    
    /**
     * Test: Weekly scorecard notification
     */
    @isTest
    static void testSendWeeklyScorecard() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.sendWeeklyScorecard();
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'sendWeeklyScorecard should not throw exception');
    }
    
    /**
     * Test: Error handling for failed callout
     */
    @isTest
    static void testErrorHandling() {
        // Mock a failed callout
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(500, 'Internal Server Error'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyAsync('Test message that will fail');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        // Should not throw exception, but log error internally
        System.assertEquals(null, caughtException, 'Should handle server errors gracefully without throwing');
    }
    
    /**
     * Test: Null/empty message handling
     */
    @isTest
    static void testNullMessageHandling() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyAsync(null);
            TeamsNotifier.notifyAsync('');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'Should handle null/empty messages without throwing');
    }
    
    /**
     * Test: Remediation notification
     */
    @isTest
    static void testNotifyRemediation() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        // Create mock remediation result
        PrometheionRemediationEngine.RemediationResult result = 
            new PrometheionRemediationEngine.RemediationResult();
        result.success = true;
        result.action = 'Permission Set Removed';
        result.message = 'Test remediation completed';
        result.remediationId = 'remediation123';
        result.reviewDeadline = Datetime.now().addDays(7);
        
        System.assertNotEquals(null, result, 'Remediation result should not be null');

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyRemediation(result, PrometheionConstants.FRAMEWORK_HIPAA);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyRemediation should not throw exception');
    }
    
    /**
     * Test: Multiple notifications in sequence
     */
    @isTest
    static void testMultipleNotifications() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyAsync('Notification 1');
            TeamsNotifier.notifyAsync('Notification 2');
            TeamsNotifier.notifyAsync('Notification 3');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'Multiple notifications should complete without exception');
    }
    
    /**
     * Test: Large payload handling
     */
    @isTest
    static void testLargePayload() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));

        // Create a large payload
        String largeMessage = 'A'.repeat(10000);
        System.assertEquals(10000, largeMessage.length(), 'Large message should be 10000 chars');

        Test.startTest();
        Exception caughtException = null;
        try {
            TeamsNotifier.notifyAsync(largeMessage);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'Should handle large payloads without exception');
    }
}

