/**
 * IAccessControlService
 *
 * Interface for access control operations across compliance frameworks.
 * Implementations handle access reviews, permission analysis, and revocation.
 *
 * @author Prometheion
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
    AccessControlTypes.AccessReviewStatus getReviewStatus(Id reviewId);

    /**
     * Get users with excessive permissions beyond their role requirements
     * @return List of users with excessive access details
     */
    List<AccessControlTypes.ExcessiveAccessUser> getExcessiveAccessUsers();

    /**
     * Revoke access for specified users
     * @param userIds List of user Ids to revoke access for
     * @param reason Reason for revocation
     * @return Result of the revocation operation
     */
    AccessControlTypes.RevokeAccessResult revokeAccess(List<Id> userIds, String reason);

    /**
     * Get users who haven't logged in within specified days
     * @param daysSinceLogin Number of days threshold
     * @return List of stale permission records
     */
    List<AccessControlTypes.StalePermission> getStalePermissions(Integer daysSinceLogin);

    /**
     * Validate need-to-know access for a user
     * @param userId The user to validate
     * @return Validation result with compliance status
     */
    AccessControlTypes.NeedToKnowResult validateNeedToKnow(Id userId);
}
