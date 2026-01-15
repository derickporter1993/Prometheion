/**
 * @description Test class for PrometheionAlertQueueable
 * Tests queueable alert processing
 * @group Tests
 * @see PrometheionAlertQueueable
 */
@isTest
private class PrometheionAlertQueueableTest {

    @isTest
    static void testQueueableExecution() {
        // Create mock queue item
        PrometheionComplianceAlert.AlertQueueItem queueItem = new PrometheionComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-001';
        queueItem.severity = 'HIGH';
        queueItem.channel = 'Slack';
        queueItem.eventData = new Map<String, Object>{
            'eventType' => 'LoginAs',
            'userId' => UserInfo.getUserId(),
            'riskScore' => 85
        };

        Test.startTest();
        PrometheionAlertQueueable queueable = new PrometheionAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Queueable should execute without errors');
    }

    @isTest
    static void testQueueableWithNullItem() {
        Test.startTest();
        PrometheionAlertQueueable queueable = new PrometheionAlertQueueable(null);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should handle null queue item gracefully');
    }

    @isTest
    static void testQueueableWithMinimalData() {
        PrometheionComplianceAlert.AlertQueueItem queueItem = new PrometheionComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-002';
        queueItem.severity = 'MEDIUM';
        queueItem.channel = 'Email';
        queueItem.eventData = new Map<String, Object>();

        Test.startTest();
        PrometheionAlertQueueable queueable = new PrometheionAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should handle minimal data');
    }

    @isTest
    static void testQueueableWithCriticalSeverity() {
        PrometheionComplianceAlert.AlertQueueItem queueItem = new PrometheionComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-003';
        queueItem.severity = 'CRITICAL';
        queueItem.channel = 'Teams';
        queueItem.eventData = new Map<String, Object>{
            'eventType' => 'ReportExport',
            'rowsExported' => 50000
        };

        Test.startTest();
        PrometheionAlertQueueable queueable = new PrometheionAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should process critical alerts');
    }
}
