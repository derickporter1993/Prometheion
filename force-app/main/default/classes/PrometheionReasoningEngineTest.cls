@IsTest
private class PrometheionReasoningEngineTest {
    @TestSetup
    static void setup() {
        // Create a test permission set for entity testing
        PermissionSet ps = new PermissionSet(
            Name = 'TestReasoningPS',
            Label = 'Test Reasoning Permission Set'
        );
        insert ps;
    }

    @IsTest
    static void testReasoningResult_Constructor() {
        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result = new PrometheionReasoningEngine.ReasoningResult(
            true,
            0.95,
            'TEST_POLICY',
            'SOC2-1.1',
            'Test explanation',
            'audit123',
            false
        );
        Test.stopTest();

        System.assertEquals(true, result.isViolation, 'isViolation should be true');
        System.assertEquals(0.95, result.confidence, 'confidence should match');
        System.assertEquals('TEST_POLICY', result.policy, 'policy should match');
        System.assertEquals('SOC2-1.1', result.legalCitation, 'legalCitation should match');
        System.assertEquals('Test explanation', result.explanation, 'explanation should match');
        System.assertEquals('audit123', result.auditTrailId, 'auditTrailId should match');
        System.assertEquals(false, result.requiresHumanReview, 'requiresHumanReview should be false');
    }

    @IsTest
    static void testReasoningResult_RequiresHumanReview() {
        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result = new PrometheionReasoningEngine.ReasoningResult(
            true,
            0.50,
            'LOW_CONFIDENCE_POLICY',
            'GDPR-2.3',
            'Low confidence explanation',
            'audit456',
            true
        );
        Test.stopTest();

        System.assertEquals(true, result.requiresHumanReview, 'Should require human review');
        System.assertEquals(0.50, result.confidence, 'Low confidence value should be preserved');
    }

    @IsTest
    static void testPredictionResult_Constructor() {
        Test.startTest();
        PrometheionReasoningEngine.PredictionResult prediction = new PrometheionReasoningEngine.PredictionResult(
            true,
            0.88,
            'POLICY_001'
        );
        Test.stopTest();

        System.assertEquals(true, prediction.isViolation, 'isViolation should be true');
        System.assertEquals(0.88, prediction.confidence, 'confidence should match');
        System.assertEquals('POLICY_001', prediction.policyId, 'policyId should match');
    }

    @IsTest
    static void testPredictionResult_NoViolation() {
        Test.startTest();
        PrometheionReasoningEngine.PredictionResult prediction = new PrometheionReasoningEngine.PredictionResult(
            false,
            0.0,
            null
        );
        Test.stopTest();

        System.assertEquals(false, prediction.isViolation, 'isViolation should be false');
        System.assertEquals(0.0, prediction.confidence, 'confidence should be zero');
        System.assertEquals(null, prediction.policyId, 'policyId should be null');
    }

