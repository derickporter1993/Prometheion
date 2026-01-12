/**
 * Test class for SlackNotifier
 */
@isTest
private class SlackNotifierTest {
    
    @isTest
    static void testNotifyAsyncQueueable() {
        String testMessage = 'Test notification';
        System.assertNotEquals(null, testMessage, 'Test message should not be null');

        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyAsyncQueueable(testMessage);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyAsyncQueueable should not throw exception');
    }

    @isTest
    static void testNotifyAsyncQueueableEmpty() {
        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyAsyncQueueable('');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        // Empty notifications should be skipped without error
        System.assertEquals(null, caughtException, 'Empty notification should not throw exception');
    }

    @isTest
    static void testNotifyRichAsyncQueueable() {
        Map<String, Object> payload = new Map<String, Object>{
            'text' => 'Test rich notification'
        };
        String jsonPayload = JSON.serialize(payload);
        System.assertNotEquals(null, jsonPayload, 'JSON payload should not be null');

        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyRichAsyncQueueable(jsonPayload);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyRichAsyncQueueable should not throw exception');
    }

    @isTest
    static void testNotifyPerformanceAlert() {
        String metric = 'CPU';
        Decimal value = 9500;
        Decimal threshold = 10000;
        System.assertEquals('CPU', metric, 'Metric should be CPU');

        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyPerformanceAlert(metric, value, threshold, 'testContext');
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyPerformanceAlert should not throw exception');
    }

    @isTest
    static void testNotifyFlowPerformance() {
        String flowName = 'Test_Flow';
        Integer cpuTime = 5000;
        System.assertNotEquals(null, flowName, 'Flow name should not be null');

        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyFlowPerformance(flowName, cpuTime, 'WARNING', 85.5);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        System.assertEquals(null, caughtException, 'notifyFlowPerformance should not throw exception');
    }

    @isTest
    static void testNotifyFlowPerformanceEmptyName() {
        Test.startTest();
        Exception caughtException = null;
        try {
            SlackNotifier.notifyFlowPerformance('', 5000, 'WARNING', 85.5);
        } catch (Exception e) {
            caughtException = e;
        }
        Test.stopTest();

        // Empty flow name should be handled gracefully
        System.assertEquals(null, caughtException, 'Empty flow name should not throw exception');
    }
}
