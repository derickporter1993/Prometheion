/**
 * SolentraComplianceScorer - Multi-Framework Compliance Scoring Engine
 * 
 * Calculates compliance scores across HIPAA, SOC2, NIST, FedRAMP, and GDPR frameworks.
 * Provides both aggregate and framework-specific scoring with actionable insights.
 * 
 * Scoring Methodology:
 * - Permission Sprawl (30%): Users with elevated access
 * - Audit Trail Coverage (25%): Field History on sensitive objects
 * - Configuration Drift (20%): Unreviewed high-risk changes
 * - Encryption Status (15%): Shield Platform Encryption
 * - Policy Compliance (10%): OWD settings, session timeout, password policy
 * 
 * @author Solentra
 * @version 1.0
 */
public with sharing class SolentraComplianceScorer {
    
    // Scoring weights
    private static final Decimal WEIGHT_PERMISSION_SPRAWL = 0.30;
    private static final Decimal WEIGHT_AUDIT_TRAIL = 0.25;
    private static final Decimal WEIGHT_CONFIG_DRIFT = 0.20;
    private static final Decimal WEIGHT_ENCRYPTION = 0.15;
    private static final Decimal WEIGHT_POLICY = 0.10;
    
    /**
     * Comprehensive score result with framework breakdown
     */
    public class ScoreResult {
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public String rating;
        @AuraEnabled public Map<String, Decimal> frameworkScores;
        @AuraEnabled public List<ScoreFactor> factors;
        @AuraEnabled public List<Risk> topRisks;
        @AuraEnabled public Datetime calculatedAt;
        
        public ScoreResult() {
            this.frameworkScores = new Map<String, Decimal>();
            this.factors = new List<ScoreFactor>();
            this.topRisks = new List<Risk>();
            this.calculatedAt = Datetime.now();
        }
    }
    
    public class ScoreFactor {
        @AuraEnabled public String name;
        @AuraEnabled public Decimal score;
        @AuraEnabled public Decimal weight;
        @AuraEnabled public Decimal weightedScore;
        @AuraEnabled public String status;
        @AuraEnabled public String detail;
    }
    
    public class Risk {
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String framework;
        @AuraEnabled public String severity;
        @AuraEnabled public String remediation;
        @AuraEnabled public String nodeId;
    }
    
    /**
     * Calculate comprehensive readiness score
     */
    @AuraEnabled(cacheable=true)
    public static ScoreResult calculateReadinessScore() {
        ScoreResult result = new ScoreResult();
        
        try {
            // Calculate individual factors
            ScoreFactor permissionFactor = calculatePermissionSprawlScore();
            ScoreFactor auditFactor = calculateAuditTrailScore();
            ScoreFactor driftFactor = calculateConfigDriftScore();
            ScoreFactor encryptionFactor = calculateEncryptionScore();
            ScoreFactor policyFactor = calculatePolicyComplianceScore();
            
            result.factors.add(permissionFactor);
            result.factors.add(auditFactor);
            result.factors.add(driftFactor);
            result.factors.add(encryptionFactor);
            result.factors.add(policyFactor);
            
            // Calculate weighted overall score
            result.overallScore = (
                permissionFactor.weightedScore +
                auditFactor.weightedScore +
                driftFactor.weightedScore +
                encryptionFactor.weightedScore +
                policyFactor.weightedScore
            ).setScale(1);
            
            // Determine rating
            result.rating = SolentraConstants.getRatingFromScore(result.overallScore);
            
            // Calculate framework-specific scores
            result.frameworkScores = calculateFrameworkScores(result.factors);
            
            // Get top risks
            result.topRisks = getTopRisks();
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, SolentraConstants.LOG_PREFIX + 'calculateReadinessScore error: ' + e.getMessage());
            throw new AuraHandledException('Error calculating readiness score: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * Calculate Permission Sprawl Score (30% weight)
     * Measures: Users with Modify All Data, View All Data, elevated permissions
     */
    private static ScoreFactor calculatePermissionSprawlScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Permission Sprawl';
        factor.weight = WEIGHT_PERMISSION_SPRAWL;
        
        // Count users with elevated permissions
        Integer elevatedUsers = [
            SELECT COUNT() FROM PermissionSetAssignment
            WHERE PermissionSet.PermissionsModifyAllData = true
            OR PermissionSet.PermissionsViewAllData = true
        ];
        
        // Count total active users
        Integer totalUsers = [SELECT COUNT() FROM User WHERE IsActive = true];
        
        // Calculate percentage of users with elevated access
        Decimal elevatedPercentage = totalUsers > 0 
            ? (Decimal.valueOf(elevatedUsers) / Decimal.valueOf(totalUsers)) * 100 
            : 0;
        
        // Score inversely: fewer elevated users = higher score
        if (elevatedPercentage <= 5) {
            factor.score = 100;
            factor.status = SolentraConstants.RATING_EXCELLENT;
        } else if (elevatedPercentage <= 10) {
            factor.score = 80;
            factor.status = SolentraConstants.RATING_GOOD;
        } else if (elevatedPercentage <= 20) {
            factor.score = 60;
            factor.status = 'WARNING';
        } else if (elevatedPercentage <= 30) {
            factor.score = 40;
            factor.status = SolentraConstants.RATING_CRITICAL;
        } else {
            factor.score = 20;
            factor.status = SolentraConstants.RATING_CRITICAL;
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        factor.detail = elevatedUsers + ' users (' + elevatedPercentage.setScale(1) + '%) have elevated permissions';
        
        return factor;
    }
    
    /**
     * Calculate Audit Trail Coverage Score (25% weight)
     * Measures: Field History Tracking on sensitive objects
     */
    private static ScoreFactor calculateAuditTrailScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Audit Trail Coverage';
        factor.weight = WEIGHT_AUDIT_TRAIL;
        
        // Get custom objects that might contain sensitive data
        List<EntityDefinition> sensitiveObjects = [
            SELECT QualifiedApiName, Label
            FROM EntityDefinition
            WHERE QualifiedApiName LIKE '%Patient%'
            OR QualifiedApiName LIKE '%Health%'
            OR QualifiedApiName LIKE '%Medical%'
            OR QualifiedApiName LIKE '%PHI%'
            OR QualifiedApiName LIKE '%Financial%'
            OR QualifiedApiName LIKE '%Payment%'
            LIMIT 20
        ];
        
        // Check Field History Tracking via compliance graph
        Integer objectsWithHistory = [
            SELECT COUNT() FROM Solentra_Compliance_Graph__b
            WHERE Entity_Type__c = :SolentraConstants.ENTITY_FIELD_HISTORY
            AND Timestamp__c >= LAST_N_DAYS:30
        ];
        
        Integer totalSensitiveObjects = sensitiveObjects.size();
        
        if (totalSensitiveObjects == 0) {
            factor.score = 75;
            factor.status = SolentraConstants.RATING_GOOD;
            factor.detail = 'No PHI/PII objects detected for tracking';
        } else {
            Decimal coverage = (Decimal.valueOf(objectsWithHistory) / Decimal.valueOf(totalSensitiveObjects)) * 100;
            
            if (coverage >= 90) {
                factor.score = 100;
                factor.status = SolentraConstants.RATING_EXCELLENT;
            } else if (coverage >= 70) {
                factor.score = 80;
                factor.status = SolentraConstants.RATING_GOOD;
            } else if (coverage >= 50) {
                factor.score = 60;
                factor.status = 'WARNING';
            } else {
                factor.score = 40;
                factor.status = SolentraConstants.RATING_CRITICAL;
            }
            
            factor.detail = objectsWithHistory + ' of ' + totalSensitiveObjects + ' sensitive objects have Field History enabled';
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        return factor;
    }
    
    /**
     * Calculate Configuration Drift Score (20% weight)
     * Measures: Unreviewed high-risk changes in last 30 days
     */
    private static ScoreFactor calculateConfigDriftScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Configuration Drift';
        factor.weight = WEIGHT_CONFIG_DRIFT;
        
        // Count unreviewed high-risk changes
        Integer unreviewedHighRisk = [
            SELECT COUNT() FROM Solentra_Compliance_Graph__b
            WHERE Risk_Score__c >= :SolentraConstants.RISK_THRESHOLD_HIGH
            AND Human_Adjudicated__c = false
            AND Timestamp__c >= LAST_N_DAYS:30
        ];
        
        // Count total changes
        Integer totalChanges = [
            SELECT COUNT() FROM Solentra_Compliance_Graph__b
            WHERE Timestamp__c >= LAST_N_DAYS:30
        ];
        
        // Score based on unreviewed high-risk changes
        if (unreviewedHighRisk == 0) {
            factor.score = 100;
            factor.status = SolentraConstants.RATING_EXCELLENT;
        } else if (unreviewedHighRisk <= 5) {
            factor.score = 80;
            factor.status = SolentraConstants.RATING_GOOD;
        } else if (unreviewedHighRisk <= 15) {
            factor.score = 60;
            factor.status = 'WARNING';
        } else if (unreviewedHighRisk <= 30) {
            factor.score = 40;
            factor.status = SolentraConstants.RATING_CRITICAL;
        } else {
            factor.score = 20;
            factor.status = SolentraConstants.RATING_CRITICAL;
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        factor.detail = unreviewedHighRisk + ' unreviewed high-risk changes (of ' + totalChanges + ' total)';
        
        return factor;
    }
    
    /**
     * Calculate Encryption Score (15% weight)
     * Measures: Shield Platform Encryption status on sensitive fields
     */
    private static ScoreFactor calculateEncryptionScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Encryption Status';
        factor.weight = WEIGHT_ENCRYPTION;
        
        Boolean shieldEnabled = false;
        
        try {
            // Try to detect Shield encryption by querying for encrypted field info
            List<Solentra_Compliance_Graph__b> encryptionNodes = [
                SELECT Id FROM Solentra_Compliance_Graph__b
                WHERE Entity_Type__c = :SolentraConstants.ENTITY_ENCRYPTION
                AND Timestamp__c >= LAST_N_DAYS:90
                LIMIT 1
            ];
            shieldEnabled = !encryptionNodes.isEmpty();
        } catch (Exception e) {
            shieldEnabled = false;
        }
        
        if (shieldEnabled) {
            factor.score = 90;
            factor.status = SolentraConstants.RATING_EXCELLENT;
            factor.detail = 'Shield Platform Encryption is enabled';
        } else {
            factor.score = 50;
            factor.status = 'WARNING';
            factor.detail = 'Shield Platform Encryption not detected - recommended for PHI/PII';
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        return factor;
    }
    
    /**
     * Calculate Policy Compliance Score (10% weight)
     * Measures: OWD settings, session timeout, password policies
     */
    private static ScoreFactor calculatePolicyComplianceScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Policy Compliance';
        factor.weight = WEIGHT_POLICY;
        
        Integer policyViolations = 0;
        
        // Check for overly permissive sharing rules
        Integer publicOWD = [
            SELECT COUNT() FROM Solentra_Compliance_Graph__b
            WHERE Entity_Type__c = :SolentraConstants.ENTITY_SHARING_RULE
            AND Drift_Category__c = :SolentraConstants.DRIFT_POLICY_VIOLATION
            AND Timestamp__c >= LAST_N_DAYS:90
        ];
        
        if (publicOWD > 0) {
            policyViolations += publicOWD;
        }
        
        // Check for recent policy violations
        Integer recentViolations = [
            SELECT COUNT() FROM Solentra_Compliance_Graph__b
            WHERE Drift_Category__c = :SolentraConstants.DRIFT_POLICY_VIOLATION
            AND Timestamp__c >= LAST_N_DAYS:30
        ];
        
        if (recentViolations > 0) {
            policyViolations += recentViolations;
        }
        
        // Score based on violations
        if (policyViolations == 0) {
            factor.score = 100;
            factor.status = SolentraConstants.RATING_EXCELLENT;
            factor.detail = 'No policy violations detected';
        } else if (policyViolations <= 3) {
            factor.score = 80;
            factor.status = SolentraConstants.RATING_GOOD;
            factor.detail = policyViolations + ' minor policy issue(s)';
        } else if (policyViolations <= 10) {
            factor.score = 60;
            factor.status = 'WARNING';
            factor.detail = policyViolations + ' policy violation(s) require attention';
        } else {
            factor.score = 40;
            factor.status = SolentraConstants.RATING_CRITICAL;
            factor.detail = policyViolations + ' policy violations - immediate action required';
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        return factor;
    }
    
    /**
     * Calculate framework-specific scores
     */
    private static Map<String, Decimal> calculateFrameworkScores(List<ScoreFactor> factors) {
        Map<String, Decimal> scores = new Map<String, Decimal>();
        
        // Get factor scores
        Decimal permissionScore = factors[0].score;
        Decimal auditScore = factors[1].score;
        Decimal driftScore = factors[2].score;
        Decimal encryptionScore = factors[3].score;
        Decimal policyScore = factors[4].score;
        
        // HIPAA: Heavy emphasis on audit trails and encryption (PHI protection)
        scores.put(SolentraConstants.FRAMEWORK_HIPAA, (
            permissionScore * 0.25 +
            auditScore * 0.35 +
            driftScore * 0.15 +
            encryptionScore * 0.20 +
            policyScore * 0.05
        ).setScale(1));
        
        // SOC2: Balanced emphasis on access controls and change management
        scores.put(SolentraConstants.FRAMEWORK_SOC2, (
            permissionScore * 0.30 +
            auditScore * 0.20 +
            driftScore * 0.30 +
            encryptionScore * 0.10 +
            policyScore * 0.10
        ).setScale(1));
        
        // NIST: Focus on access controls and policy compliance
        scores.put(SolentraConstants.FRAMEWORK_NIST, (
            permissionScore * 0.30 +
            auditScore * 0.20 +
            driftScore * 0.20 +
            encryptionScore * 0.15 +
            policyScore * 0.15
        ).setScale(1));
        
        // FedRAMP: Strict requirements across all factors
        scores.put(SolentraConstants.FRAMEWORK_FEDRAMP, (
            permissionScore * 0.25 +
            auditScore * 0.25 +
            driftScore * 0.20 +
            encryptionScore * 0.20 +
            policyScore * 0.10
        ).setScale(1));
        
        // GDPR: Focus on access controls and audit trails (data subject rights)
        scores.put(SolentraConstants.FRAMEWORK_GDPR, (
            permissionScore * 0.30 +
            auditScore * 0.30 +
            driftScore * 0.15 +
            encryptionScore * 0.15 +
            policyScore * 0.10
        ).setScale(1));
        
        return scores;
    }
    
    /**
     * Get top 5 compliance risks
     */
    private static List<Risk> getTopRisks() {
        List<Risk> risks = new List<Risk>();
        
        // Query highest risk items
        for (Solentra_Compliance_Graph__b node : [
            SELECT Graph_Node_Id__c, Entity_Type__c, Entity_Record_Id__c, Risk_Score__c,
                   Compliance_Framework__c, AI_Explanation__c, Drift_Category__c
            FROM Solentra_Compliance_Graph__b
            WHERE Risk_Score__c >= :SolentraConstants.RISK_THRESHOLD_HIGH
            AND Drift_Category__c = :SolentraConstants.DRIFT_POLICY_VIOLATION
            AND Human_Adjudicated__c = false
            ORDER BY Risk_Score__c DESC
            LIMIT 5
        ]) {
            Risk risk = new Risk();
            risk.nodeId = node.Graph_Node_Id__c;
            risk.framework = node.Compliance_Framework__c;
            risk.severity = SolentraConstants.getSeverityFromRiskScore(node.Risk_Score__c);
            risk.title = node.Entity_Type__c + ' violation';
            risk.description = String.isNotBlank(node.AI_Explanation__c) 
                ? node.AI_Explanation__c 
                : 'Review required for ' + node.Entity_Record_Id__c;
            risk.remediation = 'Click to view remediation options';
            risks.add(risk);
        }
        
        return risks;
    }
    
    /**
     * Get score for a specific framework
     */
    @AuraEnabled(cacheable=true)
    public static Decimal getFrameworkScore(String framework) {
        ScoreResult result = calculateReadinessScore();
        return result.frameworkScores.containsKey(framework) 
            ? result.frameworkScores.get(framework) 
            : 0;
    }
    
    /**
     * Get historical score trend (last 30 days)
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getScoreTrend() {
        List<Map<String, Object>> trend = new List<Map<String, Object>>();
        
        // Query historical adjudications to estimate past scores
        AggregateResult[] dailyStats = [
            SELECT DAY_ONLY(Timestamp__c) day, 
                   AVG(Risk_Score__c) avgRisk,
                   COUNT(Id) changes
            FROM Solentra_Compliance_Graph__b
            WHERE Timestamp__c >= LAST_N_DAYS:30
            GROUP BY DAY_ONLY(Timestamp__c)
            ORDER BY DAY_ONLY(Timestamp__c)
        ];
        
        for (AggregateResult ar : dailyStats) {
            Decimal avgRisk = (Decimal)ar.get('avgRisk');
            Decimal estimatedScore = 100 - (avgRisk != null ? avgRisk * 10 : 0);
            
            trend.add(new Map<String, Object>{
                'date' => ar.get('day'),
                'score' => estimatedScore.setScale(1),
                'changes' => ar.get('changes')
            });
        }
        
        return trend;
    }
}

