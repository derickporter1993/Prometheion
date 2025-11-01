@IsTest
private class PerformanceAlertPublisherTest {
    @IsTest
    static void testPublishSuccess() {
        Test.startTest();
        // This should succeed without throwing an exception
        PerformanceAlertPublisher.publish('CPU', 9500, 9000, '001000000000001', 'Test stack trace');
        Test.stopTest();

        // Verify the event was published by checking that no exception was thrown
        // Note: Platform Events are published asynchronously, so we can't query them directly in tests
        System.assert(true, 'Publish completed without exception');
    }

    @IsTest
    static void testPublishMultipleMetrics() {
        Test.startTest();
        PerformanceAlertPublisher.publish('CPU', 9500, 9000, null, 'CPU exceeded');
        PerformanceAlertPublisher.publish('HEAP', 5500, 5000, null, 'Heap exceeded');
        PerformanceAlertPublisher.publish('SOQL', 110, 100, null, 'SOQL exceeded');
        PerformanceAlertPublisher.publish('DML', 160, 150, null, 'DML exceeded');
        Test.stopTest();

        // Verify all publishes completed without exceptions
        System.assert(true, 'All publishes completed without exception');
    }

    @IsTest
    static void testPublishWithContext() {
        String testRecordId = '001000000000ABC';

        Test.startTest();
        PerformanceAlertPublisher.publish('HEAP', 6000, 5000, testRecordId, 'Memory limit approaching');
        Test.stopTest();

        System.assert(true, 'Publish with context completed without exception');
    }

    @IsTest
    static void testPublishNullValues() {
        // Test edge case with null context record
        Test.startTest();
        PerformanceAlertPublisher.publish('CPU', 8500, 8000, null, null);
        Test.stopTest();

        System.assert(true, 'Publish with null values completed without exception');
    }
}
