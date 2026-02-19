/**
 * Test class for ElaroEventScheduler
 * Tests scheduled event loading for compliance monitoring
 * @group Tests
 * @see ElaroEventScheduler
 */
@IsTest(testFor=ElaroEventScheduler.class)
private class ElaroEventSchedulerTest {

    @isTest
    static void testDefaultConstructor() {
        // Act
        Test.startTest();
        ElaroEventScheduler scheduler = new ElaroEventScheduler();
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, scheduler, 'Scheduler should be created with default constructor');
    }

    @isTest
    static void testParameterizedConstructor() {
        // Arrange
        String eventType = 'LOGIN';
        Integer daysBack = 14;
        String framework = 'HIPAA';

        // Act
        Test.startTest();
        ElaroEventScheduler scheduler = new ElaroEventScheduler(eventType, daysBack, framework);
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, scheduler, 'Scheduler should be created with parameters');
    }

    @isTest
    static void testParameterizedConstructorWithNulls() {
        // Arrange - null values should use defaults
        String eventType = 'API';

        // Act
        Test.startTest();
        ElaroEventScheduler scheduler = new ElaroEventScheduler(eventType, null, null);
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, scheduler, 'Scheduler should handle null parameters');
    }

    @isTest
    static void testSchedulerExecution() {
        // Arrange
        String cronExpression = '0 0 6 * * ?';

        // Act
        Test.startTest();
        String jobId = System.schedule('Test Event Scheduler', cronExpression, new ElaroEventScheduler());
        Test.stopTest();

        // Assert
        CronTrigger ct = [SELECT Id, CronExpression, State FROM CronTrigger WHERE Id = :jobId];
        Assert.areEqual(cronExpression, ct.CronExpression, 'Cron expression should match');
        Assert.areEqual('WAITING', ct.State, 'Job should be in WAITING state');
    }

    @isTest
    static void testExecuteMethod() {
        // Arrange
        ElaroEventScheduler scheduler = new ElaroEventScheduler('LOGIN', 7, 'SOC2');

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
    static void testExecuteWithDifferentEventTypes() {
        // Test with different event types
        List<String> eventTypes = new List<String>{'LOGIN', 'API', 'REPORT_EXPORT', 'APEX_EXECUTION'};

        Test.startTest();
        Exception caughtEx;
        try {
            for (String eventType : eventTypes) {
                ElaroEventScheduler scheduler = new ElaroEventScheduler(eventType, 7, 'SOC2');
                scheduler.execute(null);
            }
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Assert
        Assert.isNull(caughtEx, 'All event types should be processed without throwing');
    }

    @isTest
    static void testSchedulerWithDifferentFrameworks() {
        // Test with different compliance frameworks
        List<String> frameworks = new List<String>{'SOC2', 'HIPAA', 'GDPR', 'NIST'};

        Test.startTest();
        Exception caughtEx;
        try {
            for (String framework : frameworks) {
                ElaroEventScheduler scheduler = new ElaroEventScheduler('LOGIN', 7, framework);
                scheduler.execute(null);
            }
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Assert
        Assert.isNull(caughtEx, 'All frameworks should be processed without throwing');
    }
}
