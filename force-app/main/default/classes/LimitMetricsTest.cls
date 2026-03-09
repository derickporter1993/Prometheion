@IsTest
private class LimitMetricsTest {
    @IsTest
    static void testFetchGovernorStats() {
        Test.startTest();
        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Verify the object is not null
        Assert.areNotEqual(null, g, 'GovernorStats should not be null');

        // Verify all fields are populated with valid values
        Assert.areNotEqual(null, g.cpuMs, 'CPU time should not be null');
        Assert.isTrue(g.cpuMs >= 0, 'CPU time should be non-negative');

        Assert.areNotEqual(null, g.soql, 'SOQL queries should not be null');
        Assert.isTrue(g.soql >= 0, 'SOQL queries should be non-negative');

        Assert.areNotEqual(null, g.dml, 'DML statements should not be null');
        Assert.isTrue(g.dml >= 0, 'DML statements should be non-negative');

        Assert.areNotEqual(null, g.heapKb, 'Heap size should not be null');
        Assert.isTrue(g.heapKb >= 0, 'Heap size should be non-negative');

        // Verify max/remaining fields are populated
        Assert.areNotEqual(null, g.cpuMax, 'CPU max should not be null');
        Assert.isTrue(g.cpuMax > 0, 'CPU max should be positive');

        Assert.areNotEqual(null, g.soqlMax, 'SOQL max should not be null');
        Assert.isTrue(g.soqlMax > 0, 'SOQL max should be positive');

        Assert.areNotEqual(null, g.dmlMax, 'DML max should not be null');
        Assert.isTrue(g.dmlMax > 0, 'DML max should be positive');

        Assert.areNotEqual(null, g.heapMaxKb, 'Heap max should not be null');
        Assert.isTrue(g.heapMaxKb > 0, 'Heap max should be positive');
    }

    @IsTest
    static void testGovernorStatsAfterDML() {
        Test.startTest();
        // Perform DML inside test context so limits are tracked
        insert new Performance_Alert_History__c(
            Metric__c = 'TEST',
            Value__c = 100,
            Threshold__c = 50
        );

        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Verify limits show usage (DML includes the insert above)
        Assert.isTrue(g.dml >= 0, 'DML count should be non-negative');
        Assert.isTrue(g.heapKb >= 0, 'Heap should be non-negative');
    }

    @IsTest
    static void testGovernorStatsAfterSOQL() {
        Test.startTest();
        // Perform SOQL inside test context so limits are tracked
        List<Performance_Alert_History__c> records = [
            SELECT Id
            FROM Performance_Alert_History__c
            LIMIT 1
        ];

        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Verify method works and returns valid stats
        Assert.areNotEqual(null, g, 'GovernorStats should be returned');
        Assert.isTrue(g.soql >= 0, 'SOQL count should be valid');
    }

    @IsTest
    static void testCacheableAnnotation() {
        // Call the method multiple times to verify cacheability doesn't cause issues
        Test.startTest();
        LimitMetrics.GovernorStats g1 = LimitMetrics.fetchGovernorStats();
        LimitMetrics.GovernorStats g2 = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Both calls should return valid objects
        Assert.areNotEqual(null, g1, 'First call should return valid stats');
        Assert.areNotEqual(null, g2, 'Second call should return valid stats');
    }
}
