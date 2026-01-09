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
        System.debug(LoggingLevel.INFO, 'GLBA Annual Notice Scheduler started');

        try {
            // Check if today is a business day
            if (!isBusinessDay()) {
                System.debug(LoggingLevel.INFO, 'Skipping - not a business day');
                return;
            }

            // Get batch size from Custom Metadata, default to 200
            Integer batchSize = 200;
            try {
                Prometheion_Scheduler_Config__mdt config = Prometheion_Scheduler_Config__mdt.getInstance('GLBAAnnualNotice');
                if (config != null && config.Batch_Size__c != null) {
                    batchSize = config.Batch_Size__c.intValue();
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Could not load Custom Metadata, using default batch size: ' + e.getMessage());
            }
            
            Id batchId = Database.executeBatch(new PrometheionGLBAAnnualNoticeBatch(), batchSize);
            System.debug(LoggingLevel.INFO, 'Batch job queued with ID: ' + batchId);

            // Log successful scheduling
            SchedulerErrorHandler.logSuccess('PrometheionGLBAAnnualNoticeScheduler', 'GLBA batch scheduled successfully. BatchId: ' + batchId);

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'GLBA Scheduler failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

            SchedulerErrorHandler.logError('PrometheionGLBAAnnualNoticeScheduler', e);
            SchedulerErrorHandler.notifyOnFailure('PrometheionGLBAAnnualNoticeScheduler', e);
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
     * Check if a specific date is a business day
     * @param checkDate Date to check
     * @return true if business day
     */
    private Boolean isBusinessDay(Date checkDate) {
        DateTime dt = DateTime.newInstance(checkDate, Time.newInstance(0, 0, 0, 0));
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
