@IsTest
private class ElaroReasoningEngineTest {
    @TestSetup
    static void setup() {
        // Create a test permission set for entity testing
        PermissionSet ps = new PermissionSet(
            Name = 'TestReasoningPS',
            Label = 'Test Reasoning Permission Set'
        );
        insert as user ps;
    }

    @IsTest
    static void testReasoningResult_Constructor() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
            true,
            0.95,
            'TEST_POLICY',
            'SOC2-1.1',
            'Test explanation',
            'audit123',
            false
        );
        Test.stopTest();

        Assert.areEqual(true, result.isViolation, 'isViolation should be true');
        Assert.areEqual(0.95, result.confidence, 'confidence should match');
        Assert.areEqual('TEST_POLICY', result.policy, 'policy should match');
        Assert.areEqual('SOC2-1.1', result.legalCitation, 'legalCitation should match');
        Assert.areEqual('Test explanation', result.explanation, 'explanation should match');
        Assert.areEqual('audit123', result.auditTrailId, 'auditTrailId should match');
        Assert.areEqual(false, result.requiresHumanReview, 'requiresHumanReview should be false');
    }

    @IsTest
    static void testReasoningResult_RequiresHumanReview() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
            true,
            0.50,
            'LOW_CONFIDENCE_POLICY',
            'GDPR-2.3',
            'Low confidence explanation',
            'audit456',
            true
        );
        Test.stopTest();

        Assert.areEqual(true, result.requiresHumanReview, 'Should require human review');
        Assert.areEqual(0.50, result.confidence, 'Low confidence value should be preserved');
    }

    @IsTest
    static void testPredictionResult_Constructor() {
        Test.startTest();
        ElaroReasoningEngine.PredictionResult prediction = new ElaroReasoningEngine.PredictionResult(
            true,
            0.88,
            'POLICY_001'
        );
        Test.stopTest();

        Assert.areEqual(true, prediction.isViolation, 'isViolation should be true');
        Assert.areEqual(0.88, prediction.confidence, 'confidence should match');
        Assert.areEqual('POLICY_001', prediction.policyId, 'policyId should match');
    }

    @IsTest
    static void testPredictionResult_NoViolation() {
        Test.startTest();
        ElaroReasoningEngine.PredictionResult prediction = new ElaroReasoningEngine.PredictionResult(
            false,
            0.0,
            null
        );
        Test.stopTest();

        Assert.areEqual(false, prediction.isViolation, 'isViolation should be false');
        Assert.areEqual(0.0, prediction.confidence, 'confidence should be zero');
        Assert.areEqual(null, prediction.policyId, 'policyId should be null');
    }

    @IsTest
    static void testReasoningException() {
        Test.startTest();
        try {
            throw new ElaroReasoningEngine.ReasoningException('Test error message');
        } catch (ElaroReasoningEngine.ReasoningException e) {
            Assert.areEqual('Test error message', e.getMessage(), 'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testExplainViolation_NodeNotFound() {
        Test.startTest();
        try {
            ElaroReasoningEngine.explainViolation('nonexistent_hash', 'SOC2');
            Assert.fail( 'Should have thrown ReasoningException');
        } catch (ElaroReasoningEngine.ReasoningException e) {
            Assert.areEqual('Node not found', e.getMessage(), 'Should throw node not found error');
        }
        Test.stopTest();
    }

    @IsTest
    static void testReasoningResult_AuraEnabled() {
        // Verify that ReasoningResult properties are properly exposed for Lightning components
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
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
        Assert.areNotEqual(null, result.isViolation);
        Assert.areNotEqual(null, result.confidence);
        Assert.areNotEqual(null, result.policy);
        Assert.areNotEqual(null, result.legalCitation);
        Assert.areNotEqual(null, result.explanation);
        Assert.areNotEqual(null, result.auditTrailId);
        Assert.areNotEqual(null, result.requiresHumanReview);
    }

    @IsTest
    static void testPredictionResult_ZeroConfidence() {
        Test.startTest();
        ElaroReasoningEngine.PredictionResult prediction = new ElaroReasoningEngine.PredictionResult(
            false,
            0.0,
            'NO_VIOLATION_POLICY'
        );
        Test.stopTest();

        Assert.areEqual(false, prediction.isViolation, 'No violation expected');
        Assert.areEqual(0.0, prediction.confidence, 'Zero confidence expected');
    }

    @IsTest
    static void testPredictionResult_HighConfidence() {
        Test.startTest();
        ElaroReasoningEngine.PredictionResult prediction = new ElaroReasoningEngine.PredictionResult(
            true,
            1.0,
            'HIGH_RISK_POLICY'
        );
        Test.stopTest();

        Assert.areEqual(true, prediction.isViolation, 'Violation expected');
        Assert.areEqual(1.0, prediction.confidence, 'Maximum confidence expected');
    }

    @IsTest
    static void testReasoningResult_NoViolation() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
            false,
            0.90,
            'COMPLIANT_POLICY',
            'ISO-27001',
            'No violation detected',
            'compliantAudit',
            false
        );
        Test.stopTest();

        Assert.areEqual(false, result.isViolation, 'Should indicate no violation');
        Assert.areEqual(false, result.requiresHumanReview, 'Should not require human review');
    }

    @IsTest
    static void testGetConfidenceThreshold_Defaults() {
        Test.startTest();
        Decimal thresholdWhenNull = ElaroReasoningEngine.getConfidenceThreshold(null);

        Elaro_AI_Settings__c settingsWithNullThreshold = new Elaro_AI_Settings__c(
            Confidence_Threshold__c = null
        );
        Decimal thresholdWhenSettingMissing = ElaroReasoningEngine.getConfidenceThreshold(settingsWithNullThreshold);
        Test.stopTest();

        Assert.areEqual(0.85, thresholdWhenNull, 'Should fall back to minimum confidence when settings are missing');
        Assert.areEqual(
            0.85,
            thresholdWhenSettingMissing,
            'Should fall back to minimum confidence when threshold is not defined'
        );
    }

    @IsTest
    static void testGetConfidenceThreshold_CustomValue() {
        Test.startTest();
        Elaro_AI_Settings__c settings = new Elaro_AI_Settings__c(
            Confidence_Threshold__c = 0.92
        );
        Decimal threshold = ElaroReasoningEngine.getConfidenceThreshold(settings);
        Test.stopTest();

        Assert.areEqual(0.92, threshold, 'Should respect custom confidence threshold in settings');
    }

    @IsTest
    static void testBuildSafeExplanation_AddsReviewPrefixWhenBelowThreshold() {
        Compliance_Policy__mdt policy = new Compliance_Policy__mdt(
            Policy_Description__c = 'Policy description',
            Legal_Citation__c = 'CIT-123',
            Remediation_Steps__c = 'Remediate quickly'
        );
        Elaro_Compliance_Graph__b node = new Elaro_Compliance_Graph__b(
            Entity_Type__c = 'FLOW',
            Entity_Record_Id__c = 'Flow123',
            Risk_Score__c = 9
        );
        ElaroReasoningEngine.PredictionResult prediction = new ElaroReasoningEngine.PredictionResult(true, 0.5, 'POLICY');
        Elaro_AI_Settings__c settings = new Elaro_AI_Settings__c(Confidence_Threshold__c = 0.75);

        Test.startTest();
        String explanation = ElaroReasoningEngine.buildSafeExplanation(policy, node, prediction, settings);
        Test.stopTest();

        Assert.isTrue(explanation.startsWith('[REVIEW REQUIRED] '), 'Explanation should include review prefix when below threshold');
        Assert.isTrue(explanation.contains('Flow123'), 'Explanation should include entity record id');
        Assert.isTrue(explanation.contains('Policy description'), 'Explanation should reference policy description');
    }
}
