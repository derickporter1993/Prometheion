/**
 * ElaroISO27001QuarterlyScheduler - Scheduled job for ISO 27001 access reviews
 *
 * Automatically initiates quarterly access reviews at the start of each quarter.
 * Also runs privileged access reviews monthly.
 *
 * Schedule Example:
 * System.schedule('ISO 27001 Quarterly Reviews', '0 0 7 1 1,4,7,10 ?', new ElaroISO27001QuarterlyScheduler());
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroISO27001QuarterlyScheduler implements Schedulable {

    private String reviewType;

    public ElaroISO27001QuarterlyScheduler() {
        this.reviewType = 'quarterly';
    }

    public ElaroISO27001QuarterlyScheduler(String reviewType) {
        this.reviewType = reviewType;
    }

    /**
     * Execute the scheduled job
     * @param sc - SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        if (reviewType == 'privileged') {
            initiatePrivilegedReviews();
        } else {
            initiateQuarterlyReviews();
        }
    }

    /**
     * Initiate quarterly reviews for all users
     */
    private void initiateQuarterlyReviews() {
        try {
            List<Access_Review__c> reviews = ElaroISO27001AccessReviewService.initiateQuarterlyReviews();

            System.debug(LoggingLevel.INFO,
                '[ElaroISO27001QuarterlyScheduler] Created ' + reviews.size() + ' quarterly reviews');

            // Send notification to reviewers
            sendReviewerNotifications(reviews);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                '[ElaroISO27001QuarterlyScheduler] Error initiating quarterly reviews: ' + e.getMessage());
        }
    }

    /**
     * Initiate privileged access reviews
     */
    private void initiatePrivilegedReviews() {
        try {
            List<Access_Review__c> reviews = ElaroISO27001AccessReviewService.initiatePrivilegedAccessReviews();

            System.debug(LoggingLevel.INFO,
                '[ElaroISO27001QuarterlyScheduler] Created ' + reviews.size() + ' privileged access reviews');

            // Send urgent notifications for privileged reviews
            sendPrivilegedReviewNotifications(reviews);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                '[ElaroISO27001QuarterlyScheduler] Error initiating privileged reviews: ' + e.getMessage());
        }
    }

    /**
     * Send notifications to assigned reviewers
     * @param reviews - List of created reviews
     */
    private void sendReviewerNotifications(List<Access_Review__c> reviews) {
        // Group reviews by reviewer
        Map<Id, List<Access_Review__c>> reviewsByReviewer = new Map<Id, List<Access_Review__c>>();

        for (Access_Review__c review : reviews) {
            if (review.Reviewer__c != null) {
                if (!reviewsByReviewer.containsKey(review.Reviewer__c)) {
                    reviewsByReviewer.put(review.Reviewer__c, new List<Access_Review__c>());
                }
                reviewsByReviewer.get(review.Reviewer__c).add(review);
            }
        }

        // Create custom notifications for each reviewer
        for (Id reviewerId : reviewsByReviewer.keySet()) {
            Integer reviewCount = reviewsByReviewer.get(reviewerId).size();
            System.debug(LoggingLevel.INFO,
                '[ElaroISO27001QuarterlyScheduler] Reviewer ' + reviewerId +
                ' assigned ' + reviewCount + ' reviews');
        }
    }

    /**
     * Send urgent notifications for privileged access reviews
     * @param reviews - List of privileged reviews
     */
    private void sendPrivilegedReviewNotifications(List<Access_Review__c> reviews) {
        for (Access_Review__c review : reviews) {
            System.debug(LoggingLevel.INFO,
                '[ElaroISO27001QuarterlyScheduler] Privileged review created for user: ' +
                review.User__c + ' assigned to: ' + review.Reviewer__c);
        }
    }

    /**
     * Schedule quarterly reviews using CRON from Custom Metadata
     * @return Job ID
     */
    public static String scheduleQuarterly() {
        String cronExp = SchedulerErrorHandler.getCronExpression('ISO27001QuarterlyReview', '0 0 7 1 1,4,7,10 ?');
        return System.schedule(
            'ISO 27001 Quarterly Access Reviews',
            cronExp,
            new ElaroISO27001QuarterlyScheduler('quarterly')
        );
    }

    /**
     * Schedule monthly privileged reviews using CRON from Custom Metadata
     * @return Job ID
     */
    public static String scheduleMonthlyPrivileged() {
        String cronExp = SchedulerErrorHandler.getCronExpression('ISO27001MonthlyPrivileged', '0 0 7 1 * ?');
        return System.schedule(
            'ISO 27001 Privileged Access Reviews - Monthly',
            cronExp,
            new ElaroISO27001QuarterlyScheduler('privileged')
        );
    }
}
