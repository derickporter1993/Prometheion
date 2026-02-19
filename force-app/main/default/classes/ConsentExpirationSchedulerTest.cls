/**
 * Test class for ConsentExpirationScheduler.
 * Tests scheduled job execution and batch invocation for consent expiration processing.
 *
 * @group Tests
 * @see ConsentExpirationScheduler
 */
@IsTest(testFor=ConsentExpirationScheduler.class)
private class ConsentExpirationSchedulerTest {

    @TestSetup
    static void setup() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;

        // Create test consents
        List<Consent__c> consents = new List<Consent__c>();
        for (Contact c : contacts) {
            consents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Marketing',
                Consent_Given__c = true,
                Consent_Withdrawn__c = false,
                Consent_Date__c = Date.today().addDays(-30)
            ));
        }
        insert consents;
    }

    @isTest
    static void testSchedulerExecution() {
        // Arrange
        String cronExpression = '0 0 8 * * ?';

        // Act
        Test.startTest();
        String jobId = System.schedule('Test Consent Expiration', cronExpression, new ConsentExpirationScheduler());
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
        String jobId = ConsentExpirationScheduler.schedule();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
        List<CronTrigger> jobs = [SELECT Id FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(1, jobs.size(), 'Scheduled job should exist');
    }

    @isTest
    static void testExecuteMethod() {
        // Arrange
        ConsentExpirationScheduler scheduler = new ConsentExpirationScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - verify batch was queued
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ConsentExpirationBatch'
        ];
        Assert.isTrue(jobs.size() > 0, 'Batch job should have been queued');
    }

    @isTest
    static void testSchedulerWithNoConsents() {
        // Arrange - delete all consents
        delete [SELECT Id FROM Consent__c];
        ConsentExpirationScheduler scheduler = new ConsentExpirationScheduler();

        // Act
        Test.startTest();
        scheduler.execute(null);
        Test.stopTest();

        // Assert - batch should still be queued even with no consents
        List<AsyncApexJob> jobs = [
            SELECT Id, Status, JobType
            FROM AsyncApexJob
            WHERE JobType = 'BatchApex'
            AND ApexClass.Name = 'ConsentExpirationBatch'
        ];
        Assert.isTrue(jobs.size() > 0, 'Batch job should be queued even with no consents');
    }
}
