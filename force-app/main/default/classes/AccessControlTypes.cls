/**
 * AccessControlTypes
 *
 * Data types for access control operations.
 * Used by IAccessControlService implementations.
 *
 * @author Prometheion
 * @version 1.0
 */
public class AccessControlTypes {
    
    /**
     * Access Review Status wrapper
     */
    public class AccessReviewStatus {
        @AuraEnabled public Id reviewId;
        @AuraEnabled public String reviewType;
        @AuraEnabled public Integer totalUsers;
        @AuraEnabled public Integer reviewedUsers;
        @AuraEnabled public Integer pendingUsers;
        @AuraEnabled public Decimal completionPercentage;
        @AuraEnabled public String status;
        @AuraEnabled public DateTime startDate;
        @AuraEnabled public DateTime dueDate;
    }

    /**
     * User with excessive access details
     */
    public class ExcessiveAccessUser {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public List<String> excessivePermissions;
        @AuraEnabled public List<String> permissionSets;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public String justificationRequired;
        @AuraEnabled public DateTime lastLoginDate;
    }

    /**
     * Result of access revocation
     */
    public class RevokeAccessResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer usersProcessed;
        @AuraEnabled public Integer permissionsRevoked;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public DateTime processedAt;
    }

    /**
     * Stale permission record
     */
    public class StalePermission {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public DateTime lastLoginDate;
        @AuraEnabled public Integer daysSinceLogin;
        @AuraEnabled public List<String> permissionSets;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Boolean hasElevatedAccess;
    }

    /**
     * Need-to-know validation result
     */
    public class NeedToKnowResult {
        @AuraEnabled public Id userId;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public List<String> excessPermissions;
        @AuraEnabled public List<String> recommendations;
        @AuraEnabled public String justification;
    }
}
