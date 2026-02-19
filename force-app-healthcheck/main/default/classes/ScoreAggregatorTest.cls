/**
 * Tests for {@link ScoreAggregator} covering weighted score calculation,
 * clamping, recommendation generation, and sorting.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ScoreAggregator
 */
@IsTest(testFor=ScoreAggregator.class)
private class ScoreAggregatorTest {

    @IsTest
    static void shouldReturnPerfectScoreWhenAllScoresAre100() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, 100,
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(100, result.overallScore, 'All 100s should produce overall 100');
        Assert.isTrue(result.recommendations.isEmpty(),
            'Perfect scores should generate no recommendations');
    }

    @IsTest
    static void shouldReturnZeroWhenAllScoresAreZero() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            0, new List<ScanFinding>(),
            0, new List<ScanFinding>(),
            0, 0,
            0, new List<ScanFinding>(),
            0, new List<ScanFinding>(),
            0, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(0, result.overallScore, 'All 0s should produce overall 0');
        Assert.isFalse(result.recommendations.isEmpty(),
            'Zero scores should generate recommendations');
    }

    @IsTest
    static void shouldCalculateWeightedScoreCorrectly() {
        ScoreAggregator aggregator = new ScoreAggregator();

        // HC=80 (40%), MFA=60 (20%), Perm=70 (15%), Sess=90 (15%), Audit=50 (10%)
        // Expected: 80*0.40 + 60*0.20 + 70*0.15 + 90*0.15 + 50*0.10
        //         = 32 + 12 + 10.5 + 13.5 + 5 = 73
        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            80, new List<ScanFinding>(),
            60, new List<ScanFinding>(),
            100, 60,
            70, new List<ScanFinding>(),
            90, new List<ScanFinding>(),
            50, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(73, result.overallScore,
            'Weighted score should be 73, got: ' + result.overallScore);
    }

    @IsTest
    static void shouldClampNegativeScoresToZero() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            -10, new List<ScanFinding>(),
            -5, new List<ScanFinding>(),
            0, 0,
            -20, new List<ScanFinding>(),
            -30, new List<ScanFinding>(),
            -15, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(0, result.overallScore, 'Negative scores should clamp to 0');
    }

    @IsTest
    static void shouldClampScoresAbove100() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            200, new List<ScanFinding>(),
            150, new List<ScanFinding>(),
            100, 100,
            300, new List<ScanFinding>(),
            250, new List<ScanFinding>(),
            400, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(100, result.overallScore, 'Over-100 scores should clamp to 100');
    }

    @IsTest
    static void shouldHandleNullScores() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            null, new List<ScanFinding>(),
            null, new List<ScanFinding>(),
            null, null,
            null, new List<ScanFinding>(),
            null, new List<ScanFinding>(),
            null, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(0, result.overallScore, 'Null scores should default to 0');
    }

    @IsTest
    static void shouldHandleNullFindingsLists() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            80, null,
            90, null,
            50, 45,
            70, null,
            85, null,
            60, null
        );
        Test.stopTest();

        Assert.isNotNull(result.findings, 'Findings should never be null');
    }

    @IsTest
    static void shouldAggregateFindings() {
        ScoreAggregator aggregator = new ScoreAggregator();

        List<ScanFinding> hcFindings = new List<ScanFinding>{
            new ScanFinding('SecurityHealthCheck', 'Test', 'val', 'rec', 'HIGH_RISK', 'desc')
        };
        List<ScanFinding> mfaFindings = new List<ScanFinding>{
            new ScanFinding('MFA', 'Test', 'val', 'rec', 'MEDIUM_RISK', 'desc')
        };

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            80, hcFindings,
            60, mfaFindings,
            100, 60,
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(2, result.findings.size(), 'Should aggregate findings from all scanners');
    }

    @IsTest
    static void shouldSortRecommendationsByPriority() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            30, new List<ScanFinding>(),
            40, new List<ScanFinding>(),
            0, 0,
            60, new List<ScanFinding>(),
            50, new List<ScanFinding>(),
            70, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.isFalse(result.recommendations.isEmpty(), 'Should have recommendations');

        Integer previousPriority = 0;
        for (ScanRecommendation rec : result.recommendations) {
            Assert.isTrue(rec.priority >= previousPriority,
                'Recommendations should be sorted by priority ascending');
            previousPriority = rec.priority;
        }
    }

    @IsTest
    static void shouldPopulateMfaFields() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            100, new List<ScanFinding>(),
            75, new List<ScanFinding>(),
            200, 150,
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>()
        );
        Test.stopTest();

        Assert.areEqual(75, result.mfaPercentage, 'MFA percentage should be 75');
        Assert.areEqual(200, result.totalUsers, 'Total users should be 200');
        Assert.areEqual(150, result.mfaUsers, 'MFA users should be 150');
    }

    @IsTest
    static void shouldSetScanTimestamp() {
        ScoreAggregator aggregator = new ScoreAggregator();

        Datetime before = Datetime.now();
        Test.startTest();
        HealthCheckResult result = aggregator.aggregate(
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, 100,
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>(),
            100, new List<ScanFinding>()
        );
        Test.stopTest();
        Datetime after = Datetime.now();

        Assert.isNotNull(result.scanTimestamp, 'Scan timestamp should be set');
        Assert.isTrue(result.scanTimestamp >= before && result.scanTimestamp <= after,
            'Scan timestamp should be within test window');
    }
}
