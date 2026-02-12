/**
 * Detects Einstein and AI-related licenses assigned to users via PermissionSetAssignment
 * analysis. Identifies which users have access to AI capabilities and tracks license
 * utilization for governance and compliance reporting.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 * @see AIDetectionEngine
 * @see AIGovernanceService
 */
public inherited sharing class AILicenseDetector {

    private static final List<String> AI_PERMISSION_KEYWORDS = new List<String>{
        'Einstein',
        'GenAI',
        'ML',
        'Bot',
        'Prediction'
    };

    /**
     * Detects all Einstein and AI-related permission sets assigned in the org.
     *
     * @return List of AI license assignments including user and permission details
     * @throws AuraHandledException if query fails or user lacks permission
     * @example
     * List<AILicenseDetector.AILicenseAssignment> licenses = AILicenseDetector.detectAILicenses();
     */
    public static List<AILicenseAssignment> detectAILicenses() {
        List<AILicenseAssignment> assignments = new List<AILicenseAssignment>();

        try {
            // Query PermissionSetAssignment for AI-related permission sets
            List<PermissionSetAssignment> psaList = [
                SELECT Id, PermissionSet.Name, PermissionSet.Label,
                       PermissionSet.Description, Assignee.Name, Assignee.Email,
                       AssignedDate
                FROM PermissionSetAssignment
                WHERE PermissionSet.IsCustom = true
                WITH USER_MODE
                ORDER BY AssignedDate DESC
                LIMIT 5000
            ];

            for (PermissionSetAssignment psa : psaList) {
                if (isAIRelatedPermissionSet(psa.PermissionSet)) {
                    AILicenseAssignment assignment = new AILicenseAssignment();
                    assignment.permissionSetName = psa.PermissionSet.Name;
                    assignment.permissionSetLabel = psa.PermissionSet.Label;
                    assignment.assigneeName = psa.Assignee.Name;
                    assignment.assigneeEmail = psa.Assignee.Email;
                    assignment.assignedDate = psa.AssignedDate;
                    assignment.description = psa.PermissionSet.Description;
                    assignments.add(assignment);
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AILicenseDetector.detectAILicenses', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to detect AI licenses. Please verify you have the required permissions and try again.');
        }

        return assignments;
    }

    /**
     * Gets unique count of users with AI-related permissions.
     *
     * @return Number of unique users with AI capabilities
     */
    public static Integer getAIUserCount() {
        Set<Id> uniqueUserIds = new Set<Id>();

        try {
            List<PermissionSetAssignment> psaList = [
                SELECT Assignee.Id, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE PermissionSet.IsCustom = true
                WITH USER_MODE
                LIMIT 5000
            ];

            for (PermissionSetAssignment psa : psaList) {
                if (isAIRelatedPermissionSet(psa.PermissionSet)) {
                    uniqueUserIds.add(psa.Assignee.Id);
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AILicenseDetector.getAIUserCount', e.getMessage(), e.getStackTraceString());
        }

        return uniqueUserIds.size();
    }

    /**
     * Determines if a PermissionSet is AI-related based on name and description.
     *
     * @param permSet The PermissionSet to evaluate
     * @return True if permission set is AI-related
     */
    private static Boolean isAIRelatedPermissionSet(PermissionSet permSet) {
        String name = permSet.Name?.toLowerCase() ?? '';
        String label = permSet.Label?.toLowerCase() ?? '';
        String description = permSet.Description?.toLowerCase() ?? '';

        for (String keyword : AI_PERMISSION_KEYWORDS) {
            String keywordLower = keyword.toLowerCase();
            if (name.contains(keywordLower) ||
                label.contains(keywordLower) ||
                description.contains(keywordLower)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Gets AI license assignments for a specific user.
     *
     * @param userId The User Id to query
     * @return List of AILicenseAssignment records for the user
     */
    public static List<AILicenseAssignment> getLicensesForUser(Id userId) {
        List<AILicenseAssignment> assignments = new List<AILicenseAssignment>();

        try {
            List<PermissionSetAssignment> psaList = [
                SELECT Id, PermissionSet.Name, PermissionSet.Label,
                       PermissionSet.Description, Assignee.Name, Assignee.Email,
                       AssignedDate
                FROM PermissionSetAssignment
                WHERE AssigneeId = :userId
                AND PermissionSet.IsCustom = true
                WITH USER_MODE
            ];

            for (PermissionSetAssignment psa : psaList) {
                if (isAIRelatedPermissionSet(psa.PermissionSet)) {
                    AILicenseAssignment assignment = new AILicenseAssignment();
                    assignment.permissionSetName = psa.PermissionSet.Name;
                    assignment.permissionSetLabel = psa.PermissionSet.Label;
                    assignment.assigneeName = psa.Assignee.Name;
                    assignment.assigneeEmail = psa.Assignee.Email;
                    assignment.assignedDate = psa.AssignedDate;
                    assignment.description = psa.PermissionSet.Description;
                    assignments.add(assignment);
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AILicenseDetector.getLicensesForUser', e.getMessage(), e.getStackTraceString());
        }

        return assignments;
    }

    /**
     * Wrapper class representing an AI license assignment.
     */
    public class AILicenseAssignment {
        @AuraEnabled public String permissionSetName { get; set; }
        @AuraEnabled public String permissionSetLabel { get; set; }
        @AuraEnabled public String assigneeName { get; set; }
        @AuraEnabled public String assigneeEmail { get; set; }
        @AuraEnabled public Datetime assignedDate { get; set; }
        @AuraEnabled public String description { get; set; }
    }
}
