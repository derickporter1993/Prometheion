/**
 * @description Industry benchmarking service for compliance maturity
 * Provides industry comparisons and maturity assessments
 * @group Enterprise Features
 * @author Elaro Team
 */
public with sharing class BenchmarkingService {
    
    public enum MaturityLevel { AD_HOC, REPEATABLE, DEFINED, MANAGED, OPTIMIZED }
    
    // Industry benchmark data (in production, this would come from external service)
    private static final Map<String, Map<String, Decimal>> INDUSTRY_BENCHMARKS = new Map<String, Map<String, Decimal>>{
        'Healthcare' => new Map<String, Decimal>{
            'HIPAA' => 82.5,
            'SOC2' => 78.0,
            'NIST' => 75.0,
            'avgScore' => 78.5
        },
        'Financial Services' => new Map<String, Decimal>{
            'SOC2' => 88.0,
            'FINRA' => 85.0,
            'NIST' => 82.0,
            'avgScore' => 85.0
        },
        'Technology' => new Map<String, Decimal>{
            'SOC2' => 85.0,
            'GDPR' => 80.0,
            'NIST' => 78.0,
            'avgScore' => 81.0
        },
        'Retail' => new Map<String, Decimal>{
            'PCI_DSS' => 82.0,
            'GDPR' => 75.0,
            'SOC2' => 72.0,
            'avgScore' => 76.3
        },
        'Government' => new Map<String, Decimal>{
            'FedRAMP' => 90.0,
            'NIST' => 88.0,
            'FISMA' => 85.0,
            'avgScore' => 87.7
        }
    };
    
    /**
     * @description Get industry benchmarks for comparison
     * @param industry Industry name
     * @return IndustryBenchmarks with comparison data
     */
    @AuraEnabled(cacheable=true)
    public static IndustryBenchmarks getIndustryBenchmarks(String industry) {
        IndustryBenchmarks benchmarks = new IndustryBenchmarks();
        benchmarks.industry = industry;
        benchmarks.lastUpdated = Date.today();
        
        Map<String, Decimal> industryData = INDUSTRY_BENCHMARKS.get(industry);
        if (industryData == null) {
            industryData = INDUSTRY_BENCHMARKS.get('Technology'); // Default
        }
        
        benchmarks.avgComplianceScore = industryData.get('avgScore');
        benchmarks.frameworkBenchmarks = new Map<String, Decimal>();
        
        for (String key : industryData.keySet()) {
            if (key != 'avgScore') {
                benchmarks.frameworkBenchmarks.put(key, industryData.get(key));
            }
        }
        
        // Get top performers (simulated)
        benchmarks.topPerformerScore = benchmarks.avgComplianceScore + 10;
        benchmarks.bottomPerformerScore = benchmarks.avgComplianceScore - 15;
        
        return benchmarks;
    }
    
    /**
     * @description Compare organization to industry benchmarks
     * @param industry Industry for comparison
     * @return ComparisonResult with detailed comparison
     */
    @AuraEnabled
    public static ComparisonResult compareToIndustry(String industry) {
        ComparisonResult result = new ComparisonResult();
        result.industry = industry;
        result.comparedAt = Datetime.now();
        
        // Get current org score
        Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
        result.orgScore = (Decimal)scoreData.get('overallScore');
        
        // Get industry benchmarks
        IndustryBenchmarks benchmarks = getIndustryBenchmarks(industry);
        result.industryAvgScore = benchmarks.avgComplianceScore;
        
        // Calculate percentile
        result.percentile = calculatePercentile(result.orgScore, benchmarks);
        
        // Determine position
        result.vsIndustryAvg = result.orgScore - result.industryAvgScore;
        
        if (result.percentile >= 90) {
            result.position = 'Top 10%';
            result.positionClass = 'excellent';
        } else if (result.percentile >= 75) {
            result.position = 'Top 25%';
            result.positionClass = 'good';
        } else if (result.percentile >= 50) {
            result.position = 'Above Average';
            result.positionClass = 'average';
        } else if (result.percentile >= 25) {
            result.position = 'Below Average';
            result.positionClass = 'below';
        } else {
            result.position = 'Bottom 25%';
            result.positionClass = 'poor';
        }
        
        // Framework comparisons
        result.frameworkComparisons = new List<FrameworkComparison>();
        Map<String, Decimal> frameworkScores = (Map<String, Decimal>)scoreData.get('frameworkScores');
        
        for (String framework : benchmarks.frameworkBenchmarks.keySet()) {
            FrameworkComparison fc = new FrameworkComparison();
            fc.framework = framework;
            fc.industryBenchmark = benchmarks.frameworkBenchmarks.get(framework);
            fc.orgScore = frameworkScores.containsKey(framework) ? frameworkScores.get(framework) : 75;
            fc.difference = fc.orgScore - fc.industryBenchmark;
            fc.status = fc.difference >= 0 ? 'Above' : 'Below';
            result.frameworkComparisons.add(fc);
        }
        
        // Recommendations
        result.recommendations = generateBenchmarkRecommendations(result);
        
        return result;
    }
    
    /**
     * @description Assess compliance maturity level
     * @return MaturityAssessment with maturity details
     */
    @AuraEnabled
    public static MaturityAssessment assessMaturity() {
        MaturityAssessment assessment = new MaturityAssessment();
        assessment.assessedAt = Datetime.now();
        
        // Get compliance score
        Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
        Decimal overallScore = (Decimal)scoreData.get('overallScore');
        
        // Determine maturity level
        assessment.overallLevel = determineMaturityLevel(overallScore);
        assessment.overallScore = overallScore;
        
        // Assess individual dimensions
        assessment.dimensions = new List<MaturityDimension>();
        
        // Process Maturity
        assessment.dimensions.add(assessDimension('Process', 
            'Documented policies and procedures', 
            calculateProcessMaturity()));
        
        // Technology Maturity
        assessment.dimensions.add(assessDimension('Technology', 
            'Security tools and automation', 
            calculateTechnologyMaturity()));
        
        // People Maturity
        assessment.dimensions.add(assessDimension('People', 
            'Training and awareness', 
            calculatePeopleMaturity()));
        
        // Governance Maturity
        assessment.dimensions.add(assessDimension('Governance', 
            'Oversight and accountability', 
            calculateGovernanceMaturity()));
        
        // Generate roadmap
        assessment.improvementRoadmap = generateMaturityRoadmap(assessment);
        
        return assessment;
    }
    
    /**
     * @description Get available industries for benchmarking
     * @return List of industry names
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableIndustries() {
        return new List<String>(INDUSTRY_BENCHMARKS.keySet());
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static Decimal calculatePercentile(Decimal score, IndustryBenchmarks benchmarks) {
        // Simplified percentile calculation
        Decimal range = benchmarks.topPerformerScore - benchmarks.bottomPerformerScore;
        Decimal position = score - benchmarks.bottomPerformerScore;
        return Math.min(99, Math.max(1, (position / range) * 100));
    }
    
    private static MaturityLevel determineMaturityLevel(Decimal score) {
        if (score >= 90) return MaturityLevel.OPTIMIZED;
        if (score >= 75) return MaturityLevel.MANAGED;
        if (score >= 60) return MaturityLevel.DEFINED;
        if (score >= 40) return MaturityLevel.REPEATABLE;
        return MaturityLevel.AD_HOC;
    }
    
    private static Decimal calculateProcessMaturity() {
        // Check for documented policies
        Integer policyCount = [SELECT COUNT() FROM Compliance_Policy__mdt];
        return Math.min(100, policyCount * 5);
    }
    
    private static Decimal calculateTechnologyMaturity() {
        // Check for automation and tooling
        Integer auditTrailEntries = [SELECT COUNT() FROM SetupAuditTrail WHERE CreatedDate >= LAST_N_DAYS:30 LIMIT 10000];
        return Math.min(100, 70 + (auditTrailEntries > 1000 ? 30 : auditTrailEntries / 33));
    }
    
    private static Decimal calculatePeopleMaturity() {
        // Check for security awareness indicators
        return 65; // Baseline
    }
    
    private static Decimal calculateGovernanceMaturity() {
        // Check for governance structures
        Integer adminUsers = [SELECT COUNT() FROM User WHERE Profile.Name LIKE '%Admin%' AND IsActive = true];
        return adminUsers < 10 ? 80 : 60; // Fewer admins = better governance
    }
    
    private static MaturityDimension assessDimension(String name, String description, Decimal score) {
        MaturityDimension dim = new MaturityDimension();
        dim.name = name;
        dim.description = description;
        dim.score = score;
        dim.level = determineMaturityLevel(score);
        return dim;
    }
    
    private static List<String> generateBenchmarkRecommendations(ComparisonResult result) {
        List<String> recommendations = new List<String>();
        
        if (result.vsIndustryAvg < 0) {
            recommendations.add('Focus on improving overall compliance score to meet industry average');
        }
        
        for (FrameworkComparison fc : result.frameworkComparisons) {
            if (fc.difference < -5) {
                recommendations.add('Prioritize ' + fc.framework + ' compliance (currently ' + fc.difference.setScale(1) + '% below benchmark)');
            }
        }
        
        if (result.percentile < 50) {
            recommendations.add('Consider investing in compliance automation tools');
            recommendations.add('Schedule quarterly compliance reviews');
        }
        
        return recommendations;
    }
    
    private static List<RoadmapItem> generateMaturityRoadmap(MaturityAssessment assessment) {
        List<RoadmapItem> roadmap = new List<RoadmapItem>();
        
        for (MaturityDimension dim : assessment.dimensions) {
            if (dim.score < 80) {
                RoadmapItem item = new RoadmapItem();
                item.dimension = dim.name;
                item.currentLevel = dim.level;
                item.targetLevel = getNextMaturityLevel(dim.level);
                item.priority = dim.score < 60 ? 'High' : 'Medium';
                item.actions = getImprovementActions(dim.name, dim.level);
                roadmap.add(item);
            }
        }
        
        return roadmap;
    }
    
    private static MaturityLevel getNextMaturityLevel(MaturityLevel current) {
        switch on current {
            when AD_HOC { return MaturityLevel.REPEATABLE; }
            when REPEATABLE { return MaturityLevel.DEFINED; }
            when DEFINED { return MaturityLevel.MANAGED; }
            when MANAGED { return MaturityLevel.OPTIMIZED; }
            when else { return MaturityLevel.OPTIMIZED; }
        }
    }
    
    private static List<String> getImprovementActions(String dimension, MaturityLevel level) {
        Map<String, List<String>> actions = new Map<String, List<String>>{
            'Process' => new List<String>{'Document policies', 'Implement review cycles', 'Automate workflows'},
            'Technology' => new List<String>{'Deploy monitoring tools', 'Enable encryption', 'Implement SIEM'},
            'People' => new List<String>{'Conduct training', 'Run phishing simulations', 'Establish security champions'},
            'Governance' => new List<String>{'Define roles', 'Establish committees', 'Implement metrics'}
        };
        return actions.containsKey(dimension) ? actions.get(dimension) : new List<String>();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    public class IndustryBenchmarks {
        @AuraEnabled public String industry;
        @AuraEnabled public Decimal avgComplianceScore;
        @AuraEnabled public Decimal topPerformerScore;
        @AuraEnabled public Decimal bottomPerformerScore;
        @AuraEnabled public Map<String, Decimal> frameworkBenchmarks;
        @AuraEnabled public Date lastUpdated;
    }
    
    public class ComparisonResult {
        @AuraEnabled public String industry;
        @AuraEnabled public Decimal orgScore;
        @AuraEnabled public Decimal industryAvgScore;
        @AuraEnabled public Decimal vsIndustryAvg;
        @AuraEnabled public Decimal percentile;
        @AuraEnabled public String position;
        @AuraEnabled public String positionClass;
        @AuraEnabled public List<FrameworkComparison> frameworkComparisons;
        @AuraEnabled public List<String> recommendations;
        @AuraEnabled public Datetime comparedAt;
    }
    
    public class FrameworkComparison {
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal industryBenchmark;
        @AuraEnabled public Decimal orgScore;
        @AuraEnabled public Decimal difference;
        @AuraEnabled public String status;
    }
    
    public class MaturityAssessment {
        @AuraEnabled public MaturityLevel overallLevel;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public List<MaturityDimension> dimensions;
        @AuraEnabled public List<RoadmapItem> improvementRoadmap;
        @AuraEnabled public Datetime assessedAt;
    }
    
    public class MaturityDimension {
        @AuraEnabled public String name;
        @AuraEnabled public String description;
        @AuraEnabled public Decimal score;
        @AuraEnabled public MaturityLevel level;
    }
    
    public class RoadmapItem {
        @AuraEnabled public String dimension;
        @AuraEnabled public MaturityLevel currentLevel;
        @AuraEnabled public MaturityLevel targetLevel;
        @AuraEnabled public String priority;
        @AuraEnabled public List<String> actions;
    }
}
