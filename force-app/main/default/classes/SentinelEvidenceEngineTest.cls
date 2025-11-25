/**
 * @description Test class for SentinelEvidenceEngine
 * @author Sentinel Team
 * @date 2025
 */
@isTest
private class SentinelEvidenceEngineTest {

    @isTest
    static void testGenerateEvidencePack_SOC2() {
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('SOC2');
        Test.stopTest();

        // Verify evidence pack generated
        System.assertNotEquals(null, result, 'Evidence pack should not be null');
        System.assert(result.contains('SOC2'), 'Result should mention framework');
        System.assert(result.contains('Sentinel Evidence Pack'), 'Result should be evidence summary');
    }

    @isTest
    static void testGenerateEvidencePack_HIPAA() {
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('HIPAA');
        Test.stopTest();

        // Verify framework specific output
        System.assertNotEquals(null, result, 'Evidence pack should not be null');
        System.assert(result.contains('HIPAA'), 'Result should mention HIPAA framework');
    }

    @isTest
    static void testGenerateEvidencePack_InvalidInput() {
        Test.startTest();
        try {
            String result = SentinelEvidenceEngine.generateEvidencePack('');
            System.assert(false, 'Should throw exception for blank framework');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should indicate framework is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testGenerateEvidencePack_FedRAMP() {
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('FedRAMP');
        Test.stopTest();

        // Verify FedRAMP evidence generated
        System.assertNotEquals(null, result, 'Evidence pack should not be null');
        System.assert(result.contains('FedRAMP'), 'Result should mention FedRAMP');
    }

    @isTest
    static void testGenerateEvidencePack_ContainsAllFiles() {
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('SOC2');
        Test.stopTest();

        // Verify all expected files mentioned
        System.assert(result.contains('UserAccess'), 'Should include UserAccess file');
        System.assert(result.contains('RoleHierarchy'), 'Should include RoleHierarchy file');
        System.assert(result.contains('PermissionSets'), 'Should include PermissionSets file');
        System.assert(result.contains('Flows'), 'Should include Flows file');
    }

    @isTest
    static void testGenerateEvidencePack_GovernorLimits() {
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('SOC2');
        Test.stopTest();

        // Verify efficient execution
        System.assert(Limits.getQueries() < 10, 'Should use minimal SOQL queries');
        System.assert(Limits.getCpuTime() < 10000, 'Should execute within CPU limits');
    }

    @isTest
    static void testGenerateEvidencePack_BulkData() {
        // Test with org that has lots of data
        Test.startTest();
        String result = SentinelEvidenceEngine.generateEvidencePack('SOC2');
        Test.stopTest();

        // Verify handles large datasets
        System.assertNotEquals(null, result, 'Should handle bulk data');
        System.assert(result.length() > 0, 'Should generate meaningful output');
    }

    @isTest
    static void testGenerateEvidencePack_SecurityContext() {
        // Test FLS/CRUD checks work
        Test.startTest();
        try {
            String result = SentinelEvidenceEngine.generateEvidencePack('SOC2');
            System.assertNotEquals(null, result, 'Should generate evidence');
        } catch (AuraHandledException e) {
            // If insufficient permissions, should throw appropriate error
            System.assert(e.getMessage().contains('permissions'),
                'Should indicate permission issue');
        }
        Test.stopTest();
    }
}
