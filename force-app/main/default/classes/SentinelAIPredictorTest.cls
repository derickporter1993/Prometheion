/**
 * @description Test class for SentinelAIPredictor
 * @author Sentinel Team
 * @date 2025
 */
@isTest
private class SentinelAIPredictorTest {

    @isTest
    static void testPredictViolation_AdminKeyword() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Assign Admin permissions to Sales Manager',
            'PermissionSet'
        );
        Test.stopTest();

        // Verify prediction returned
        System.assertNotEquals(null, result, 'Prediction should not be null');

        // Parse JSON result
        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, prediction.get('isViolation'), 'Should detect admin as violation');
        System.assertNotEquals(null, prediction.get('confidence'), 'Should include confidence score');
        System.assertNotEquals(null, prediction.get('explanation'), 'Should include explanation');
    }

    @isTest
    static void testPredictViolation_ModifyAllKeyword() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Grant Modify All Data permission',
            'Profile'
        );
        Test.stopTest();

        // Parse and verify
        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, prediction.get('isViolation'), 'Should detect modify all as violation');

        // Verify confidence is reasonable
        Decimal confidence = (Decimal) prediction.get('confidence');
        System.assert(confidence > 0.5, 'Confidence should be > 50% for clear violations');
    }

    @isTest
    static void testPredictViolation_DeleteRule() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Delete validation rule for security',
            'ValidationRule'
        );
        Test.stopTest();

        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, prediction.get('isViolation'), 'Should detect deletion of security controls');
    }

    @isTest
    static void testPredictViolation_ExportAll() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Export all customer data',
            'DataExport'
        );
        Test.stopTest();

        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, prediction.get('isViolation'), 'Should detect bulk data export');
    }

    @isTest
    static void testPredictViolation_SystemModeFlow() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Activate flow in system mode',
            'Flow'
        );
        Test.stopTest();

        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(true, prediction.get('isViolation'), 'Should detect system mode flow risk');
    }

    @isTest
    static void testPredictViolation_SafeChange() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Update user phone number',
            'User'
        );
        Test.stopTest();

        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals(false, prediction.get('isViolation'), 'Should not flag safe changes');
    }

    @isTest
    static void testPredictViolation_MockPrediction() {
        // Test mock prediction path (Test.isRunningTest() = true)
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Test admin change',
            'Test'
        );
        Test.stopTest();

        Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
        System.assertEquals('MockModel', prediction.get('model'), 'Should use mock model in tests');
        System.assertEquals(0.95, prediction.get('confidence'), 'Mock should have 95% confidence');
    }

    @isTest
    static void testPredictViolation_JSONFormat() {
        Test.startTest();
        String result = SentinelAIPredictor.predictViolation(
            'Sample change',
            'Sample'
        );
        Test.stopTest();

        // Verify valid JSON
        try {
            Map<String, Object> prediction = (Map<String, Object>) JSON.deserializeUntyped(result);
            System.assert(prediction.containsKey('isViolation'), 'Should have isViolation field');
            System.assert(prediction.containsKey('confidence'), 'Should have confidence field');
            System.assert(prediction.containsKey('explanation'), 'Should have explanation field');
            System.assert(prediction.containsKey('model'), 'Should have model field');
            System.assert(prediction.containsKey('timestamp'), 'Should have timestamp field');
        } catch (Exception e) {
            System.assert(false, 'Result should be valid JSON: ' + e.getMessage());
        }
    }

    @isTest
    static void testPredictViolation_BulkScenario() {
        Test.startTest();
        List<String> results = new List<String>();
        for (Integer i = 0; i < 10; i++) {
            results.add(SentinelAIPredictor.predictViolation('Test change ' + i, 'Test'));
        }
        Test.stopTest();

        // Verify bulk processing works
        System.assertEquals(10, results.size(), 'Should handle multiple predictions');
        System.assert(Limits.getCpuTime() < Limits.getLimitCpuTime(), 'Should not hit CPU limits');
    }
}
