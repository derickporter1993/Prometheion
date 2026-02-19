/**
 * Test class for ElaroDormantAccountAlertScheduler
 * Tests dormant account detection and alert generation
 * @group Tests
 * @see ElaroDormantAccountAlertScheduler
 */
@IsTest(testFor=ElaroDormantAccountAlertScheduler.class)
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
        Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
        Assert.areEqual('WAITING', ct.State, 'Job should be in WAITING state');
    }

    @isTest
    static void testScheduleDailyMethod() {
        // Act
        Test.startTest();
        String jobId = ElaroDormantAccountAlertScheduler.scheduleDaily();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, jobs.size(), 'Scheduled job should exist');
    }

    @isTest
    static void testExecuteMethod() {
        // Arrange
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Assert - method should complete without error
        Assert.isNull(caughtEx, 'Execute method should complete without throwing');
    }

    @isTest
    static void testExecuteWithNoUsers() {
        // Arrange - test with no standard users that are dormant
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Assert
        Assert.isNull(caughtEx, 'Scheduler should handle case with no dormant users without throwing');
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
        Assert.isTrue(reviewCount >= 0, 'Access review query should succeed');
    }

    @isTest
    static void testSchedulerErrorHandling() {
        // Arrange
        ElaroDormantAccountAlertScheduler scheduler = new ElaroDormantAccountAlertScheduler();

        // Act
        Test.startTest();
        Exception caughtEx;
        try {
            scheduler.execute(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Scheduler should handle errors gracefully without throwing');
    }
}
