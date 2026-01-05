@IsTest
private class PrometheionComplianceScorerTest {
    @TestSetup
    static void setup() {
        PermissionSet ps = new PermissionSet(
            Name='TestPS',
            Label='Test Permission Set',
            Description='Test description'
        );
        insert ps;
    }

    @IsTest
    static void testCalculateReadinessScore_ReturnsScore() {
        Test.startTest();
        PrometheionComplianceScorer.ScoreResult result = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a result');
        System.assertNotEquals(null, result.totalScore, 'Should have a total score');
        System.assert(result.totalScore >= 0 && result.totalScore <= 100, 'Score should be between 0 and 100');
    }

    @IsTest
    static void testCalculateReadinessScore_WithData() {
        // Additional permission sets to test scoring
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 5; i++) {
            permSets.add(new PermissionSet(
                Name='TestPS' + i,
                Label='Test PS ' + i,
                Description='Description ' + i
            ));
        }
        insert permSets;

        Test.startTest();
        PrometheionComplianceScorer.ScoreResult result = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assert(result.totalScore > 0, 'Should have positive score with documented permission sets');
    }
}
