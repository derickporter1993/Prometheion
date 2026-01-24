/**
 * SOC2AccessReviewService
 *
 * Automates periodic access reviews per SOC2 CC6.2/CC6.3.
 * Handles access review cycles, permission analysis, and revocation.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class SOC2AccessReviewService extends ComplianceServiceBase implements IAccessControlService {

    // Access review thresholds
    private static final Integer STALE_LOGIN_DAYS = 90;
    private static final Integer QUARTERLY_REVIEW_DAYS = 90;
    private static final Integer ANNUAL_REVIEW_DAYS = 365;

    // High-risk permissions
    private static final Set<String> HIGH_RISK_PERMISSIONS = new Set<String>{
        'PermissionsModifyAllData', 'PermissionsViewAllData',
        'PermissionsManageUsers', 'PermissionsAuthorApex',
        'PermissionsViewSetup', 'PermissionsModifyMetadata'
    };

    /**
     * Get framework name
     */
    public override String getFrameworkName() {
        return 'SOC2';
    }

    /**
     * Get framework score multiplier
     */
    protected override Decimal getFrameworkMultiplier() {
        return 1.0;
    }

    /**
     * Evaluate SOC2 access controls
     */
    protected override List<ComplianceServiceBase.InternalViolation> evaluateControls() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Add violations from helper methods
        violations.addAll(evaluateStaleAccess());
        violations.addAll(evaluateExcessiveAccess());

        return violations;
    }

    // ========== IAccessControlService Implementation ==========

    /**
     * Initiate an access review cycle
     */
    public Id initiateAccessReview(String reviewType) {
        if (!Schema.sObjectType.Access_Review__c.isCreateable()) {
            throw new ComplianceServiceException('Insufficient permissions to create Access Review records');
        }

        // Calculate due date based on review type
        Date dueDate;
        if (reviewType == 'QUARTERLY') {
            dueDate = Date.today().addDays(30);
        } else if (reviewType == 'ANNUAL') {
            dueDate = Date.today().addDays(60);
        } else {
            dueDate = Date.today().addDays(14); // AD_HOC
        }

        // Get users requiring review
        List<User> usersToReview = [
            SELECT Id, Name, Email, Profile.Name, LastLoginDate, IsActive
            FROM User
            WHERE IsActive = true
            WITH SECURITY_ENFORCED
            LIMIT 1000
        ];

        List<Access_Review__c> reviews = new List<Access_Review__c>();
        for (User u : usersToReview) {
            Access_Review__c review = new Access_Review__c(
                Review_Type__c = reviewType,
                User__c = u.Id,
                Status__c = 'PENDING',
                Due_Date__c = dueDate,
                Framework__c = 'SOC2',
                Permission_Sets__c = JSON.serialize(getUserPermissionSets(u.Id))
            );
            reviews.add(review);
        }

        if (!reviews.isEmpty()) {
            insert reviews;
            logAuditEntry('ACCESS_REVIEW_INITIATED', 'Initiated ' + reviewType + ' access review for ' + reviews.size() + ' users', reviews[0].Id);
            return reviews[0].Id;
        }

        return null;
    }

    /**
     * Get access review status
     */
    public AccessControlTypes.AccessReviewStatus getReviewStatus(Id reviewId) {
        AccessControlTypes.AccessReviewStatus status = new AccessControlTypes.AccessReviewStatus();

        // Get review cycle info
        List<Access_Review__c> reviews = [
            SELECT Id, Review_Type__c, Status__c, Due_Date__c, CreatedDate
            FROM Access_Review__c
            WHERE Id = :reviewId
            WITH SECURITY_ENFORCED
        ];

        if (reviews.isEmpty()) {
            return status;
        }

        Access_Review__c firstReview = reviews[0];
        status.reviewId = reviewId;
        status.reviewType = firstReview.Review_Type__c;
        status.startDate = firstReview.CreatedDate;
        status.dueDate = DateTime.newInstance(firstReview.Due_Date__c, Time.newInstance(23, 59, 59, 0));

        // Calculate counts
        Integer pending = 0;
        Integer reviewed = 0;
        for (Access_Review__c review : reviews) {
            if (review.Status__c == 'PENDING' || review.Status__c == 'IN_PROGRESS') {
                pending++;
            } else {
                reviewed++;
            }
        }

        status.totalUsers = reviews.size();
        status.reviewedUsers = reviewed;
        status.pendingUsers = pending;
        status.completionPercentage = reviews.size() > 0 ?
            (Decimal.valueOf(reviewed) / Decimal.valueOf(reviews.size()) * 100).setScale(2) : 0;
        status.status = status.completionPercentage >= 100 ? 'COMPLETED' :
                       status.completionPercentage > 0 ? 'IN_PROGRESS' : 'NOT_STARTED';

        return status;
    }

    /**
     * Get users with excessive access
     */
    public List<AccessControlTypes.ExcessiveAccessUser> getExcessiveAccessUsers() {
        List<AccessControlTypes.ExcessiveAccessUser> result = new List<AccessControlTypes.ExcessiveAccessUser>();

        // Query users with high-risk permissions
        List<PermissionSetAssignment> psAssignments = [
            SELECT AssigneeId, Assignee.Name, Assignee.Email, Assignee.LastLoginDate,
                   PermissionSet.Name, PermissionSet.PermissionsModifyAllData,
                   PermissionSet.PermissionsViewAllData, PermissionSet.PermissionsManageUsers
            FROM PermissionSetAssignment
            WHERE Assignee.IsActive = true
            AND (PermissionSet.PermissionsModifyAllData = true
                 OR PermissionSet.PermissionsViewAllData = true
                 OR PermissionSet.PermissionsManageUsers = true)
            WITH SECURITY_ENFORCED
            LIMIT 1000
        ];

        // Group by user
        Map<Id, AccessControlTypes.ExcessiveAccessUser> userMap = new Map<Id, AccessControlTypes.ExcessiveAccessUser>();

        for (PermissionSetAssignment psa : psAssignments) {
            AccessControlTypes.ExcessiveAccessUser exUser;
            if (userMap.containsKey(psa.AssigneeId)) {
                exUser = userMap.get(psa.AssigneeId);
            } else {
                exUser = new AccessControlTypes.ExcessiveAccessUser();
                exUser.userId = psa.AssigneeId;
                exUser.userName = psa.Assignee.Name;
                exUser.userEmail = psa.Assignee.Email;
                exUser.lastLoginDate = psa.Assignee.LastLoginDate;
                exUser.excessivePermissions = new List<String>();
                exUser.permissionSets = new List<String>();
                exUser.riskScore = 0;
                userMap.put(psa.AssigneeId, exUser);
            }

            exUser.permissionSets.add(psa.PermissionSet.Name);

            if (psa.PermissionSet.PermissionsModifyAllData) {
                if (!exUser.excessivePermissions.contains('Modify All Data')) {
                    exUser.excessivePermissions.add('Modify All Data');
                    exUser.riskScore += 3;
                }
            }
            if (psa.PermissionSet.PermissionsViewAllData) {
                if (!exUser.excessivePermissions.contains('View All Data')) {
                    exUser.excessivePermissions.add('View All Data');
                    exUser.riskScore += 2;
                }
            }
            if (psa.PermissionSet.PermissionsManageUsers) {
                if (!exUser.excessivePermissions.contains('Manage Users')) {
                    exUser.excessivePermissions.add('Manage Users');
                    exUser.riskScore += 2;
                }
            }
        }

        result.addAll(userMap.values());

        // Sort by risk score descending
        result.sort();

        return result;
    }

    /**
     * Revoke access for users
     */
    public AccessControlTypes.RevokeAccessResult revokeAccess(List<Id> userIds, String reason) {
        AccessControlTypes.RevokeAccessResult result = new AccessControlTypes.RevokeAccessResult();
        result.success = true;
        result.usersProcessed = 0;
        result.permissionsRevoked = 0;
        result.errors = new List<String>();
        result.processedAt = DateTime.now();

        if (userIds == null || userIds.isEmpty()) {
            result.success = false;
            result.errors.add('No users specified');
            return result;
        }

        try {
            // Get permission set assignments to revoke
            List<PermissionSetAssignment> toRevoke = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE AssigneeId IN :userIds
                AND PermissionSet.IsOwnedByProfile = false
                WITH SECURITY_ENFORCED
            ];

            if (!toRevoke.isEmpty()) {
                // Log before deletion
                for (PermissionSetAssignment psa : toRevoke) {
                    logAuditEntry('ACCESS_REVOKED',
                        'Revoked permission set ' + psa.PermissionSet.Name + ' from user. Reason: ' + reason,
                        psa.AssigneeId);
                }

                delete toRevoke;
                result.permissionsRevoked = toRevoke.size();
            }

            result.usersProcessed = userIds.size();
        } catch (Exception e) {
            result.success = false;
            result.errors.add(e.getMessage());
        }

        return result;
    }

    /**
     * Get stale permissions (users not logged in)
     */
    public List<AccessControlTypes.StalePermission> getStalePermissions(Integer daysSinceLogin) {
        List<AccessControlTypes.StalePermission> result = new List<AccessControlTypes.StalePermission>();

        Date cutoffDate = Date.today().addDays(-daysSinceLogin);

        List<User> staleUsers = [
            SELECT Id, Name, LastLoginDate, IsActive
            FROM User
            WHERE IsActive = true
            AND (LastLoginDate < :cutoffDate OR LastLoginDate = null)
            WITH SECURITY_ENFORCED
            LIMIT 500
        ];

        Set<Id> staleUserIds = new Set<Id>();
        for (User u : staleUsers) {
            staleUserIds.add(u.Id);
        }

        // Get their permission sets
        Map<Id, List<String>> userPermSets = new Map<Id, List<String>>();
        Map<Id, Boolean> userHasElevated = new Map<Id, Boolean>();

        for (PermissionSetAssignment psa : [
            SELECT AssigneeId, PermissionSet.Name, PermissionSet.PermissionsModifyAllData,
                   PermissionSet.PermissionsViewAllData
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :staleUserIds
            AND PermissionSet.IsOwnedByProfile = false
            WITH SECURITY_ENFORCED
        ]) {
            if (!userPermSets.containsKey(psa.AssigneeId)) {
                userPermSets.put(psa.AssigneeId, new List<String>());
                userHasElevated.put(psa.AssigneeId, false);
            }
            userPermSets.get(psa.AssigneeId).add(psa.PermissionSet.Name);

            if (psa.PermissionSet.PermissionsModifyAllData || psa.PermissionSet.PermissionsViewAllData) {
                userHasElevated.put(psa.AssigneeId, true);
            }
        }

        for (User u : staleUsers) {
            AccessControlTypes.StalePermission sp = new AccessControlTypes.StalePermission();
            sp.userId = u.Id;
            sp.userName = u.Name;
            sp.lastLoginDate = u.LastLoginDate;
            sp.daysSinceLogin = u.LastLoginDate != null ?
                Date.today().daysBetween(u.LastLoginDate.date()) * -1 : 999;
            sp.permissionSets = userPermSets.containsKey(u.Id) ? userPermSets.get(u.Id) : new List<String>();
            sp.hasElevatedAccess = userHasElevated.containsKey(u.Id) ? userHasElevated.get(u.Id) : false;
            sp.riskScore = calculateStaleUserRiskScore(sp);
            result.add(sp);
        }

        return result;
    }

    /**
     * Validate need-to-know access
     */
    public AccessControlTypes.NeedToKnowResult validateNeedToKnow(Id userId) {
        AccessControlTypes.NeedToKnowResult result = new AccessControlTypes.NeedToKnowResult();
        result.userId = userId;
        result.compliant = true;
        result.excessPermissions = new List<String>();
        result.recommendations = new List<String>();

        // Get user's permission sets
        List<PermissionSetAssignment> assignments = [
            SELECT PermissionSet.Name, PermissionSet.PermissionsModifyAllData,
                   PermissionSet.PermissionsViewAllData, PermissionSet.PermissionsManageUsers,
                   PermissionSet.PermissionsAuthorApex
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSet.IsOwnedByProfile = false
            WITH SECURITY_ENFORCED
        ];

        for (PermissionSetAssignment psa : assignments) {
            if (psa.PermissionSet.PermissionsModifyAllData) {
                result.compliant = false;
                result.excessPermissions.add('Modify All Data (' + psa.PermissionSet.Name + ')');
                result.recommendations.add('Remove Modify All Data and assign granular object permissions');
            }
            if (psa.PermissionSet.PermissionsViewAllData) {
                result.compliant = false;
                result.excessPermissions.add('View All Data (' + psa.PermissionSet.Name + ')');
                result.recommendations.add('Remove View All Data and use sharing rules for data access');
            }
        }

        return result;
    }

    // ========== Helper Methods ==========

    /**
     * Evaluate stale access violations
     */
    private List<ComplianceServiceBase.InternalViolation> evaluateStaleAccess() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        List<AccessControlTypes.StalePermission> stalePerms = getStalePermissions(STALE_LOGIN_DAYS);

        for (AccessControlTypes.StalePermission sp : stalePerms) {
            if (sp.hasElevatedAccess) {
                ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                    'Stale Elevated Access',
                    'User ' + sp.userName + ' has elevated permissions but has not logged in for ' + sp.daysSinceLogin + ' days',
                    'HIGH',
                    'SOC2-CC6.2',
                    'Revoke elevated permissions or confirm user still requires access',
                    sp.riskScore
                );
                violations.add(v);
            }
        }

        return violations;
    }

    /**
     * Evaluate excessive access violations
     */
    private List<ComplianceServiceBase.InternalViolation> evaluateExcessiveAccess() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        List<AccessControlTypes.ExcessiveAccessUser> excessiveUsers = getExcessiveAccessUsers();

        // Only flag if more than 10% of active users have elevated access
        Integer activeUserCount = [SELECT COUNT() FROM User WHERE IsActive = true WITH SECURITY_ENFORCED];
        Decimal threshold = activeUserCount * 0.10;

        if (excessiveUsers.size() > threshold) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Excessive Elevated Access',
                excessiveUsers.size() + ' users have elevated permissions (>10% of active users)',
                'HIGH',
                'SOC2-CC6.3',
                'Review and reduce the number of users with Modify All/View All permissions',
                8.0
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Get permission sets for a user
     */
    private List<String> getUserPermissionSets(Id userId) {
        List<String> permSets = new List<String>();

        for (PermissionSetAssignment psa : [
            SELECT PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId = :userId
            AND PermissionSet.IsOwnedByProfile = false
            WITH SECURITY_ENFORCED
        ]) {
            permSets.add(psa.PermissionSet.Name);
        }

        return permSets;
    }

    /**
     * Calculate risk score for stale user
     */
    private Decimal calculateStaleUserRiskScore(AccessControlTypes.StalePermission sp) {
        Decimal score = 3.0; // Base score

        if (sp.hasElevatedAccess) {
            score += 3.0;
        }

        if (sp.daysSinceLogin > 180) {
            score += 2.0;
        } else if (sp.daysSinceLogin > 90) {
            score += 1.0;
        }

        if (sp.permissionSets != null && sp.permissionSets.size() > 5) {
            score += 1.0;
        }

        return Math.min(score, 10.0);
    }
}
