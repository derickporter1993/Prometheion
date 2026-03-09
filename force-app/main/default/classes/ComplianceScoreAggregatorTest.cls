/**
 * Tests for ComplianceScoreAggregator weighted scoring.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see ComplianceScoreAggregator
 */
@IsTest
private class ComplianceScoreAggregatorTest {

    private static RuleResult createResult(Boolean passed, Decimal weight, String category) {
        RuleResult result = new RuleResult();
        result.ruleDeveloperName = 'Test_Rule';
        result.ruleName = 'Test Rule';
        result.framework = 'SOC2';
        result.passed = passed;
        result.weight = weight;
        result.category = category;
        result.severity = 'MEDIUM';
        return result;
    }

    @IsTest
    static void shouldReturn100ForAllPassed() {
        List<RuleResult> results = new List<RuleResult>{
            createResult(true, 1, 'Access'),
            createResult(true, 1, 'Access'),
            createResult(true, 1, 'Encryption')
        };

        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(results);
        Test.stopTest();

        Assert.areEqual(100.0, score, 'All passed should give 100');
    }

    @IsTest
    static void shouldReturn0ForAllFailed() {
        List<RuleResult> results = new List<RuleResult>{
            createResult(false, 1, 'Access'),
            createResult(false, 1, 'Encryption')
        };

        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(results);
        Test.stopTest();

        Assert.areEqual(0.0, score, 'All failed should give 0');
    }

    @IsTest
    static void shouldCalculateWeightedScore() {
        List<RuleResult> results = new List<RuleResult>{
            createResult(true, 3, 'Access'),   // 3 weight passed
            createResult(false, 1, 'Access')   // 1 weight failed
        };

        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(results);
        Test.stopTest();

        // 3 / 4 * 100 = 75.0
        Assert.areEqual(75.0, score, 'Weighted score should be 75.0');
    }

    @IsTest
    static void shouldReturn0ForEmptyResults() {
        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(
            new List<RuleResult>());
        Test.stopTest();

        Assert.areEqual(0, score, 'Empty results should give 0');
    }

    @IsTest
    static void shouldReturn0ForNullResults() {
        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(null);
        Test.stopTest();

        Assert.areEqual(0, score, 'Null results should give 0');
    }

    @IsTest
    static void shouldDefaultWeightTo1WhenNull() {
        RuleResult result = new RuleResult();
        result.passed = true;
        result.weight = null;

        Test.startTest();
        Decimal score = ComplianceScoreAggregator.calculateScore(
            new List<RuleResult>{ result });
        Test.stopTest();

        Assert.areEqual(100.0, score,
            'Null weight should default to 1 and score should be 100');
    }

    @IsTest
    static void shouldGenerateSummaryWithCategories() {
        List<RuleResult> results = new List<RuleResult>{
            createResult(true, 2, 'Access Control'),
            createResult(true, 1, 'Access Control'),
            createResult(false, 1, 'Encryption'),
            createResult(true, 1, 'Encryption')
        };

        Test.startTest();
        ComplianceScoreAggregator.ScoreSummary summary =
            ComplianceScoreAggregator.generateSummary('SOC2', results);
        Test.stopTest();

        Assert.areEqual('SOC2', summary.framework, 'Framework should match');
        Assert.areEqual(4, summary.totalRules, 'Total rules should be 4');
        Assert.areEqual(3, summary.rulesPassed, 'Rules passed should be 3');
        Assert.areEqual(1, summary.rulesFailed, 'Rules failed should be 1');
        Assert.isTrue(summary.score > 0, 'Score should be positive');
        Assert.isNotNull(summary.rating, 'Rating should be set');
        Assert.isTrue(summary.categoryScores.containsKey('Access Control'),
            'Should have Access Control category');
        Assert.isTrue(summary.categoryScores.containsKey('Encryption'),
            'Should have Encryption category');
        Assert.areEqual(100.0, summary.categoryScores.get('Access Control'),
            'Access Control should be 100% (all passed)');
        Assert.areEqual(50.0, summary.categoryScores.get('Encryption'),
            'Encryption should be 50% (1 of 2 passed)');
    }

    @IsTest
    static void shouldGenerateSummaryForEmptyResults() {
        Test.startTest();
        ComplianceScoreAggregator.ScoreSummary summary =
            ComplianceScoreAggregator.generateSummary('SOC2', new List<RuleResult>());
        Test.stopTest();

        Assert.areEqual(0, summary.score, 'Empty results should give 0 score');
        Assert.areEqual(0, summary.totalRules, 'Should have 0 total rules');
        Assert.isNotNull(summary.rating, 'Rating should be set even for 0');
    }

    @IsTest
    static void shouldGenerateSummaryForNullResults() {
        Test.startTest();
        ComplianceScoreAggregator.ScoreSummary summary =
            ComplianceScoreAggregator.generateSummary('SOC2', null);
        Test.stopTest();

        Assert.areEqual(0, summary.score, 'Null results should give 0 score');
        Assert.areEqual(0, summary.totalRules, 'Should have 0 total rules');
    }

    @IsTest
    static void shouldCategorizeBlankCategoryAsGeneral() {
        RuleResult result = createResult(true, 1, '');

        Test.startTest();
        ComplianceScoreAggregator.ScoreSummary summary =
            ComplianceScoreAggregator.generateSummary('SOC2',
                new List<RuleResult>{ result });
        Test.stopTest();

        Assert.isTrue(summary.categoryScores.containsKey('General'),
            'Blank category should be categorized as General');
    }

    @IsTest
    static void shouldReturnNullScoreForBlankFramework() {
        Test.startTest();
        Decimal score = ComplianceScoreAggregator.getLatestScore('');
        Test.stopTest();

        Assert.isNull(score, 'Blank framework should return null');
    }

    @IsTest
    static void shouldReturnNullScoreForNullFramework() {
        Test.startTest();
        Decimal score = ComplianceScoreAggregator.getLatestScore(null);
        Test.stopTest();

        Assert.isNull(score, 'Null framework should return null');
    }

    @IsTest
    static void shouldReturnNullWhenNoExecutionHistory() {
        Test.startTest();
        Decimal score = ComplianceScoreAggregator.getLatestScore('NONEXISTENT_FRAMEWORK');
        Test.stopTest();

        Assert.isNull(score, 'No history should return null');
    }

    @IsTest
    static void shouldReturnLatestScoreFromExecutionHistory() {
        Workflow_Execution__c execution = new Workflow_Execution__c(
            Template_Name__c = 'Test',
            Framework__c = 'SOC2',
            Status__c = 'COMPLETED',
            Compliance_Score__c = 87.5,
            Completed_At__c = Datetime.now()
        );
        insert as user execution;

        Test.startTest();
        Decimal score = ComplianceScoreAggregator.getLatestScore('SOC2');
        Test.stopTest();

        Assert.areEqual(87.5, score, 'Should return most recent score');
    }

    @IsTest
    static void shouldSetScoreSummaryProperties() {
        ComplianceScoreAggregator.ScoreSummary summary =
            new ComplianceScoreAggregator.ScoreSummary();
        summary.framework = 'SOC2';
        summary.score = 95.0;
        summary.totalRules = 20;
        summary.rulesPassed = 19;
        summary.rulesFailed = 1;
        summary.rating = 'EXCELLENT';
        summary.categoryScores = new Map<String, Decimal>{ 'Access' => 100.0 };

        Assert.areEqual('SOC2', summary.framework, 'Framework getter should work');
        Assert.areEqual(95.0, summary.score, 'Score getter should work');
        Assert.areEqual('EXCELLENT', summary.rating, 'Rating getter should work');
    }
}
