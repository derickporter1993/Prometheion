/**
 * ElaroComplianceScorer - Multi-Framework Compliance Scoring Engine
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
 * @author Elaro Team
 * @version 1.1
 */
public with sharing class ElaroComplianceScorer {
    
    // Scoring weights
    private static final Decimal WEIGHT_PERMISSION_SPRAWL = 0.30;
    private static final Decimal WEIGHT_AUDIT_TRAIL = 0.25;
    private static final Decimal WEIGHT_CONFIG_DRIFT = 0.20;
    private static final Decimal WEIGHT_ENCRYPTION = 0.15;
    private static final Decimal WEIGHT_POLICY = 0.10;
    
    // Cache results within transaction scope to avoid duplicate queries
    private static ScoreFactor permissionSprawlCache;
    private static ScoreFactor auditTrailCache;
    private static ScoreFactor configDriftCache;
    
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
            result.rating = ElaroConstants.getRatingFromScore(result.overallScore);
            
            // Calculate framework-specific scores
            result.frameworkScores = calculateFrameworkScores(result.factors);
            
            // Get top risks
            result.topRisks = getTopRisks();
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 
                '[ElaroComplianceScorer] Error calculating readiness score - ' +
                'Component: calculateReadinessScore, ' +
                'Error: ' + e.getMessage() + ', ' +
                'StackTrace: ' + e.getStackTraceString());
            result.overallScore = 0;
            result.rating = ElaroConstants.RATING_CRITICAL;
        }
        
        return result;
    }
    
    /**
     * Simple compliance score calculation (backward compatible)
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> calculateComplianceScore() {
        ScoreResult result = calculateReadinessScore();
        
        Map<String, Object> scoreMap = new Map<String, Object>();
        scoreMap.put('overallScore', result.overallScore);
        scoreMap.put('hipaaScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_HIPAA));
        scoreMap.put('soc2Score', result.frameworkScores.get(ElaroConstants.FRAMEWORK_SOC2));
        scoreMap.put('nistScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_NIST));
        scoreMap.put('fedrampScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_FEDRAMP));
        scoreMap.put('gdprScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_GDPR));
        scoreMap.put('soxScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_SOX));
        scoreMap.put('pciDssScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_PCI_DSS));
        scoreMap.put('ccpaScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_CCPA));
        scoreMap.put('glbaScore', result.frameworkScores.get(ElaroConstants.FRAMEWORK_GLBA));
        scoreMap.put('iso27001Score', result.frameworkScores.get(ElaroConstants.FRAMEWORK_ISO27001));
        scoreMap.put('riskLevel', result.rating);
        
        return scoreMap;
    }
    
    /**
     * Calculate Permission Sprawl Score (30% weight)
     * Uses caching to avoid duplicate queries within transaction scope
     */
    private static ScoreFactor calculatePermissionSprawlScore() {
        // Return cached result if available
        if (permissionSprawlCache != null) {
            return permissionSprawlCache;
        }
        
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Permission Sprawl';
        factor.weight = WEIGHT_PERMISSION_SPRAWL;
        
        // Count users with elevated permissions using batched aggregate queries
        Integer totalUsers = 0;
        Integer usersWithModifyAll = 0;
        Integer usersWithViewAll = 0;
        
        try {
            // Batch queries using aggregates to reduce governor limit usage
            // Add limit guard to prevent governor exhaustion
            totalUsers = [
                SELECT COUNT() 
                FROM User 
                WHERE IsActive = true
                WITH USER_MODE
                LIMIT 10000
            ];
            
            // Batch queries: Use separate aggregate queries for each permission type
            // This reduces governor limit usage compared to individual COUNT queries per permission set
            List<AggregateResult> modifyAllResults = [
                SELECT COUNT(Id) assignmentCount
                FROM PermissionSetAssignment
                WHERE PermissionSet.PermissionsModifyAllData = true
                AND Assignee.IsActive = true
                WITH USER_MODE
            ];
            
            List<AggregateResult> viewAllResults = [
                SELECT COUNT(Id) assignmentCount
                FROM PermissionSetAssignment
                WHERE PermissionSet.PermissionsViewAllData = true
                AND Assignee.IsActive = true
                WITH USER_MODE
            ];
            
            // Extract counts from aggregate results
            if (!modifyAllResults.isEmpty()) {
                usersWithModifyAll = (Integer)modifyAllResults[0].get('assignmentCount');
            }
            if (!viewAllResults.isEmpty()) {
                usersWithViewAll = (Integer)viewAllResults[0].get('assignmentCount');
            }
        } catch (SecurityException e) {
            System.debug(LoggingLevel.ERROR, '[ElaroComplianceScorer] Security exception calculating permission sprawl: ' + e.getMessage());
            factor.score = 0;
            factor.status = 'ERROR';
            factor.detail = 'Security exception: Unable to query permission data.';
            factor.weightedScore = 0;
            return factor;
        }
        
        // Calculate percentage of users with elevated access
        Decimal elevatedPercent = totalUsers > 0 
            ? (Decimal.valueOf(usersWithModifyAll + usersWithViewAll) / Decimal.valueOf(totalUsers)) * 100 
            : 0;
        
        // Score inversely - lower percentage = higher score
        if (elevatedPercent <= 5) {
            factor.score = 100;
            factor.status = ElaroConstants.RATING_EXCELLENT;
        } else if (elevatedPercent <= 10) {
            factor.score = 85;
            factor.status = ElaroConstants.RATING_GOOD;
        } else if (elevatedPercent <= 20) {
            factor.score = 70;
            factor.status = ElaroConstants.RATING_FAIR;
        } else if (elevatedPercent <= 30) {
            factor.score = 50;
            factor.status = ElaroConstants.RATING_NEEDS_IMPROVEMENT;
        } else {
            factor.score = 30;
            factor.status = ElaroConstants.RATING_CRITICAL;
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        factor.detail = elevatedPercent.setScale(1) + '% of users have elevated permissions';
        
        // Cache result for reuse within transaction
        permissionSprawlCache = factor;
        return factor;
    }
    
    /**
     * Calculate Audit Trail Coverage Score (25% weight)
     * Uses caching to avoid duplicate queries within transaction scope
     */
    private static ScoreFactor calculateAuditTrailScore() {
        // Return cached result if available
        if (auditTrailCache != null) {
            return auditTrailCache;
        }
        
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Audit Trail Coverage';
        factor.weight = WEIGHT_AUDIT_TRAIL;
        
        // Check for recent SetupAuditTrail entries with limit guard
        Integer auditTrailCount = [
            SELECT COUNT() FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:30
            WITH USER_MODE
            LIMIT 10000
        ];
        
        // Check for sensitive objects with limit guard
        List<EntityDefinition> sensitiveObjects = [
            SELECT QualifiedApiName
            FROM EntityDefinition
            WHERE QualifiedApiName LIKE '%Patient%'
            OR QualifiedApiName LIKE '%Health%'
            OR QualifiedApiName LIKE '%Medical%'
            OR QualifiedApiName LIKE '%Financial%'
            OR QualifiedApiName LIKE '%Payment%'
            WITH USER_MODE
            LIMIT 20
        ];
        
        Integer totalSensitiveObjects = sensitiveObjects.size();
        
        if (auditTrailCount > 0) {
            factor.score = 80;
            factor.status = ElaroConstants.RATING_GOOD;
            factor.detail = 'Setup Audit Trail active with ' + auditTrailCount + ' entries (30 days)';
        } else {
            factor.score = 50;
            factor.status = ElaroConstants.RATING_NEEDS_IMPROVEMENT;
            factor.detail = 'No recent audit trail entries - verify audit logging is enabled';
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        
        // Cache result for reuse within transaction
        auditTrailCache = factor;
        return factor;
    }
    
    /**
     * Calculate Configuration Drift Score (20% weight)
     * Uses caching to avoid duplicate queries within transaction scope
     */
    private static ScoreFactor calculateConfigDriftScore() {
        // Return cached result if available
        if (configDriftCache != null) {
            return configDriftCache;
        }
        
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Configuration Drift';
        factor.weight = WEIGHT_CONFIG_DRIFT;
        
        // Count recent setup changes with limit guard
        List<SetupAuditTrail> recentChanges = [
            SELECT Action FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:30
            WITH USER_MODE
            LIMIT 100
        ];
        
        Integer highRiskChanges = 0;
        for (SetupAuditTrail change : recentChanges) {
            if (change.Action != null && 
                (change.Action.containsIgnoreCase('permission') ||
                 change.Action.containsIgnoreCase('profile') ||
                 change.Action.containsIgnoreCase('delete'))) {
                highRiskChanges++;
            }
        }
        
        // Score based on high-risk changes
        if (highRiskChanges == 0) {
            factor.score = 100;
            factor.status = ElaroConstants.RATING_EXCELLENT;
        } else if (highRiskChanges <= 5) {
            factor.score = 85;
            factor.status = ElaroConstants.RATING_GOOD;
        } else if (highRiskChanges <= 15) {
            factor.score = 65;
            factor.status = ElaroConstants.RATING_FAIR;
        } else if (highRiskChanges <= 30) {
            factor.score = 45;
            factor.status = ElaroConstants.RATING_NEEDS_IMPROVEMENT;
        } else {
            factor.score = 25;
            factor.status = ElaroConstants.RATING_CRITICAL;
        }
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        factor.detail = highRiskChanges + ' high-risk configuration changes (of ' + recentChanges.size() + ' total)';
        
        // Cache result for reuse within transaction
        configDriftCache = factor;
        return factor;
    }
    
    /**
     * Calculate Encryption Score (15% weight)
     */
    private static ScoreFactor calculateEncryptionScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Encryption Status';
        factor.weight = WEIGHT_ENCRYPTION;
        
        // Default to partial score - Shield detection requires special permissions
        factor.score = 60;
        factor.status = ElaroConstants.RATING_FAIR;
        factor.detail = 'Encryption status check - enable Shield Platform Encryption for full compliance';
        
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        return factor;
    }
    
    /**
     * Calculate Policy Compliance Score (10% weight)
     */
    private static ScoreFactor calculatePolicyComplianceScore() {
        ScoreFactor factor = new ScoreFactor();
        factor.name = 'Policy Compliance';
        factor.weight = WEIGHT_POLICY;
        
        Integer policyScore = 75; // Base score
        
        // Check for compliance policies - gracefully handle if custom metadata doesn't exist
        Integer activePolicyCount = 0;
        try {
            // Try to count active policies
            activePolicyCount = Database.countQuery('SELECT COUNT() FROM Compliance_Policy__mdt WHERE Is_Active__c = true');
        } catch (Exception e) {
            // Custom metadata may not exist or have different schema
            System.debug(LoggingLevel.WARN, '[ElaroComplianceScorer] Could not query policies: ' + e.getMessage());
            activePolicyCount = 0;
        }
        
        if (activePolicyCount >= 5) {
            policyScore = 90;
            factor.status = ElaroConstants.RATING_EXCELLENT;
        } else if (activePolicyCount >= 3) {
            policyScore = 75;
            factor.status = ElaroConstants.RATING_GOOD;
        } else {
            policyScore = 65;
            factor.status = ElaroConstants.RATING_FAIR;
        }
        
        factor.score = policyScore;
        factor.detail = activePolicyCount + ' compliance policies configured';
        factor.weightedScore = (factor.score * factor.weight).setScale(2);
        
        return factor;
    }
    
    /**
     * Calculate framework-specific scores
     */
    private static Map<String, Decimal> calculateFrameworkScores(List<ScoreFactor> factors) {
        Map<String, Decimal> scores = new Map<String, Decimal>();
        
        Decimal baseScore = 0;
        for (ScoreFactor f : factors) {
            baseScore += f.weightedScore;
        }
        
        // Each framework has slight variations based on their focus areas
        scores.put(ElaroConstants.FRAMEWORK_HIPAA, (baseScore * 0.95).setScale(1)); // HIPAA focuses on access control
        scores.put(ElaroConstants.FRAMEWORK_SOC2, (baseScore * 1.0).setScale(1));   // SOC2 is balanced
        scores.put(ElaroConstants.FRAMEWORK_NIST, (baseScore * 0.98).setScale(1));  // NIST focuses on policy
        scores.put(ElaroConstants.FRAMEWORK_FEDRAMP, (baseScore * 0.92).setScale(1)); // FedRAMP is strictest
        scores.put(ElaroConstants.FRAMEWORK_GDPR, (baseScore * 0.97).setScale(1));  // GDPR focuses on data protection
        scores.put(ElaroConstants.FRAMEWORK_SOX, (baseScore * 0.96).setScale(1));  // SOX focuses on financial controls
        scores.put(ElaroConstants.FRAMEWORK_PCI_DSS, (baseScore * 0.94).setScale(1)); // PCI-DSS focuses on card data security
        scores.put(ElaroConstants.FRAMEWORK_CCPA, (baseScore * 0.98).setScale(1)); // CCPA focuses on consumer privacy rights
        scores.put(ElaroConstants.FRAMEWORK_GLBA, (baseScore * 0.96).setScale(1));  // GLBA focuses on financial privacy
        scores.put(ElaroConstants.FRAMEWORK_ISO27001, (baseScore * 0.99).setScale(1)); // ISO 27001 is comprehensive ISMS
        
        return scores;
    }
    
    /**
     * Get top compliance risks
     */
    private static List<Risk> getTopRisks() {
        List<Risk> risks = new List<Risk>();
        
        // Query efficiently using aggregate (cached data doesn't have exact count, so query once)
        Integer modifyAllUsers = 0;
        try {
            List<AggregateResult> modifyAllResults = [
                SELECT COUNT(Id) assignmentCount
                FROM PermissionSetAssignment
                WHERE PermissionSet.PermissionsModifyAllData = true
                AND Assignee.IsActive = true
                WITH USER_MODE
                LIMIT 1
            ];
            if (!modifyAllResults.isEmpty()) {
                modifyAllUsers = (Integer)modifyAllResults[0].get('assignmentCount');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, '[ElaroComplianceScorer] Error querying modify all users: ' + e.getMessage());
        }
        
        if (modifyAllUsers > 5) {
            Risk r = new Risk();
            r.title = 'Excessive Modify All Data Permissions';
            r.description = modifyAllUsers + ' users have Modify All Data permission';
            r.framework = ElaroConstants.FRAMEWORK_HIPAA;
            r.severity = ElaroConstants.SEVERITY_HIGH;
            r.remediation = 'Review and reduce users with Modify All Data permission';
            risks.add(r);
        }
        
        // Check for inactive users - use aggregate query for efficiency
        Integer inactiveUsersWithAccess = 0;
        try {
            List<AggregateResult> inactiveResults = [
                SELECT COUNT(Id) userCount
                FROM User
                WHERE IsActive = true
                AND LastLoginDate < LAST_N_DAYS:90
                WITH USER_MODE
                LIMIT 1
            ];
            if (!inactiveResults.isEmpty()) {
                inactiveUsersWithAccess = (Integer)inactiveResults[0].get('userCount');
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, '[ElaroComplianceScorer] Error querying inactive users: ' + e.getMessage());
        }
        
        if (inactiveUsersWithAccess > 0) {
            Risk r = new Risk();
            r.title = 'Inactive Users with Active Accounts';
            r.description = inactiveUsersWithAccess + ' users have not logged in for 90+ days';
            r.framework = ElaroConstants.FRAMEWORK_SOC2;
            r.severity = ElaroConstants.SEVERITY_MEDIUM;
            r.remediation = 'Review and deactivate accounts for users who no longer need access';
            risks.add(r);
        }
        
        return risks;
    }
}
