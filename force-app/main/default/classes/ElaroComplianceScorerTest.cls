@IsTest
private class ElaroComplianceScorerTest {
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
        ElaroComplianceScorer.ScoreResult result = ElaroComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return a result');
        System.assertNotEquals(null, result.overallScore, 'Should have an overall score');
        System.assert(result.overallScore >= 0 && result.overallScore <= 100, 'Score should be between 0 and 100');
        System.assertNotEquals(null, result.rating, 'Should have a rating');
        System.assertNotEquals(null, result.frameworkScores, 'Should have framework scores');
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
        ElaroComplianceScorer.ScoreResult result = ElaroComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assert(result.overallScore > 0, 'Should have positive score with documented permission sets');
        System.assertNotEquals(null, result.factors, 'Should have score factors');
        System.assert(!result.factors.isEmpty(), 'Should have at least one factor');
    }
    
    @IsTest
    static void testCalculateReadinessScore_BulkPermissionSets() {
        // Test with 200+ permission sets to verify governor limit handling
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 250; i++) {
            permSets.add(new PermissionSet(
                Name='BulkTestPS' + i,
                Label='Bulk Test PS ' + i,
                Description='Bulk test description ' + i
            ));
        }
        insert permSets;
        
        Test.startTest();
        ElaroComplianceScorer.ScoreResult result = ElaroComplianceScorer.calculateReadinessScore();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return a result even with bulk data');
        System.assert(result.overallScore >= 0 && result.overallScore <= 100, 'Score should be valid');
    }
    
    @IsTest
    static void testCalculateReadinessScore_ErrorHandling() {
        // Test error handling - method should not throw exceptions
        Test.startTest();
        try {
            ElaroComplianceScorer.ScoreResult result = ElaroComplianceScorer.calculateReadinessScore();
            System.assertNotEquals(null, result, 'Should return a result even on error');
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
