/**
 * IAccessControlService
 *
 * Interface for access control operations across compliance frameworks.
 * Implementations handle access reviews, permission analysis, and revocation.
 *
 * @author Elaro
 * @version 1.0
 */
public interface IAccessControlService {

    /**
     * Initiate an access review cycle
     * @param reviewType Type of review (QUARTERLY, ANNUAL, AD_HOC)
     * @return Id of the created review cycle record
     */
    Id initiateAccessReview(String reviewType);

    /**
     * Get current status of an access review
     * @param reviewId The review cycle Id
     * @return AccessReviewStatus with progress details
     */
    AccessReviewStatus getReviewStatus(Id reviewId);

    /**
     * Get users with excessive permissions beyond their role requirements
     * @return List of users with excessive access details
     */
    List<ExcessiveAccessUser> getExcessiveAccessUsers();

    /**
     * Revoke access for specified users
     * @param userIds List of user Ids to revoke access for
     * @param reason Reason for revocation
     * @return Result of the revocation operation
     */
    RevokeAccessResult revokeAccess(List<Id> userIds, String reason);

    /**
     * Get users who haven't logged in within specified days
     * @param daysSinceLogin Number of days threshold
     * @return List of stale permission records
     */
    List<StalePermission> getStalePermissions(Integer daysSinceLogin);

    /**
     * Validate need-to-know access for a user
     * @param userId The user to validate
     * @return Validation result with compliance status
     */
    NeedToKnowResult validateNeedToKnow(Id userId);

    /**
     * Access Review Status wrapper
     */
    class AccessReviewStatus {
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
    class ExcessiveAccessUser {
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
    class RevokeAccessResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Integer usersProcessed;
        @AuraEnabled public Integer permissionsRevoked;
        @AuraEnabled public List<String> errors;
        @AuraEnabled public DateTime processedAt;
    }

    /**
     * Stale permission record
     */
    class StalePermission {
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
    class NeedToKnowResult {
        @AuraEnabled public Id userId;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public List<String> excessPermissions;
        @AuraEnabled public List<String> recommendations;
        @AuraEnabled public String justification;
    }
}
