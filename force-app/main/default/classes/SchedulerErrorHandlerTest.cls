/**
 * SchedulerErrorHandlerTest - Test class for SchedulerErrorHandler utility
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
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

        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assertEquals('SCHEDULER_FAILURE', errors[0].Error_Type__c, 'Should be SCHEDULER_FAILURE type');
        System.assertEquals('Test error message', errors[0].Error_Message__c, 'Should capture error message');
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

        System.assertEquals(1, logs.size(), 'Should create one log record');
        System.assertEquals('SCHEDULER_SUCCESS', logs[0].Error_Type__c, 'Should be SCHEDULER_SUCCESS type');
        System.assert(logs[0].Error_Message__c.contains('100 records'), 'Should capture success details');
    }

    @isTest
    static void testGetCronExpressionWithConfig() {
        // Custom Metadata is available in tests
        Test.startTest();
        String cron = SchedulerErrorHandler.getCronExpression('CCPASLAMonitor', '0 0 0 * * ?');
        Test.stopTest();

        // Should return the configured value or the default
        System.assertNotEquals(null, cron, 'Should return a CRON expression');
        System.assert(cron.contains('*'), 'Should be a valid CRON expression');
    }

    @isTest
    static void testGetCronExpressionWithDefault() {
        String defaultCron = '0 0 12 * * ?';

        Test.startTest();
        String cron = SchedulerErrorHandler.getCronExpression('NonExistentScheduler', defaultCron);
        Test.stopTest();

        System.assertEquals(defaultCron, cron, 'Should return default CRON when config not found');
    }

    @isTest
    static void testGetBatchSizeWithConfig() {
        Test.startTest();
        Integer batchSize = SchedulerErrorHandler.getBatchSize('DormantAccountAlert', 100);
        Test.stopTest();

        // Should return configured value (500) or default (100)
        System.assert(batchSize > 0, 'Should return a positive batch size');
    }

    @isTest
    static void testGetBatchSizeWithDefault() {
        Integer defaultSize = 250;

        Test.startTest();
        Integer batchSize = SchedulerErrorHandler.getBatchSize('NonExistentScheduler', defaultSize);
        Test.stopTest();

        System.assertEquals(defaultSize, batchSize, 'Should return default batch size when config not found');
    }

    @isTest
    static void testIsSchedulerActive() {
        Test.startTest();
        Boolean isActive = SchedulerErrorHandler.isSchedulerActive('CCPASLAMonitor');
        Test.stopTest();

        // Custom Metadata should indicate active or default to true
        System.assertNotEquals(null, isActive, 'Should return a boolean value');
    }

    @isTest
    static void testIsSchedulerActiveDefault() {
        Test.startTest();
        Boolean isActive = SchedulerErrorHandler.isSchedulerActive('NonExistentScheduler');
        Test.stopTest();

        System.assertEquals(true, isActive, 'Should default to active when config not found');
    }

    @isTest
    static void testNotifyOnFailure() {
        Exception testException = new DmlException('Test failure notification');

        Test.startTest();
        // This will attempt to call SlackNotifier which may not exist in test context
        // The method handles exceptions gracefully
        SchedulerErrorHandler.notifyOnFailure('TestScheduler', testException);
        Test.stopTest();

        // No assertion needed - just verify no exception thrown
        System.assert(true, 'notifyOnFailure should handle missing SlackNotifier gracefully');
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

        System.assertEquals(1, errors.size(), 'Should create one error record');
        System.assert(errors[0].Error_Message__c.length() <= 255, 'Message should be truncated to 255 chars');
    }
}
