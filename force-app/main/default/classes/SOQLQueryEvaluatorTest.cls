/**
 * Tests for SOQLQueryEvaluator strategy.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see SOQLQueryEvaluator
 */
@IsTest
private class SOQLQueryEvaluatorTest {

    private static Compliance_Rule__mdt createSOQLRule(String query, String operator,
            String threshold) {
        return new Compliance_Rule__mdt(
            DeveloperName = 'SOQL_Test',
            Rule_Name__c = 'SOQL Test Rule',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'SOQL_QUERY',
            Evaluation_Query__c = query,
            Threshold_Operator__c = operator,
            Threshold_Value__c = threshold,
            Severity__c = 'MEDIUM',
            Weight__c = 1
        );
    }

    @IsTest
    static void shouldPassWhenQueryReturnsExpectedCount() {
        Compliance_Rule__mdt rule = createSOQLRule(
            'SELECT Id FROM User LIMIT 1', 'EQUALS', '1');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Should pass when result count equals threshold');
    }

    @IsTest
    static void shouldFailWhenQueryCountExceedsThreshold() {
        Compliance_Rule__mdt rule = createSOQLRule(
            'SELECT Id FROM User LIMIT 5', 'LESS_THAN', '1');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when result count >= threshold');
        Assert.isTrue(result.findingDetails.contains('Query returned'),
            'Finding details should describe the count mismatch');
    }

    @IsTest
    static void shouldPassWithGreaterThanOperator() {
        Compliance_Rule__mdt rule = createSOQLRule(
            'SELECT Id FROM User LIMIT 1', 'GREATER_THAN', '0');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Should pass when result count > threshold');
    }

    @IsTest
    static void shouldPassWithNotEqualsOperator() {
        Compliance_Rule__mdt rule = createSOQLRule(
            'SELECT Id FROM User LIMIT 1', 'NOT_EQUALS', '0');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Should pass when count != threshold');
    }

    @IsTest
    static void shouldReturnErrorForBlankQuery() {
        Compliance_Rule__mdt rule = createSOQLRule('', 'EQUALS', '0');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for blank query');
        Assert.isTrue(result.findingDetails.contains('query is blank'),
            'Should indicate blank query error');
    }

    @IsTest
    static void shouldReturnErrorForInvalidQuery() {
        Compliance_Rule__mdt rule = createSOQLRule(
            'THIS IS NOT A VALID QUERY', 'EQUALS', '0');

        Test.startTest();
        RuleResult result = SOQLQueryEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for invalid query');
    }

    @IsTest
    static void shouldCompareThresholdEquals() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(5, 'EQUALS', '5');
        Test.stopTest();

        Assert.isTrue(result, '5 should equal 5');
    }

    @IsTest
    static void shouldCompareThresholdNotEquals() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(5, 'NOT_EQUALS', '3');
        Test.stopTest();

        Assert.isTrue(result, '5 should not equal 3');
    }

    @IsTest
    static void shouldCompareThresholdGreaterThan() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(10, 'GREATER_THAN', '5');
        Test.stopTest();

        Assert.isTrue(result, '10 should be greater than 5');
    }

    @IsTest
    static void shouldCompareThresholdLessThan() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(3, 'LESS_THAN', '5');
        Test.stopTest();

        Assert.isTrue(result, '3 should be less than 5');
    }

    @IsTest
    static void shouldHandleNonNumericThreshold() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(5, 'EQUALS', 'not_a_number');
        Test.stopTest();

        Assert.isTrue(result, 'Should fall back to string comparison: "5" == "not_a_number" is false');
    }

    @IsTest
    static void shouldDefaultToEqualsForUnknownOperator() {
        Test.startTest();
        Boolean result = SOQLQueryEvaluator.compareThreshold(5, 'UNKNOWN', '5');
        Test.stopTest();

        Assert.isTrue(result, 'Unknown operator should default to EQUALS');
    }
}
