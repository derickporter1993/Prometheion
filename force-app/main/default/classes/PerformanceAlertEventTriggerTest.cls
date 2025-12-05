@IsTest
private class PerformanceAlertEventTriggerTest {
    @IsTest
    static void testTriggerCreatesHistory() {
        // Create and publish a performance alert event
        Performance_Alert__e alert = new Performance_Alert__e(
            Metric__c = 'CPU',
            Value__c = 9500,
            Threshold__c = 9000,
            Context_Record__c = '001000000000001',
            Stack__c = 'Test stack trace'
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(alert);
        Test.stopTest();

        // Verify the event was published
        System.assert(sr.isSuccess(), 'Event should be published successfully');

        // Verify the trigger created a history record
        List<Performance_Alert_History__c> history = [
            SELECT Metric__c, Value__c, Threshold__c, Context_Record__c, Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'CPU'
        ];

        System.assertEquals(1, history.size(), 'Should create 1 history record');
        System.assertEquals('CPU', history[0].Metric__c, 'Metric should match');
        System.assertEquals(9500, history[0].Value__c, 'Value should match');
        System.assertEquals(9000, history[0].Threshold__c, 'Threshold should match');
        System.assertEquals('001000000000001', history[0].Context_Record__c, 'Context should match');
        System.assertEquals('Test stack trace', history[0].Stack__c, 'Stack should match');
    }

    @IsTest
    static void testTriggerBulkProcessing() {
        // Test bulk insert of multiple events
        List<Performance_Alert__e> alerts = new List<Performance_Alert__e>();
        alerts.add(
            new Performance_Alert__e(
                Metric__c = 'CPU',
                Value__c = 9500,
                Threshold__c = 9000,
                Stack__c = 'CPU exceeded'
            )
        );
        alerts.add(
            new Performance_Alert__e(
                Metric__c = 'HEAP',
                Value__c = 5500,
                Threshold__c = 5000,
                Stack__c = 'Heap exceeded'
            )
        );
        alerts.add(
            new Performance_Alert__e(
                Metric__c = 'SOQL',
                Value__c = 110,
                Threshold__c = 100,
                Stack__c = 'SOQL exceeded'
            )
        );

        Test.startTest();
        List<Database.SaveResult> results = EventBus.publish(alerts);
        Test.stopTest();

        // Verify all events were published
        for (Database.SaveResult sr : results) {
            System.assert(sr.isSuccess(), 'All events should be published successfully');
        }

        // Verify the trigger created history records for all events
        List<Performance_Alert_History__c> history = [
            SELECT Metric__c
            FROM Performance_Alert_History__c
        ];

        System.assertEquals(3, history.size(), 'Should create 3 history records');
    }

    @IsTest
    static void testTriggerWithNullContext() {
        // Test with null context record
        Performance_Alert__e alert = new Performance_Alert__e(
            Metric__c = 'DML',
            Value__c = 160,
            Threshold__c = 150,
            Context_Record__c = null,
            Stack__c = 'DML limit approaching'
        );

        Test.startTest();
        Database.SaveResult sr = EventBus.publish(alert);
        Test.stopTest();

        System.assert(sr.isSuccess(), 'Event should be published successfully');

        List<Performance_Alert_History__c> history = [
            SELECT Context_Record__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'DML'
        ];

        System.assertEquals(1, history.size(), 'Should create history record');
        System.assertEquals(null, history[0].Context_Record__c, 'Context should be null');
    }
}
