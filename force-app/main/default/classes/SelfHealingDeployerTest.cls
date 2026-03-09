/**
 * Tests for SelfHealingDeployer metadata deployment queuing.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see SelfHealingDeployer
 */
@IsTest
private class SelfHealingDeployerTest {

    @IsTest
    static void shouldQueueDeploymentSuccessfully() {
        String payload = '{"type":"PERMISSION_SET","target":"Elaro_Admin"}';

        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment(payload, 'Test_Rule_001');
        Test.stopTest();

        Assert.areEqual('QUEUED', request.status, 'Status should be QUEUED');
        Assert.isNotNull(request.requestId, 'Request ID should be set');
        Assert.isTrue(request.requestId.startsWith('DEP-'),
            'Request ID should start with DEP-');
        Assert.areEqual('PERMISSION_SET', request.deploymentType,
            'Deployment type should be PERMISSION_SET');
        Assert.areEqual('Elaro_Admin', request.targetMetadata,
            'Target metadata should match');
        Assert.areEqual('Deployment queued for review', request.message,
            'Message should indicate queued status');
    }

    @IsTest
    static void shouldFailForEmptyPayload() {
        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment('', 'Test_Rule');
        Test.stopTest();

        Assert.areEqual('FAILED', request.status, 'Status should be FAILED');
        Assert.areEqual('Empty remediation payload', request.message,
            'Should indicate empty payload');
    }

    @IsTest
    static void shouldFailForNullPayload() {
        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment(null, 'Test_Rule');
        Test.stopTest();

        Assert.areEqual('FAILED', request.status, 'Status should be FAILED');
    }

    @IsTest
    static void shouldFailForInvalidJsonPayload() {
        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment('not valid json', 'Test_Rule');
        Test.stopTest();

        Assert.areEqual('FAILED', request.status, 'Status should be FAILED');
        Assert.isTrue(request.message.contains('Invalid payload'),
            'Should indicate invalid payload');
    }

    @IsTest
    static void shouldHandleMissingTypeInPayload() {
        String payload = '{"target":"Elaro_Admin"}';

        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment(payload, 'Test_Rule');
        Test.stopTest();

        Assert.areEqual('QUEUED', request.status, 'Status should be QUEUED');
        Assert.areEqual('UNKNOWN', request.deploymentType,
            'Missing type should default to UNKNOWN');
    }

    @IsTest
    static void shouldHandleMissingTargetInPayload() {
        String payload = '{"type":"FIELD_LEVEL_SECURITY"}';

        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.queueDeployment(payload, 'Test_Rule');
        Test.stopTest();

        Assert.areEqual('QUEUED', request.status, 'Status should be QUEUED');
        Assert.areEqual('', request.targetMetadata,
            'Missing target should default to empty string');
    }

    @IsTest
    static void shouldCheckDeploymentStatus() {
        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request =
            SelfHealingDeployer.checkDeploymentStatus('DEP-12345');
        Test.stopTest();

        Assert.areEqual('DEP-12345', request.requestId, 'Request ID should match');
        Assert.areEqual('PENDING', request.status, 'Status should be PENDING');
        Assert.areEqual('Deployment pending review', request.message,
            'Message should indicate pending review');
    }

    @IsTest
    static void shouldReturnSupportedDeploymentTypes() {
        Test.startTest();
        Set<String> types = SelfHealingDeployer.getSupportedDeploymentTypes();
        Test.stopTest();

        Assert.areEqual(5, types.size(), 'Should have 5 deployment types');
        Assert.isTrue(types.contains('PERMISSION_SET'), 'Should contain PERMISSION_SET');
        Assert.isTrue(types.contains('FIELD_LEVEL_SECURITY'),
            'Should contain FIELD_LEVEL_SECURITY');
        Assert.isTrue(types.contains('SHARING_RULE'), 'Should contain SHARING_RULE');
        Assert.isTrue(types.contains('CUSTOM_SETTING'), 'Should contain CUSTOM_SETTING');
        Assert.isTrue(types.contains('PROFILE_UPDATE'), 'Should contain PROFILE_UPDATE');
    }

    @IsTest
    static void shouldGenerateUniqueRequestIds() {
        String payload = '{"type":"CUSTOM_SETTING","target":"TestSetting"}';

        Test.startTest();
        SelfHealingDeployer.DeploymentRequest request1 =
            SelfHealingDeployer.queueDeployment(payload, 'Rule1');
        SelfHealingDeployer.DeploymentRequest request2 =
            SelfHealingDeployer.queueDeployment(payload, 'Rule2');
        Test.stopTest();

        Assert.isNotNull(request1.requestId, 'First request ID should be set');
        Assert.isNotNull(request2.requestId, 'Second request ID should be set');
    }

    @IsTest
    static void shouldSetDeploymentRequestProperties() {
        SelfHealingDeployer.DeploymentRequest request =
            new SelfHealingDeployer.DeploymentRequest();
        request.requestId = 'DEP-001';
        request.deploymentType = 'SHARING_RULE';
        request.targetMetadata = 'Account';
        request.status = 'QUEUED';
        request.message = 'Test message';

        Assert.areEqual('DEP-001', request.requestId, 'Request ID getter should work');
        Assert.areEqual('SHARING_RULE', request.deploymentType,
            'Deployment type getter should work');
        Assert.areEqual('Account', request.targetMetadata,
            'Target metadata getter should work');
        Assert.areEqual('QUEUED', request.status, 'Status getter should work');
        Assert.areEqual('Test message', request.message, 'Message getter should work');
    }
}
