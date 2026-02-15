@IsTest
private class ElaroReasoningEngineTest {
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
    static void testReasoningResult_NullOptionalFields() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
            true,
            0.88,
            'TEST_POLICY',
            null,
            'Test explanation',
            null,
            false
        );
        Test.stopTest();

        Assert.areEqual(null, result.legalCitation, 'Null legalCitation should be preserved');
        Assert.areEqual(null, result.auditTrailId, 'Null auditTrailId should be preserved');
        Assert.areEqual(true, result.isViolation, 'isViolation should be true');
    }

    @IsTest
    static void testReasoningResult_BoundaryConfidence() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult zeroConf = new ElaroReasoningEngine.ReasoningResult(
            false, 0.0, 'POLICY', 'N/A', 'Zero confidence', 'audit0', true
        );
        ElaroReasoningEngine.ReasoningResult maxConf = new ElaroReasoningEngine.ReasoningResult(
            true, 1.0, 'POLICY', 'N/A', 'Max confidence', 'audit1', false
        );
        Test.stopTest();

        Assert.areEqual(0.0, zeroConf.confidence, 'Zero confidence should be preserved');
        Assert.areEqual(true, zeroConf.requiresHumanReview, 'Zero confidence should require review');
        Assert.areEqual(1.0, maxConf.confidence, 'Maximum confidence should be preserved');
        Assert.areEqual(false, maxConf.requiresHumanReview, 'Max confidence should not require review');
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
            Assert.isTrue(e.getMessage().startsWith('Node not found:'),
                'Should throw node not found error, got: ' + e.getMessage());
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
    static void testReasoningResult_AllFieldsPopulated() {
        Test.startTest();
        ElaroReasoningEngine.ReasoningResult result = new ElaroReasoningEngine.ReasoningResult(
            true,
            0.99,
            'FULL_POLICY',
            'PCI-DSS-3.2',
            'All fields populated test',
            'fullAudit123',
            false
        );
        Test.stopTest();

        Assert.areEqual(true, result.isViolation, 'isViolation should be true');
        Assert.areEqual(0.99, result.confidence, 'Confidence should be 0.99');
        Assert.areEqual('FULL_POLICY', result.policy, 'Policy should match');
        Assert.areEqual('PCI-DSS-3.2', result.legalCitation, 'Legal citation should match');
        Assert.areEqual('All fields populated test', result.explanation, 'Explanation should match');
        Assert.areEqual('fullAudit123', result.auditTrailId, 'Audit trail ID should match');
        Assert.areEqual(false, result.requiresHumanReview, 'Should not require human review');
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
    static void testBuildSimpleExplanation_HighRisk() {
        Elaro_Compliance_Graph__b node = new Elaro_Compliance_Graph__b(
            Entity_Type__c = 'FLOW',
            Entity_Record_Id__c = 'Flow123',
            Risk_Score__c = 9
        );

        Test.startTest();
        String explanation = ElaroReasoningEngine.buildSimpleExplanation(node, 9.0, 'SOC2');
        Test.stopTest();

        Assert.isTrue(explanation.contains('FLOW'), 'Explanation should include entity type');
        Assert.isTrue(explanation.contains('Flow123'), 'Explanation should include entity record id');
        Assert.isTrue(explanation.contains('HIGH RISK'), 'Should be flagged as HIGH RISK for score 9.0');
        Assert.isTrue(explanation.contains('SOC2'), 'Explanation should include framework');
        Assert.isTrue(explanation.contains('Immediate review required'), 'Should include high-risk remediation');
    }
}
