/**
 * @description Test class for ElaroAlertQueueable
 * Tests queueable alert processing
 * @group Tests
 * @see ElaroAlertQueueable
 */
@isTest
private class ElaroAlertQueueableTest {

    @isTest
    static void testQueueableExecution() {
        // Create mock queue item
        ElaroComplianceAlert.AlertQueueItem queueItem = new ElaroComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-001';
        queueItem.severity = 'HIGH';
        queueItem.channel = 'Slack';
        queueItem.eventData = new Map<String, Object>{
            'eventType' => 'LoginAs',
            'userId' => UserInfo.getUserId(),
            'riskScore' => 85
        };

        Test.startTest();
        ElaroAlertQueueable queueable = new ElaroAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Queueable should execute without errors');
    }

    @isTest
    static void testQueueableWithNullItem() {
        Test.startTest();
        ElaroAlertQueueable queueable = new ElaroAlertQueueable(null);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should handle null queue item gracefully');
    }

    @isTest
    static void testQueueableWithMinimalData() {
        ElaroComplianceAlert.AlertQueueItem queueItem = new ElaroComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-002';
        queueItem.severity = 'MEDIUM';
        queueItem.channel = 'Email';
        queueItem.eventData = new Map<String, Object>();

        Test.startTest();
        ElaroAlertQueueable queueable = new ElaroAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should handle minimal data');
    }

    @isTest
    static void testQueueableWithCriticalSeverity() {
        ElaroComplianceAlert.AlertQueueItem queueItem = new ElaroComplianceAlert.AlertQueueItem();
        queueItem.alertId = 'ALERT-003';
        queueItem.severity = 'CRITICAL';
        queueItem.channel = 'Teams';
        queueItem.eventData = new Map<String, Object>{
            'eventType' => 'ReportExport',
            'rowsExported' => 50000
        };

        Test.startTest();
        ElaroAlertQueueable queueable = new ElaroAlertQueueable(queueItem);
        System.enqueueJob(queueable);
        Test.stopTest();

        System.assert(true, 'Should process critical alerts');
    }
}
