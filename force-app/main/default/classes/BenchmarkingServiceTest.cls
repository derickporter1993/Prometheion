/**
 * Unit tests for BenchmarkingService
 * Tests industry benchmarks, comparisons, maturity assessment, and recommendations
 * @group Tests
 * @author Elaro Team
 */
@IsTest
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
        
        Assert.areNotEqual(null, benchmarks, 'Should return benchmarks');
        Assert.areEqual('Healthcare', benchmarks.industry, 'Industry should match');
        Assert.areNotEqual(null, benchmarks.avgComplianceScore, 'Should have average score');
        Assert.isTrue(benchmarks.avgComplianceScore > 0, 'Average score should be positive');
        Assert.areNotEqual(null, benchmarks.frameworkBenchmarks, 'Should have framework benchmarks');
        Assert.areNotEqual(null, benchmarks.lastUpdated, 'Should have last updated date');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_FinancialServices() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Financial Services');
        Test.stopTest();
        
        Assert.areNotEqual(null, benchmarks, 'Should return benchmarks');
        Assert.areEqual('Financial Services', benchmarks.industry, 'Industry should match');
        Assert.isTrue(benchmarks.avgComplianceScore > 0, 'Average score should be positive');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_Technology() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Technology');
        Test.stopTest();
        
        Assert.areNotEqual(null, benchmarks, 'Should return benchmarks');
        Assert.areEqual('Technology', benchmarks.industry, 'Industry should match');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_UnknownIndustry() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('Unknown Industry');
        Test.stopTest();
        
        // Should default to Technology
        Assert.areNotEqual(null, benchmarks, 'Should return default benchmarks');
        Assert.isTrue(benchmarks.avgComplianceScore > 0, 'Should have default score');
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
        
        Assert.areNotEqual(null, result, 'Should return comparison result');
        Assert.areEqual('Healthcare', result.industry, 'Industry should match');
        Assert.areNotEqual(null, result.orgScore, 'Should have org score');
        Assert.areNotEqual(null, result.industryAvgScore, 'Should have industry average');
        Assert.areNotEqual(null, result.percentile, 'Should have percentile');
        Assert.isTrue(result.percentile >= 0 && result.percentile <= 100, 'Percentile should be 0-100');
        Assert.areNotEqual(null, result.position, 'Should have position');
        Assert.areNotEqual(null, result.frameworkComparisons, 'Should have framework comparisons');
        Assert.areNotEqual(null, result.recommendations, 'Should have recommendations');
    }
    
    @isTest
    static void testCompareToIndustry_AboveAverage() {
        // This test verifies comparison logic
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Technology');
        Test.stopTest();
        
        Assert.areNotEqual(null, result.vsIndustryAvg, 'Should have comparison delta');
        Assert.areNotEqual(null, result.positionClass, 'Should have position class');
    }
    
    @isTest
    static void testCompareToIndustry_FrameworkComparisons() {
        Test.startTest();
        BenchmarkingService.ComparisonResult result = 
            BenchmarkingService.compareToIndustry('Retail');
        Test.stopTest();
        
        Assert.areNotEqual(null, result.frameworkComparisons, 'Should have framework comparisons');
        Assert.isTrue(result.frameworkComparisons.size() > 0, 'Should have at least one framework comparison');
        
        for (BenchmarkingService.FrameworkComparison fc : result.frameworkComparisons) {
            Assert.areNotEqual(null, fc.framework, 'Framework should be set');
            Assert.areNotEqual(null, fc.industryBenchmark, 'Industry benchmark should be set');
            Assert.areNotEqual(null, fc.orgScore, 'Org score should be set');
            Assert.areNotEqual(null, fc.difference, 'Difference should be set');
            Assert.areNotEqual(null, fc.status, 'Status should be set');
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
        
        Assert.areNotEqual(null, assessment, 'Should return assessment');
        Assert.areNotEqual(null, assessment.overallLevel, 'Should have overall level');
        Assert.areNotEqual(null, assessment.overallScore, 'Should have overall score');
        Assert.areNotEqual(null, assessment.dimensions, 'Should have dimensions');
        Assert.isTrue(assessment.dimensions.size() > 0, 'Should have at least one dimension');
        Assert.areNotEqual(null, assessment.improvementRoadmap, 'Should have roadmap');
        Assert.areNotEqual(null, assessment.assessedAt, 'Should have assessment timestamp');
    }
    
    @isTest
    static void testAssessMaturity_Dimensions() {
        Test.startTest();
        BenchmarkingService.MaturityAssessment assessment = 
            BenchmarkingService.assessMaturity();
        Test.stopTest();
        
        Assert.isTrue(assessment.dimensions.size() >= 4, 'Should have at least 4 dimensions');
        
        Set<String> dimensionNames = new Set<String>();
        for (BenchmarkingService.MaturityDimension dim : assessment.dimensions) {
            Assert.areNotEqual(null, dim.name, 'Dimension should have name');
            Assert.areNotEqual(null, dim.description, 'Dimension should have description');
            Assert.areNotEqual(null, dim.score, 'Dimension should have score');
            Assert.isTrue(dim.score >= 0 && dim.score <= 100, 'Score should be 0-100');
            Assert.areNotEqual(null, dim.level, 'Dimension should have maturity level');
            dimensionNames.add(dim.name);
        }
        
        // Verify expected dimensions
        Assert.isTrue(dimensionNames.contains('Process'), 'Should have Process dimension');
        Assert.isTrue(dimensionNames.contains('Technology'), 'Should have Technology dimension');
        Assert.isTrue(dimensionNames.contains('People'), 'Should have People dimension');
        Assert.isTrue(dimensionNames.contains('Governance'), 'Should have Governance dimension');
    }
    
    @isTest
    static void testAssessMaturity_Roadmap() {
        Test.startTest();
        BenchmarkingService.MaturityAssessment assessment = 
            BenchmarkingService.assessMaturity();
        Test.stopTest();
        
        Assert.areNotEqual(null, assessment.improvementRoadmap, 'Should have roadmap');
        
        for (BenchmarkingService.RoadmapItem item : assessment.improvementRoadmap) {
            Assert.areNotEqual(null, item.dimension, 'Roadmap item should have dimension');
            Assert.areNotEqual(null, item.currentLevel, 'Roadmap item should have current level');
            Assert.areNotEqual(null, item.targetLevel, 'Roadmap item should have target level');
            Assert.areNotEqual(null, item.priority, 'Roadmap item should have priority');
            Assert.areNotEqual(null, item.actions, 'Roadmap item should have actions');
            Assert.isTrue(item.actions.size() > 0, 'Roadmap item should have at least one action');
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
        
        Assert.areNotEqual(null, industries, 'Should return industries list');
        Assert.isTrue(industries.size() > 0, 'Should have at least one industry');
        
        // Verify expected industries
        Assert.isTrue(industries.contains('Healthcare'), 'Should include Healthcare');
        Assert.isTrue(industries.contains('Financial Services'), 'Should include Financial Services');
        Assert.isTrue(industries.contains('Technology'), 'Should include Technology');
        Assert.isTrue(industries.contains('Retail'), 'Should include Retail');
        Assert.isTrue(industries.contains('Government'), 'Should include Government');
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
        
        Assert.areNotEqual(null, adHoc, 'AD_HOC should be defined');
        Assert.areNotEqual(null, repeatable, 'REPEATABLE should be defined');
        Assert.areNotEqual(null, defined, 'DEFINED should be defined');
        Assert.areNotEqual(null, managed, 'MANAGED should be defined');
        Assert.areNotEqual(null, optimized, 'OPTIMIZED should be defined');
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
        
        Assert.areEqual(industries.size(), results.size(), 'Should compare to all industries');
        
        for (BenchmarkingService.ComparisonResult result : results) {
            Assert.areNotEqual(null, result, 'Each result should be non-null');
            Assert.areNotEqual(null, result.orgScore, 'Each result should have org score');
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
        
        Assert.areNotEqual(null, result, 'Should return result with default industry');
    }
    
    @isTest
    static void testGetIndustryBenchmarks_EmptyString() {
        Test.startTest();
        BenchmarkingService.IndustryBenchmarks benchmarks = 
            BenchmarkingService.getIndustryBenchmarks('');
        Test.stopTest();
        
        Assert.areNotEqual(null, benchmarks, 'Should return default benchmarks');
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
        
        Assert.areNotEqual(null, result.recommendations, 'Should have recommendations');
        
        // Recommendations should be actionable
        for (String recommendation : result.recommendations) {
            Assert.areNotEqual(null, recommendation, 'Recommendation should not be null');
            Assert.isTrue(recommendation.length() > 0, 'Recommendation should have content');
        }
    }
}
