/**
 * SchedulerErrorHandler - Utility class for scheduler error handling and configuration
 *
 * Provides centralized error logging, success logging, and configuration
 * retrieval from Custom Metadata for all Prometheion schedulers.
 *
 * Security: Uses 'without sharing' to ensure error logging always works
 * regardless of user permissions. This is intentional for system-level logging.
 *
 * @author Prometheion
 * @version 1.0
 */
public without sharing class SchedulerErrorHandler {
    // System context ensures error logging always works regardless of user permissions

    /**
     * Log scheduler error to Integration_Error__c
     * @param schedulerName Name of the scheduler that failed
     * @param e Exception that occurred
     */
    public static void logError(String schedulerName, Exception e) {
        try {
            insert new Integration_Error__c(
                Error_Type__c = 'SCHEDULER_FAILURE',
                Error_Message__c = e.getMessage() != null ? e.getMessage().left(255) : 'Unknown error',
                Stack_Trace__c = e.getStackTraceString() != null ? e.getStackTraceString().left(32000) : '',
                Context__c = schedulerName,
                Timestamp__c = System.now()
            );
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR, 'SchedulerErrorHandler: Failed to log error: ' + logError.getMessage());
        }
    }

    /**
     * Log scheduler success to Integration_Error__c
     * @param schedulerName Name of the scheduler that succeeded
     * @param details Success details message
     */
    public static void logSuccess(String schedulerName, String details) {
        try {
            insert new Integration_Error__c(
                Error_Type__c = 'SCHEDULER_SUCCESS',
                Error_Message__c = details != null ? details.left(255) : 'Scheduler completed successfully',
                Context__c = schedulerName,
                Timestamp__c = System.now()
            );
        } catch (Exception logError) {
            System.debug(LoggingLevel.ERROR, 'SchedulerErrorHandler: Failed to log success: ' + logError.getMessage());
        }
    }

    /**
     * Notify administrators of scheduler failure via Slack
     * @param schedulerName Name of the scheduler that failed
     * @param e Exception that occurred
     */
    public static void notifyOnFailure(String schedulerName, Exception e) {
        try {
            String message = schedulerName + ' failed: ' + (e.getMessage() != null ? e.getMessage() : 'Unknown error');
            SlackNotifier.notifyAsyncQueueable(message);
        } catch (Exception notifyError) {
            System.debug(LoggingLevel.ERROR, 'SchedulerErrorHandler: Failed to notify: ' + notifyError.getMessage());
        }
    }

    /**
     * Get CRON expression from Custom Metadata for a scheduler
     * @param schedulerName DeveloperName of the scheduler config record
     * @param defaultCron Default CRON expression if config not found
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
     * @param schedulerName DeveloperName of the scheduler config record
     * @param defaultSize Default batch size if config not found
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
     * @param schedulerName DeveloperName of the scheduler config record
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
