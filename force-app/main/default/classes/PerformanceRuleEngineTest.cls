@IsTest
private class PerformanceRuleEngineTest {
    @IsTest static void testEvaluate() {
        LimitMetrics.GovernorStats s = new LimitMetrics.GovernorStats();
        s.cpuMs = 9500; s.heapKb = 6000; s.soql = 100; s.dml = 155;
        Test.startTest();
        PerformanceRuleEngine.EvalResult r = PerformanceRuleEngine.evaluateAndPublish(s, null);
        Test.stopTest();
        System.assertEquals(true, r.critical, 'Should mark critical');
    }
}
