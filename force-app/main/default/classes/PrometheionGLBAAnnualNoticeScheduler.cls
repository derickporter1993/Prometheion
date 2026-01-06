/**
 * GLBAAnnualNoticeScheduler - Scheduled job for GLBA annual privacy notices
 *
 * Automatically sends annual privacy notices to customers who are due.
 * Should be scheduled to run daily to ensure timely notice delivery.
 *
 * Schedule Example:
 * System.schedule('GLBA Annual Notice Check', '0 0 6 * * ?', new GLBAAnnualNoticeScheduler());
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionGLBAAnnualNoticeScheduler implements Schedulable {

    /**
     * Execute the scheduled job
     * @param sc - SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        // Check if it's a business day
        if (isBusinessDay()) {
            // Queue the batch job to send annual notices
            Database.executeBatch(new PrometheionGLBAAnnualNoticeBatch(), 200);
        }
    }

    /**
     * Check if today is a business day (Mon-Fri)
     * @return true if business day
     */
    private Boolean isBusinessDay() {
        Date today = Date.today();
        DateTime dt = DateTime.newInstance(today, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dt.format('EEEE');
        return dayOfWeek != 'Saturday' && dayOfWeek != 'Sunday';
    }

    /**
     * Schedule the job to run daily at 6 AM
     * @return Job ID
     */
    public static String scheduleDaily() {
        String cronExp = '0 0 6 * * ?'; // 6 AM every day
        return System.schedule(
            'GLBA Annual Notice Distribution - Daily',
            cronExp,
            new PrometheionGLBAAnnualNoticeScheduler()
        );
    }

}
