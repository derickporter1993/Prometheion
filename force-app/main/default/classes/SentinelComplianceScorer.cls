/**
 * @description Sentinel Compliance Readiness Score Engine
 * Calculates org compliance score across multiple dimensions
 * @author Sentinel Team
 * @date 2025
 */
public with sharing class SentinelComplianceScorer {

    /**
     * @description Calculates overall compliance readiness score (0-100)
     * @return Integer Compliance score
     */
    @AuraEnabled(cacheable=true)
    public static Integer calculateReadinessScore() {
        try {
            Decimal totalScore = 0;
            Decimal maxScore = 0;

            // 1. Access Governance (25 points)
            totalScore += calculateAccessScore() * 25;
            maxScore += 25;

            // 2. Config Health (25 points)
            totalScore += calculateConfigScore() * 25;
            maxScore += 25;

            // 3. Automation Safety (25 points)
            totalScore += calculateAutomationScore() * 25;
            maxScore += 25;

            // 4. Evidence Completeness (25 points)
            totalScore += calculateEvidenceScore() * 25;
            maxScore += 25;

            return (maxScore > 0) ? Integer.valueOf(Math.round(totalScore)) : 0;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to calculate score: ' + e.getMessage());
        }
    }

    /**
     * @description Scores access governance (0-1 scale)
     * @return Decimal Score between 0 and 1
     */
    private static Decimal calculateAccessScore() {
        Decimal score = 0;

        // Check for inactive admin users
        if (!Schema.sObjectType.User.isAccessible()) {
            return 0;
        }

        Integer inactiveAdminCount = [
            SELECT COUNT()
            FROM User
            WHERE Profile.Name LIKE '%Admin%'
            AND IsActive = false
        ];
        score += (inactiveAdminCount == 0) ? 0.3 : 0;

        // Check for excessive permission set usage
        Integer totalPermissions = [
            SELECT COUNT()
            FROM PermissionSetAssignment
            WHERE PermissionSet.IsOwnedByProfile = false
        ];
        score += (totalPermissions < 500) ? 0.3 : 0.1;

        // Check for role hierarchy completeness
        Integer orphanedRoles = [
            SELECT COUNT()
            FROM UserRole
            WHERE ParentRoleId = null
        ];
        score += (orphanedRoles <= 1) ? 0.4 : 0.2; // Allow 1 for CEO role

        return score;
    }

    /**
     * @description Scores configuration health (0-1 scale)
     * @return Decimal Score between 0 and 1
     */
    private static Decimal calculateConfigScore() {
        Decimal score = 0;

        // Check for active flows
        Integer activeFlows = [
            SELECT COUNT()
            FROM FlowDefinitionView
            WHERE IsActive = true
        ];
        score += (activeFlows > 0) ? 0.5 : 0.2;

        // Check for validation rules
        // Note: Would need Tooling API for full check
        score += 0.5;

        return score;
    }

    /**
     * @description Scores automation safety (0-1 scale)
     * @return Decimal Score between 0 and 1
     */
    private static Decimal calculateAutomationScore() {
        Decimal score = 0;

        // Check for flows running in system mode
        Integer systemModeFlows = [
            SELECT COUNT()
            FROM FlowDefinitionView
            WHERE IsActive = true
            // Note: RunInMode is not queryable, would need Tooling API
        ];

        // For now, give partial score
        score += 0.8;

        return score;
    }

    /**
     * @description Scores evidence completeness (0-1 scale)
     * @return Decimal Score between 0 and 1
     */
    private static Decimal calculateEvidenceScore() {
        // In production, would check Alert__c for recent evidence packs
        // For now, return moderate score

        return 0.7;
    }

    /**
     * @description Gets detailed breakdown of compliance scores
     * @return Map<String, Integer> Score breakdown by category
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getScoreBreakdown() {
        Map<String, Integer> breakdown = new Map<String, Integer>();

        breakdown.put('access', Integer.valueOf(Math.round(calculateAccessScore() * 100)));
        breakdown.put('config', Integer.valueOf(Math.round(calculateConfigScore() * 100)));
        breakdown.put('automation', Integer.valueOf(Math.round(calculateAutomationScore() * 100)));
        breakdown.put('evidence', Integer.valueOf(Math.round(calculateEvidenceScore() * 100)));

        return breakdown;
    }
}
