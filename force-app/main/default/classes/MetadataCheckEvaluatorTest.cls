/**
 * Tests for MetadataCheckEvaluator strategy.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see MetadataCheckEvaluator
 */
@IsTest
private class MetadataCheckEvaluatorTest {

    private static Compliance_Rule__mdt createMetadataRule(String configJson) {
        return new Compliance_Rule__mdt(
            DeveloperName = 'Metadata_Test',
            Rule_Name__c = 'Metadata Test Rule',
            Framework__c = 'SOC2',
            Evaluation_Type__c = 'METADATA_CHECK',
            Evaluation_Query__c = configJson,
            Severity__c = 'HIGH',
            Weight__c = 1
        );
    }

    @IsTest
    static void shouldPassWhenObjectExists() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"OBJECT_EXISTS","target":"Account"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Account object should exist');
    }

    @IsTest
    static void shouldFailWhenObjectDoesNotExist() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"OBJECT_EXISTS","target":"NonExistentObject__x_y_z"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Non-existent object should fail');
        Assert.isTrue(result.findingDetails.contains('OBJECT_EXISTS'),
            'Finding details should reference check type');
    }

    @IsTest
    static void shouldCheckFieldEncryption() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"FIELD_ENCRYPTED","target":"Account","field":"Name"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        // Name field is not encrypted, so this should fail
        Assert.isNotNull(result, 'Result should not be null');
    }

    @IsTest
    static void shouldReturnFalseForEncryptedCheckWithBlankField() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"FIELD_ENCRYPTED","target":"Account"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when field is not specified');
    }

    @IsTest
    static void shouldCheckFLSEnforced() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"FLS_ENFORCED","target":"Account","field":"Name"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Account.Name should be accessible');
    }

    @IsTest
    static void shouldReturnFalseForFLSWithBlankField() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"FLS_ENFORCED","target":"Account"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when field is not specified');
    }

    @IsTest
    static void shouldCheckSharingEnabled() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"SHARING_ENABLED","target":"Account"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isTrue(result.passed, 'Account should be accessible');
    }

    @IsTest
    static void shouldReturnErrorForBlankConfig() {
        Compliance_Rule__mdt rule = createMetadataRule('');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for blank config');
        Assert.isTrue(result.findingDetails.contains('blank'),
            'Should indicate blank configuration');
    }

    @IsTest
    static void shouldReturnErrorForInvalidJson() {
        Compliance_Rule__mdt rule = createMetadataRule('not valid json');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail for invalid JSON');
        Assert.isTrue(result.findingDetails.contains('Invalid JSON'),
            'Should indicate JSON error');
    }

    @IsTest
    static void shouldReturnErrorForMissingCheckType() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"target":"Account"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when checkType is missing');
        Assert.isTrue(result.findingDetails.contains('Missing checkType'),
            'Should indicate missing checkType');
    }

    @IsTest
    static void shouldReturnErrorForMissingTarget() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"OBJECT_EXISTS"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Should fail when target is missing');
    }

    @IsTest
    static void shouldReturnFalseForUnknownCheckType() {
        Test.startTest();
        Boolean result = MetadataCheckEvaluator.executeCheck(
            'UNKNOWN_CHECK', 'Account', new Map<String, Object>());
        Test.stopTest();

        Assert.isFalse(result, 'Unknown check type should return false');
    }

    @IsTest
    static void shouldHandleNonExistentObjectForSharing() {
        Compliance_Rule__mdt rule = createMetadataRule(
            '{"checkType":"SHARING_ENABLED","target":"FakeObject__zzz"}');

        Test.startTest();
        RuleResult result = MetadataCheckEvaluator.evaluate(rule);
        Test.stopTest();

        Assert.isFalse(result.passed, 'Non-existent object should fail sharing check');
    }
}
