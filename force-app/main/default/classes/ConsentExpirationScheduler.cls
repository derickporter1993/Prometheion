/**
 * Consent Expiration Scheduler
 * Scheduled job to check for expiring consents and send renewal reminders
 * 
 * Runs daily to identify consents that are expiring soon and notify data subjects.
 * Integrates with GDPRConsentManagementService for consent management.
 * 
 * Schedule Example:
 * System.schedule('Consent Expiration Check', '0 0 8 * * ?', new ConsentExpirationScheduler());
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class ConsentExpirationScheduler implements Schedulable {
    
    private static final String SCHEDULER_NAME = 'ConsentExpirationScheduler';
    private static final Integer DEFAULT_EXPIRATION_WARNING_DAYS = 30;
    
    /**
     * Execute the scheduled job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug(LoggingLevel.INFO, SCHEDULER_NAME + ' started');
        
        try {
            // Get batch size from Custom Metadata
            Integer batchSize = getBatchSize();
            
            // Execute batch job to process expiring consents
            Id batchId = Database.executeBatch(new ConsentExpirationBatch(), batchSize);
            System.debug(LoggingLevel.INFO, 'Consent expiration batch queued with ID: ' + batchId);
            
            // Log successful scheduling
            SchedulerErrorHandler.logSuccess(SCHEDULER_NAME, 
                'Consent expiration batch scheduled successfully. BatchId: ' + batchId);
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, SCHEDULER_NAME + ' failed: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            
            SchedulerErrorHandler.logError(SCHEDULER_NAME, e);
            SchedulerErrorHandler.notifyOnFailure(SCHEDULER_NAME, e);
        }
    }
    
    /**
     * Get batch size from Custom Metadata
     * @return Batch size (default 200)
     */
    private Integer getBatchSize() {
        try {
            Elaro_Scheduler_Config__mdt config = Elaro_Scheduler_Config__mdt.getInstance('ConsentExpiration');
            if (config != null && config.Batch_Size__c != null) {
                return config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not load Custom Metadata, using default batch size: ' + e.getMessage());
        }
        return 200;
    }
    
    /**
     * Schedule the job to run daily at 8 AM
     * @return Job ID
     */
    public static String schedule() {
        String cronExpression = '0 0 8 * * ?'; // Daily at 8 AM
        return System.schedule('Consent Expiration Check', cronExpression, new ConsentExpirationScheduler());
    }
}
