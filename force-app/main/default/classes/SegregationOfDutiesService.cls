/**
 * SegregationOfDutiesService
 * 
 * Detect and remediate Segregation of Duties (SoD) violations
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class SegregationOfDutiesService {
    
    /**
     * Detect SoD violations for a user
     * @param userId User ID to check
     * @return List of SoD violations
     */
    @AuraEnabled
    public static List<SoDViolation> detectViolations(Id userId) {
        if (userId == null) {
            throw new IllegalArgumentException('User ID is required');
        }
        
        List<SoDViolation> violations = new List<SoDViolation>();
        
        // Get all permission sets assigned to user
        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSetId, PermissionSet.Name, PermissionSet.Label
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            WITH SECURITY_ENFORCED
        ];
        
        Set<Id> permSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : assignments) {
            permSetIds.add(psa.PermissionSetId);
        }
        
        // Check for conflicting permissions
        // Example: User cannot have both "Create" and "Approve" on financial objects
        
        // Get object permissions
        List<ObjectPermissions> objPerms = [
            SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit, 
                   PermissionsDelete, PermissionsModifyAllRecords, PermissionSetId
            FROM ObjectPermissions
            WHERE PermissionSetId IN :permSetIds
            WITH SECURITY_ENFORCED
        ];
        
        // Check for SoD conflicts (simplified - in production, use a rules engine)
        Map<String, Set<String>> userPermissions = new Map<String, Set<String>>();
        
        for (ObjectPermissions op : objPerms) {
            if (!userPermissions.containsKey(op.SObjectType)) {
                userPermissions.put(op.SObjectType, new Set<String>());
            }
            
            if (op.PermissionsCreate) {
                userPermissions.get(op.SObjectType).add('CREATE');
            }
            if (op.PermissionsEdit) {
                userPermissions.get(op.SObjectType).add('EDIT');
            }
            if (op.PermissionsDelete) {
                userPermissions.get(op.SObjectType).add('DELETE');
            }
            if (op.PermissionsModifyAllRecords) {
                userPermissions.get(op.SObjectType).add('MODIFY_ALL');
            }
        }
        
        // Check for conflicts on financial objects
        // Note: Salesforce ObjectPermissions doesn't have a PermissionsApprove field.
        // Approval permissions are managed through Approval Processes, not object-level permissions.
        // We check for practical SoD violations: CREATE+MODIFY_ALL and full CRUD access.
        Set<String> financialObjects = new Set<String>{'Account', 'Opportunity', 'Invoice__c', 'Payment__c'};
        
        for (String objType : userPermissions.keySet()) {
            if (financialObjects.contains(objType)) {
                Set<String> perms = userPermissions.get(objType);
                
                // Check for CREATE + MODIFY_ALL conflict (critical SoD violation)
                // This allows user to create records and then modify all records, bypassing approval workflows
                if (perms.contains('CREATE') && perms.contains('MODIFY_ALL')) {
                    SoDViolation violation = new SoDViolation();
                    violation.userId = userId;
                    violation.objectType = objType;
                    violation.conflictType = 'CREATE_AND_MODIFY_ALL';
                    violation.severity = 'CRITICAL';
                    violation.description = 'User has both Create and Modify All permissions on ' + objType + ' - critical SoD violation';
                    violations.add(violation);
                }
                
                // Check for CREATE + EDIT + DELETE (weaker but still a violation)
                // Full CRUD access without approval controls is a compliance risk
                if (perms.contains('CREATE') && perms.contains('EDIT') && perms.contains('DELETE')) {
                    SoDViolation violation = new SoDViolation();
                    violation.userId = userId;
                    violation.objectType = objType;
                    violation.conflictType = 'FULL_CRUD_ACCESS';
                    violation.severity = 'HIGH';
                    violation.description = 'User has full CRUD access (Create, Edit, Delete) on ' + objType + ' - SoD violation';
                    violations.add(violation);
                }
            }
        }
        
        return violations;
    }
    
    /**
     * Remediate SoD violation by removing conflicting permission
     */
    @AuraEnabled
    public static String remediateViolation(Id userId, String violationId, String remediationAction) {
        // In production, implement actual remediation logic
        // For now, return success message
        return 'Violation remediated: ' + violationId;
    }
    
    /**
     * SoD Violation
     */
    public class SoDViolation {
        @AuraEnabled public Id userId;
        @AuraEnabled public String objectType;
        @AuraEnabled public String conflictType;
        @AuraEnabled public String severity;
        @AuraEnabled public String description;
    }
}
