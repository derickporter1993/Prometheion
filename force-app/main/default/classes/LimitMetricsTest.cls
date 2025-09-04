@IsTest
private class LimitMetricsTest {
    @IsTest static void testFetch() {
        Test.startTest();
        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        System.assertNotEquals(null, g);
        Test.stopTest();
    }
}