    @IsTest
    static void testReasoningException() {
        Test.startTest();
        try {
            throw new PrometheionReasoningEngine.ReasoningException('Test error message');
        } catch (PrometheionReasoningEngine.ReasoningException e) {
            System.assertEquals('Test error message', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testExplainViolation_NodeNotFound() {
        Test.startTest();
        try {
            PrometheionReasoningEngine.explainViolation('nonexistent_hash', 'SOC2');
            System.assert(false, 'Should have thrown ReasoningException');
        } catch (PrometheionReasoningEngine.ReasoningException e) {
            System.assertEquals('Node not found', e.getMessage(), 'Should throw node not found error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testReasoningResult_AuraEnabled() {
        // Verify that ReasoningResult properties are properly exposed for Lightning components
        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result = new PrometheionReasoningEngine.ReasoningResult(
            false,
            0.75,
            'AURA_TEST_POLICY',
            'HIPAA-4.5',
            'Aura enabled test',
            'auraAudit789',
            true
        );
        Test.stopTest();

        // Access all AuraEnabled properties to ensure they're properly exposed
        System.assertNotEquals(null, result.isViolation);
        System.assertNotEquals(null, result.confidence);
        System.assertNotEquals(null, result.policy);
        System.assertNotEquals(null, result.legalCitation);
        System.assertNotEquals(null, result.explanation);
        System.assertNotEquals(null, result.auditTrailId);
        System.assertNotEquals(null, result.requiresHumanReview);
    }

    @IsTest
    static void testPredictionResult_ZeroConfidence() {
        Test.startTest();
        PrometheionReasoningEngine.PredictionResult prediction = new PrometheionReasoningEngine.PredictionResult(
            false,
            0.0,
            'NO_VIOLATION_POLICY'
        );
        Test.stopTest();

        System.assertEquals(false, prediction.isViolation, 'No violation expected');
        System.assertEquals(0.0, prediction.confidence, 'Zero confidence expected');
    }

    @IsTest
    static void testPredictionResult_HighConfidence() {
        Test.startTest();
        PrometheionReasoningEngine.PredictionResult prediction = new PrometheionReasoningEngine.PredictionResult(
            true,
            1.0,
            'HIGH_RISK_POLICY'
        );
        Test.stopTest();

        System.assertEquals(true, prediction.isViolation, 'Violation expected');
        System.assertEquals(1.0, prediction.confidence, 'Maximum confidence expected');
    }

    @IsTest
    static void testReasoningResult_NoViolation() {
        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result = new PrometheionReasoningEngine.ReasoningResult(
            false,
            0.90,
            'COMPLIANT_POLICY',
            'ISO-27001',
            'No violation detected',
            'compliantAudit',
            false
        );
        Test.stopTest();

        System.assertEquals(false, result.isViolation, 'Should indicate no violation');
        System.assertEquals(false, result.requiresHumanReview, 'Should not require human review');
    }

    @IsTest
    static void testGetConfidenceThreshold_Defaults() {
        Test.startTest();
        Decimal thresholdWhenNull = PrometheionReasoningEngine.getConfidenceThreshold(null);

        Prometheion_AI_Settings__c settingsWithNullThreshold = new Prometheion_AI_Settings__c(
            Confidence_Threshold__c = null
        );
        Decimal thresholdWhenSettingMissing = PrometheionReasoningEngine.getConfidenceThreshold(settingsWithNullThreshold);
        Test.stopTest();

        System.assertEquals(0.85, thresholdWhenNull, 'Should fall back to minimum confidence when settings are missing');
        System.assertEquals(
            0.85,
            thresholdWhenSettingMissing,
            'Should fall back to minimum confidence when threshold is not defined'
        );
    }

    @IsTest
    static void testGetConfidenceThreshold_CustomValue() {
        Test.startTest();
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(
            Confidence_Threshold__c = 0.92
        );
        Decimal threshold = PrometheionReasoningEngine.getConfidenceThreshold(settings);
        Test.stopTest();

        System.assertEquals(0.92, threshold, 'Should respect custom confidence threshold in settings');
    }

    @IsTest
    static void testBuildSafeExplanation_AddsReviewPrefixWhenBelowThreshold() {
        Compliance_Policy__mdt policy = new Compliance_Policy__mdt(
            Policy_Description__c = 'Policy description',
            Legal_Citation__c = 'CIT-123',
            Remediation_Steps__c = 'Remediate quickly'
        );
        Prometheion_Compliance_Graph__b node = new Prometheion_Compliance_Graph__b(
            Entity_Type__c = 'FLOW',
            Entity_Record_Id__c = 'Flow123',
            Risk_Score__c = 9
        );
        PrometheionReasoningEngine.PredictionResult prediction = new PrometheionReasoningEngine.PredictionResult(true, 0.5, 'POLICY');
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(Confidence_Threshold__c = 0.75);

        Test.startTest();
        String explanation = PrometheionReasoningEngine.buildSafeExplanation(policy, node, prediction, settings);
        Test.stopTest();

        System.assert(explanation.startsWith('[REVIEW REQUIRED] '), 'Explanation should include review prefix when below threshold');
        System.assert(explanation.contains('Flow123'), 'Explanation should include entity record id');
        System.assert(explanation.contains('Policy description'), 'Explanation should reference policy description');
    }
}
