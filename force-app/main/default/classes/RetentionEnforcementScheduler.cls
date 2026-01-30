/**
 * Retention Enforcement Scheduler
 * Scheduled job to enforce data retention policies and trigger erasure workflows
 * 
 * Runs weekly to identify data that has exceeded retention periods and trigger
 * erasure workflows according to GDPR Article 5(1)(e) and framework requirements.
 * 
 * Schedule Example:
 * System.schedule('Retention Enforcement', '0 0 2 ? * SUN', new RetentionEnforcementScheduler());
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class RetentionEnforcementScheduler implements Schedulable {
    
    private static final String SCHEDULER_NAME = 'RetentionEnforcementScheduler';
    
    /**
     * Execute the scheduled job
     * @param sc SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        System.debug(LoggingLevel.INFO, SCHEDULER_NAME + ' started');
        
        try {
            // Get batch size from Custom Metadata
            Integer batchSize = getBatchSize();
            
            // Execute batch job to process retention enforcement
            Id batchId = Database.executeBatch(new RetentionEnforcementBatch(), batchSize);
            System.debug(LoggingLevel.INFO, 'Retention enforcement batch queued with ID: ' + batchId);
            
            // Log successful scheduling
            SchedulerErrorHandler.logSuccess(SCHEDULER_NAME, 
                'Retention enforcement batch scheduled successfully. BatchId: ' + batchId);
            
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
            Elaro_Scheduler_Config__mdt config = Elaro_Scheduler_Config__mdt.getInstance('RetentionEnforcement');
            if (config != null && config.Batch_Size__c != null) {
                return config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not load Custom Metadata, using default batch size: ' + e.getMessage());
        }
        return 200;
    }
    
    /**
     * Schedule the job to run weekly on Sunday at 2 AM
     * @return Job ID
     */
    public static String schedule() {
        String cronExpression = '0 0 2 ? * SUN'; // Weekly on Sunday at 2 AM
        return System.schedule('Retention Enforcement', cronExpression, new RetentionEnforcementScheduler());
    }
}
