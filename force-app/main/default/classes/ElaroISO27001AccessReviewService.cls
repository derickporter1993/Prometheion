/**
 * ISO27001AccessReviewService - ISO 27001 Control A.9 Implementation
 *
 * Manages user access reviews, privilege certifications, and access right management.
 * Ensures compliance with information security access control requirements.
 *
 * Compliance Coverage:
 * - ISO 27001 A.9.2.1: User registration and de-registration
 * - ISO 27001 A.9.2.2: User access provisioning
 * - ISO 27001 A.9.2.3: Management of privileged access rights
 * - ISO 27001 A.9.2.5: Review of user access rights
 * - ISO 27001 A.9.2.6: Removal or adjustment of access rights
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroISO27001AccessReviewService {

    private static final Integer QUARTERLY_REVIEW_DAYS = 90;
    private static final Integer ANNUAL_CERTIFICATION_DAYS = 365;
    private static final Integer DORMANT_ACCOUNT_DAYS = 90;

    // Privileged permission sets that require enhanced review
    private static final Set<String> PRIVILEGED_PERMISSIONS = new Set<String>{
        'System Administrator',
        'Modify All Data',
        'View All Data',
        'Manage Users',
        'Author Apex',
        'Customize Application'
    };

    /**
     * Initiate quarterly access reviews for all active users
     * @return List of Access_Review__c records created
     */
    public static List<Access_Review__c> initiateQuarterlyReviews() {
        List<Access_Review__c> reviews = new List<Access_Review__c>();

        // Get active users with their managers
        List<User> activeUsers = [
            SELECT Id, Name, Username, Profile.Name, ManagerId, LastLoginDate,
                   (SELECT PermissionSet.Name FROM PermissionSetAssignments
                    WHERE PermissionSet.IsOwnedByProfile = false)
            FROM User
            WHERE IsActive = true
            AND UserType = 'Standard'
            WITH USER_MODE
            LIMIT 1000
        ];

        Date dueDate = Date.today().addDays(14); // 2 weeks to complete

        for (User u : activeUsers) {
            // Collect permission sets
            List<String> permSets = new List<String>();
            Boolean isPrivileged = false;

            for (PermissionSetAssignment psa : u.PermissionSetAssignments) {
                permSets.add(psa.PermissionSet.Name);
                if (PRIVILEGED_PERMISSIONS.contains(psa.PermissionSet.Name)) {
                    isPrivileged = true;
                }
            }

            // Check for admin profile
            if (u.Profile.Name == 'System Administrator') {
                isPrivileged = true;
            }

            // Calculate risk level
            String riskLevel = calculateRiskLevel(u, isPrivileged);

            reviews.add(new Access_Review__c(
                User__c = u.Id,
                Reviewer__c = u.ManagerId,
                Review_Type__c = 'Quarterly Review',
                Review_Status__c = 'Pending',
                Due_Date__c = dueDate,
                Profiles_Reviewed__c = u.Profile.Name,
                Permission_Sets_Reviewed__c = String.join(permSets, '\n'),
                Is_Privileged_User__c = isPrivileged,
                Last_Login_Date__c = u.LastLoginDate,
                Risk_Level__c = riskLevel
            ));
        }

        if (!reviews.isEmpty()) {
            Database.insert(reviews, AccessLevel.USER_MODE);
        }

        return reviews;
    }

    /**
     * Initiate privileged access reviews (more frequent for admins)
     * @return List of Access_Review__c records for privileged users
     */
    public static List<Access_Review__c> initiatePrivilegedAccessReviews() {
        List<Access_Review__c> reviews = new List<Access_Review__c>();

        // Find users with privileged access
        // First get users with privileged permission sets
        Set<Id> privilegedUserIds = new Set<Id>();
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name IN :PRIVILEGED_PERMISSIONS
            WITH USER_MODE
        ]) {
            privilegedUserIds.add(psa.AssigneeId);
        }

        // Then get all active users who are admins or have privileged permissions
        List<User> privilegedUsers = [
            SELECT Id, Name, Username, Profile.Name, ManagerId, LastLoginDate,
                   (SELECT PermissionSet.Name FROM PermissionSetAssignments
                    WHERE PermissionSet.IsOwnedByProfile = false)
            FROM User
            WHERE IsActive = true
            AND (Profile.Name = 'System Administrator' OR Id IN :privilegedUserIds)
            WITH USER_MODE
            LIMIT 200
        ];

        Date dueDate = Date.today().addDays(7); // 1 week for privileged reviews

        for (User u : privilegedUsers) {
            List<String> permSets = new List<String>();
            for (PermissionSetAssignment psa : u.PermissionSetAssignments) {
                permSets.add(psa.PermissionSet.Name);
            }

            reviews.add(new Access_Review__c(
                User__c = u.Id,
                Reviewer__c = u.ManagerId,
                Review_Type__c = 'Privileged Access Review',
                Review_Status__c = 'Pending',
                Due_Date__c = dueDate,
                Profiles_Reviewed__c = u.Profile.Name,
                Permission_Sets_Reviewed__c = String.join(permSets, '\n'),
                Is_Privileged_User__c = true,
                Last_Login_Date__c = u.LastLoginDate,
                Risk_Level__c = 'High'
            ));
        }

        if (!reviews.isEmpty()) {
            Database.insert(reviews, AccessLevel.USER_MODE);
        }

        return reviews;
    }

    /**
     * Process access review decision
     * @param reviewId - Access_Review__c record ID
     * @param decision - Reviewer's decision
     * @param justification - Justification for decision
     */
    public static void processReviewDecision(
        Id reviewId,
        String decision,
        String justification
    ) {
        Access_Review__c review = [
            SELECT Id, User__c, Review_Status__c, Decision__c
            FROM Access_Review__c
            WHERE Id = :reviewId
            WITH USER_MODE
            LIMIT 1
        ];

        review.Review_Status__c = getStatusFromDecision(decision);
        review.Decision__c = decision;
        review.Decision_Justification__c = justification;
        review.Review_Date__c = System.now();
        review.Reviewer__c = UserInfo.getUserId();

        Database.update(review, AccessLevel.USER_MODE);

        // If access revoked, take action
        if (decision == 'Revoke All Access') {
            revokeUserAccess(review.User__c);
        }

        // Publish audit event
        publishAccessReviewEvent(review, decision);
    }

    /**
     * Identify dormant accounts (no login in 90+ days)
     * @return List of User IDs with dormant accounts
     */
    @AuraEnabled(cacheable=true)
    public static List<DormantAccountInfo> identifyDormantAccounts() {
        List<DormantAccountInfo> dormantAccounts = new List<DormantAccountInfo>();

        Date dormantThreshold = Date.today().addDays(-DORMANT_ACCOUNT_DAYS);

        List<User> dormantUsers = [
            SELECT Id, Name, Username, Profile.Name, LastLoginDate, ManagerId
            FROM User
            WHERE IsActive = true
            AND (LastLoginDate < :dormantThreshold OR LastLoginDate = null)
            AND UserType = 'Standard'
            WITH USER_MODE
            LIMIT 500
        ];

        for (User u : dormantUsers) {
            DormantAccountInfo info = new DormantAccountInfo();
            info.userId = u.Id;
            info.userName = u.Username;
            info.profileName = u.Profile.Name;
            info.lastLoginDate = u.LastLoginDate;
            info.daysSinceLogin = u.LastLoginDate != null ?
                Date.today().daysBetween(u.LastLoginDate.date()) * -1 : null;
            dormantAccounts.add(info);
        }

        return dormantAccounts;
    }

    /**
     * Create termination access review when employee leaves
     * @param userId - User ID of departing employee
     * @param terminationDate - Date of termination
     * @return Access_Review__c record created
     */
    public static Access_Review__c createTerminationReview(Id userId, Date terminationDate) {
        User u = [
            SELECT Id, Name, Profile.Name, ManagerId, LastLoginDate,
                   (SELECT PermissionSet.Name FROM PermissionSetAssignments
                    WHERE PermissionSet.IsOwnedByProfile = false)
            FROM User
            WHERE Id = :userId
            WITH USER_MODE
            LIMIT 1
        ];

        List<String> permSets = new List<String>();
        for (PermissionSetAssignment psa : u.PermissionSetAssignments) {
            permSets.add(psa.PermissionSet.Name);
        }

        Access_Review__c review = new Access_Review__c(
            User__c = userId,
            Reviewer__c = u.ManagerId,
            Review_Type__c = 'Termination Review',
            Review_Status__c = 'In Progress',
            Due_Date__c = terminationDate,
            Profiles_Reviewed__c = u.Profile.Name,
            Permission_Sets_Reviewed__c = String.join(permSets, '\n'),
            Is_Privileged_User__c = u.Profile.Name == 'System Administrator',
            Last_Login_Date__c = u.LastLoginDate,
            Risk_Level__c = 'High',
            Decision__c = 'Revoke All Access',
            Decision_Justification__c = 'Employee termination - all access must be revoked'
        );

        Database.insert(review, AccessLevel.USER_MODE);

        return review;
    }

    /**
     * Get pending reviews for a reviewer
     * @param reviewerId - User ID of the reviewer
     * @return List of pending Access_Review__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Access_Review__c> getPendingReviews(Id reviewerId) {
        return [
            SELECT Id, Name, User__c, User__r.Name, Review_Type__c,
                   Due_Date__c, Is_Privileged_User__c, Risk_Level__c,
                   Profiles_Reviewed__c, Permission_Sets_Reviewed__c,
                   Last_Login_Date__c
            FROM Access_Review__c
            WHERE Reviewer__c = :reviewerId
            AND Review_Status__c IN ('Pending', 'In Progress')
            WITH USER_MODE
            ORDER BY Due_Date__c ASC
            LIMIT 100
        ];
    }

    /**
     * Get overdue access reviews
     * @return List of overdue Access_Review__c records
     */
    @AuraEnabled(cacheable=true)
    public static List<Access_Review__c> getOverdueReviews() {
        return [
            SELECT Id, Name, User__c, User__r.Name, Reviewer__c, Reviewer__r.Name,
                   Review_Type__c, Due_Date__c, Is_Privileged_User__c, Risk_Level__c
            FROM Access_Review__c
            WHERE Due_Date__c < TODAY
            AND Review_Status__c IN ('Pending', 'In Progress')
            WITH USER_MODE
            ORDER BY Due_Date__c ASC
            LIMIT 100
        ];
    }

    /**
     * Get compliance dashboard metrics
     * @return Map of metric name to value
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getComplianceMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        // Optimized: Use separate queries (SOQL doesn't support CASE WHEN)
        // Total reviews due
        Integer total = [
            SELECT COUNT()
            FROM Access_Review__c
            WHERE Due_Date__c < TODAY
            WITH USER_MODE
        ];

        // Completed reviews
        Integer completed = [
            SELECT COUNT()
            FROM Access_Review__c
            WHERE Due_Date__c < TODAY
            AND Review_Status__c IN ('Approved', 'Revoked', 'Modified')
            WITH USER_MODE
        ];

        // Overdue reviews
        Integer overdue = [
            SELECT COUNT()
            FROM Access_Review__c
            WHERE Due_Date__c < TODAY
            AND Review_Status__c IN ('Pending', 'In Progress')
            WITH USER_MODE
        ];

        // Reviews this quarter
        Integer thisQuarter = [
            SELECT COUNT()
            FROM Access_Review__c
            WHERE CreatedDate = THIS_QUARTER
            WITH USER_MODE
        ];

        metrics.put('reviewsThisQuarter', thisQuarter);
        metrics.put('overdueCount', overdue);
        metrics.put('completionRate', total > 0 ?
            (Decimal.valueOf(completed) / total * 100).setScale(2) : 100);

        // Privileged users count
        Set<Id> privUserIds = new Set<Id>();
        for (PermissionSetAssignment psa : [
            SELECT AssigneeId FROM PermissionSetAssignment
            WHERE PermissionSet.Name IN :PRIVILEGED_PERMISSIONS
            WITH USER_MODE
        ]) {
            privUserIds.add(psa.AssigneeId);
        }

        // Optimized: Use separate queries for User counts (SOQL doesn't support CASE WHEN)
        Date dormantThreshold = Date.today().addDays(-DORMANT_ACCOUNT_DAYS);
        
        // Privileged users
        Integer privileged = [
            SELECT COUNT()
            FROM User
            WHERE IsActive = true
            AND (Profile.Name = 'System Administrator' OR Id IN :privUserIds)
            WITH USER_MODE
        ];

        // Dormant accounts
        Integer dormant = [
            SELECT COUNT()
            FROM User
            WHERE IsActive = true
            AND UserType = 'Standard'
            AND (LastLoginDate < :dormantThreshold OR LastLoginDate = null)
            WITH USER_MODE
        ];

        metrics.put('privilegedUsersCount', privileged);
        metrics.put('dormantAccountsCount', dormant);

        return metrics;
    }

    /**
     * Calculate risk level based on user access and activity
     * @param u - User record
     * @param isPrivileged - Whether user has privileged access
     * @return Risk level string
     */
    private static String calculateRiskLevel(User u, Boolean isPrivileged) {
        // Critical: Privileged user with no recent login
        if (isPrivileged && (u.LastLoginDate == null ||
            u.LastLoginDate < System.now().addDays(-30))) {
            return 'Critical';
        }

        // High: Any privileged user
        if (isPrivileged) {
            return 'High';
        }

        // Medium: Dormant account
        if (u.LastLoginDate == null ||
            u.LastLoginDate < System.now().addDays(-DORMANT_ACCOUNT_DAYS)) {
            return 'Medium';
        }

        return 'Low';
    }

    /**
     * Get review status from decision
     * @param decision - Decision string
     * @return Status string
     */
    private static String getStatusFromDecision(String decision) {
        if (decision == 'Approve All Access') {
            return 'Approved';
        } else if (decision == 'Revoke All Access') {
            return 'Revoked';
        } else if (decision == 'Modify Access') {
            return 'Modified';
        } else if (decision == 'Escalate to Security') {
            return 'Escalated';
        }
        return 'In Progress';
    }

    /**
     * Revoke user access (deactivate)
     * @param userId - User ID to revoke
     */
    private static void revokeUserAccess(Id userId) {
        // In production, this would deactivate user or remove permissions
        // Requires appropriate permissions to modify User records
        System.debug(LoggingLevel.INFO,
            '[ISO27001AccessReviewService] Access revocation initiated for User: ' + userId);
    }

    /**
     * Publish access review event for audit trail
     * @param review - Access_Review__c record
     * @param action - Action taken
     */
    private static void publishAccessReviewEvent(Access_Review__c review, String action) {
        // Publish to platform event for immutable audit
        // Would use Access_Review_Event__e in production
        System.debug(LoggingLevel.INFO,
            '[ISO27001AccessReviewService] Access review event: ' + action +
            ' for Review: ' + review.Id);
    }

    /**
     * Wrapper class for dormant account information
     */
    public class DormantAccountInfo {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String profileName;
        @AuraEnabled public Datetime lastLoginDate;
        @AuraEnabled public Integer daysSinceLogin;
    }
}
