/**
 * TriggerRecursionGuard
 *
 * Utility class to prevent recursive trigger execution.
 * Use this in triggers to avoid infinite loops when triggers
 * cause DML operations that re-fire the same trigger.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class TriggerRecursionGuard {

    private static Set<String> runningTriggers = new Set<String>();

    /**
     * Check if this is the first execution of a trigger
     * @param triggerName Unique identifier for the trigger
     * @return true if this is the first run, false if already running
     */
    public static Boolean isFirstRun(String triggerName) {
        if (runningTriggers.contains(triggerName)) {
            return false;
        }
        runningTriggers.add(triggerName);
        return true;
    }

    /**
     * Reset the guard for a specific trigger
     * Call this in a finally block to ensure cleanup
     * @param triggerName Unique identifier for the trigger
     */
    public static void reset(String triggerName) {
        runningTriggers.remove(triggerName);
    }

    /**
     * Reset all trigger guards
     * Primarily for test cleanup
     */
    @TestVisible
    private static void resetAll() {
        runningTriggers.clear();
    }

    /**
     * Check if a specific trigger is currently running
     * @param triggerName Unique identifier for the trigger
     * @return true if the trigger is currently running
     */
    public static Boolean isRunning(String triggerName) {
        return runningTriggers.contains(triggerName);
    }

    /**
     * Get count of currently running triggers
     * Useful for debugging
     * @return Number of triggers currently marked as running
     */
    @TestVisible
    private static Integer getRunningCount() {
        return runningTriggers.size();
    }
}
