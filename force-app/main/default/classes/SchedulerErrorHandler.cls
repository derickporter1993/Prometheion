/**
 * SchedulerErrorHandler - Utility class for consistent scheduler error handling
 *
 * Provides centralized logging and notification for scheduler failures and successes.
 * All schedulers should use this class for consistent error handling.
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
}
