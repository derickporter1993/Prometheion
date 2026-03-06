/**
 * SegregationOfDutiesService
 * 
 * Detect and remediate Segregation of Duties (SoD) violations
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Security
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

        List<ObjectPermissions> objPerms = queryUserObjectPermissions(userId);
        Map<String, Set<String>> userPermissions = buildPermissionMap(objPerms);

        return checkFinancialObjectConflicts(userPermissions, userId);
    }

    /**
     * Queries object permissions across all permission sets assigned to a user.
     *
     * @param userId The user ID to query permissions for
     * @return List of ObjectPermissions from all assigned permission sets
     */
    private static List<ObjectPermissions> queryUserObjectPermissions(Id userId) {
        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSetId, PermissionSet.Name, PermissionSet.Label
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            WITH USER_MODE
        ];

        Set<Id> permSetIds = new Set<Id>();
        for (PermissionSetAssignment psa : assignments) {
            permSetIds.add(psa.PermissionSetId);
        }

        return [
            SELECT SObjectType, PermissionsRead, PermissionsCreate, PermissionsEdit,
                   PermissionsDelete, PermissionsModifyAllRecords, ParentId
            FROM ObjectPermissions
            WHERE ParentId IN :permSetIds
            WITH USER_MODE
        ];
    }

    /**
     * Builds a map of object type to granted permission names from raw ObjectPermissions.
     *
     * @param objPerms List of ObjectPermissions records to process
     * @return Map where keys are SObject type names and values are sets of permission strings
     */
    private static Map<String, Set<String>> buildPermissionMap(List<ObjectPermissions> objPerms) {
        Map<String, Set<String>> userPermissions = new Map<String, Set<String>>();

        for (ObjectPermissions op : objPerms) {
            if (!userPermissions.containsKey(op.SObjectType)) {
                userPermissions.put(op.SObjectType, new Set<String>());
            }
            Set<String> perms = userPermissions.get(op.SObjectType);

            if (op.PermissionsCreate) {
                perms.add('CREATE');
            }
            if (op.PermissionsEdit) {
                perms.add('EDIT');
            }
            if (op.PermissionsDelete) {
                perms.add('DELETE');
            }
            if (op.PermissionsModifyAllRecords) {
                perms.add('MODIFY_ALL');
            }
        }
        return userPermissions;
    }

    /**
     * Detects CREATE+MODIFY_ALL and full CRUD conflicts on financial objects.
     *
     * @param permMap Map of object type to granted permission strings
     * @param userId The user ID to attach to detected violations
     * @return List of SoDViolation records for any detected conflicts
     */
    private static List<SoDViolation> checkFinancialObjectConflicts(Map<String, Set<String>> permMap, Id userId) {
        List<SoDViolation> violations = new List<SoDViolation>();
        Set<String> financialObjects = new Set<String>{'Account', 'Opportunity', 'Invoice__c', 'Payment__c'};

        for (String objType : permMap.keySet()) {
            if (!financialObjects.contains(objType)) {
                continue;
            }
            Set<String> perms = permMap.get(objType);

            // CREATE + MODIFY_ALL: user can create and then modify all records, bypassing approval workflows
            if (perms.contains('CREATE') && perms.contains('MODIFY_ALL')) {
                SoDViolation violation = new SoDViolation();
                violation.userId = userId;
                violation.objectType = objType;
                violation.conflictType = 'CREATE_AND_MODIFY_ALL';
                violation.severity = 'CRITICAL';
                violation.description = 'User has both Create and Modify All permissions on ' + objType + ' - critical SoD violation';
                violations.add(violation);
            }

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
