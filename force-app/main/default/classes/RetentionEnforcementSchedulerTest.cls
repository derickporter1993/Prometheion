/**
 * Test class for RetentionEnforcementScheduler.
 * Tests scheduled job execution for data retention enforcement.
 * @group Tests
 * @see RetentionEnforcementScheduler
 */
@IsTest(testFor=RetentionEnforcementScheduler.class)
private class RetentionEnforcementSchedulerTest {

    @TestSetup
    static void setup() {
        // Create test Data Processing Activities
        List<Data_Processing_Activity__c> activities = new List<Data_Processing_Activity__c>();
        for (Integer i = 0; i < 5; i++) {
            activities.add(new Data_Processing_Activity__c(
                Activity_Name__c = 'Test Activity ' + i,
                Retention_Period__c = 365,
                Legal_Basis__c = 'Consent'
            ));
        }
        insert activities;
    }

    @isTest
    static void testSchedulerExecution() {
        // Arrange
        String cronExpression = '0 0 2 ? * SUN';

        // Act
        Test.startTest();
        String jobId = System.schedule('Test Retention Enforcement', cronExpression, new RetentionEnforcementScheduler());
        Test.stopTest();

        // Assert
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
        Assert.areEqual('WAITING', ct.State, 'Job should be in WAITING state');
    }

    @isTest
    static void testScheduleStaticMethod() {
        // Act
        Test.startTest();
        String jobId = RetentionEnforcementScheduler.schedule();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, jobs.size(), 'Scheduled job should exist');
    }

    @isTest
    static void testExecuteMethod() {
        // Arrange
        RetentionEnforcementScheduler scheduler = new RetentionEnforcementScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - verify batch was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'RetentionEnforcementBatch'
        ];
        Assert.isTrue(jobs.size() > 0, 'Batch job should have been queued');
    }

    @isTest
    static void testSchedulerWithNoActivities() {
        // Arrange - delete all activities
        delete [SELECT Id FROM Data_Processing_Activity__c];
        RetentionEnforcementScheduler scheduler = new RetentionEnforcementScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - should complete without error, batch may or may not be queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'RetentionEnforcementBatch'
        ];
        Assert.isNotNull(jobs, 'Scheduler should handle empty activity list gracefully');
    }
}
