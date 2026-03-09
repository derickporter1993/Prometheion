/**
 * Tests for ComplianceRuleEvaluator core evaluation engine.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see ComplianceRuleEvaluator
 */
@IsTest
private class ComplianceRuleEvaluatorTest {

    @IsTest
    static void shouldReturnEmptyListForBlankFramework() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules = ComplianceRuleEvaluator.loadRules('');
        Test.stopTest();

        Assert.isTrue(rules.isEmpty(), 'Blank framework should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyListForNullFramework() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules = ComplianceRuleEvaluator.loadRules(null);
        Test.stopTest();

        Assert.isTrue(rules.isEmpty(), 'Null framework should return empty list');
    }

    @IsTest
    static void shouldLoadAllActiveRules() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules = ComplianceRuleEvaluator.loadAllActiveRules();
        Test.stopTest();

        // CMT records may or may not exist in test context, just verify no exception
        Assert.isNotNull(rules, 'Rules list should not be null');
    }

    @IsTest
    static void shouldLoadRulesForFramework() {
        Test.startTest();
        List<Compliance_Rule__mdt> rules = ComplianceRuleEvaluator.loadRules('SOC2');
        Test.stopTest();

        Assert.isNotNull(rules, 'Rules list should not be null');
    }

    @IsTest
    static void shouldHandleUnknownEvaluationType() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'Unknown_Type_Rule',
            Rule_Name__c = 'Unknown Type Test',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'INVALID_TYPE',
            Severity__c = 'LOW',
            Weight__c = 1
        );

        Test.startTest();
        RuleResult result = ComplianceRuleEvaluator.evaluateRule(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Unknown type should result in error');
        Assert.isTrue(result.findingDetails.contains('Unknown evaluation type'),
            'Should contain unknown type message');
    }

    @IsTest
    static void shouldDispatchToSOQLEvaluator() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'SOQL_Test_Rule',
            Rule_Name__c = 'SOQL Test',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'SOQL_QUERY',
            Evaluation_Query__c = 'SELECT Id FROM User LIMIT 1',
            Threshold_Operator__c = 'GREATER_THAN',
            Threshold_Value__c = '0',
            Severity__c = 'MEDIUM',
            Weight__c = 1
        );

        Test.startTest();
        RuleResult result = ComplianceRuleEvaluator.evaluateRule(rule);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.executionTimeMs, 'Execution time should be recorded');
    }

    @IsTest
    static void shouldDispatchToMetadataEvaluator() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'Metadata_Test_Rule',
            Rule_Name__c = 'Metadata Test',
            Framework__c = 'HIPAA',
            Evaluation_Type__c = 'METADATA_CHECK',
            Evaluation_Query__c = '{"checkType":"OBJECT_EXISTS","target":"Account"}',
            Severity__c = 'HIGH',
            Weight__c = 1
        );

        Test.startTest();
        RuleResult result = ComplianceRuleEvaluator.evaluateRule(rule);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.passed, 'Account object should exist');
    }

    @IsTest
    static void shouldDispatchToConfigEvaluator() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'Config_Test_Rule',
            Rule_Name__c = 'Config Test',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'CONFIG_SCAN',
            Evaluation_Query__c = '{"scanType":"PASSWORD_POLICY","minLength":8}',
            Severity__c = 'MEDIUM',
            Weight__c = 1
        );

        Test.startTest();
        RuleResult result = ComplianceRuleEvaluator.evaluateRule(rule);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void shouldDefaultToSOQLWhenEvalTypeNull() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'Null_Type_Rule',
            Rule_Name__c = 'Null Type Test',
            Framework__c = 'SOC2',
            Evaluation_Query__c = 'SELECT Id FROM User LIMIT 1',
            Threshold_Operator__c = 'GREATER_THAN',
            Threshold_Value__c = '0',
            Severity__c = 'LOW',
            Weight__c = 1
        );

        Test.startTest();
        RuleResult result = ComplianceRuleEvaluator.evaluateRule(rule);
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void shouldReturnSupportedEvaluationTypes() {
        Test.startTest();
        Set<String> types = ComplianceRuleEvaluator.getSupportedEvaluationTypes();
        Test.stopTest();

        Assert.areEqual(3, types.size(), 'Should have 3 evaluation types');
        Assert.isTrue(types.contains('SOQL_QUERY'), 'Should contain SOQL_QUERY');
        Assert.isTrue(types.contains('METADATA_CHECK'), 'Should contain METADATA_CHECK');
        Assert.isTrue(types.contains('CONFIG_SCAN'), 'Should contain CONFIG_SCAN');
    }

    @IsTest
    static void shouldEvaluateFrameworkRules() {
        Test.startTest();
        List<RuleResult> results = ComplianceRuleEvaluator.evaluateFramework('SOC2');
        Test.stopTest();

        Assert.isNotNull(results, 'Results should not be null');
    }
}
