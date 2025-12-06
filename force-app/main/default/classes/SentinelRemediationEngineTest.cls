/**
 * SentinelRemediationEngineTest - Tests for Auto-Remediation Engine
 */
@isTest
private class SentinelRemediationEngineTest {
    
    @testSetup
    static void setupTestData() {
        // Create Sentinel AI Settings
        Sentinel_AI_Settings__c settings = new Sentinel_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = true,
            Confidence_Threshold__c = 0.85,
            Auto_Remediation_Enabled__c = true,
            Require_Human_Approval__c = true
        );
        insert settings;
    }
    
    @isTest
    static void testRemediationDisabled() {
        // Disable auto-remediation
        Sentinel_AI_Settings__c settings = Sentinel_AI_Settings__c.getOrgDefaults();
        settings.Auto_Remediation_Enabled__c = false;
        update settings;
        
        Test.startTest();
        SentinelRemediationEngine.RemediationResult result = 
            SentinelRemediationEngine.evaluateAndRemediate('test-node-hash', 'HIPAA');
        Test.stopTest();
        
        System.assertEquals(false, result.success, 'Should not remediate when disabled');
        System.assert(result.message.contains('disabled'), 'Should indicate disabled status');
    }
    
    @isTest
    static void testGetPendingRemediations() {
        Test.startTest();
        List<Map<String, Object>> pending = SentinelRemediationEngine.getPendingRemediations();
        Test.stopTest();
        
        System.assertNotEquals(null, pending, 'Should return list');
    }
    
    @isTest
    static void testApproveRemediation() {
        Test.startTest();
        Boolean result = SentinelRemediationEngine.approveRemediation('test-remediation-id');
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should successfully approve');
    }
}
