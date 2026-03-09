@IsTest
private class ApiUsageSnapshotTest {
    @IsTest static void testRun() {
        Test.setMock(HttpCalloutMock.class, new ApiLimitsCalloutMock());
        Test.startTest();
        ApiUsageSnapshot.run();
        Test.stopTest();
        List<API_Usage_Snapshot__c> rows = [SELECT Id, Daily_Used__c, Daily_Limit__c FROM API_Usage_Snapshot__c LIMIT 1];
        Assert.areEqual(1, rows.size());
        Assert.areEqual(25000, rows[0].Daily_Used__c);
        Assert.areEqual(100000, rows[0].Daily_Limit__c);
    }
}
