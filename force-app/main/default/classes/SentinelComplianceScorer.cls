public with sharing class SentinelComplianceScorer {
    @AuraEnabled(cacheable=true)
    public static Decimal calculateReadinessScore() {
        try {
            Decimal accessScore = calculateAccessGovernanceScore();
            Decimal configScore = calculateConfigHealthScore();
            Decimal automationScore = calculateAutomationSafetyScore();
            Decimal evidenceScore = calculateEvidenceScore();

            return (accessScore + configScore + automationScore + evidenceScore) / 4;
        } catch (Exception e) {
            throw new AuraHandledException('Error calculating readiness score: ' + e.getMessage());
        }
    }

    private static Decimal calculateAccessGovernanceScore() {
        // Simplified scoring logic
        Integer totalPermSets = [SELECT COUNT() FROM PermissionSet WHERE IsCustom = true];
        Integer documentedPermSets = [SELECT COUNT() FROM PermissionSet WHERE IsCustom = true AND Description != null];

        if (totalPermSets == 0) return 50.0;
        return (Decimal.valueOf(documentedPermSets) / Decimal.valueOf(totalPermSets)) * 100;
    }

    private static Decimal calculateConfigHealthScore() {
        // Simplified scoring logic
        Integer totalFlows = [SELECT COUNT() FROM FlowDefinitionView WHERE IsActive = true];
        Integer safeFlows = [SELECT COUNT() FROM FlowDefinitionView WHERE IsActive = true AND ProcessType = 'Workflow'];

        if (totalFlows == 0) return 75.0;
        return (Decimal.valueOf(safeFlows) / Decimal.valueOf(totalFlows)) * 100;
    }

    private static Decimal calculateAutomationSafetyScore() {
        // Simplified scoring logic - check for triggers with proper error handling
        return 80.0; // Default for now
    }

    private static Decimal calculateEvidenceScore() {
        // Check if we have recent compliance graph entries
        List<Sentinel_Compliance_Graph__b> recentEntries = [
            SELECT Id
            FROM Sentinel_Compliance_Graph__b
            WHERE Timestamp__c >= LAST_N_DAYS:30
            LIMIT 1
        ];

        return recentEntries.isEmpty() ? 0.0 : 90.0;
    }
}
