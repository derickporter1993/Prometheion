/**
 * SOC 2 Compliance Service
 * Implements SOC 2 Type II compliance checks and risk scoring
 * 
 * SOC 2 Common Criteria:
 * - CC6.1: Logical and physical access controls
 * - CC6.2: Prior to issuing credentials
 * - CC6.3: Access credentials and identification information
 * - CC7.1: System configuration changes
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class ElaroSOC2ComplianceService implements IRiskScoringService {
    private static final String FRAMEWORK = ElaroConstants.FRAMEWORK_SOC2;
    
    public Decimal calculateRiskScore(String entityType, String entityId, Map<String, Object> metadata) {
        Decimal score = ElaroConstants.BASE_RISK_SCORE;
        
        // SOC2-specific risk factors
        if (entityType == ElaroConstants.ENTITY_PERMISSION_SET) {
            // SOC2 focuses on access control and change management
            Object permCount = metadata.get('objectPermissionCount');
            if (permCount != null) {
                Integer count = Integer.valueOf(permCount);
                if (count > 40) {
                    score += 2.5; // SOC2 is slightly less strict than HIPAA
                }
            }
        }
        
        return Math.min(score, ElaroConstants.RISK_SCORE_MAX);
    }
    
    public Decimal getComplianceScore() {
        return ElaroComplianceScorer.calculateReadinessScore().frameworkScores.get(FRAMEWORK);
    }
    
    public List<Violation> getViolations() {
        List<Violation> violations = new List<Violation>();
        
        // Check for SOC2 violations
        // Example: Unreviewed configuration changes
        List<SetupAuditTrail> recentChanges = [
            SELECT CreatedDate, CreatedBy.Name, Action, Section
            FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:30
            AND (Action LIKE '%permission%' OR Action LIKE '%sharing%')
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];
        
        for (SetupAuditTrail sat : recentChanges) {
            Violation v = new Violation();
            v.title = 'Unreviewed Change: ' + sat.Section;
            v.description = 'Configuration change made without documented approval process';
            v.severity = ElaroConstants.SEVERITY_MEDIUM;
            v.remediation = 'Implement change management process with approval workflow';
            v.entityId = sat.Id;
            v.riskScore = 6.0;
            violations.add(v);
        }
        
        return violations;
    }
    
    public String getFrameworkName() {
        return FRAMEWORK;
    }
}
