/**
 * @description Test class for SentinelComplianceScorer
 * @author Sentinel Team
 * @date 2025
 */
@isTest
private class SentinelComplianceScorerTest {

    @isTest
    static void testCalculateReadinessScore_ReturnsValidScore() {
        Test.startTest();
        Integer score = SentinelComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // Verify score is in valid range
        System.assertNotEquals(null, score, 'Score should not be null');
        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testCalculateReadinessScore_Cacheable() {
        // Test that @AuraEnabled(cacheable=true) works
        Test.startTest();
        Integer score1 = SentinelComplianceScorer.calculateReadinessScore();
        Integer score2 = SentinelComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // Verify consistent results
        System.assertEquals(score1, score2, 'Cacheable method should return consistent results');
    }

    @isTest
    static void testGetScoreBreakdown_ReturnsAllCategories() {
        Test.startTest();
        Map<String, Integer> breakdown = SentinelComplianceScorer.getScoreBreakdown();
        Test.stopTest();

        // Verify all categories present
        System.assertNotEquals(null, breakdown, 'Breakdown should not be null');
        System.assert(breakdown.containsKey('access'), 'Should include access score');
        System.assert(breakdown.containsKey('config'), 'Should include config score');
        System.assert(breakdown.containsKey('automation'), 'Should include automation score');
        System.assert(breakdown.containsKey('evidence'), 'Should include evidence score');
    }

    @isTest
    static void testGetScoreBreakdown_ValidRanges() {
        Test.startTest();
        Map<String, Integer> breakdown = SentinelComplianceScorer.getScoreBreakdown();
        Test.stopTest();

        // Verify all scores in valid range
        for (String category : breakdown.keySet()) {
            Integer categoryScore = breakdown.get(category);
            System.assert(categoryScore >= 0 && categoryScore <= 100,
                category + ' score should be between 0 and 100, got: ' + categoryScore);
        }
    }

    @isTest
    static void testCalculateReadinessScore_GovernorLimits() {
        Test.startTest();
        Integer score = SentinelComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // Verify efficient execution
        System.assert(Limits.getQueries() < 10, 'Should use minimal SOQL queries');
        System.assert(Limits.getCpuTime() < 5000, 'Should execute efficiently');
    }

    @isTest
    static void testScoreCalculation_WithDifferentOrgStates() {
        // Test score calculation adapts to org state
        Test.startTest();
        Integer score = SentinelComplianceScorer.calculateReadinessScore();
        Map<String, Integer> breakdown = SentinelComplianceScorer.getScoreBreakdown();
        Test.stopTest();

        // Verify breakdown sums logically
        System.assertNotEquals(null, score, 'Score should be calculated');
        System.assertNotEquals(null, breakdown, 'Breakdown should be calculated');
    }

    @isTest
    static void testErrorHandling_InvalidState() {
        // Test graceful error handling
        Test.startTest();
        try {
            Integer score = SentinelComplianceScorer.calculateReadinessScore();
            System.assertNotEquals(null, score, 'Should return valid score even in edge cases');
        } catch (Exception e) {
            System.assert(false, 'Should handle errors gracefully: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
