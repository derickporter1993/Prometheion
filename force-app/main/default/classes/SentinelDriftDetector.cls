/**
 * @description Sentinel Drift Detection Engine
 * Detects unauthorized configuration changes and policy violations
 * @author Sentinel Team
 * @date 2025
 */
public with sharing class SentinelDriftDetector {

    @TestVisible
    private static final String MONITOR_SET = 'SentinelMonitored';

    /**
     * @description Detects configuration drift by comparing current state to last baseline
     * @return List<SObject> Drift alerts (will be Alert__c when object is deployed)
     */
    public static List<SObject> detectDrift() {
        List<SObject> alerts = new List<SObject>();

        // Note: This returns SObject until Alert__c custom object is deployed
        // In production, cast to List<Alert__c>

        try {
            // 1. Check permission set changes
            alerts.addAll(checkPermissionSetChanges());

            // 2. Check sharing rule changes
            alerts.addAll(checkSharingRuleChanges());

            // 3. Check flow changes
            alerts.addAll(checkFlowChanges());

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Drift detection failed: ' + e.getMessage());
        }

        return alerts;
    }

    /**
     * @description Detects risky permission set assignments
     * @return List<SObject> Permission drift alerts
     */
    private static List<SObject> checkPermissionSetChanges() {
        List<SObject> alerts = new List<SObject>();
        DateTime lastRun = getLastBaselineTimestamp();

        // Query recent permission set assignments
        List<PermissionSetAssignment> changes = [
            SELECT Id, AssigneeId, Assignee.Name, PermissionSetId, PermissionSet.Name, CreatedDate
            FROM PermissionSetAssignment
            WHERE CreatedDate > :lastRun
            AND PermissionSet.IsOwnedByProfile = false
            LIMIT 200
        ];

        for (PermissionSetAssignment psa : changes) {
            // Check if this is a restricted permission set
            if (isRestrictedPermissionSet(psa.PermissionSet.Name)) {
                // Create alert record (placeholder until Alert__c is deployed)
                // In production: new Alert__c(...)
                System.debug('HIGH SEVERITY: User ' + psa.Assignee.Name + ' assigned to ' + psa.PermissionSet.Name);
            }
        }

        return alerts;
    }

    /**
     * @description Detects sharing rule modifications
     * @return List<SObject> Sharing drift alerts
     */
    private static List<SObject> checkSharingRuleChanges() {
        List<SObject> alerts = new List<SObject>();

        // Note: Sharing rules are metadata - would need Tooling API or Setup Audit Trail
        // Placeholder for production implementation

        return alerts;
    }

    /**
     * @description Detects flow modifications that might impact compliance
     * @return List<SObject> Flow drift alerts
     */
    private static List<SObject> checkFlowChanges() {
        List<SObject> alerts = new List<SObject>();
        DateTime lastRun = getLastBaselineTimestamp();

        // Query flows activated recently
        List<FlowDefinitionView> recentFlows = [
            SELECT ApiName, Label, ActiveVersionId, LatestVersionId
            FROM FlowDefinitionView
            WHERE LastModifiedDate > :lastRun
            AND IsActive = true
            LIMIT 100
        ];

        for (FlowDefinitionView flow : recentFlows) {
            System.debug('Flow changed: ' + flow.Label);
            // In production: Create Alert__c record
        }

        return alerts;
    }

    /**
     * @description Publishes alerts to platform event for real-time notifications
     * @param alerts List of alerts to publish
     */
    @future(callout=false)
    public static void publishAlerts(List<Id> alertIds) {
        // Will publish to Sentinel_Alert_Event__e when platform event is deployed
        System.debug('Publishing ' + alertIds.size() + ' alerts');
    }

    // ========== Helper Methods ==========

    /**
     * @description Checks if a permission set is on the restricted list
     * @param permSetName Permission set API name
     * @return Boolean True if restricted
     */
    private static Boolean isRestrictedPermissionSet(String permSetName) {
        Set<String> restrictedSets = new Set<String>{
            'Admin',
            'Finance_Manager',
            'HR_Data_Access',
            'SystemAdministrator'
        };

        return restrictedSets.contains(permSetName);
    }

    /**
     * @description Gets the last baseline scan timestamp
     * @return DateTime Last scan time (defaults to 24 hours ago)
     */
    private static DateTime getLastBaselineTimestamp() {
        // In production, fetch from Custom Setting or Custom Metadata
        // For now, return 24 hours ago
        return DateTime.now().addHours(-24);
    }
}
