/**
 * PerformanceRuleEngineTest - Test class for PerformanceRuleEngine
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
@isTest
private class PerformanceRuleEngineTest {
    
    @isTest
    static void testEvaluateNormalStats() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();
        
        System.assertEquals(false, result.critical, 'Should not be critical');
        System.assertEquals(false, result.warning, 'Should not be warning');
    }
    
    @isTest
    static void testEvaluateCriticalStats() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 9500;
        stats.heapKb = 6000;
        stats.soql = 100;
        stats.dml = 155;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();
        
        System.assertEquals(true, result.critical, 'Should be critical');
    }
    
    @isTest
    static void testEvalResultDefaults() {
        PerformanceRuleEngine.EvalResult result = new PerformanceRuleEngine.EvalResult();
        System.assertEquals(false, result.warning, 'Default warning should be false');
        System.assertEquals(false, result.critical, 'Default critical should be false');
    }
}
