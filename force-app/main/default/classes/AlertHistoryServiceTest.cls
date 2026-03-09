@IsTest
private class AlertHistoryServiceTest {
    @IsTest
    static void testRecentHistory() {
        // Create test data
        insert new Performance_Alert_History__c(
            Metric__c = 'CPU',
            Value__c = 9000,
            Threshold__c = 8000,
            Context_Record__c = UserInfo.getUserId()
        );

        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.getRecentAlerts(5);
        Test.stopTest();

        // Verify exact count
        Assert.areEqual(1, rows.size(), 'Should return exactly 1 alert');

        // Verify field values
        Assert.areEqual('CPU', rows[0].metric, 'Metric should be CPU');
        Assert.areEqual(9000, rows[0].value, 'Value should be 9000');
        Assert.areEqual(8000, rows[0].threshold, 'Threshold should be 8000');
        Assert.areEqual(UserInfo.getUserId(), rows[0].contextRecordId, 'Context should match');
        Assert.areNotEqual(null, rows[0].createdDate, 'Created date should be populated');
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
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.getRecentAlerts(10);
        Test.stopTest();

        Assert.areEqual(3, rows.size(), 'Should return all 3 alerts');

        // Verify different metrics are returned
        Set<String> metrics = new Set<String>();
        for (AlertHistoryService.AlertRow row : rows) {
            metrics.add(row.metric);
        }
        Assert.isTrue(metrics.contains('CPU'), 'Should include CPU metric');
        Assert.isTrue(metrics.contains('HEAP'), 'Should include HEAP metric');
        Assert.isTrue(metrics.contains('SOQL'), 'Should include SOQL metric');
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
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.getRecentAlerts(5);
        Test.stopTest();

        Assert.areEqual(5, rows.size(), 'Should respect limit of 5');
    }

    @IsTest
    static void testRecentEmpty() {
        // Test with no history records
        Test.startTest();
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.getRecentAlerts(5);
        Test.stopTest();

        Assert.areEqual(0, rows.size(), 'Should return empty list when no history');
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
        List<AlertHistoryService.AlertRow> rows = AlertHistoryService.getRecentAlerts(10);
        Test.stopTest();

        // Verify descending order by created date (most recent first)
        Assert.areEqual(3, rows.size(), 'Should return all 3 alerts');
        for (Integer i = 0; i < rows.size() - 1; i++) {
            Assert.isTrue(
                rows[i].createdDate >= rows[i + 1].createdDate,
                'Alerts should be ordered by CreatedDate DESC'
            );
        }
    }
}
