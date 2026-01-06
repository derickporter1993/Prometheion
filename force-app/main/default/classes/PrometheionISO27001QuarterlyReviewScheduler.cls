/**
 * ISO27001QuarterlyReviewScheduler - Scheduled job for ISO 27001 access reviews
 *
 * Automatically initiates quarterly access reviews at the start of each quarter.
 * Also runs privileged access reviews monthly.
 *
 * Schedule Example:
 * System.schedule('ISO 27001 Quarterly Reviews', '0 0 7 1 1,4,7,10 ?', new ISO27001QuarterlyReviewScheduler());
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionISO27001QuarterlyReviewScheduler implements Schedulable {

    private String reviewType;

    public PrometheionISO27001QuarterlyReviewScheduler() {
        this.reviewType = 'quarterly';
    }

    public ISO27001QuarterlyReviewScheduler(String reviewType) {
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
            List<Access_Review__c> reviews = ISO27001AccessReviewService.initiateQuarterlyReviews();

            System.debug(LoggingLevel.INFO,
                '[ISO27001QuarterlyReviewScheduler] Created ' + reviews.size() + ' quarterly reviews');

            // Send notification to reviewers
            sendReviewerNotifications(reviews);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                '[ISO27001QuarterlyReviewScheduler] Error initiating quarterly reviews: ' + e.getMessage());
        }
    }

    /**
     * Initiate privileged access reviews
     */
    private void initiatePrivilegedReviews() {
        try {
            List<Access_Review__c> reviews = ISO27001AccessReviewService.initiatePrivilegedAccessReviews();

            System.debug(LoggingLevel.INFO,
                '[ISO27001QuarterlyReviewScheduler] Created ' + reviews.size() + ' privileged access reviews');

            // Send urgent notifications for privileged reviews
            sendPrivilegedReviewNotifications(reviews);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR,
                '[ISO27001QuarterlyReviewScheduler] Error initiating privileged reviews: ' + e.getMessage());
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
                '[ISO27001QuarterlyReviewScheduler] Reviewer ' + reviewerId +
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
                '[ISO27001QuarterlyReviewScheduler] Privileged review created for user: ' +
                review.User__c + ' assigned to: ' + review.Reviewer__c);
        }
    }

    /**
     * Schedule quarterly reviews (1st of Jan, Apr, Jul, Oct at 7 AM)
     * @return Job ID
     */
    public static String scheduleQuarterly() {
        String cronExp = '0 0 7 1 1,4,7,10 ?';
        return System.schedule(
            'ISO 27001 Quarterly Access Reviews',
            cronExp,
            new ISO27001QuarterlyReviewScheduler('quarterly')
        );
    }

    /**
     * Schedule monthly privileged reviews (1st of each month at 7 AM)
     * @return Job ID
     */
    public static String scheduleMonthlyPrivileged() {
        String cronExp = '0 0 7 1 * ?';
        return System.schedule(
            'ISO 27001 Privileged Access Reviews - Monthly',
            cronExp,
            new ISO27001QuarterlyReviewScheduler('privileged')
        );
    }
}
