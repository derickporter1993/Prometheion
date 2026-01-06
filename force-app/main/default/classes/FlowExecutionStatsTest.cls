@IsTest
private class FlowExecutionStatsTest {

    @TestSetup
    static void setupTestData() {
        // Create test Flow_Execution__c records
        List<Flow_Execution__c> executions = new List<Flow_Execution__c>();

        // Flow 1: 10 successful runs
        for (Integer i = 0; i < 10; i++) {
            executions.add(new Flow_Execution__c(
                Flow_Name__c = 'TestFlow_Alpha',
                Status__c = 'SUCCESS',
                Run_Time__c = Datetime.now().addHours(-i),
                CPU__c = 100,
                SOQL__c = 5,
                DML__c = 2
            ));
        }

        // Flow 2: 5 runs with 2 faults
        for (Integer i = 0; i < 5; i++) {
            String status = (i < 2) ? 'Fault' : 'SUCCESS';
            executions.add(new Flow_Execution__c(
                Flow_Name__c = 'TestFlow_Beta',
                Status__c = status,
                Run_Time__c = Datetime.now().addHours(-i),
                CPU__c = 200,
                SOQL__c = 10,
                DML__c = 5
            ));
        }

        // Flow 3: 3 runs, all successful
        for (Integer i = 0; i < 3; i++) {
            executions.add(new Flow_Execution__c(
                Flow_Name__c = 'TestFlow_Gamma',
                Status__c = 'SUCCESS',
                Run_Time__c = Datetime.now().addDays(-i),
                CPU__c = 50,
                SOQL__c = 2,
                DML__c = 1
            ));
        }

        insert executions;
    }

    @IsTest
    static void testTopFlows_PositivePath() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: Should return aggregated results
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assert(results.size() > 0, 'Should have at least one flow');
        System.assert(results.size() <= 10, 'Should respect limit parameter');
    }

    @IsTest
    static void testTopFlows_OrderedByRunCount() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: Should be ordered by runs descending
        System.assertEquals('TestFlow_Alpha', results[0].flowName, 'Most executed flow should be first');
        System.assertEquals(10, results[0].runs, 'Alpha should have 10 runs');
    }

    @IsTest
    static void testTopFlows_CalculatesFaults() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Find TestFlow_Beta in results
        FlowExecutionStats.ExecAgg betaFlow = null;
        for (FlowExecutionStats.ExecAgg agg : results) {
            if (agg.flowName == 'TestFlow_Beta') {
                betaFlow = agg;
                break;
            }
        }

        System.assertNotEquals(null, betaFlow, 'Beta flow should be in results');
        System.assertEquals(5, betaFlow.runs, 'Beta should have 5 runs');
        System.assertEquals(2, betaFlow.faults, 'Beta should have 2 faults');
    }

    @IsTest
    static void testTopFlows_TracksLastRun() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: lastRun should be populated
        for (FlowExecutionStats.ExecAgg agg : results) {
            System.assertNotEquals(null, agg.lastRun, 'lastRun should be populated for ' + agg.flowName);
        }
    }

    @IsTest
    static void testTopFlows_LimitParameter() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(2);
        Test.stopTest();

        // Then: Should only return 2 flows
        System.assertEquals(2, results.size(), 'Should respect limit of 2');
    }

    @IsTest
    static void testTopFlows_LimitOfOne() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(1);
        Test.stopTest();

        // Then: Should return only the top flow
        System.assertEquals(1, results.size(), 'Should return exactly 1 flow');
        System.assertEquals('TestFlow_Alpha', results[0].flowName, 'Should be the most executed flow');
    }

    @IsTest
    static void testTopFlows_ZeroLimit() {
        // Given: Zero limit (should be treated as minimum of 1)
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(0);
        Test.stopTest();

        // Then: Should return at least 1 due to Math.max(1, limitSize)
        System.assertEquals(1, results.size(), 'Zero limit should default to 1');
    }

    @IsTest
    static void testTopFlows_NegativeLimit() {
        // Given: Negative limit (should be treated as minimum of 1)
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(-5);
        Test.stopTest();

        // Then: Should return 1 due to Math.max(1, limitSize)
        System.assertEquals(1, results.size(), 'Negative limit should default to 1');
    }

    @IsTest
    static void testTopFlows_NoData() {
        // Given: Delete all test data
        delete [SELECT Id FROM Flow_Execution__c];

        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: Should return empty list
        System.assertEquals(0, results.size(), 'Should return empty list when no data');
    }

    @IsTest
    static void testTopFlows_BulkData() {
        // Given: Create additional bulk data
        List<Flow_Execution__c> bulkExecutions = new List<Flow_Execution__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkExecutions.add(new Flow_Execution__c(
                Flow_Name__c = 'BulkFlow_' + Math.mod(i, 20),
                Status__c = Math.mod(i, 10) == 0 ? 'Fault' : 'SUCCESS',
                Run_Time__c = Datetime.now().addMinutes(-i),
                CPU__c = 100,
                SOQL__c = 5,
                DML__c = 2
            ));
        }
        insert bulkExecutions;

        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(50);
        Test.stopTest();

        // Then: Should handle bulk data without governor limit issues
        System.assert(results.size() > 0, 'Should return results for bulk data');
        System.assert(results.size() <= 50, 'Should respect limit parameter');
    }

    @IsTest
    static void testTopFlows_ExecAggProperties() {
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: All properties should be accessible (AuraEnabled verification)
        for (FlowExecutionStats.ExecAgg agg : results) {
            System.assertNotEquals(null, agg.flowName, 'flowName should be accessible');
            System.assertNotEquals(null, agg.runs, 'runs should be accessible');
            System.assertNotEquals(null, agg.faults, 'faults should be accessible');
            // Note: lastRun will be populated from test data
        }
    }

    @IsTest
    static void testTopFlows_AllFaults() {
        // Given: A flow with only fault executions
        delete [SELECT Id FROM Flow_Execution__c];
        List<Flow_Execution__c> faultExecutions = new List<Flow_Execution__c>();
        for (Integer i = 0; i < 5; i++) {
            faultExecutions.add(new Flow_Execution__c(
                Flow_Name__c = 'AllFaultsFlow',
                Status__c = 'Fault',
                Run_Time__c = Datetime.now().addHours(-i),
                CPU__c = 100,
                SOQL__c = 5,
                DML__c = 2
            ));
        }
        insert faultExecutions;

        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Then: Faults should equal runs
        System.assertEquals(1, results.size(), 'Should have one flow');
        System.assertEquals(5, results[0].runs, 'Should have 5 runs');
        System.assertEquals(5, results[0].faults, 'Should have 5 faults');
    }

    @IsTest
    static void testTopFlows_ZeroFaults() {
        // Given: A flow with only successful executions (already in test setup - TestFlow_Alpha)
        Test.startTest();
        List<FlowExecutionStats.ExecAgg> results = FlowExecutionStats.topFlows(10);
        Test.stopTest();

        // Find TestFlow_Alpha
        FlowExecutionStats.ExecAgg alphaFlow = null;
        for (FlowExecutionStats.ExecAgg agg : results) {
            if (agg.flowName == 'TestFlow_Alpha') {
                alphaFlow = agg;
                break;
            }
        }

        System.assertNotEquals(null, alphaFlow, 'Alpha flow should be in results');
        System.assertEquals(0, alphaFlow.faults, 'Alpha should have 0 faults');
    }
}
