/**
 * Tests for RuleResult DTO and static factory methods.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see RuleResult
 */
@IsTest
private class RuleResultTest {

    private static Compliance_Rule__mdt createMockRule() {
        return new Compliance_Rule__mdt(
            DeveloperName = 'Test_Rule_001',
            Rule_Name__c = 'Test Rule',
            Framework__c = 'SOC2',
            Control_Reference__c = 'CC6.1',
            Category__c = 'Access Control',
            Severity__c = 'HIGH',
            Evaluation_Type__c = 'SOQL_QUERY',
            Weight__c = 2.0
        );
    }

    @IsTest
    static void shouldCreatePassingResult() {
        Compliance_Rule__mdt rule = createMockRule();

        Test.startTest();
        RuleResult result = RuleResult.pass(rule, 150);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Result should be passing');
        Assert.areEqual('Test_Rule_001', result.ruleDeveloperName, 'DeveloperName should match');
        Assert.areEqual('Test Rule', result.ruleName, 'Rule name should match');
        Assert.areEqual('SOC2', result.framework, 'Framework should match');
        Assert.areEqual('CC6.1', result.controlReference, 'Control reference should match');
        Assert.areEqual('Access Control', result.category, 'Category should match');
        Assert.areEqual('HIGH', result.severity, 'Severity should match');
        Assert.areEqual('SOQL_QUERY', result.evaluationType, 'Evaluation type should match');
        Assert.areEqual(2.0, result.weight, 'Weight should match');
        Assert.areEqual(150, result.executionTimeMs, 'Execution time should match');
        Assert.isNotNull(result.evaluatedAt, 'Evaluated timestamp should be set');
    }

    @IsTest
    static void shouldCreateFailingResult() {
        Compliance_Rule__mdt rule = createMockRule();

        Test.startTest();
        RuleResult result = RuleResult.fail(rule, 'Found 5 non-compliant records', 200);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Result should be failing');
        Assert.areEqual('Found 5 non-compliant records', result.findingDetails,
            'Finding details should match');
        Assert.areEqual(200, result.executionTimeMs, 'Execution time should match');
    }

    @IsTest
    static void shouldCreateErrorResult() {
        Compliance_Rule__mdt rule = createMockRule();

        Test.startTest();
        RuleResult result = RuleResult.error(rule, 'Query syntax error');
        Test.stopTest();

        Assert.isFalse(result.passed, 'Error result should be failing');
        Assert.isTrue(result.findingDetails.contains('Evaluation error'),
            'Finding details should contain error prefix');
        Assert.isTrue(result.findingDetails.contains('Query syntax error'),
            'Finding details should contain error message');
        Assert.areEqual(0, result.executionTimeMs, 'Error result should have 0 execution time');
    }

    @IsTest
    static void shouldHandleNullFieldsGracefully() {
        Compliance_Rule__mdt rule = new Compliance_Rule__mdt(
            DeveloperName = 'Null_Test_Rule'
        );

        Test.startTest();
        RuleResult result = RuleResult.pass(rule, 10);
        Test.stopTest();

        Assert.areEqual('Null_Test_Rule', result.ruleDeveloperName, 'DeveloperName should match');
        Assert.areEqual('Null_Test_Rule', result.ruleName,
            'Rule name should fall back to DeveloperName when null');
        Assert.areEqual('', result.controlReference, 'Control reference should default to empty');
        Assert.areEqual('', result.category, 'Category should default to empty');
        Assert.areEqual('MEDIUM', result.severity, 'Severity should default to MEDIUM');
        Assert.areEqual('SOQL_QUERY', result.evaluationType,
            'Evaluation type should default to SOQL_QUERY');
        Assert.areEqual(1, result.weight, 'Weight should default to 1');
    }

    @IsTest
    static void shouldSetAuraEnabledProperties() {
        RuleResult result = new RuleResult();
        result.ruleDeveloperName = 'Test';
        result.ruleName = 'Test Name';
        result.framework = 'HIPAA';
        result.controlReference = '164.312';
        result.category = 'Technical';
        result.severity = 'CRITICAL';
        result.passed = true;
        result.findingDetails = 'Details';
        result.executionTimeMs = 100;
        result.weight = 3;
        result.evaluationType = 'CONFIG_SCAN';
        result.evaluatedAt = Datetime.now();

        Assert.areEqual('Test', result.ruleDeveloperName, 'Property getter should work');
        Assert.areEqual('HIPAA', result.framework, 'Property getter should work');
        Assert.areEqual('CRITICAL', result.severity, 'Property getter should work');
    }
}
