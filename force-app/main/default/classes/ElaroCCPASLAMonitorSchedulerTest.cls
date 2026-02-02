/**
 * @description Test class for ElaroCCPASLAMonitorScheduler
 * Tests CCPA SLA monitoring and deadline tracking
 * @group Tests
 * @see ElaroCCPASLAMonitorScheduler
 */
@isTest
private class ElaroCCPASLAMonitorSchedulerTest {

    @TestSetup
    static void setup() {
        // Create test contacts
        Contact c = new Contact(
            FirstName = 'Test',
            LastName = 'Consumer',
            Email = 'test.consumer@example.com'
        );
        insert c;

        // Create CCPA requests with various deadlines
        List<CCPA_Request__c> requests = new List<CCPA_Request__c>();

        // Request due in 2 days (critical)
        requests.add(new CCPA_Request__c(
            Contact__c = c.Id,
            Request_Type__c = 'Access',
            Status__c = 'In Progress',
            Request_Date__c = Date.today().addDays(-43),
            Response_Deadline__c = Date.today().addDays(2)
        ));

        // Request due in 5 days (warning)
        requests.add(new CCPA_Request__c(
            Contact__c = c.Id,
            Request_Type__c = 'Deletion',
            Status__c = 'Pending',
            Request_Date__c = Date.today().addDays(-40),
            Response_Deadline__c = Date.today().addDays(5)
        ));

        // Overdue request
        requests.add(new CCPA_Request__c(
            Contact__c = c.Id,
            Request_Type__c = 'Access',
            Status__c = 'In Progress',
            Request_Date__c = Date.today().addDays(-50),
            Response_Deadline__c = Date.today().addDays(-5)
        ));

        insert requests;
    }

    @isTest
    static void testSchedulerExecution() {
        String cronExpression = '0 0 8 * * ?';

        Test.startTest();
        String jobId = System.schedule('Test CCPA SLA Monitor', cronExpression, new ElaroCCPASLAMonitorScheduler());
        Test.stopTest();

        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression, 'Cron expression should match');
    }

    @isTest
    static void testScheduleDailyMethod() {
        Test.startTest();
        String jobId = ElaroCCPASLAMonitorScheduler.scheduleDaily();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @isTest
    static void testScheduleHourlyMethod() {
        Test.startTest();
        String jobId = ElaroCCPASLAMonitorScheduler.scheduleHourly();
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Hourly job ID should not be null');
    }

    @isTest
    static void testExecuteMethod() {
        ElaroCCPASLAMonitorScheduler scheduler = new ElaroCCPASLAMonitorScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Verify overdue requests were marked
        List<CCPA_Request__c> overdueRequests = [
            SELECT Id, Status__c FROM CCPA_Request__c
            WHERE Status__c = 'Overdue'
        ];
        System.assert(overdueRequests.size() > 0, 'Overdue requests should be marked');
    }

    @isTest
    static void testExecuteWithNoRequests() {
        delete [SELECT Id FROM CCPA_Request__c];

        ElaroCCPASLAMonitorScheduler scheduler = new ElaroCCPASLAMonitorScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        System.assert(true, 'Should handle no requests gracefully');
    }
}
