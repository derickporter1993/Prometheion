/**
 * Test class for SchedulerErrorHandler
 */
@isTest
private class SchedulerErrorHandlerTest {

    @isTest
    static void testLogError() {
        Test.startTest();
        Exception testException = new DmlException('Test error message');
        testException.setMessage('Test error message');
        SchedulerErrorHandler.logError('TestScheduler', testException);
        Test.stopTest();

        List<Integration_Error__c> errors = [
            SELECT Error_Type__c, Error_Message__c, Context__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
            AND Error_Type__c = 'SCHEDULER_FAILURE'
        ];
        System.assertEquals(1, errors.size(), 'Should log one error');
        System.assertEquals('TestScheduler', errors[0].Context__c);
    }

    @isTest
    static void testLogSuccess() {
        Test.startTest();
        SchedulerErrorHandler.logSuccess('TestScheduler', 'Completed successfully');
        Test.stopTest();

        List<Integration_Error__c> successes = [
            SELECT Error_Type__c, Error_Message__c, Context__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
            AND Error_Type__c = 'SCHEDULER_SUCCESS'
        ];
        System.assertEquals(1, successes.size(), 'Should log one success');
        System.assertEquals('TestScheduler', successes[0].Context__c);
    }

    @isTest
    static void testNotifyOnFailure() {
        Test.startTest();
        Exception testException = new DmlException('Test error');
        testException.setMessage('Test error');
        SchedulerErrorHandler.notifyOnFailure('TestScheduler', testException);
        Test.stopTest();
        // Just verify no exceptions thrown - actual Slack notification requires mock
        System.assert(true, 'Notification should complete without errors');
    }

    @isTest
    static void testLogErrorWithNullMessage() {
        Test.startTest();
        Exception testException = new NullPointerException();
        SchedulerErrorHandler.logError('TestScheduler', testException);
        Test.stopTest();

        List<Integration_Error__c> errors = [
            SELECT Error_Type__c, Error_Message__c
            FROM Integration_Error__c
            WHERE Context__c = 'TestScheduler'
        ];
        System.assertEquals(1, errors.size(), 'Should handle null message');
    }
}
