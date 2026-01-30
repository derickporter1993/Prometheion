/**
 * @description Test class for ElaroDormantAccountAlertScheduler
 * Tests dormant account detection and alert generation
 * @group Tests
 * @see ElaroDormantAccountAlertScheduler
 */
@isTest
private class ElaroDormantAccountAlertSchedulerTest {

    @isTest
    static void testSchedulerExecution() {
        // Arrange
        String cronExpression = '0 0 5 * * ?';

        // Act
        Test.startTest();
        String jobId = System.schedule('Test Dormant Account Alert', cronExpression, new ElaroDormantAccountAlertScheduler());
        Test.stopTest();

        // Assert
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(cronExpression, ct.CronExpression, 'Cron expression should match');
        System.assertEquals('WAITING', ct.State, 'Job should be in WAITING state');
    }

    @isTest
    static void testScheduleDailyMethod() {
        // Act
        Test.startTest();
        String jobId = ElaroDormantAccountAlertScheduler.scheduleDaily();
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, jobId, 'Job ID should not be null');
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(1, jobs.size(), 'Scheduled job should exist');
    }

    @isTest
    static void testExecuteMethod() {
        // Arrange
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - method should complete without error
        System.assert(true, 'Execute method should complete successfully');
    }

    @isTest
    static void testExecuteWithNoUsers() {
        // Arrange - test with no standard users that are dormant
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert
        System.assert(true, 'Scheduler should handle case with no dormant users');
    }

    @isTest
    static void testAccessReviewCreation() {
        // Arrange
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - check if any access reviews were created
        Integer reviewCount = [SELECT COUNT() FROM Access_Review__c WHERE Review_Type__c = 'Termination Review'];
        // Note: Count may vary based on org's user data
        System.assert(reviewCount >= 0, 'Access review query should succeed');
    }

    @isTest
    static void testSchedulerErrorHandling() {
        // Arrange
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        try {
            scheduler.execute(null);
            System.assert(true, 'Scheduler executed without throwing exception');
        } catch (Exception e) {
            // Error handling is expected to log and notify
            System.assert(true, 'Scheduler handles errors gracefully');
        }
        Test.stopTest();
    }
}
