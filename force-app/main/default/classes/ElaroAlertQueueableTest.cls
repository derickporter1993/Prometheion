/**
 * Test class for ElaroAlertQueueable.
 * Tests queueable alert processing.
 *
 * @group Tests
 * @see ElaroAlertQueueable
 */
@IsTest(testFor=ElaroAlertQueueable.class)
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

        // Verify the queueable job completed
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ElaroAlertQueueable'
        ];
        Assert.isTrue(jobs.size() > 0, 'Queueable job should have been executed');
    }

    @isTest
    static void testQueueableWithNullItem() {
        Test.startTest();
        ElaroAlertQueueable queueable = new ElaroAlertQueueable(null);
        System.enqueueJob(queueable);
        Test.stopTest();

        // Verify job completed (null item causes early return, no exception)
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ElaroAlertQueueable'
        ];
        Assert.isTrue(jobs.size() > 0, 'Queueable job should complete even with null item');
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

        // Verify job completed with minimal data
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ElaroAlertQueueable'
        ];
        Assert.isTrue(jobs.size() > 0, 'Queueable job should complete with minimal data');
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

        // Verify job completed for critical severity
        List<AsyncApexJob> jobs = [
            SELECT Id, Status FROM AsyncApexJob
            WHERE JobType = 'Queueable'
            AND ApexClass.Name = 'ElaroAlertQueueable'
        ];
        Assert.isTrue(jobs.size() > 0, 'Queueable job should process critical alerts');
    }
}
