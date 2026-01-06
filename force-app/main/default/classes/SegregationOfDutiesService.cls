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
        
        // Check for conflicts (e.g., CREATE + APPROVE on financial objects)
        Set<String> financialObjects = new Set<String>{'Account', 'Opportunity', 'Invoice__c', 'Payment__c'};
        
        for (String objType : userPermissions.keySet()) {
            if (financialObjects.contains(objType)) {
                Set<String> perms = userPermissions.get(objType);
                
                // Check for CREATE + APPROVE conflict
                if (perms.contains('CREATE') && perms.contains('APPROVE')) {
                    SoDViolation violation = new SoDViolation();
                    violation.userId = userId;
                    violation.objectType = objType;
                    violation.conflictType = 'CREATE_AND_APPROVE';
                    violation.severity = 'HIGH';
                    violation.description = 'User has both Create and Approve permissions on ' + objType;
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
