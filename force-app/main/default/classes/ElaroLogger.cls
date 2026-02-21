/**
 * ElaroLogger
 *
 * Centralized structured logging service for Elaro platform
 * Replaces System.debug with configurable, auditable logging
 *
 * @author Elaro
 * @version 1.0
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
     * Main logging method
     */
    public static void log(Level level, String message, Map<String, Object> context) {
        if (!shouldLog(level)) {
            return;
        }

        LogEntry entry = new LogEntry(level, message, context);

        // In production, you might want to:
        // 1. Insert to custom object: insert new Elaro_Log__c(...)
        // 2. Publish platform event: EventBus.publish(new Elaro_Log_Event__e(...))
        // 3. Send to external SIEM via callout

        // For now, use System.debug with structured format
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
     * Logs a message at DEBUG level without additional context.
     *
     * @param message The log message describing what occurred
     */
    public static void debug(String message) {
        log(Level.DEBUG, message, null);
    }

    /**
     * Logs a message at DEBUG level with additional structured context.
     *
     * @param message The log message describing what occurred
     * @param context Key-value pairs providing additional diagnostic data
     */
    public static void debug(String message, Map<String, Object> context) {
        log(Level.DEBUG, message, context);
    }

    /**
     * Logs a message at INFO level without additional context.
     *
     * @param message The log message describing what occurred
     */
    public static void info(String message) {
        log(Level.INFO, message, null);
    }

    /**
     * Logs a message at INFO level with additional structured context.
     *
     * @param message The log message describing what occurred
     * @param context Key-value pairs providing additional diagnostic data
     */
    public static void info(String message, Map<String, Object> context) {
        log(Level.INFO, message, context);
    }

    /**
     * Logs a message at WARN level without additional context.
     *
     * @param message The log message describing a potential issue or degraded condition
     */
    public static void warn(String message) {
        log(Level.WARN, message, null);
    }

    /**
     * Logs a message at WARN level with additional structured context.
     *
     * @param message The log message describing a potential issue or degraded condition
     * @param context Key-value pairs providing additional diagnostic data
     */
    public static void warn(String message, Map<String, Object> context) {
        log(Level.WARN, message, context);
    }

    /**
     * Logs a message at ERROR level without additional context.
     *
     * @param message The log message describing the error condition
     */
    public static void error(String message) {
        log(Level.ERROR, message, null);
    }

    /**
     * Logs a message at ERROR level with additional structured context.
     *
     * @param message The log message describing the error condition
     * @param context Key-value pairs providing additional diagnostic data
     */
    public static void error(String message, Map<String, Object> context) {
        log(Level.ERROR, message, context);
    }

    /**
     * Logs a message at ERROR level with exception details automatically extracted
     * into structured context (exception type, message, and stack trace).
     *
     * @param message The log message describing the error condition
     * @param ex The caught exception whose details will be included in the log context
     */
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
