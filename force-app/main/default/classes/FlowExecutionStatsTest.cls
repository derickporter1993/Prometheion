/**
 * Test class for FlowExecutionStats
 */
@IsTest
private class FlowExecutionStatsTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test flow execution records
        List<Flow_Execution__c> executions = new List<Flow_Execution__c>();
        for (Integer i = 0; i < 10; i++) {
            Integer mod3 = Math.mod(i, 3);
            
            executions.add(new Flow_Execution__c(
                Flow_Name__c = 'TestFlow' + mod3, // 3 different flows
                Status__c = (i < 2) ? 'Fault' : 'Success',
                CPU__c = 100 + i,
                SOQL__c = 5 + i,
                DML__c = 2 + i,
                Run_Time__c = System.now().addMinutes(-i)
            ));
        }
        insert executions;
    }
    
    @IsTest
    static void testGetTopFlows_ReturnsResults() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(5);
        Test.stopTest();
        
        Assert.areNotEqual(null, results, 'Results should not be null');
        Assert.isTrue(!results.isEmpty(), 'Should return at least one result');
    }
    
    @IsTest
    static void testGetTopFlows_WithLimit() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(2);
        Test.stopTest();
        
        Assert.isTrue(results.size() <= 2, 'Should respect limit');
    }
    
    @IsTest
    static void testGetTopFlows_IncludesFaultCount() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(5);
        Test.stopTest();
        
        // Verify fault counts are included
        for (FlowExecutionStats.ExecAgg agg : results) {
            Assert.areNotEqual(null, agg.faults, 'Fault count should not be null');
            Assert.isTrue(agg.faults >= 0, 'Fault count should be non-negative');
        }
    }
    
    @IsTest
    static void testGetTopFlows_ZeroLimit() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(0);
        Test.stopTest();
        
        // Should default to at least 1
        Assert.isTrue(results.size() >= 1, 'Should return at least 1 result even with 0 limit');
    }
    
    @IsTest
    static void testGetTopFlows_NegativeLimit() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(-5);
        Test.stopTest();
        
        // Should default to at least 1
        Assert.isTrue(results.size() >= 1, 'Should return at least 1 result even with negative limit');
    }
    
    @IsTest
    static void testGetTopFlows_EmptyData() {
        Test.startTest();
        // Delete all test data inside test context to preserve DML limits
        delete [SELECT Id FROM Flow_Execution__c];

        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.getTopFlows(5);
        Test.stopTest();
        
        Assert.areEqual(0, results.size(), 'Should return empty list when no data');
    }
}
