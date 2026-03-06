/**
 * Aggregate result of a full org security health check scan containing the composite
 * score, per-category scores, individual findings, and prioritized recommendations.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 */
public inherited sharing class HealthCheckResult {

    @AuraEnabled
    public Integer overallScore { get; set; }

    @AuraEnabled
    public Map<String, Integer> categoryScores { get; set; }

    @AuraEnabled
    public List<ScanFinding> findings { get; set; }

    @AuraEnabled
    public List<ScanRecommendation> recommendations { get; set; }

    @AuraEnabled
    public Datetime scanTimestamp { get; set; }

    @AuraEnabled
    public Integer mfaPercentage { get; set; }

    @AuraEnabled
    public Integer totalUsers { get; set; }

    @AuraEnabled
    public Integer mfaUsers { get; set; }

    /**
     * Default constructor initializing empty collections.
     */
    public HealthCheckResult() {
        this.overallScore = 0;
        this.categoryScores = new Map<String, Integer>();
        this.findings = new List<ScanFinding>();
        this.recommendations = new List<ScanRecommendation>();
        this.scanTimestamp = Datetime.now();
        this.mfaPercentage = 0;
        this.totalUsers = 0;
        this.mfaUsers = 0;
    }
}
