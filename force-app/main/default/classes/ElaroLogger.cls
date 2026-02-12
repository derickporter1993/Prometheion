/**
 * Centralized structured logging service for the Elaro platform.
 * Publishes log entries as LogEvent__e Platform Events in Publish Immediately
 * mode so that logs survive transaction rollbacks. Falls back to System.debug
 * when Platform Event publishing is not available.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Core
 * @see LogEvent__e
 */
public with sharing class ElaroLogger {

    /**
     * Log severity levels
     */
    public enum Level {
        DEBUG,
        INFO,
        WARN,
        ERROR
    }

    /**
     * Log entry structure
     */
    public class LogEntry {
        public Level level;
        public String message;
        public Map<String, Object> context;
        public DateTime timestamp;
        public String userId;
        public String className;
        public String methodName;

        public LogEntry(Level level, String message, Map<String, Object> context) {
            this.level = level;
            this.message = message;
            this.context = context;
            this.timestamp = System.now();
            this.userId = UserInfo.getUserId();
        }
    }

    /**
     * Main logging method. Publishes a LogEvent__e Platform Event for
     * durable, structured logging that survives transaction rollbacks.
     *
     * @param level The log severity level
     * @param message The log message
     * @param context Additional context data (serialized as JSON)
     */
    public static void log(Level level, String message, Map<String, Object> context) {
        if (!shouldLog(level)) {
            return;
        }

        LogEntry entry = new LogEntry(level, message, context);

        // Publish LogEvent__e Platform Event (Publish Immediately mode)
        try {
            LogEvent__e logEvent = new LogEvent__e(
                Level__c = entry.level.name(),
                Message__c = entry.message?.left(131072),
                Context__c = entry.context != null && !entry.context.isEmpty()
                    ? JSON.serialize(entry.context)?.left(131072) : null,
                User_Id__c = entry.userId,
                Timestamp__c = entry.timestamp
            );
            EventBus.publish(logEvent);
        } catch (Exception e) {
            // Fall back to System.debug if Platform Event publish fails
            System.debug(LoggingLevel.ERROR, 'ElaroLogger: Failed to publish LogEvent__e: ' + e.getMessage());
        }

        // Also emit System.debug for developer console visibility
        String logMessage = formatLogEntry(entry);
        if (level == Level.ERROR) {
            System.debug(LoggingLevel.ERROR, logMessage);
        } else if (level == Level.WARN) {
            System.debug(LoggingLevel.WARN, logMessage);
        } else if (level == Level.INFO) {
            System.debug(LoggingLevel.INFO, logMessage);
        } else {
            System.debug(LoggingLevel.DEBUG, logMessage);
        }
    }

    /**
     * Convenience methods
     */
    public static void debug(String message) {
        log(Level.DEBUG, message, null);
    }

    public static void debug(String message, Map<String, Object> context) {
        log(Level.DEBUG, message, context);
    }

    public static void info(String message) {
        log(Level.INFO, message, null);
    }

    public static void info(String message, Map<String, Object> context) {
        log(Level.INFO, message, context);
    }

    public static void warn(String message) {
        log(Level.WARN, message, null);
    }

    public static void warn(String message, Map<String, Object> context) {
        log(Level.WARN, message, context);
    }

    public static void error(String message) {
        log(Level.ERROR, message, null);
    }

    public static void error(String message, Map<String, Object> context) {
        log(Level.ERROR, message, context);
    }

    public static void error(String message, Exception ex) {
        Map<String, Object> context = new Map<String, Object>{
            'exceptionType' => ex.getTypeName(),
            'exceptionMessage' => ex.getMessage(),
            'stackTrace' => ex.getStackTraceString()
        };
        log(Level.ERROR, message, context);
    }

    /**
     * Check if log level should be recorded
     * Can be controlled via Custom Metadata in production
     */
    private static Boolean shouldLog(Level level) {
        // In production, check Custom Metadata Type: Elaro_Log_Settings__mdt
        // For now, log everything except DEBUG in production

        // In test context, suppress all logging
        if (Test.isRunningTest()) {
            return false;
        }

        // Log all levels in sandbox/dev orgs
        // In production, you might want: return level != Level.DEBUG;
        return true;
    }

    /**
     * Format log entry as structured JSON-like string
     */
    private static String formatLogEntry(LogEntry entry) {
        List<String> parts = new List<String>();
        parts.add('[' + entry.level.name() + ']');
        parts.add(entry.timestamp.format('yyyy-MM-dd HH:mm:ss'));
        parts.add('User=' + entry.userId);
        parts.add('Message=' + entry.message);

        if (entry.context != null && !entry.context.isEmpty()) {
            parts.add('Context=' + JSON.serialize(entry.context));
        }

        return String.join(parts, ' | ');
    }
}
