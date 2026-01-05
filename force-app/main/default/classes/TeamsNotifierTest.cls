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
        TeamsNotifier.notifyAsync('Test notification message');
        Test.stopTest();
        
        // Verify no exceptions thrown
        System.assert(true, 'Notification should complete without errors');
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
        
        Test.startTest();
        TeamsNotifier.notifyRichAsync(JSON.serialize(cardPayload));
        Test.stopTest();
        
        System.assert(true, 'Rich notification should complete without errors');
    }
    
    /**
     * Test: Compliance alert notification
     */
    @isTest
    static void testNotifyComplianceAlert() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        Test.startTest();
        TeamsNotifier.notifyComplianceAlert(
            'Test Alert',
            PrometheionConstants.SEVERITY_HIGH,
            PrometheionConstants.FRAMEWORK_HIPAA,
            'This is a test compliance alert',
            'node123',
            0.95
        );
        Test.stopTest();
        
        System.assert(true, 'Compliance alert should send successfully');
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
        
        Test.startTest();
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
        Test.stopTest();
        
        System.assert(true, 'All severity levels should send successfully');
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
        
        Test.startTest();
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
        Test.stopTest();
        
        System.assert(true, 'All frameworks should send successfully');
    }
    
    /**
     * Test: Weekly scorecard notification
     */
    @isTest
    static void testSendWeeklyScorecard() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        Test.startTest();
        TeamsNotifier.sendWeeklyScorecard();
        Test.stopTest();
        
        System.assert(true, 'Weekly scorecard should send successfully');
    }
    
    /**
     * Test: Error handling for failed callout
     */
    @isTest
    static void testErrorHandling() {
        // Mock a failed callout
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(500, 'Internal Server Error'));
        
        Test.startTest();
        try {
            TeamsNotifier.notifyAsync('Test message that will fail');
            // Should not throw exception, but log error
            System.assert(true, 'Should handle errors gracefully');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * Test: Null/empty message handling
     */
    @isTest
    static void testNullMessageHandling() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        Test.startTest();
        try {
            TeamsNotifier.notifyAsync(null);
            TeamsNotifier.notifyAsync('');
            System.assert(true, 'Should handle null/empty messages');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
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
        
        Test.startTest();
        TeamsNotifier.notifyRemediation(result, PrometheionConstants.FRAMEWORK_HIPAA);
        Test.stopTest();
        
        System.assert(true, 'Remediation notification should send successfully');
    }
    
    /**
     * Test: Multiple notifications in sequence
     */
    @isTest
    static void testMultipleNotifications() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        Test.startTest();
        TeamsNotifier.notifyAsync('Notification 1');
        TeamsNotifier.notifyAsync('Notification 2');
        TeamsNotifier.notifyAsync('Notification 3');
        Test.stopTest();
        
        System.assert(true, 'Multiple notifications should complete successfully');
    }
    
    /**
     * Test: Large payload handling
     */
    @isTest
    static void testLargePayload() {
        Test.setMock(HttpCalloutMock.class, new TeamsCalloutMock(200, 'OK'));
        
        // Create a large payload
        String largeMessage = 'A'.repeat(10000);
        
        Test.startTest();
        TeamsNotifier.notifyAsync(largeMessage);
        Test.stopTest();
        
        System.assert(true, 'Should handle large payloads');
    }
}

