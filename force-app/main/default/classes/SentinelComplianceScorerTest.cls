@IsTest
private class SentinelComplianceScorerTest {
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
        Decimal score = SentinelComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assertNotEquals(null, score, 'Should return a score');
        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
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
        Decimal score = SentinelComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assert(score > 0, 'Should have positive score with documented permission sets');
    }
}
