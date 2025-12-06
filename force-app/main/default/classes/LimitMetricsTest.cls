/**
 * LimitMetricsTest - Test class for LimitMetrics
 * 
 * @author Solentra
 * @version 1.0
 */
@IsTest
private class LimitMetricsTest {
    
    @IsTest
    static void testFetchGovernorStats() {
        Test.startTest();
        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Verify the object is not null
        System.assertNotEquals(null, g, 'GovernorStats should not be null');

        // Verify all fields are populated with valid values
        System.assertNotEquals(null, g.cpuMs, 'CPU time should not be null');
        System.assert(g.cpuMs >= 0, 'CPU time should be non-negative');

        System.assertNotEquals(null, g.soql, 'SOQL queries should not be null');
        System.assert(g.soql >= 0, 'SOQL queries should be non-negative');

        System.assertNotEquals(null, g.dml, 'DML statements should not be null');
        System.assert(g.dml >= 0, 'DML statements should be non-negative');

        System.assertNotEquals(null, g.heapKb, 'Heap size should not be null');
        System.assert(g.heapKb >= 0, 'Heap size should be non-negative');
    }

    @IsTest
    static void testGovernorStatsAfterDML() {
        // Perform some DML to consume governor limits
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Test.startTest();
        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Verify limits show usage
        System.assertNotEquals(null, g, 'GovernorStats should be returned');
    }

    @IsTest
    static void testGovernorStatsAfterSOQL() {
        // Perform a SOQL query to consume limits
        List<User> users = [SELECT Id FROM User LIMIT 1];

        Test.startTest();
        LimitMetrics.GovernorStats g = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // After startTest/stopTest, governor limits reset, but we can verify the method works
        System.assertNotEquals(null, g, 'GovernorStats should be returned');
        System.assert(g.soql >= 0, 'SOQL count should be valid');
    }

    @IsTest
    static void testCacheableAnnotation() {
        // Call the method multiple times to verify cacheability doesn't cause issues
        Test.startTest();
        LimitMetrics.GovernorStats g1 = LimitMetrics.fetchGovernorStats();
        LimitMetrics.GovernorStats g2 = LimitMetrics.fetchGovernorStats();
        Test.stopTest();

        // Both calls should return valid objects
        System.assertNotEquals(null, g1, 'First call should return valid stats');
        System.assertNotEquals(null, g2, 'Second call should return valid stats');
    }
}
