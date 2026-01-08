/**
 * SchedulerErrorHandler - Utility class for scheduler error handling and configuration
 *
 * Provides centralized error logging, success logging, and configuration
 * retrieval from Custom Metadata for all Prometheion schedulers.
 *
 * @author Prometheion
 * @version 1.0
 */
public class SchedulerErrorHandler {

    /**
     * Log a scheduler error to Integration_Error__c
     * @param schedulerName - Name of the scheduler that failed
     * @param e - The exception that occurred
     */
    public static void logError(String schedulerName, Exception e) {
        try {
            if (Schema.sObjectType.Integration_Error__c.isCreateable()) {
                insert new Integration_Error__c(
                    Error_Type__c = 'SCHEDULER_FAILURE',
                    Error_Message__c = e.getMessage().left(255),
                    Stack_Trace__c = e.getStackTraceString().left(32000),
                    Context__c = schedulerName,
                    Timestamp__c = System.now()
                );
            }
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR,
                '[SchedulerErrorHandler] Failed to log error: ' + logError.getMessage());
        }
    }

    /**
     * Log a scheduler success to Integration_Error__c
     * @param schedulerName - Name of the scheduler that succeeded
     * @param details - Details about the successful execution
     */
    public static void logSuccess(String schedulerName, String details) {
        try {
            if (Schema.sObjectType.Integration_Error__c.isCreateable()) {
                insert new Integration_Error__c(
                    Error_Type__c = 'SCHEDULER_SUCCESS',
                    Error_Message__c = details.left(255),
                    Context__c = schedulerName,
                    Timestamp__c = System.now()
                );
            }
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR,
                '[SchedulerErrorHandler] Failed to log success: ' + logError.getMessage());
        }
    }

    /**
     * Send notification on scheduler failure
     * @param schedulerName - Name of the scheduler that failed
     * @param e - The exception that occurred
     */
    public static void notifyOnFailure(String schedulerName, Exception e) {
        try {
            String message = schedulerName + ' failed: ' + e.getMessage();
            SlackNotifier.notifyAsync(message);
        } catch (Exception notifyError) {
            System.debug(LoggingLevel.ERROR,
                '[SchedulerErrorHandler] Failed to notify: ' + notifyError.getMessage());
        }
    }

    /**
     * Get CRON expression from Custom Metadata for a scheduler
     * @param schedulerName - DeveloperName of the scheduler config record
     * @param defaultCron - Default CRON expression if config not found
     * @return CRON expression string
     */
    public static String getCronExpression(String schedulerName, String defaultCron) {
        try {
            Prometheion_Scheduler_Config__mdt config = Prometheion_Scheduler_Config__mdt.getInstance(schedulerName);
            if (config != null && String.isNotBlank(config.CRON_Expression__c)) {
                return config.CRON_Expression__c;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                '[SchedulerErrorHandler] Could not retrieve config for ' + schedulerName +
                ': ' + e.getMessage() + '. Using default.');
        }
        return defaultCron;
    }

    /**
     * Get batch size from Custom Metadata for a scheduler
     * @param schedulerName - DeveloperName of the scheduler config record
     * @param defaultSize - Default batch size if config not found
     * @return Batch size integer
     */
    public static Integer getBatchSize(String schedulerName, Integer defaultSize) {
        try {
            Prometheion_Scheduler_Config__mdt config = Prometheion_Scheduler_Config__mdt.getInstance(schedulerName);
            if (config != null && config.Batch_Size__c != null) {
                return config.Batch_Size__c.intValue();
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                '[SchedulerErrorHandler] Could not retrieve batch size for ' + schedulerName +
                ': ' + e.getMessage() + '. Using default.');
        }
        return defaultSize;
    }

    /**
     * Check if a scheduler is active based on Custom Metadata
     * @param schedulerName - DeveloperName of the scheduler config record
     * @return true if active, false if inactive or not found
     */
    public static Boolean isSchedulerActive(String schedulerName) {
        try {
            Prometheion_Scheduler_Config__mdt config = Prometheion_Scheduler_Config__mdt.getInstance(schedulerName);
            if (config != null) {
                return config.Is_Active__c;
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN,
                '[SchedulerErrorHandler] Could not check active status for ' + schedulerName +
                ': ' + e.getMessage() + '. Assuming active.');
        }
        return true; // Default to active if config not found
    }
}
