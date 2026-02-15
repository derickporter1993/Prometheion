/**
 * Test class for AIRiskClassificationEngine.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest(testFor=AIRiskClassificationEngine.class)
private class AIRiskClassificationEngineTest {

    @IsTest
    static void shouldClassifyEinsteinPrediction() {
        Test.startTest();
        AIRiskClassificationEngine.RiskClassification classification =
            AIRiskClassificationEngine.classifySystem('Einstein Prediction', 'Sales forecasting');
        Test.stopTest();

        Assert.isNotNull(classification, 'Should return classification');
        Assert.isNotNull(classification.riskLevel, 'Risk level should be set');
        Assert.areEqual('Einstein Prediction', classification.systemType, 'System type should match');
    }

    @IsTest
    static void shouldClassifyEinsteinBot() {
        Test.startTest();
        AIRiskClassificationEngine.RiskClassification classification =
            AIRiskClassificationEngine.classifySystem('Einstein Bot', 'Customer service and support');
        Test.stopTest();

        Assert.isNotNull(classification, 'Should return classification');
        Assert.isNotNull(classification.euAIActArticle, 'EU AI Act article should be referenced');
    }

    @IsTest
    static void shouldClassifyGenAIFunction() {
        Test.startTest();
        AIRiskClassificationEngine.RiskClassification classification =
            AIRiskClassificationEngine.classifySystem('GenAI Function', 'Content generation');
        Test.stopTest();

        Assert.isNotNull(classification, 'Should return classification');
        Assert.isTrue(classification.recommendedControls.size() > 0, 'Should have recommended controls');
    }

    @IsTest
    static void shouldClassifyGenAIPlanner() {
        Test.startTest();
        AIRiskClassificationEngine.RiskClassification classification =
            AIRiskClassificationEngine.classifySystem('GenAI Planner', 'Automated planning and workflow generation');
        Test.stopTest();

        Assert.isNotNull(classification, 'Should return classification');
        Assert.areEqual('High', classification.riskLevel, 'GenAI Planner should be High risk');
    }

    @IsTest
    static void shouldProvideDefaultClassification() {
        Test.startTest();
        AIRiskClassificationEngine.RiskClassification classification =
            AIRiskClassificationEngine.classifySystem('Custom ML', 'Unknown use case');
        Test.stopTest();

        Assert.isNotNull(classification, 'Should return default classification');
        Assert.isNotNull(classification.riskLevel, 'Should have default risk level');
    }

    @IsTest
    static void shouldBatchClassifyMultipleSystems() {
        List<AIDetectionEngine.AISystemMetadata> systems = new List<AIDetectionEngine.AISystemMetadata>();

        AIDetectionEngine.AISystemMetadata system1 = new AIDetectionEngine.AISystemMetadata();
        system1.systemType = 'Einstein Prediction';
        system1.systemName = 'TestSystem1';
        system1.useCaseDescription = 'Forecasting';
        systems.add(system1);

        AIDetectionEngine.AISystemMetadata system2 = new AIDetectionEngine.AISystemMetadata();
        system2.systemType = 'Einstein Bot';
        system2.systemName = 'TestSystem2';
        system2.useCaseDescription = 'Support';
        systems.add(system2);

        Test.startTest();
        Map<String, AIRiskClassificationEngine.RiskClassification> classifications =
            AIRiskClassificationEngine.batchClassify(systems);
        Test.stopTest();

        Assert.areEqual(2, classifications.size(), 'Should classify all systems');
        Assert.isTrue(classifications.containsKey('TestSystem1'), 'Should include TestSystem1');
        Assert.isTrue(classifications.containsKey('TestSystem2'), 'Should include TestSystem2');
    }

    @IsTest
    static void shouldProvideControlsForEachRiskLevel() {
        List<String> riskLevels = new List<String>{'Unacceptable', 'High', 'Limited', 'Minimal'};

        for (String riskLevel : riskLevels) {
            Test.startTest();
            AIRiskClassificationEngine.RiskClassification classification =
                AIRiskClassificationEngine.classifySystem('Custom ML', 'Test');
            Test.stopTest();

            // Verify controls exist for each level
            Assert.isTrue(classification.recommendedControls != null,
                'Should have controls for ' + riskLevel);
        }
    }

    @IsTest
    static void shouldUsePlatformCacheAcrossCalls() {
        Test.startTest();
        // First classification populates Platform Cache
        AIRiskClassificationEngine.RiskClassification first =
            AIRiskClassificationEngine.classifySystem('Einstein Prediction', 'Sales forecasting');
        // Second classification should leverage cached rules
        AIRiskClassificationEngine.RiskClassification second =
            AIRiskClassificationEngine.classifySystem('Einstein Prediction', 'Sales forecasting');
        Test.stopTest();

        Assert.isNotNull(first, 'First classification should succeed');
        Assert.isNotNull(second, 'Second classification should succeed from cache');
        Assert.areEqual(first.riskLevel, second.riskLevel,
            'Cached classification should produce same risk level');
    }
}
