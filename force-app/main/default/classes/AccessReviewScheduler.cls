/**
 * AccessReviewScheduler
 *
 * Scheduled job to automate periodic access reviews for SOC2 and HIPAA compliance.
 * Identifies users requiring review, creates review records, and sends notifications.
 *
 * Schedule: Monthly (recommended)
 * Example: System.schedule('Monthly Access Review', '0 0 6 1 * ?', new AccessReviewScheduler());
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class AccessReviewScheduler implements Schedulable {

    private static final Integer DEFAULT_REVIEW_CYCLE_DAYS = 90;
    private static final String JOB_NAME = 'Elaro Access Review';

    /**
     * Schedulable execute method
     */
    public void execute(SchedulableContext ctx) {
        // Run in future context to avoid governor limits
        runAccessReviewAsync();
    }

    /**
     * Async method to perform access review
     */
    @future
    private static void runAccessReviewAsync() {
        AccessReviewScheduler scheduler = new AccessReviewScheduler();
        scheduler.performAccessReview();
    }

    /**
     * Perform the access review process
     */
    public void performAccessReview() {
        try {
            // Get users requiring review
            List<User> usersToReview = getUsersRequiringReview();

            if (usersToReview.isEmpty()) {
                logExecution('No users requiring review at this time', 0);
                return;
            }

            // Create access review records
            List<Access_Review__c> reviews = createReviewRecords(usersToReview);

            // Insert review records
            if (!reviews.isEmpty()) {
                ElaroSecurityUtils.validateCRUDAccess('Access_Review__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
                insert reviews;
            }

            // Check for stale permissions
            checkStalePermissions(usersToReview);

            // Log successful execution
            logExecution('Access review completed successfully', reviews.size());

        } catch (Exception e) {
            logError('Access review failed: ' + e.getMessage());
        }
    }

    /**
     * Get users that require access review
     */
    private List<User> getUsersRequiringReview() {
        Date reviewCutoff = Date.today().addDays(-DEFAULT_REVIEW_CYCLE_DAYS);

        // Get users who haven't been reviewed recently
        Set<Id> recentlyReviewedUserIds = new Set<Id>();

        for (Access_Review__c review : [
            SELECT User__c
            FROM Access_Review__c
            WHERE Review_Date__c >= :reviewCutoff
            AND Status__c IN ('Completed', 'Approved')
            WITH SECURITY_ENFORCED
        ]) {
            if (review.User__c != null) {
                recentlyReviewedUserIds.add(review.User__c);
            }
        }

        // Get active users with significant permissions
        return [
            SELECT Id, Name, Username, Email, Profile.Name, ProfileId,
                   LastLoginDate, IsActive, UserRole.Name
            FROM User
            WHERE IsActive = true
            AND Id NOT IN :recentlyReviewedUserIds
            AND Profile.Name != 'Chatter Free User'
            AND Profile.Name != 'Chatter External User'
            WITH SECURITY_ENFORCED
            ORDER BY LastLoginDate DESC NULLS LAST
            LIMIT 500
        ];
    }

    /**
     * Create access review records for users
     */
    private List<Access_Review__c> createReviewRecords(List<User> users) {
        List<Access_Review__c> reviews = new List<Access_Review__c>();
        Date dueDate = Date.today().addDays(14); // 2 weeks to complete review

        for (User u : users) {
            Access_Review__c review = new Access_Review__c();
            review.User__c = u.Id;
            review.Review_Type__c = 'Periodic Review';
            review.Status__c = 'Pending';
            review.Due_Date__c = dueDate;
            review.Review_Scope__c = 'Full Access Review';
            review.Notes__c = 'Automated periodic review. Profile: ' + u.Profile.Name;

            // Determine priority based on last login
            if (u.LastLoginDate == null || u.LastLoginDate < DateTime.now().addDays(-60)) {
                review.Priority__c = 'High';
                review.Notes__c += '. User has not logged in recently - verify access is still required.';
            } else {
                review.Priority__c = 'Medium';
            }

            reviews.add(review);
        }

        return reviews;
    }

    /**
     * Check for stale permissions across users
     */
    private void checkStalePermissions(List<User> users) {
        Set<Id> userIds = new Set<Id>();
        for (User u : users) {
            userIds.add(u.Id);
        }

        // Check for permission set assignments that might be stale
        List<PermissionSetAssignment> assignments = [
            SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
            FROM PermissionSetAssignment
            WHERE AssigneeId IN :userIds
            AND PermissionSet.IsOwnedByProfile = false
            WITH SECURITY_ENFORCED
        ];

        // Log permission set counts for review
        Map<Id, Integer> permissionCounts = new Map<Id, Integer>();
        for (PermissionSetAssignment psa : assignments) {
            if (!permissionCounts.containsKey(psa.AssigneeId)) {
                permissionCounts.put(psa.AssigneeId, 0);
            }
            permissionCounts.put(psa.AssigneeId, permissionCounts.get(psa.AssigneeId) + 1);
        }

        // Flag users with excessive permission sets
        for (Id userId : permissionCounts.keySet()) {
            if (permissionCounts.get(userId) > 10) {
                createComplianceGap(userId, permissionCounts.get(userId));
            }
        }
    }

    /**
     * Create compliance gap for excessive permissions
     */
    private void createComplianceGap(Id userId, Integer permSetCount) {
        try {
            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'Access Control';
            gap.Framework__c = 'SOC2';
            gap.Severity__c = 'Medium';
            gap.Status__c = 'Open';
            gap.Description__c = 'User has ' + permSetCount + ' permission sets assigned. ' +
                'Review for excessive access per principle of least privilege.';
            gap.Remediation_Steps__c = 'Review all permission set assignments and remove unnecessary access.';
            gap.Due_Date__c = Date.today().addDays(30);

            ElaroSecurityUtils.validateCRUDAccess('Compliance_Gap__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert gap;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to create compliance gap: ' + e.getMessage());
        }
    }

    /**
     * Log successful execution
     */
    private void logExecution(String message, Integer recordsProcessed) {
        try {
            Elaro_Audit_Log__c log = new Elaro_Audit_Log__c();
            log.Action__c = 'Access Review Scheduled Job';
            log.Status__c = 'Success';
            log.Details__c = message + '. Records processed: ' + recordsProcessed;
            log.User__c = UserInfo.getUserId();
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log execution: ' + e.getMessage());
        }
    }

    /**
     * Log error
     */
    private void logError(String message) {
        try {
            Elaro_Audit_Log__c log = new Elaro_Audit_Log__c();
            log.Action__c = 'Access Review Scheduled Job';
            log.Status__c = 'Error';
            log.Details__c = message;
            log.User__c = UserInfo.getUserId();
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + e.getMessage());
        }
    }

    // ========== Static Utility Methods ==========

    /**
     * Schedule the job with default settings
     */
    public static String scheduleMonthly() {
        // Run at 6 AM on the 1st of each month
        String cronExp = '0 0 6 1 * ?';
        return System.schedule(JOB_NAME + ' - Monthly', cronExp, new AccessReviewScheduler());
    }

    /**
     * Schedule the job with custom cron expression
     */
    public static String scheduleCustom(String cronExpression, String jobSuffix) {
        return System.schedule(JOB_NAME + ' - ' + jobSuffix, cronExpression, new AccessReviewScheduler());
    }

    /**
     * Abort all scheduled access review jobs
     */
    public static void abortAllJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%' + JOB_NAME + '%')
        ];

        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }

    /**
     * Get status of scheduled jobs
     */
    public static List<JobStatus> getScheduledJobs() {
        List<JobStatus> statuses = new List<JobStatus>();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, State, NextFireTime, PreviousFireTime
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%' + JOB_NAME + '%')
        ];

        for (CronTrigger job : jobs) {
            JobStatus status = new JobStatus();
            status.jobId = job.Id;
            status.jobName = job.CronJobDetail.Name;
            status.state = job.State;
            status.nextRunTime = job.NextFireTime;
            status.lastRunTime = job.PreviousFireTime;
            statuses.add(status);
        }

        return statuses;
    }

    /**
     * Run immediately (for testing or manual execution)
     */
    @AuraEnabled
    public static void runNow() {
        AccessReviewScheduler scheduler = new AccessReviewScheduler();
        scheduler.performAccessReview();
    }

    // ========== Inner Classes ==========

    public class JobStatus {
        @AuraEnabled public Id jobId;
        @AuraEnabled public String jobName;
        @AuraEnabled public String state;
        @AuraEnabled public DateTime nextRunTime;
        @AuraEnabled public DateTime lastRunTime;
    }
}
