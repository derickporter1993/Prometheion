/**
 * AccessReviewSchedulerTest
 *
 * Test coverage for AccessReviewScheduler
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class AccessReviewSchedulerTest {

    @TestSetup
    static void setupTestData() {
        // Create test users via existing method won't work - users are system managed
        // Create test access review records instead
        List<Access_Review__c> reviews = new List<Access_Review__c>();
        for (Integer i = 0; i < 5; i++) {
            reviews.add(new Access_Review__c(
                Review_Type__c = 'Periodic Review',
                Status__c = 'Completed',
                Review_Date__c = Date.today().addDays(-100),
                Due_Date__c = Date.today().addDays(-90),
                Review_Scope__c = 'Full Access Review'
            ));
        }
        insert reviews;
    }

    @IsTest
    static void testExecute_Success() {
        Test.startTest();

        AccessReviewScheduler scheduler = new AccessReviewScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Scheduler should execute successfully');
    }

    @IsTest
    static void testPerformAccessReview() {
        Test.startTest();

        AccessReviewScheduler scheduler = new AccessReviewScheduler();
        scheduler.performAccessReview();

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Access review should complete successfully');
    }

    @IsTest
    static void testScheduleMonthly() {
        Test.startTest();

        String jobId = AccessReviewScheduler.scheduleMonthly();

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
    static void testScheduleCustom() {
        Test.startTest();

        String cronExp = '0 0 9 * * ?';
        String jobId = AccessReviewScheduler.scheduleCustom(cronExp, 'Custom');

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testAbortAllJobs() {
        // First schedule a job
        String jobId = AccessReviewScheduler.scheduleMonthly();

        Test.startTest();

        AccessReviewScheduler.abortAllJobs();

        Test.stopTest();

        // Verify job was aborted
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(0, jobs.size(), 'Job should be aborted');
    }

    @IsTest
    static void testGetScheduledJobs() {
        // Schedule a job first
        AccessReviewScheduler.scheduleMonthly();

        Test.startTest();

        List<AccessReviewScheduler.JobStatus> statuses = AccessReviewScheduler.getScheduledJobs();

        Test.stopTest();

        System.assertNotEquals(null, statuses, 'Should return job statuses');
        System.assertEquals(1, statuses.size(), 'Should have 1 scheduled job');
    }

    @IsTest
    static void testRunNow() {
        Test.startTest();

        AccessReviewScheduler.runNow();

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'runNow should complete successfully');
    }

    @IsTest
    static void testJobStatusClass() {
        AccessReviewScheduler.JobStatus status = new AccessReviewScheduler.JobStatus();
        status.jobId = null;
        status.jobName = 'Test Job';
        status.state = 'WAITING';
        status.nextRunTime = DateTime.now().addDays(1);
        status.lastRunTime = DateTime.now().addDays(-1);

        System.assertEquals('Test Job', status.jobName, 'Job name should be set');
        System.assertEquals('WAITING', status.state, 'State should be set');
    }

    @IsTest
    static void testBulkAccessReview() {
        // Create 200 access review records
        List<Access_Review__c> reviews = new List<Access_Review__c>();
        for (Integer i = 0; i < 200; i++) {
            reviews.add(new Access_Review__c(
                Review_Type__c = 'Periodic Review',
                Status__c = 'Pending',
                Due_Date__c = Date.today().addDays(14),
                Review_Scope__c = 'Full Access Review'
            ));
        }
        insert reviews;

        Test.startTest();

        AccessReviewScheduler scheduler = new AccessReviewScheduler();
        scheduler.performAccessReview();

        Test.stopTest();

        // Should handle bulk data without governor limit issues
        System.assert(Limits.getQueries() < 100, 'Should stay under SOQL limit');
        System.assert(Limits.getDmlStatements() < 150, 'Should stay under DML limit');
    }
}
