/**
 * ComplianceServiceBase
 *
 * Abstract base class for all compliance framework services.
 * Provides common functionality for gap creation, evidence collection,
 * audit logging, and policy retrieval.
 *
 * @author Elaro
 * @version 1.0
 */
public abstract with sharing class ComplianceServiceBase implements IRiskScoringService {

    // Cache for policies to avoid repeated queries
    protected Map<String, List<Compliance_Policy__mdt>> policyCache = new Map<String, List<Compliance_Policy__mdt>>();

    /**
     * Abstract method - must be implemented by each framework service
     * @return The framework identifier (e.g., 'HIPAA', 'SOC2')
     */
    public abstract String getFrameworkName();

    /**
     * Abstract method - framework-specific control evaluation
     * @return List of violations found
     */
    protected abstract List<Violation> evaluateControls();

    /**
     * Abstract method - framework-specific score multiplier
     * @return Score adjustment factor (0.0 - 1.0)
     */
    protected abstract Decimal getFrameworkMultiplier();

    /**
     * Get policies for this framework from custom metadata
     * @return List of active policies for the framework
     */
    protected List<Compliance_Policy__mdt> getPoliciesForFramework() {
        String framework = getFrameworkName();

        if (policyCache.containsKey(framework)) {
            return policyCache.get(framework);
        }

        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, MasterLabel, Framework__c, Policy_Code__c,
                   Policy_Description__c, Legal_Citation__c, Remediation_Steps__c,
                   Severity__c, Control_Category__c, Risk_Weight__c, Active__c
            FROM Compliance_Policy__mdt
            WHERE Framework__c = :framework
            AND Active__c = true
            WITH SECURITY_ENFORCED
        ];

        policyCache.put(framework, policies);
        return policies;
    }

    /**
     * Get active (non-verified) gaps for this framework
     * @return List of open compliance gaps
     */
    protected List<Compliance_Gap__c> getActiveGaps() {
        return [
            SELECT Id, Framework__c, Policy_Reference__c, Gap_Description__c,
                   Severity__c, Status__c, Risk_Score__c, Entity_Type__c,
                   Entity_Id__c, Detected_Date__c, Remediation_Owner__c,
                   Target_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Framework__c = :getFrameworkName()
            AND Status__c NOT IN ('VERIFIED', 'ACCEPTED_RISK')
            WITH SECURITY_ENFORCED
            ORDER BY Risk_Score__c DESC NULLS LAST
        ];
    }

    /**
     * Create a compliance gap record
     * @param policyReference The policy that was violated
     * @param description Description of the gap
     * @param severity Severity level (CRITICAL, HIGH, MEDIUM, LOW)
     * @param entityType Type of entity causing the gap
     * @param entityId Id of the entity
     * @param riskScore Calculated risk score (0-10)
     * @return Id of the created gap record
     */
    protected Id createGap(String policyReference, String description, String severity,
                          String entityType, String entityId, Decimal riskScore) {
        // Validate CRUD access
        if (!Schema.sObjectType.Compliance_Gap__c.isCreateable()) {
            throw new ComplianceServiceException('Insufficient permissions to create Compliance Gap records');
        }

        Compliance_Gap__c gap = new Compliance_Gap__c(
            Framework__c = getFrameworkName(),
            Policy_Reference__c = policyReference,
            Gap_Description__c = description,
            Severity__c = severity,
            Status__c = 'OPEN',
            Entity_Type__c = entityType,
            Entity_Id__c = entityId,
            Risk_Score__c = riskScore,
            Detected_Date__c = Date.today()
        );

        insert gap;
        logAuditEntry('GAP_CREATED', 'Created compliance gap: ' + policyReference, gap.Id);
        return gap.Id;
    }

    /**
     * Create a compliance evidence record
     * @param evidenceType Type of evidence
     * @param description Description of the evidence
     * @param evidenceData JSON data payload
     * @param policyReference Related policy
     * @return Id of the created evidence record
     */
    protected Id createEvidence(String evidenceType, String description,
                               String evidenceData, String policyReference) {
        // Validate CRUD access
        if (!Schema.sObjectType.Compliance_Evidence__c.isCreateable()) {
            throw new ComplianceServiceException('Insufficient permissions to create Compliance Evidence records');
        }

        Compliance_Evidence__c evidence = new Compliance_Evidence__c(
            Framework__c = getFrameworkName(),
            Evidence_Type__c = evidenceType,
            Description__c = description,
            Evidence_Data__c = evidenceData,
            Policy_Reference__c = policyReference,
            Evidence_Date__c = DateTime.now(),
            Status__c = 'COLLECTED'
        );

        insert evidence;
        logAuditEntry('EVIDENCE_COLLECTED', 'Collected evidence: ' + evidenceType, evidence.Id);
        return evidence.Id;
    }

    /**
     * Calculate base risk score using common factors
     * @param entityType Type of entity being scored
     * @param metadata Additional metadata for scoring
     * @return Base risk score (0-10)
     */
    protected Decimal calculateBaseRiskScore(String entityType, Map<String, Object> metadata) {
        Decimal score = 5.0; // Default medium risk

        // Adjust based on entity type
        if (entityType == 'PERMISSION_SET') {
            Boolean hasModifyAll = metadata.containsKey('hasModifyAll') &&
                                   (Boolean)metadata.get('hasModifyAll');
            Boolean hasViewAll = metadata.containsKey('hasViewAll') &&
                                 (Boolean)metadata.get('hasViewAll');

            if (hasModifyAll) {
                score += 3.0;
            }
            if (hasViewAll) {
                score += 2.0;
            }
        } else if (entityType == 'SHARING_RULE') {
            String accessLevel = (String)metadata.get('accessLevel');
            if (accessLevel == 'Edit') {
                score += 2.0;
            } else if (accessLevel == 'All') {
                score += 3.0;
            }
        } else if (entityType == 'FIELD') {
            Boolean isSensitive = metadata.containsKey('isSensitive') &&
                                  (Boolean)metadata.get('isSensitive');
            Boolean isEncrypted = metadata.containsKey('isEncrypted') &&
                                  (Boolean)metadata.get('isEncrypted');

            if (isSensitive && !isEncrypted) {
                score += 3.0;
            }
        }

        // Cap at 10
        return Math.min(score, 10.0);
    }

    /**
     * Log an audit entry for compliance actions
     * @param action The action performed
     * @param description Description of the action
     * @param relatedRecordId Related record Id (optional)
     */
    protected void logAuditEntry(String action, String description, Id relatedRecordId) {
        try {
            if (!Schema.sObjectType.Elaro_Audit_Log__c.isCreateable()) {
                System.debug(LoggingLevel.WARN, 'Cannot create audit log entry - insufficient permissions');
                return;
            }

            Elaro_Audit_Log__c auditLog = new Elaro_Audit_Log__c(
                Action__c = action,
                Description__c = description,
                Framework__c = getFrameworkName(),
                Related_Record_Id__c = relatedRecordId,
                User__c = UserInfo.getUserId(),
                Timestamp__c = DateTime.now()
            );

            insert auditLog;
        } catch (Exception e) {
            // Log but don't fail the main operation
            System.debug(LoggingLevel.ERROR, 'Failed to create audit log: ' + e.getMessage());
        }
    }

    /**
     * Map severity string to risk score threshold
     * @param severity Severity level string
     * @return Minimum risk score for that severity
     */
    protected Decimal getSeverityThreshold(String severity) {
        Map<String, Decimal> thresholds = new Map<String, Decimal>{
            'CRITICAL' => 9.0,
            'HIGH' => 7.0,
            'MEDIUM' => 5.0,
            'LOW' => 3.0
        };
        return thresholds.containsKey(severity) ? thresholds.get(severity) : 5.0;
    }

    /**
     * Get severity from risk score
     * @param riskScore The risk score (0-10)
     * @return Severity string
     */
    protected String getSeverityFromScore(Decimal riskScore) {
        if (riskScore >= 9.0) return 'CRITICAL';
        if (riskScore >= 7.0) return 'HIGH';
        if (riskScore >= 5.0) return 'MEDIUM';
        return 'LOW';
    }

    // ========== IRiskScoringService Implementation ==========

    /**
     * Calculate risk score for an entity
     * Implementation of IRiskScoringService
     */
    public Decimal calculateRiskScore(String entityType, String entityId, Map<String, Object> metadata) {
        Decimal baseScore = calculateBaseRiskScore(entityType, metadata);
        return baseScore * getFrameworkMultiplier();
    }

    /**
     * Get overall compliance score for the framework
     * Implementation of IRiskScoringService
     */
    public Decimal getComplianceScore() {
        List<Compliance_Policy__mdt> policies = getPoliciesForFramework();
        List<Compliance_Gap__c> gaps = getActiveGaps();

        if (policies.isEmpty()) {
            return 100.0; // No policies means fully compliant
        }

        // Calculate max possible score
        Decimal maxScore = 0;
        for (Compliance_Policy__mdt policy : policies) {
            maxScore += policy.Risk_Weight__c != null ? policy.Risk_Weight__c : 5.0;
        }

        // Calculate penalty from gaps
        Decimal penalty = 0;
        Map<String, Decimal> gapPenalties = new Map<String, Decimal>();
        for (Compliance_Gap__c gap : gaps) {
            String policyRef = gap.Policy_Reference__c;
            Decimal gapPenalty = gap.Risk_Score__c != null ? gap.Risk_Score__c : 5.0;

            // Aggregate penalties per policy
            if (!gapPenalties.containsKey(policyRef)) {
                gapPenalties.put(policyRef, 0);
            }
            gapPenalties.put(policyRef, gapPenalties.get(policyRef) + gapPenalty);
        }

        // Sum penalties (capped at policy weight)
        for (String policyRef : gapPenalties.keySet()) {
            Decimal policyWeight = 5.0; // Default weight
            for (Compliance_Policy__mdt policy : policies) {
                if (policy.DeveloperName == policyRef || policy.Policy_Code__c == policyRef) {
                    policyWeight = policy.Risk_Weight__c != null ? policy.Risk_Weight__c : 5.0;
                    break;
                }
            }
            penalty += Math.min(gapPenalties.get(policyRef), policyWeight);
        }

        // Calculate score
        Decimal score = ((maxScore - penalty) / maxScore) * 100;
        return Math.max(0, Math.min(100, score * getFrameworkMultiplier()));
    }

    /**
     * Get list of violations for the framework
     * Implementation of IRiskScoringService
     */
    public List<Violation> getViolations() {
        return evaluateControls();
    }

    /**
     * Violation data structure
     */
    public class Violation {
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String severity;
        @AuraEnabled public String policyReference;
        @AuraEnabled public String remediation;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public String entityType;
        @AuraEnabled public String entityId;

        public Violation(String title, String description, String severity,
                        String policyReference, String remediation, Decimal riskScore) {
            this.title = title;
            this.description = description;
            this.severity = severity;
            this.policyReference = policyReference;
            this.remediation = remediation;
            this.riskScore = riskScore;
        }
    }

    /**
     * Custom exception for compliance service errors
     */
    public class ComplianceServiceException extends Exception {}
}
