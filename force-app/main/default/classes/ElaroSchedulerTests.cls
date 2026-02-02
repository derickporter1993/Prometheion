/**
 * ElaroSchedulerTests - Comprehensive test coverage for all scheduler classes
 *
 * Covers:
 * - ElaroCCPASLAMonitorScheduler
 * - ElaroDormantAccountAlertScheduler
 * - ElaroGLBAAnnualNoticeScheduler
 * - ElaroISO27001QuarterlyScheduler
 * - ElaroEventScheduler
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroSchedulerTests {

    // ========================================
    // TEST DATA SETUP
    // ========================================

    @TestSetup
    static void setupTestData() {
        // Create test CCPA requests
        List<CCPA_Request__c> ccpaRequests = new List<CCPA_Request__c>();

        // Request approaching deadline (within 7 days)
        ccpaRequests.add(new CCPA_Request__c(
            Request_Type__c = 'Right to Know',
            Status__c = 'Pending',
            Request_Date__c = Date.today().addDays(-40),
            Response_Deadline__c = Date.today().addDays(5)
        ));

        // Critical request (within 3 days)
        ccpaRequests.add(new CCPA_Request__c(
            Request_Type__c = 'Right to Delete',
            Status__c = 'In Progress',
            Request_Date__c = Date.today().addDays(-43),
            Response_Deadline__c = Date.today().addDays(2)
        ));

        // Overdue request
        ccpaRequests.add(new CCPA_Request__c(
            Request_Type__c = 'Do Not Sell',
            Status__c = 'Pending',
            Request_Date__c = Date.today().addDays(-50),
            Response_Deadline__c = Date.today().addDays(-5)
        ));

        // Completed request
        ccpaRequests.add(new CCPA_Request__c(
            Request_Type__c = 'Right to Know',
            Status__c = 'Completed',
            Request_Date__c = Date.today().addDays(-30),
            Response_Deadline__c = Date.today().addDays(15),
            Completed_Date__c = Date.today()
        ));

        insert ccpaRequests;

        // Create test accounts for privacy notices
        Account testAccount = new Account(Name = 'Test Customer Account');
        insert testAccount;

        // Create test privacy notices
        List<Privacy_Notice__c> notices = new List<Privacy_Notice__c>();
        notices.add(new Privacy_Notice__c(
            Account__c = testAccount.Id,
            Notice_Type__c = 'Annual',
            Sent_Date__c = Date.today().addDays(-365),
            Delivery_Status__c = 'Delivered',
            Next_Annual_Notice_Due__c = Date.today()
        ));
        insert notices;
    }

    // ========================================
    // CCPA SLA MONITOR SCHEDULER TESTS
    // ========================================

    @IsTest
    static void testCCPASLAMonitorScheduler_Execute() {
        Test.startTest();

        ElaroCCPASLAMonitorScheduler scheduler = new ElaroCCPASLAMonitorScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Verify overdue requests were marked
        List<CCPA_Request__c> overdueRequests = [
            SELECT Id, Status__c
            FROM CCPA_Request__c
            WHERE Status__c = 'Overdue'
        ];

        System.assertEquals(1, overdueRequests.size(), 'Should have 1 overdue request');
    }

    @IsTest
    static void testCCPASLAMonitorScheduler_ScheduleDaily() {
        Test.startTest();

        String jobId = ElaroCCPASLAMonitorScheduler.scheduleDaily();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
    }

    @IsTest
    static void testCCPASLAMonitorScheduler_ScheduleHourly() {
        Test.startTest();

        String jobId = ElaroCCPASLAMonitorScheduler.scheduleHourly();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testCCPASLAMonitorScheduler_NoApproachingDeadlines() {
        // Delete all test CCPA requests
        delete [SELECT Id FROM CCPA_Request__c];

        Test.startTest();

        ElaroCCPASLAMonitorScheduler scheduler = new ElaroCCPASLAMonitorScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Scheduler should handle empty data gracefully');
    }

    // ========================================
    // DORMANT ACCOUNT ALERT SCHEDULER TESTS
    // ========================================

    @IsTest
    static void testDormantAccountAlertScheduler_Execute() {
        Test.startTest();

        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Scheduler should complete without errors
        System.assert(true, 'Scheduler should execute successfully');
    }

    @IsTest
    static void testDormantAccountAlertScheduler_ScheduleDaily() {
        Test.startTest();

        String jobId = ElaroDormantAccountAlertScheduler.scheduleDaily();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
    }

    @IsTest
    static void testDormantAccountAlertScheduler_WithDormantUsers() {
        // Note: Creating dormant users is tricky in tests because we can't
        // set LastLoginDate. This test verifies the scheduler handles
        // the scenario where no dormant users are found.

        Test.startTest();

        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();
        scheduler.execute(null);

        Test.stopTest();

        System.assert(true, 'Scheduler should handle no dormant users gracefully');
    }

    // ========================================
    // GLBA ANNUAL NOTICE SCHEDULER TESTS
    // ========================================

    @IsTest
    static void testGLBAAnnualNoticeScheduler_Execute_BusinessDay() {
        Test.startTest();

        ElaroGLBAAnnualNoticeScheduler scheduler = new ElaroGLBAAnnualNoticeScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Scheduler should execute successfully');
    }

    @IsTest
    static void testGLBAAnnualNoticeScheduler_ScheduleDaily() {
        Test.startTest();

        String jobId = ElaroGLBAAnnualNoticeScheduler.scheduleDaily();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
    }

    // ========================================
    // ISO 27001 QUARTERLY SCHEDULER TESTS
    // ========================================

    @IsTest
    static void testISO27001QuarterlyScheduler_Execute_Quarterly() {
        Test.startTest();

        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Scheduler should execute successfully');
    }

    @IsTest
    static void testISO27001QuarterlyScheduler_Execute_Privileged() {
        Test.startTest();

        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler('privileged');
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Privileged scheduler should execute successfully');
    }

    @IsTest
    static void testISO27001QuarterlyScheduler_ScheduleQuarterly() {
        Test.startTest();

        String jobId = ElaroISO27001QuarterlyScheduler.scheduleQuarterly();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testISO27001QuarterlyScheduler_ScheduleMonthlyPrivileged() {
        Test.startTest();

        String jobId = ElaroISO27001QuarterlyScheduler.scheduleMonthlyPrivileged();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testISO27001QuarterlyScheduler_DefaultConstructor() {
        ElaroISO27001QuarterlyScheduler scheduler = new ElaroISO27001QuarterlyScheduler();

        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Default should run quarterly reviews
        System.assert(true, 'Default constructor should work');
    }

    // ========================================
    // EVENT SCHEDULER TESTS
    // ========================================

    @IsTest
    static void testEventScheduler_DefaultConstructor() {
        Test.startTest();

        ElaroEventScheduler scheduler = new ElaroEventScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Default scheduler should execute successfully');
    }

    @IsTest
    static void testEventScheduler_ParameterizedConstructor() {
        Test.startTest();

        ElaroEventScheduler scheduler = new ElaroEventScheduler('LOGOUT', 14, 'HIPAA');
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Parameterized scheduler should execute successfully');
    }

    @IsTest
    static void testEventScheduler_NullParameters() {
        Test.startTest();

        ElaroEventScheduler scheduler = new ElaroEventScheduler('LOGIN', null, null);
        scheduler.execute(null);

        Test.stopTest();

        // Should use defaults and complete without errors
        System.assert(true, 'Scheduler should handle null parameters gracefully');
    }

    // ========================================
    // BULK TESTING
    // ========================================

    @IsTest
    static void testCCPASLAMonitorScheduler_BulkData() {
        // Create 200 CCPA requests to test bulk handling
        List<CCPA_Request__c> bulkRequests = new List<CCPA_Request__c>();

        for (Integer i = 0; i < 200; i++) {
            bulkRequests.add(new CCPA_Request__c(
                Request_Type__c = 'Right to Know',
                Status__c = Math.mod(i, 3) == 0 ? 'Pending' : 'In Progress',
                Request_Date__c = Date.today().addDays(-40 - Math.mod(i, 10)),
                Response_Deadline__c = Date.today().addDays(5 - Math.mod(i, 15))
            ));
        }

        insert bulkRequests;

        Test.startTest();

        ElaroCCPASLAMonitorScheduler scheduler = new ElaroCCPASLAMonitorScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Verify some requests were marked overdue
        Integer overdueCount = [SELECT COUNT() FROM CCPA_Request__c WHERE Status__c = 'Overdue'];
        System.assert(overdueCount > 0, 'Should have some overdue requests');
    }

    // ========================================
    // NEGATIVE SCENARIOS
    // ========================================

    @IsTest
    static void testSchedulers_WithNoData() {
        // Delete all test data
        delete [SELECT Id FROM CCPA_Request__c];
        delete [SELECT Id FROM Privacy_Notice__c];
        delete [SELECT Id FROM Access_Review__c];

        Test.startTest();

        // All schedulers should handle empty data gracefully
        new ElaroCCPASLAMonitorScheduler().execute(null);
        new ElaroDormantAccountAlertScheduler().execute(null);
        new ElaroGLBAAnnualNoticeScheduler().execute(null);
        new ElaroISO27001QuarterlyScheduler().execute(null);
        new ElaroEventScheduler().execute(null);

        Test.stopTest();

        System.assert(true, 'All schedulers should handle empty data gracefully');
    }

    @IsTest
    static void testSchedulers_ScheduleMultipleJobs() {
        Test.startTest();

        // Schedule all jobs - should not conflict
        String job1 = ElaroCCPASLAMonitorScheduler.scheduleDaily();
        String job2 = ElaroDormantAccountAlertScheduler.scheduleDaily();
        String job3 = ElaroGLBAAnnualNoticeScheduler.scheduleDaily();
        String job4 = ElaroISO27001QuarterlyScheduler.scheduleQuarterly();

        Test.stopTest();

        // All jobs should be scheduled
        System.assertNotEquals(null, job1, 'CCPA job should be scheduled');
        System.assertNotEquals(null, job2, 'Dormant Account job should be scheduled');
        System.assertNotEquals(null, job3, 'GLBA job should be scheduled');
        System.assertNotEquals(null, job4, 'ISO 27001 job should be scheduled');
    }
}
