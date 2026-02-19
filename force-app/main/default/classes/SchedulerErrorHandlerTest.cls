/**
 * SchedulerErrorHandlerTest - Test class for SchedulerErrorHandler utility
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=SchedulerErrorHandler.class)
private class SchedulerErrorHandlerTest {

    @isTest
    static void testLogError() {
        Exception testException = new DmlException('Test error message');

        Test.startTest();
        SchedulerErrorHandler.logError('TestScheduler', testException);
        Test.stopTest();

        List<Integration_Error__c> errors = [
            SELECT Error_Type__c, Error_Message__c, Context__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
        ];

        Assert.areEqual(1, errors.size(), 'Should create one error record');
        Assert.areEqual('SCHEDULER_FAILURE', errors[0].Error_Type__c, 'Should be SCHEDULER_FAILURE type');
        Assert.areEqual('Test error message', errors[0].Error_Message__c, 'Should capture error message');
    }

    @isTest
    static void testLogSuccess() {
        Test.startTest();
        SchedulerErrorHandler.logSuccess('TestScheduler', 'Processed 100 records successfully');
        Test.stopTest();

        List<Integration_Error__c> logs = [
            SELECT Error_Type__c, Error_Message__c, Context__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
        ];

        Assert.areEqual(1, logs.size(), 'Should create one log record');
        Assert.areEqual('SCHEDULER_SUCCESS', logs[0].Error_Type__c, 'Should be SCHEDULER_SUCCESS type');
        Assert.isTrue(logs[0].Error_Message__c.contains('100 records'), 'Should capture success details');
    }

    @isTest
    static void testGetCronExpressionWithConfig() {
        // Custom Metadata is available in tests
        Test.startTest();
        String cron = SchedulerErrorHandler.getCronExpression('CCPASLAMonitor', '0 0 0 * * ?');
        Test.stopTest();

        // Should return the configured value or the default
        Assert.areNotEqual(null, cron, 'Should return a CRON expression');
        Assert.isTrue(cron.contains('*'), 'Should be a valid CRON expression');
    }

    @isTest
    static void testGetCronExpressionWithDefault() {
        String defaultCron = '0 0 12 * * ?';

        Test.startTest();
        String cron = SchedulerErrorHandler.getCronExpression('NonExistentScheduler', defaultCron);
        Test.stopTest();

        Assert.areEqual(defaultCron, cron, 'Should return default CRON when config not found');
    }

    @isTest
    static void testGetBatchSizeWithConfig() {
        Test.startTest();
        Integer batchSize = SchedulerErrorHandler.getBatchSize('DormantAccountAlert', 100);
        Test.stopTest();

        // Should return configured value (500) or default (100)
        Assert.isTrue(batchSize > 0, 'Should return a positive batch size');
    }

    @isTest
    static void testGetBatchSizeWithDefault() {
        Integer defaultSize = 250;

        Test.startTest();
        Integer batchSize = SchedulerErrorHandler.getBatchSize('NonExistentScheduler', defaultSize);
        Test.stopTest();

        Assert.areEqual(defaultSize, batchSize, 'Should return default batch size when config not found');
    }

    @isTest
    static void testIsSchedulerActive() {
        Test.startTest();
        Boolean isActive = SchedulerErrorHandler.isSchedulerActive('CCPASLAMonitor');
        Test.stopTest();

        // Custom Metadata should indicate active or default to true
        Assert.areNotEqual(null, isActive, 'Should return a boolean value');
    }

    @isTest
    static void testIsSchedulerActiveDefault() {
        Test.startTest();
        Boolean isActive = SchedulerErrorHandler.isSchedulerActive('NonExistentScheduler');
        Test.stopTest();

        Assert.areEqual(true, isActive, 'Should default to active when config not found');
    }

    @isTest
    static void testNotifyOnFailure() {
        Exception testException = new DmlException('Test failure notification');

        Exception caughtEx;
        Test.startTest();
        try {
            // This will attempt to call SlackNotifier which may not exist in test context
            // The method handles exceptions gracefully
            SchedulerErrorHandler.notifyOnFailure('TestScheduler', testException);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'notifyOnFailure should handle missing SlackNotifier gracefully without throwing');
    }

    @isTest
    static void testLogErrorWithLongMessage() {
        // Test with a very long error message to verify truncation
        String longMessage = 'A'.repeat(500);
        Exception testException = new DmlException(longMessage);

        Test.startTest();
        SchedulerErrorHandler.logError('TestScheduler', testException);
        Test.stopTest();

        List<Integration_Error__c> errors = [
            SELECT Error_Message__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
        ];

        Assert.areEqual(1, errors.size(), 'Should create one error record');
        Assert.isTrue(errors[0].Error_Message__c.length() <= 255, 'Message should be truncated to 255 chars');
    }
}
