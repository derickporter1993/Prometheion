/**
 * @description Sentinel Evidence Pack Generator
 * Generates auditable compliance evidence for SOC2, HIPAA, FedRAMP
 * @author Sentinel Team
 * @date 2025
 */
public with sharing class SentinelEvidenceEngine {

    /**
     * @description Generates auditable evidence pack for compliance frameworks
     * @param frameworkName SOC2, HIPAA, NIST, FedRAMP
     * @return String Evidence pack summary (ContentDocumentId in production)
     */
    @AuraEnabled
    public static String generateEvidencePack(String frameworkName) {
        try {
            // Validate input
            if (String.isBlank(frameworkName)) {
                throw new IllegalArgumentException('Framework name is required');
            }

            Map<String, String> evidenceFiles = new Map<String, String>();

            // 1. Export user access data
            evidenceFiles.put('UserAccess', exportUserAccess(frameworkName));

            // 2. Export role hierarchy
            evidenceFiles.put('RoleHierarchy', exportRoleHierarchy(frameworkName));

            // 3. Export permission sets
            evidenceFiles.put('PermissionSets', exportPermissionSets(frameworkName));

            // 4. Export active flows
            evidenceFiles.put('Flows', exportFlows(frameworkName));

            // 5. Create summary
            String summary = createEvidenceSummary(frameworkName, evidenceFiles.keySet());

            // In production: Create ContentVersion with ZIP file
            // For now, return summary
            return summary;

        } catch (Exception e) {
            throw new AuraHandledException('Failed to generate evidence pack: ' + e.getMessage());
        }
    }

    /**
     * @description Exports user access matrix as CSV
     * @param framework Framework name
     * @return String CSV content
     */
    private static String exportUserAccess(String framework) {
        if (!Schema.sObjectType.User.isAccessible()) {
            throw new AuraHandledException('Insufficient permissions to export user data');
        }

        String csvData = 'UserId,Username,Profile,Role,IsActive,LastLogin\n';

        List<User> users = [
            SELECT Id, Username, Profile.Name, UserRole.Name, IsActive, LastLoginDate
            FROM User
            WHERE IsActive = true
            ORDER BY Profile.Name, Username
            LIMIT 1000
        ];

        for (User u : users) {
            csvData += String.join(new List<String>{
                u.Id,
                u.Username,
                u.Profile.Name,
                (u.UserRole != null ? u.UserRole.Name : 'N/A'),
                String.valueOf(u.IsActive),
                (u.LastLoginDate != null ? u.LastLoginDate.format() : 'Never')
            }, ',') + '\n';
        }

        return csvData;
    }

    /**
     * @description Exports role hierarchy as CSV
     * @param framework Framework name
     * @return String CSV content
     */
    private static String exportRoleHierarchy(String framework) {
        String csvData = 'RoleId,RoleName,ParentRole,Level\n';

        List<UserRole> roles = [
            SELECT Id, Name, ParentRoleId
            FROM UserRole
            ORDER BY ParentRoleId NULLS FIRST, Name
        ];

        for (UserRole r : roles) {
            csvData += String.join(new List<String>{
                r.Id,
                r.Name,
                (r.ParentRoleId != null ? r.ParentRoleId : 'ROOT'),
                '1'
            }, ',') + '\n';
        }

        return csvData;
    }

    /**
     * @description Exports permission sets as CSV
     * @param framework Framework name
     * @return String CSV content
     */
    private static String exportPermissionSets(String framework) {
        String csvData = 'PermissionSetId,Name,Label,IsCustom,AssignmentCount\n';

        List<PermissionSet> permSets = [
            SELECT Id, Name, Label, IsOwnedByProfile,
                   (SELECT COUNT() FROM Assignments)
            FROM PermissionSet
            WHERE IsOwnedByProfile = false
            ORDER BY Name
            LIMIT 500
        ];

        for (PermissionSet ps : permSets) {
            csvData += String.join(new List<String>{
                ps.Id,
                ps.Name,
                ps.Label,
                String.valueOf(!ps.IsOwnedByProfile),
                String.valueOf(ps.Assignments.size())
            }, ',') + '\n';
        }

        return csvData;
    }

    /**
     * @description Exports active flows as CSV
     * @param framework Framework name
     * @return String CSV content
     */
    private static String exportFlows(String framework) {
        String csvData = 'FlowName,Label,IsActive,LastModified\n';

        List<FlowDefinitionView> flows = [
            SELECT ApiName, Label, IsActive, LastModifiedDate
            FROM FlowDefinitionView
            WHERE IsActive = true
            ORDER BY Label
            LIMIT 500
        ];

        for (FlowDefinitionView flow : flows) {
            csvData += String.join(new List<String>{
                flow.ApiName,
                flow.Label,
                String.valueOf(flow.IsActive),
                flow.LastModifiedDate.format()
            }, ',') + '\n';
        }

        return csvData;
    }

    /**
     * @description Creates evidence pack summary
     * @param framework Framework name
     * @param fileNames List of generated file names
     * @return String Summary text
     */
    private static String createEvidenceSummary(String framework, Set<String> fileNames) {
        String summary = '=== Sentinel Evidence Pack ===\n';
        summary += 'Framework: ' + framework + '\n';
        summary += 'Generated: ' + DateTime.now().format() + '\n';
        summary += 'Org: ' + UserInfo.getOrganizationName() + '\n';
        summary += '\nFiles Included:\n';

        for (String fileName : fileNames) {
            summary += '- ' + fileName + '.csv\n';
        }

        summary += '\nTotal Files: ' + fileNames.size() + '\n';
        summary += '=== End Summary ===\n';

        return summary;
    }
}
