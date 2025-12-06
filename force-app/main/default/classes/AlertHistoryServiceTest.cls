@IsTest
private class AlertHistoryServiceTest {
    @IsTest
    static void testRecentHistory() {
        // Create test data
        insert new Performance_Alert_History__c(
            Metric__c = 'CPU',
            Value__c = 9000,
            Threshold__c = 8000,
            Context_Record__c = '001000000000001'
        );

        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(5);
        Test.stopTest();

        // Verify exact count
        System.assertEquals(1, rows.size(), 'Should return exactly 1 alert');

        // Verify field values
        System.assertEquals('CPU', rows[0].metric, 'Metric should be CPU');
        System.assertEquals(9000, rows[0].value, 'Value should be 9000');
        System.assertEquals(8000, rows[0].threshold, 'Threshold should be 8000');
        System.assertEquals('001000000000001', rows[0].contextRecordId, 'Context should match');
        System.assertNotEquals(null, rows[0].createdDate, 'Created date should be populated');
    }

    @IsTest
    static void testRecentMultipleAlerts() {
        // Create multiple test alerts
        List<Performance_Alert_History__c> alerts = new List<Performance_Alert_History__c>();
        alerts.add(
            new Performance_Alert_History__c(
                Metric__c = 'CPU',
                Value__c = 9500,
                Threshold__c = 9000
            )
        );
        alerts.add(
            new Performance_Alert_History__c(
                Metric__c = 'HEAP',
                Value__c = 5500,
                Threshold__c = 5000
            )
        );
        alerts.add(
            new Performance_Alert_History__c(
                Metric__c = 'SOQL',
                Value__c = 110,
                Threshold__c = 100
            )
        );
        insert alerts;

        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(10);
        Test.stopTest();

        System.assertEquals(3, rows.size(), 'Should return all 3 alerts');

        // Verify different metrics are returned
        Set<String> metrics = new Set<String>();
        for (AlertHistoryService.AlertRow row : rows) {
            metrics.add(row.metric);
        }
        System.assert(metrics.contains('CPU'), 'Should include CPU metric');
        System.assert(metrics.contains('HEAP'), 'Should include HEAP metric');
        System.assert(metrics.contains('SOQL'), 'Should include SOQL metric');
    }

    @IsTest
    static void testRecentWithLimit() {
        // Create more records than the limit
        List<Performance_Alert_History__c> alerts = new List<Performance_Alert_History__c>();
        for (Integer i = 0; i < 10; i++) {
            alerts.add(
                new Performance_Alert_History__c(
                    Metric__c = 'TEST',
                    Value__c = i * 100,
                    Threshold__c = 50
                )
            );
        }
        insert alerts;

        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(5);
        Test.stopTest();

        System.assertEquals(5, rows.size(), 'Should respect limit of 5');
    }

    @IsTest
    static void testRecentEmpty() {
        // Test with no history records
        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(5);
        Test.stopTest();

        System.assertEquals(0, rows.size(), 'Should return empty list when no history');
    }

    @IsTest
    static void testRecentOrderedByCreatedDate() {
        // Create alerts with different timestamps
        List<Performance_Alert_History__c> alerts = new List<Performance_Alert_History__c>();
        for (Integer i = 0; i < 3; i++) {
            alerts.add(
                new Performance_Alert_History__c(
                    Metric__c = 'METRIC' + i,
                    Value__c = i,
                    Threshold__c = 1
                )
            );
        }
        insert alerts;

        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.recent(10);
        Test.stopTest();

        // Verify descending order by created date (most recent first)
        System.assertEquals(3, rows.size(), 'Should return all 3 alerts');
        for (Integer i = 0; i < rows.size() - 1; i++) {
            System.assert(
                rows[i].createdDate >= rows[i + 1].createdDate,
                'Alerts should be ordered by CreatedDate DESC'
            );
        }
    }
}
