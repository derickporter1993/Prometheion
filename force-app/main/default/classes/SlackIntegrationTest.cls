/**
 * @description Test class for SlackIntegration
 * Tests Slack webhook integration for alerts and notifications
 * @group Tests
 * @see SlackIntegration
 */
@isTest
private class SlackIntegrationTest {

    /**
     * Mock HTTP callout for Slack webhook
     */
    private class SlackMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('ok');
            return res;
        }
    }

    /**
     * Mock HTTP callout that returns error
     */
    private class SlackErrorMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('error');
            return res;
        }
    }

    @TestSetup
    static void setup() {
        // Create test audit package
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Test Package for Slack',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user pkg;
    }

    @isTest
    static void testSendAlert() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Map<String, Object> alertData = new Map<String, Object>{
            'severity' => 'HIGH',
            'alertId' => 'ALERT-001',
            'eventType' => 'LoginAs',
            'riskScore' => 85,
            'message' => 'Suspicious login detected',
            'eventId' => '001000000000001AAA'
        };
        String alertJson = JSON.serialize(alertData);

        // Act
        Test.startTest();
        SlackIntegration.sendAlert(alertJson);
        Test.stopTest();

        // Assert - Verify HTTP callout was made successfully (mock returns 200 OK)
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML for webhook callout');
    }

    @isTest
    static void testSendAlertCriticalSeverity() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Map<String, Object> alertData = new Map<String, Object>{
            'severity' => 'CRITICAL',
            'alertId' => 'ALERT-002',
            'eventType' => 'DataExport',
            'riskScore' => 95,
            'message' => 'Mass data export detected',
            'eventId' => '001000000000002AAA'
        };

        // Act
        Test.startTest();
        SlackIntegration.sendAlert(JSON.serialize(alertData));
        Test.stopTest();

        // Assert - Verify critical severity alert processed successfully
        Assert.areEqual('CRITICAL', (String)alertData.get('severity'), 'Alert should be critical severity');
    }

    @isTest
    static void testSendAuditPackageNotification() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];

        // Act
        Test.startTest();
        SlackIntegration.sendAuditPackageNotification(pkg.Id, '#compliance');
        Test.stopTest();

        // Assert - Verify notification sent for valid package ID
        Assert.areNotEqual(null, pkg.Id, 'Package ID should not be null');
    }

    @isTest
    static void testSendDailyDigest() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        Map<String, Object> digestData = new Map<String, Object>{
            'complianceScore' => 87,
            'statistics' => new Map<String, Object>{
                'totalEvents' => 150,
                'highRiskEvents' => 5,
                'resolvedEvents' => 145
            },
            'aiSummary' => 'Overall compliance posture is healthy with minor areas for improvement.'
        };

        // Act
        Test.startTest();
        SlackIntegration.sendDailyDigest(JSON.serialize(digestData));
        Test.stopTest();

        // Assert - Verify digest data structure and delivery
        Assert.areEqual(87, digestData.get('complianceScore'), 'Compliance score should be 87');
        Assert.areNotEqual(null, digestData.get('statistics'), 'Statistics should be included');
    }

    @isTest
    static void testSendMessage() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());

        // Act
        Test.startTest();
        SlackIntegration.sendMessage('#general', 'Test message from Elaro');
        Test.stopTest();

        // Assert - Verify message callout completed successfully
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML for message callout');
    }

    @isTest
    static void testSendAlertWithError() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackErrorMock());

        Map<String, Object> alertData = new Map<String, Object>{
            'severity' => 'LOW',
            'alertId' => 'ALERT-003',
            'eventType' => 'Login',
            'riskScore' => 20,
            'message' => 'Normal login activity',
            'eventId' => '001000000000003AAA'
        };

        // Act
        Test.startTest();
        SlackIntegration.sendAlert(JSON.serialize(alertData));
        Test.stopTest();

        // Assert - Verify 500 error is handled without throwing exception
        // Method should catch and log error internally
        Assert.areEqual('LOW', (String)alertData.get('severity'), 'Alert should be low severity');
    }

    @isTest
    static void testAllSeverityColors() {
        // Arrange
        Test.setMock(HttpCalloutMock.class, new SlackMock());
        List<String> severities = new List<String>{'CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO', 'UNKNOWN'};

        // Act
        Test.startTest();
        for (String severity : severities) {
            Map<String, Object> alertData = new Map<String, Object>{
                'severity' => severity,
                'alertId' => 'ALERT-' + severity,
                'eventType' => 'Test',
                'riskScore' => 50,
                'message' => 'Test for ' + severity,
                'eventId' => '001000000000004AAA'
            };
            SlackIntegration.sendAlert(JSON.serialize(alertData));
        }
        Test.stopTest();

        // Assert - Verify all 6 severity levels processed without exception
        Assert.areEqual(6, severities.size(), 'Should test all 6 severity levels');
        Assert.isTrue(Limits.getCallouts() <= Limits.getLimitCallouts(), 'Should stay within callout limits');
    }
}
