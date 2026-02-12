/**
 * Tests for ComplianceAlertPublisher covering single and bulk event publishing,
 * drift alerts, breach indicators, and error handling.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see ComplianceAlertPublisher
 */
@IsTest(testFor=ComplianceAlertPublisher.class)
private class ComplianceAlertPublisherTest {

    @IsTest
    static void shouldPublishSingleAlert() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishAlert(
            'SOC2',
            'CC6.1',
            ElaroConstants.SEVERITY_HIGH,
            'Excessive admin permissions detected',
            ComplianceAlertPublisher.ALERT_TYPE_FINDING,
            '001000000000001AAA'
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Alert should publish successfully');
    }

    @IsTest
    static void shouldPublishAlertWithNullSeverity() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishAlert(
            'HIPAA',
            'AC-2',
            null,
            'Test finding',
            null,
            null
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Alert with null severity should default and publish');
    }

    @IsTest
    static void shouldPublishBulkAlerts() {
        List<ComplianceAlert__e> alerts = new List<ComplianceAlert__e>();
        for (Integer i = 0; i < 5; i++) {
            alerts.add(new ComplianceAlert__e(
                Framework__c = 'SOC2',
                Control_Reference__c = 'CC' + i + '.1',
                Severity__c = ElaroConstants.SEVERITY_MEDIUM,
                Finding_Summary__c = 'Bulk finding ' + i,
                Alert_Type__c = ComplianceAlertPublisher.ALERT_TYPE_FINDING,
                Source_Record_Id__c = null
            ));
        }

        Test.startTest();
        List<Database.SaveResult> results = ComplianceAlertPublisher.publishAlerts(alerts);
        Test.stopTest();

        Assert.areEqual(5, results.size(), 'Should return 5 results');
        for (Database.SaveResult sr : results) {
            Assert.isTrue(sr.isSuccess(), 'Each alert should publish successfully');
        }
    }

    @IsTest
    static void shouldHandleEmptyBulkAlerts() {
        Test.startTest();
        List<Database.SaveResult> results = ComplianceAlertPublisher.publishAlerts(
            new List<ComplianceAlert__e>()
        );
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Empty list should return empty results');
    }

    @IsTest
    static void shouldHandleNullBulkAlerts() {
        Test.startTest();
        List<Database.SaveResult> results = ComplianceAlertPublisher.publishAlerts(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Null list should return empty results');
    }

    @IsTest
    static void shouldPublishDriftAlert() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishDriftAlert(
            'Security Setting Changed',
            'admin@test.org',
            'Session Settings',
            'HttpsRequired=true',
            'HttpsRequired=false',
            ElaroConstants.SEVERITY_HIGH
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Drift alert should publish successfully');
    }

    @IsTest
    static void shouldPublishDriftAlertWithNullRiskLevel() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishDriftAlert(
            'Config Change',
            'user@test.org',
            'Custom Objects',
            null,
            'New value',
            null
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Drift alert with null risk level should default');
    }

    @IsTest
    static void shouldPublishBreachIndicator() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishBreachIndicator(
            'Brute Force Login',
            ElaroConstants.SEVERITY_CRITICAL,
            '["LOGIN_FAILURE","LOGIN_FAILURE","LOGIN_FAILURE"]',
            15,
            '005000000000001AAA'
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Breach indicator should publish successfully');
    }

    @IsTest
    static void shouldPublishBreachIndicatorWithNullSeverity() {
        Test.startTest();
        Database.SaveResult result = ComplianceAlertPublisher.publishBreachIndicator(
            'Unknown Pattern',
            null,
            '[]',
            30,
            null
        );
        Test.stopTest();

        Assert.isNotNull(result, 'SaveResult should not be null');
        Assert.isTrue(result.isSuccess(), 'Breach with null severity should default to CRITICAL');
    }

    @IsTest
    static void shouldExposeAlertTypeConstants() {
        Assert.areEqual('FINDING', ComplianceAlertPublisher.ALERT_TYPE_FINDING,
            'FINDING constant should match');
        Assert.areEqual('DRIFT', ComplianceAlertPublisher.ALERT_TYPE_DRIFT,
            'DRIFT constant should match');
        Assert.areEqual('BREACH', ComplianceAlertPublisher.ALERT_TYPE_BREACH,
            'BREACH constant should match');
        Assert.areEqual('THRESHOLD', ComplianceAlertPublisher.ALERT_TYPE_THRESHOLD,
            'THRESHOLD constant should match');
        Assert.areEqual('POLICY_VIOLATION', ComplianceAlertPublisher.ALERT_TYPE_POLICY,
            'POLICY_VIOLATION constant should match');
    }
}
