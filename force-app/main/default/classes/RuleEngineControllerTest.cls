/**
 * Tests for RuleEngineController LWC endpoints.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see RuleEngineController
 */
@IsTest
private class RuleEngineControllerTest {

    @IsTest
    static void shouldEvaluateFramework() {
        Test.startTest();
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            RuleEngineController.evaluateFramework('SOC2');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.areEqual('COMPLETED', result.status, 'Status should be COMPLETED');
        Assert.areEqual('SOC2', result.framework, 'Framework should match');
    }

    @IsTest
    static void shouldThrowForBlankFramework() {
        Test.startTest();
        try {
            RuleEngineController.evaluateFramework('');
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'),
                'Exception should indicate framework is required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowForNullFramework() {
        Test.startTest();
        try {
            RuleEngineController.evaluateFramework(null);
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'),
                'Exception should indicate framework is required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldGetFrameworkScores() {
        Test.startTest();
        List<ComplianceScoreAggregator.ScoreSummary> summaries =
            RuleEngineController.getFrameworkScores();
        Test.stopTest();

        Assert.isNotNull(summaries, 'Summaries should not be null');
    }

    @IsTest
    static void shouldGetExecutionHistoryWithDefault() {
        // Create test execution records
        Workflow_Execution__c exec1 = new Workflow_Execution__c(
            Template_Name__c = 'Test 1',
            Framework__c = 'SOC2',
            Status__c = 'COMPLETED',
            Started_At__c = Datetime.now().addHours(-2),
            Completed_At__c = Datetime.now().addHours(-1)
        );
        Workflow_Execution__c exec2 = new Workflow_Execution__c(
            Template_Name__c = 'Test 2',
            Framework__c = 'HIPAA',
            Status__c = 'COMPLETED',
            Started_At__c = Datetime.now().addHours(-1),
            Completed_At__c = Datetime.now()
        );
        insert as user new List<Workflow_Execution__c>{ exec1, exec2 };

        Test.startTest();
        List<Workflow_Execution__c> history =
            RuleEngineController.getExecutionHistory(null);
        Test.stopTest();

        Assert.isTrue(history.size() >= 2,
            'Should return at least 2 execution records');
    }

    @IsTest
    static void shouldGetExecutionHistoryWithCustomLimit() {
        Workflow_Execution__c exec = new Workflow_Execution__c(
            Template_Name__c = 'Test',
            Framework__c = 'SOC2',
            Status__c = 'COMPLETED',
            Started_At__c = Datetime.now()
        );
        insert as user exec;

        Test.startTest();
        List<Workflow_Execution__c> history =
            RuleEngineController.getExecutionHistory(1);
        Test.stopTest();

        Assert.areEqual(1, history.size(), 'Should return exactly 1 record');
    }

    @IsTest
    static void shouldCapExecutionHistoryAt100() {
        Test.startTest();
        List<Workflow_Execution__c> history =
            RuleEngineController.getExecutionHistory(500);
        Test.stopTest();

        // Even though 500 was requested, limit is capped at 100
        Assert.isTrue(history.size() <= 100,
            'Should never return more than 100 records');
    }

    @IsTest
    static void shouldGetActiveRulesForFramework() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules =
            RuleEngineController.getActiveRules('SOC2');
        Test.stopTest();

        Assert.isNotNull(rules, 'Rules should not be null');
    }

    @IsTest
    static void shouldGetAllActiveRulesWhenFrameworkBlank() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules =
            RuleEngineController.getActiveRules('');
        Test.stopTest();

        Assert.isNotNull(rules, 'Rules should not be null');
    }

    @IsTest
    static void shouldGetAllActiveRulesWhenFrameworkNull() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules =
            RuleEngineController.getActiveRules(null);
        Test.stopTest();

        Assert.isNotNull(rules, 'Rules should not be null');
    }

    @IsTest
    static void shouldGetActiveFrameworks() {
        Test.startTest();
        Set<String> frameworks = RuleEngineController.getActiveFrameworks();
        Test.stopTest();

        Assert.isNotNull(frameworks, 'Frameworks set should not be null');
    }
}
