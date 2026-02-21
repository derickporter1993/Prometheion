/**
 * Performance Alert Publisher with improved error handling
 * Best Practice: Validates inputs, provides detailed error messages, structured logging
 * Security: Input validation, secure error handling
 * 
 * Note: Performance_Alert__e platform event not available due to org custom object limits.
 * This version stores alerts in Performance_Alert_History__c instead.
 */
public with sharing class PerformanceAlertPublisher {
    private static final String RATE_LIMIT_PARTITION = 'ElaroRateLimit';
    private static final Integer RATE_LIMIT_MAX_CALLS = 100;
    private static final Integer RATE_LIMIT_WINDOW_SECONDS = 60;
    
    /**
     * Publishes a performance alert by persisting it to Performance_Alert_History__c and optionally
     * sending a Slack notification. Validates inputs, sanitizes metric and stack trace against XSS,
     * and enforces rate limiting (100 calls per 60-second window). Silently skips publication if
     * rate limit is exceeded rather than throwing.
     *
     * @param metric Name of the performance metric that triggered the alert (required)
     * @param value Current observed value of the metric (required)
     * @param threshold Threshold value that was exceeded (required)
     * @param contextRecordId Optional Salesforce record ID providing context for the alert
     * @param stack Optional stack trace or diagnostic information (truncated to 32KB, HTML-escaped)
     * @throws AuraHandledException When inputs are invalid or the alert record fails to save
     */
    @AuraEnabled
    public static void publish(String metric, Decimal value, Decimal threshold, String contextRecordId, String stack) {
        try {
            // Rate limiting check
            if (!checkRateLimit('PerformanceAlertPublisher')) {
                ElaroLogger.warn( 'PerformanceAlertPublisher: Rate limit exceeded, skipping alert publication');
                return;
            }
            // Validate inputs
            if (String.isBlank(metric)) {
                throw new IllegalArgumentException('Metric cannot be blank');
            }
            if (value == null) {
                throw new IllegalArgumentException('Value cannot be null');
            }
            if (threshold == null) {
                throw new IllegalArgumentException('Threshold cannot be null');
            }

            // XSS prevention: sanitize metric parameter
            // Escape HTML special characters (& must be escaped first to prevent double-encoding)
            String safeMetric = metric.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
                .replace('"', '&quot;').replace('\'', '&#39;');

            // Truncate and sanitize stack trace if too long
            String safeStack = String.isNotBlank(stack) && stack.length() > 32768
                ? stack.substring(0, 32765) + '...'
                : stack;
            // XSS protection: escape HTML special characters in stack trace
            // Note: & must be escaped first to prevent double-encoding of &lt; / &gt;
            if (String.isNotBlank(safeStack)) {
                safeStack = safeStack.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;');
            }

            // Store alert in Performance_Alert_History__c instead of platform event
            Performance_Alert_History__c alertHistory = new Performance_Alert_History__c(
                Metric__c = safeMetric,
                Value__c = value,
                Threshold__c = threshold,
                Context_Record__c = contextRecordId,
                Stack__c = safeStack
            );
            
            insert alertHistory;
            
            // Also send Slack notification if configured
            try {
                SlackNotifier.notifyPerformanceAlert(metric, value, threshold, contextRecordId);
            } catch (Exception slackError) {
                ElaroLogger.warn( 'PerformanceAlertPublisher: Slack notification failed: ' + slackError.getMessage());
            }
            
        } catch (IllegalArgumentException e) {
            ElaroLogger.error( 'PerformanceAlertPublisher: Validation error: ' + e.getMessage());
            throw new AuraHandledException('Invalid input: ' + e.getMessage());
        } catch (DmlException e) {
            String correlationId = 'ALERT-' + System.now().getTime() + '-' + Crypto.getRandomInteger();
            ElaroLogger.error( 'PerformanceAlertPublisher: DML error: ' + e.getMessage() + '. CorrelationId: ' + correlationId);
            
            // Log to Integration_Error__c for error tracking
            try {
                Integration_Error__c error = new Integration_Error__c(
                    Error_Type__c = 'DML_ERROR',
                    Error_Message__c = 'Failed to save performance alert: ' + e.getMessage(),
                    Stack_Trace__c = e.getStackTraceString(),
                    Correlation_Id__c = correlationId,
                    Context__c = 'Metric: ' + metric + ', Value: ' + value + ', Threshold: ' + threshold,
                    Status__c = 'NEW',
                    Timestamp__c = System.now()
                );
                insert error;
            } catch (Exception logError) {
                ElaroLogger.warn( 'Failed to log PerformanceAlertPublisher error: ' + logError.getMessage());
            }
            
            throw new AuraHandledException('Failed to publish alert: ' + e.getMessage());
        } catch (Exception e) {
            ElaroLogger.error( 'PerformanceAlertPublisher: Unexpected error: ' + e.getMessage() + ', Stack: ' + e.getStackTraceString());
            throw new AuraHandledException('Failed to publish alert: ' + e.getMessage());
        }
    }
    
    /**
     * Check rate limit using Cache.OrgPartition
     * Returns true if within limit, false if limit exceeded
     */
    private static Boolean checkRateLimit(String key) {
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(RATE_LIMIT_PARTITION);
            String cacheKey = key + '_' + String.valueOf(System.now().getTime() / (RATE_LIMIT_WINDOW_SECONDS * 1000));
            Integer currentCount = (Integer)orgPart.get(cacheKey);
            
            if (currentCount == null) {
                currentCount = 0;
            }
            
            if (currentCount >= RATE_LIMIT_MAX_CALLS) {
                return false;
            }
            
            orgPart.put(cacheKey, currentCount + 1, RATE_LIMIT_WINDOW_SECONDS);
            return true;
        } catch (Exception e) {
            // If cache partition doesn't exist, allow the call
            ElaroLogger.warn( 'PerformanceAlertPublisher: Rate limit check failed, allowing call: ' + e.getMessage());
            return true;
        }
    }
}
