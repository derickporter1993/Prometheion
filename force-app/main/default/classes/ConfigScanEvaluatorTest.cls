/**
 * Tests for ConfigScanEvaluator strategy.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see ConfigScanEvaluator
 */
@IsTest
private class ConfigScanEvaluatorTest {

    private static Compliance_Rule__mdt createConfigRule(String configJson) {
        return new Compliance_Rule__mdt(
            DeveloperName = 'Config_Test',
            Rule_Name__c = 'Config Test Rule',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'CONFIG_SCAN',
            Evaluation_Query__c = configJson,
            Severity__c = 'HIGH',
            Weight__c = 1
        );
    }

    @IsTest
    static void shouldPassAuditTrailScanWithNoChanges() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"AUDIT_TRAIL","section":"NonExistentSection_XYZ","hoursBack":1,"operator":"EQUALS","threshold":0}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed,
            'Should pass when no audit trail entries found for obscure section');
    }

    @IsTest
    static void shouldPassAuditTrailScanWithBlankSection() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"AUDIT_TRAIL","hoursBack":24}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed,
            'Should pass when section is blank (no specific section to check)');
    }

    @IsTest
    static void shouldPassSessionSettingsScan() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"SESSION_SETTINGS","expectedTimeout":"120"}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Session settings scan should pass');
    }

    @IsTest
    static void shouldPassPasswordPolicyWithValidLength() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"PASSWORD_POLICY","minLength":8}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Password policy with minLength >= 8 should pass');
    }

    @IsTest
    static void shouldFailPasswordPolicyWithShortLength() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"PASSWORD_POLICY","minLength":4}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Password policy with minLength < 8 should fail');
    }

    @IsTest
    static void shouldFailCustomSettingScanWithMissingFields() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"CUSTOM_SETTING"}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed,
            'Should fail when settingName and fieldName are missing');
    }

    @IsTest
    static void shouldReturnErrorForBlankConfig() {
        Compliance_Rule__mdt rule = createConfigRule('');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for blank config');
        Assert.isTrue(result.findingDetails.contains('blank'),
            'Should indicate blank configuration');
    }

    @IsTest
    static void shouldReturnErrorForInvalidJson() {
        Compliance_Rule__mdt rule = createConfigRule('{not valid}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for invalid JSON');
        Assert.isTrue(result.findingDetails.contains('Invalid JSON'),
            'Should indicate JSON parse error');
    }

    @IsTest
    static void shouldReturnErrorForMissingScanType() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"section":"Security"}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when scanType is missing');
        Assert.isTrue(result.findingDetails.contains('Missing scanType'),
            'Should indicate missing scanType');
    }

    @IsTest
    static void shouldReturnFalseForUnknownScanType() {
        Test.startTest();
        Boolean result = ConfigScanEvaluator.executeScan(
            'UNKNOWN_SCAN', new Map<String, Object>());
        Test.stopTest();

        Assert.isFalse(result, 'Unknown scan type should return false');
    }

    @IsTest
    static void shouldHandleAuditTrailWithLessThanOperator() {
        Compliance_Rule__mdt rule = createConfigRule(
            '{"scanType":"AUDIT_TRAIL","section":"NonExistentSection_ABC","hoursBack":1,"operator":"LESS_THAN","threshold":100}');

        Test.startTest();
        RuleResult result = ConfigScanEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed,
            'Should pass when change count is less than high threshold');
    }
}
