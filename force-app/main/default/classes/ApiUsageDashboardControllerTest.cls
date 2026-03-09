@IsTest
private class ApiUsageDashboardControllerTest {
    @IsTest
    static void testRecent() {
        // Create test data
        List<API_Usage_Snapshot__c> snapshots = new List<API_Usage_Snapshot__c>();
        for (Integer i = 0; i < 5; i++) {
            snapshots.add(
                new API_Usage_Snapshot__c(
                    Taken_On__c = System.now().addMinutes(-i * 10),
                    Daily_Used__c = 1000 * i,
                    Daily_Limit__c = 100000,
                    Percent_Used__c = i * 1.0,
                    Projected_Exhaustion__c = System.now().addHours(i)
                )
            );
        }
        insert snapshots;

        Test.startTest();
        List<ApiUsageDashboardController.Row> rows = ApiUsageDashboardController.getRecentSnapshots(10);
        Test.stopTest();

        Assert.areEqual(5, rows.size(), 'Should return 5 snapshot rows');
        Assert.areNotEqual(null, rows[0].takenOn, 'TakenOn should be populated');
        Assert.areNotEqual(null, rows[0].used, 'Used should be populated');
        Assert.areEqual(100000, rows[0].dailyLimit, 'Limit should be 100000');
        Assert.areNotEqual(null, rows[0].percent, 'Percent should be populated');
    }

    @IsTest
    static void testRecentWithLimit() {
        // Create more test data than the limit
        List<API_Usage_Snapshot__c> snapshots = new List<API_Usage_Snapshot__c>();
        for (Integer i = 0; i < 20; i++) {
            snapshots.add(
                new API_Usage_Snapshot__c(
                    Taken_On__c = System.now().addMinutes(-i),
                    Daily_Used__c = 5000,
                    Daily_Limit__c = 100000,
                    Percent_Used__c = 5.0
                )
            );
        }
        insert snapshots;

        Test.startTest();
        List<ApiUsageDashboardController.Row> rows = ApiUsageDashboardController.getRecentSnapshots(5);
        Test.stopTest();

        Assert.areEqual(5, rows.size(), 'Should respect limit size of 5');
    }

    @IsTest
    static void testRecentEmpty() {
        // Test with no data
        Test.startTest();
        List<ApiUsageDashboardController.Row> rows = ApiUsageDashboardController.getRecentSnapshots(10);
        Test.stopTest();

        Assert.areEqual(0, rows.size(), 'Should return empty list when no data');
    }

    @IsTest
    static void testRecentMinimumLimit() {
        // Test that minimum limit is enforced
        insert new API_Usage_Snapshot__c(
            Taken_On__c = System.now(),
            Daily_Used__c = 1000,
            Daily_Limit__c = 100000,
            Percent_Used__c = 1.0
        );

        Test.startTest();
        List<ApiUsageDashboardController.Row> rows = ApiUsageDashboardController.getRecentSnapshots(0);
        Test.stopTest();

        // Math.max(1, limitSize) should ensure at least 1 result
        Assert.areEqual(1, rows.size(), 'Should return at least 1 row even with limit 0');
    }
}
