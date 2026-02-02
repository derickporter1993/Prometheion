/**
 * @description Unit tests for BenchmarkingService
 * Tests industry benchmarks, comparisons, maturity assessment, and recommendations
 * @group Tests
 * @author Elaro Team
 */
@isTest
private class BenchmarkingServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create audit package and evidence for compliance scoring
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('SOC2');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 20);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getIndustryBenchmarks Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testGetIndustryBenchmarks_Healthcare() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Healthcare');
        Test.stopTest();
        
        System.assertNotEquals(null, benchmarks, 'Should return benchmarks');
        System.assertEquals('Healthcare', benchmarks.industry, 'Industry should match');
        System.assertNotEquals(null, benchmarks.avgComplianceScore, 'Should have average score');
        System.assert(benchmarks.avgComplianceScore > 0, 'Average score should be positive');
        System.assertNotEquals(null, benchmarks.frameworkBenchmarks, 'Should have framework benchmarks');
        System.assertNotEquals(null, benchmarks.lastUpdated, 'Should have last updated date');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_FinancialServices() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Financial Services');
        Test.stopTest();
        
        System.assertNotEquals(null, benchmarks, 'Should return benchmarks');
        System.assertEquals('Financial Services', benchmarks.industry, 'Industry should match');
        System.assert(benchmarks.avgComplianceScore > 0, 'Average score should be positive');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_Technology() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Technology');
        Test.stopTest();
        
        System.assertNotEquals(null, benchmarks, 'Should return benchmarks');
        System.assertEquals('Technology', benchmarks.industry, 'Industry should match');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_UnknownIndustry() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Unknown Industry');
        Test.stopTest();
        
        // Should default to Technology
        System.assertNotEquals(null, benchmarks, 'Should return default benchmarks');
        System.assert(benchmarks.avgComplianceScore > 0, 'Should have default score');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // compareToIndustry Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testCompareToIndustry_Success() {
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Healthcare');
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return comparison result');
        System.assertEquals('Healthcare', result.industry, 'Industry should match');
        System.assertNotEquals(null, result.orgScore, 'Should have org score');
        System.assertNotEquals(null, result.industryAvgScore, 'Should have industry average');
        System.assertNotEquals(null, result.percentile, 'Should have percentile');
        System.assert(result.percentile >= 0 && result.percentile <= 100, 'Percentile should be 0-100');
        System.assertNotEquals(null, result.position, 'Should have position');
        System.assertNotEquals(null, result.frameworkComparisons, 'Should have framework comparisons');
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
    }
    
    @isTest
    static void testCompareToIndustry_AboveAverage() {
        // This test verifies comparison logic
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Technology');
        Test.stopTest();
        
        System.assertNotEquals(null, result.vsIndustryAvg, 'Should have comparison delta');
        System.assertNotEquals(null, result.positionClass, 'Should have position class');
    }
    
    @isTest
    static void testCompareToIndustry_FrameworkComparisons() {
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Retail');
        Test.stopTest();
        
        System.assertNotEquals(null, result.frameworkComparisons, 'Should have framework comparisons');
        System.assert(result.frameworkComparisons.size() > 0, 'Should have at least one framework comparison');
        
        for (BenchmarkingService.FrameworkComparison fc : result.frameworkComparisons) {
            System.assertNotEquals(null, fc.framework, 'Framework should be set');
            System.assertNotEquals(null, fc.industryBenchmark, 'Industry benchmark should be set');
            System.assertNotEquals(null, fc.orgScore, 'Org score should be set');
            System.assertNotEquals(null, fc.difference, 'Difference should be set');
            System.assertNotEquals(null, fc.status, 'Status should be set');
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // assessMaturity Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testAssessMaturity() {
        Test.startTest();
        BenchmarkingService.MaturityAssessment assessment = 
            BenchmarkingService.assessMaturity();
        Test.stopTest();
        
        System.assertNotEquals(null, assessment, 'Should return assessment');
        System.assertNotEquals(null, assessment.overallLevel, 'Should have overall level');
        System.assertNotEquals(null, assessment.overallScore, 'Should have overall score');
        System.assertNotEquals(null, assessment.dimensions, 'Should have dimensions');
        System.assert(assessment.dimensions.size() > 0, 'Should have at least one dimension');
        System.assertNotEquals(null, assessment.improvementRoadmap, 'Should have roadmap');
        System.assertNotEquals(null, assessment.assessedAt, 'Should have assessment timestamp');
    }
    
    @isTest
    static void testAssessMaturity_Dimensions() {
        Test.startTest();
        BenchmarkingService.MaturityAssessment assessment = 
            BenchmarkingService.assessMaturity();
        Test.stopTest();
        
        System.assert(assessment.dimensions.size() >= 4, 'Should have at least 4 dimensions');
        
        Set<String> dimensionNames = new Set<String>();
        for (BenchmarkingService.MaturityDimension dim : assessment.dimensions) {
            System.assertNotEquals(null, dim.name, 'Dimension should have name');
            System.assertNotEquals(null, dim.description, 'Dimension should have description');
            System.assertNotEquals(null, dim.score, 'Dimension should have score');
            System.assert(dim.score >= 0 && dim.score <= 100, 'Score should be 0-100');
            System.assertNotEquals(null, dim.level, 'Dimension should have maturity level');
            dimensionNames.add(dim.name);
        }
        
        // Verify expected dimensions
        System.assert(dimensionNames.contains('Process'), 'Should have Process dimension');
        System.assert(dimensionNames.contains('Technology'), 'Should have Technology dimension');
        System.assert(dimensionNames.contains('People'), 'Should have People dimension');
        System.assert(dimensionNames.contains('Governance'), 'Should have Governance dimension');
    }
    
    @isTest
    static void testAssessMaturity_Roadmap() {
        Test.startTest();
        BenchmarkingService.MaturityAssessment assessment = 
            BenchmarkingService.assessMaturity();
        Test.stopTest();
        
        System.assertNotEquals(null, assessment.improvementRoadmap, 'Should have roadmap');
        
        for (BenchmarkingService.RoadmapItem item : assessment.improvementRoadmap) {
            System.assertNotEquals(null, item.dimension, 'Roadmap item should have dimension');
            System.assertNotEquals(null, item.currentLevel, 'Roadmap item should have current level');
            System.assertNotEquals(null, item.targetLevel, 'Roadmap item should have target level');
            System.assertNotEquals(null, item.priority, 'Roadmap item should have priority');
            System.assertNotEquals(null, item.actions, 'Roadmap item should have actions');
            System.assert(item.actions.size() > 0, 'Roadmap item should have at least one action');
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getAvailableIndustries Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testGetAvailableIndustries() {
        Test.startTest();
        List<String> industries = BenchmarkingService.getAvailableIndustries();
        Test.stopTest();
        
        System.assertNotEquals(null, industries, 'Should return industries list');
        System.assert(industries.size() > 0, 'Should have at least one industry');
        
        // Verify expected industries
        System.assert(industries.contains('Healthcare'), 'Should include Healthcare');
        System.assert(industries.contains('Financial Services'), 'Should include Financial Services');
        System.assert(industries.contains('Technology'), 'Should include Technology');
        System.assert(industries.contains('Retail'), 'Should include Retail');
        System.assert(industries.contains('Government'), 'Should include Government');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Maturity Level Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testMaturityLevel_Enum() {
        // Test that maturity levels are defined
        BenchmarkingService.MaturityLevel adHoc = BenchmarkingService.MaturityLevel.AD_HOC;
        BenchmarkingService.MaturityLevel repeatable = BenchmarkingService.MaturityLevel.REPEATABLE;
        BenchmarkingService.MaturityLevel defined = BenchmarkingService.MaturityLevel.DEFINED;
        BenchmarkingService.MaturityLevel managed = BenchmarkingService.MaturityLevel.MANAGED;
        BenchmarkingService.MaturityLevel optimized = BenchmarkingService.MaturityLevel.OPTIMIZED;
        
        System.assertNotEquals(null, adHoc, 'AD_HOC should be defined');
        System.assertNotEquals(null, repeatable, 'REPEATABLE should be defined');
        System.assertNotEquals(null, defined, 'DEFINED should be defined');
        System.assertNotEquals(null, managed, 'MANAGED should be defined');
        System.assertNotEquals(null, optimized, 'OPTIMIZED should be defined');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkBenchmarking() {
        List<String> industries = BenchmarkingService.getAvailableIndustries();
        
        Test.startTest();
        List<BenchmarkingService.ComparisonResult> results = new List<BenchmarkingService.ComparisonResult>();
        
        for (String industry : industries) {
            BenchmarkingService.ComparisonResult result = 
                BenchmarkingService.compareToIndustry(industry);
            results.add(result);
        }
        Test.stopTest();
        
        System.assertEquals(industries.size(), results.size(), 'Should compare to all industries');
        
        for (BenchmarkingService.ComparisonResult result : results) {
            System.assertNotEquals(null, result, 'Each result should be non-null');
            System.assertNotEquals(null, result.orgScore, 'Each result should have org score');
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Edge Cases Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testCompareToIndustry_NullIndustry() {
        Test.startTest();
        // Should default to Technology
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry(null);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return result with default industry');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_EmptyString() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('');
        Test.stopTest();
        
        System.assertNotEquals(null, benchmarks, 'Should return default benchmarks');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Recommendations Tests
    // ═══════════════════════════════════════════════════════════
    
    @isTest
    static void testCompareToIndustry_Recommendations() {
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Healthcare');
        Test.stopTest();
        
        System.assertNotEquals(null, result.recommendations, 'Should have recommendations');
        
        // Recommendations should be actionable
        for (String recommendation : result.recommendations) {
            System.assertNotEquals(null, recommendation, 'Recommendation should not be null');
            System.assert(recommendation.length() > 0, 'Recommendation should have content');
        }
    }
}
