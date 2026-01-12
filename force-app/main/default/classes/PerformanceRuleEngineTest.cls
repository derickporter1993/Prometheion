/**
 * Test class for PerformanceRuleEngine
 */
@isTest
private class PerformanceRuleEngineTest {
    
    @isTest
    static void testEvaluateAndPublishNoAlerts() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();
        
        System.assertEquals(false, result.warning, 'Should not trigger warning');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assertEquals(0, result.eventsPublished, 'No events should be published');
    }
    
    @isTest
    static void testEvaluateAndPublishWarning() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 8500; // Above default warn (8000) but below crit (9000)
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'testContext');
        Test.stopTest();
        
        System.assertEquals(true, result.warning, 'Should trigger warning');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
    
    @isTest
    static void testEvaluateAndPublishCritical() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 9500; // Above default crit (9000)
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'testContext');
        Test.stopTest();
        
        System.assertEquals(true, result.critical, 'Should trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
    
    @isTest
    static void testEvaluateAndPublishNullStats() {
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(null, null);
        Test.stopTest();
        
        System.assert(result.message.contains('Error'), 'Should return error message');
    }
    
    @isTest
    static void testEvaluateAndPublishMultipleThresholds() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 9500; // Critical
        stats.heapKb = 5500; // Critical (above 5000)
        stats.soql = 95; // Warning (above 90, below 100)
        stats.dml = 145; // Warning (above 140, below 150)
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'multiTest');
        Test.stopTest();
        
        System.assertEquals(true, result.critical, 'Should trigger critical');
        System.assertEquals(true, result.warning, 'Should trigger warning');
        System.assert(result.eventsPublished >= 4, 'Should have published multiple events');
    }
    
    @isTest
    static void testEvaluateWithCustomCCXSettings() {
        // Create custom CCX settings
        CCX_Settings__c customSettings = new CCX_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CPU_Warn__c = 7000,
            CPU_Crit__c = 8500,
            Heap_Warn__c = 4000,
            Heap_Crit__c = 4500,
            SOQL_Warn__c = 80,
            SOQL_Crit__c = 95,
            DML_Warn__c = 120,
            DML_Crit__c = 140
        );
        insert customSettings;
        
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 7200; // Above custom warn (7000) but below custom crit (8500)
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'customSettingsTest');
        Test.stopTest();
        
        System.assertEquals(true, result.warning, 'Should trigger warning with custom CPU threshold');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
    
    @isTest
    static void testEvaluate_IndividualHeapThreshold() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 4600; // Above default warn (4500) but below crit (5000)
        stats.soql = 10;
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'heapWarningTest');
        Test.stopTest();
        
        System.assertEquals(true, result.warning, 'Should trigger warning for HEAP');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
    
    @isTest
    static void testEvaluate_IndividualSOQLThreshold() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 95; // Above default warn (90) but below crit (100)
        stats.dml = 10;
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'soqlWarningTest');
        Test.stopTest();
        
        System.assertEquals(true, result.warning, 'Should trigger warning for SOQL');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
    
    @isTest
    static void testEvaluate_IndividualDMLThreshold() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 145; // Above default warn (140) but below crit (150)
        
        Test.startTest();
        PerformanceRuleEngine.EvalResult result = PerformanceRuleEngine.evaluateAndPublish(stats, 'dmlWarningTest');
        Test.stopTest();
        
        System.assertEquals(true, result.warning, 'Should trigger warning for DML');
        System.assertEquals(false, result.critical, 'Should not trigger critical');
        System.assert(result.eventsPublished > 0, 'Should have published events');
    }
}
