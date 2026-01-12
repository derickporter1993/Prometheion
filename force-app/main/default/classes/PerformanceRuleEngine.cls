/**
 * Performance rule evaluation engine with improved error handling and validation
 * Best Practice: Validates inputs, extracts helper methods, improves error reporting
 * Security: Input validation, safe parsing, structured error handling
 * 
 * Note: Performance_Alert__e platform event not available due to org custom object limits.
 * This version stores alerts in Performance_Alert_History__c instead.
 */
public with sharing class PerformanceRuleEngine {
    public class EvalResult {
        @AuraEnabled
        public Boolean warning;
        @AuraEnabled
        public Boolean critical;
        @AuraEnabled
        public String message;
        @AuraEnabled
        public Integer eventsPublished;
        @AuraEnabled
        public Integer eventsFailed;
    }

    private static final Integer DEFAULT_CPU_WARN = 8000;
    private static final Integer DEFAULT_CPU_CRIT = 9000;
    private static final Integer DEFAULT_HEAP_WARN = 4500;
    private static final Integer DEFAULT_HEAP_CRIT = 5000;
    private static final Integer DEFAULT_SOQL_WARN = 90;
    private static final Integer DEFAULT_SOQL_CRIT = 100;
    private static final Integer DEFAULT_DML_WARN = 140;
    private static final Integer DEFAULT_DML_CRIT = 150;

    @AuraEnabled
    public static EvalResult evaluateAndPublish(
        LimitMetrics.GovernorStats stats,
        String contextRecordId
    ) {
        EvalResult out = new EvalResult();
        out.warning = false;
        out.critical = false;
        out.eventsPublished = 0;
        out.eventsFailed = 0;

        try {
            // Validate inputs
            if (stats == null) {
                throw new IllegalArgumentException('GovernorStats cannot be null');
            }

            // Get thresholds with safe parsing
            Thresholds thresholds = getThresholds();

            List<AlertData> alertsToSave = new List<AlertData>();

            // Check all thresholds using helper method
            checkThreshold('CPU', stats.cpuMs, thresholds.cpuWarn, thresholds.cpuCrit, contextRecordId, out, alertsToSave);
            checkThreshold('HEAP', stats.heapKb, thresholds.heapWarn, thresholds.heapCrit, contextRecordId, out, alertsToSave);
            checkThreshold('SOQL', stats.soql, thresholds.soqlWarn, thresholds.soqlCrit, contextRecordId, out, alertsToSave);
            checkThreshold('DML', stats.dml, thresholds.dmlWarn, thresholds.dmlCrit, contextRecordId, out, alertsToSave);

            // Save all alerts at once
            if (!alertsToSave.isEmpty()) {
                SaveResult saveResult = saveAlerts(alertsToSave);
                out.eventsPublished = saveResult.saved;
                out.eventsFailed = saveResult.failed;

                if (saveResult.failed > 0) {
                    out.message = 'Evaluated stats. Saved ' + saveResult.saved + ' alerts, ' + saveResult.failed + ' failed.';
                } else {
                    out.message = 'Evaluated stats. Saved ' + saveResult.saved + ' alerts successfully.';
                }
            } else {
                out.message = 'Evaluated current governor stats against thresholds. No alerts triggered.';
            }

            return out;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'PerformanceRuleEngine: Error in evaluateAndPublish. Error: ' + e.getMessage() + ', Stack: ' + e.getStackTraceString());
            out.message = 'Error evaluating performance: ' + e.getMessage();
            return out;
        }
    }

    /**
     * Get thresholds with safe parsing and validation
     */
    private static Thresholds getThresholds() {
        Thresholds t = new Thresholds();
        CCX_Settings__c s = null;
        try {
            s = CCX_Settings__c.getInstance();
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'CCX_Settings__c not accessible or not configured: ' + e.getMessage());
        }

        if (s != null) {
            t.cpuWarn = safeParseInteger(s.CPU_Warn__c, DEFAULT_CPU_WARN);
            t.cpuCrit = safeParseInteger(s.CPU_Crit__c, DEFAULT_CPU_CRIT);
            t.heapWarn = safeParseInteger(s.Heap_Warn__c, DEFAULT_HEAP_WARN);
            t.heapCrit = safeParseInteger(s.Heap_Crit__c, DEFAULT_HEAP_CRIT);
            t.soqlWarn = safeParseInteger(s.SOQL_Warn__c, DEFAULT_SOQL_WARN);
            t.soqlCrit = safeParseInteger(s.SOQL_Crit__c, DEFAULT_SOQL_CRIT);
            t.dmlWarn = safeParseInteger(s.DML_Warn__c, DEFAULT_DML_WARN);
            t.dmlCrit = safeParseInteger(s.DML_Crit__c, DEFAULT_DML_CRIT);
        } else {
            // Use defaults
            t.cpuWarn = DEFAULT_CPU_WARN;
            t.cpuCrit = DEFAULT_CPU_CRIT;
            t.heapWarn = DEFAULT_HEAP_WARN;
            t.heapCrit = DEFAULT_HEAP_CRIT;
            t.soqlWarn = DEFAULT_SOQL_WARN;
            t.soqlCrit = DEFAULT_SOQL_CRIT;
            t.dmlWarn = DEFAULT_DML_WARN;
            t.dmlCrit = DEFAULT_DML_CRIT;
        }

        // Validate thresholds are reasonable
        validateThresholds(t);

        return t;
    }

    /**
     * Safely parse integer with default fallback
     */
    private static Integer safeParseInteger(Decimal value, Integer defaultValue) {
        if (value == null) {
            return defaultValue;
        }
        try {
            Integer intValue = Integer.valueOf(value);
            // Guard against negative or unreasonably large values
            if (intValue < 0 || intValue > 100000) {
                System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: Threshold value out of range: ' + intValue + ', using default: ' + defaultValue);
                return defaultValue;
            }
            return intValue;
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: Failed to parse threshold value: ' + value + ', using default: ' + defaultValue);
            return defaultValue;
        }
    }

    /**
     * Validate thresholds are in reasonable ranges
     */
    private static void validateThresholds(Thresholds t) {
        // Ensure warn < crit for all metrics
        if (t.cpuWarn >= t.cpuCrit) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: CPU warn threshold >= crit, adjusting');
            t.cpuWarn = t.cpuCrit - 1000;
        }
        if (t.heapWarn >= t.heapCrit) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: Heap warn threshold >= crit, adjusting');
            t.heapWarn = t.heapCrit - 500;
        }
        if (t.soqlWarn >= t.soqlCrit) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: SOQL warn threshold >= crit, adjusting');
            t.soqlWarn = t.soqlCrit - 10;
        }
        if (t.dmlWarn >= t.dmlCrit) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: DML warn threshold >= crit, adjusting');
            t.dmlWarn = t.dmlCrit - 10;
        }
    }

    /**
     * Check threshold and create alert data if needed
     */
    private static void checkThreshold(
        String metric,
        Decimal value,
        Integer warnThreshold,
        Integer critThreshold,
        String contextRecordId,
        EvalResult result,
        List<AlertData> alerts
    ) {
        if (value == null) {
            System.debug(LoggingLevel.WARN, 'PerformanceRuleEngine: Null value for metric: ' + metric);
            return;
        }

        // Create alert data using helper method
        AlertData alert = createAlertData(metric, value, warnThreshold, critThreshold, contextRecordId);

        if (alert != null) {
            alerts.add(alert);
            if (value >= critThreshold) {
                result.critical = true;
            } else if (value >= warnThreshold) {
                result.warning = true;
            }
        }
    }

    /**
     * Create alert data
     */
    private static AlertData createAlertData(
        String metric,
        Decimal value,
        Integer warnThreshold,
        Integer critThreshold,
        String contextRecordId
    ) {
        if (value >= critThreshold) {
            AlertData alert = new AlertData();
            alert.metric = metric;
            alert.value = value;
            alert.threshold = critThreshold;
            alert.contextRecordId = contextRecordId;
            alert.stack = metric + ' critical threshold exceeded: ' + value + ' >= ' + critThreshold;
            return alert;
        } else if (value >= warnThreshold) {
            AlertData alert = new AlertData();
            alert.metric = metric;
            alert.value = value;
            alert.threshold = warnThreshold;
            alert.contextRecordId = contextRecordId;
            alert.stack = metric + ' warning threshold exceeded: ' + value + ' >= ' + warnThreshold;
            return alert;
        }
        return null;
    }

    /**
     * Save alerts to Performance_Alert_History__c
     */
    private static SaveResult saveAlerts(List<AlertData> alerts) {
        SaveResult result = new SaveResult();
        result.saved = 0;
        result.failed = 0;

        if (alerts == null || alerts.isEmpty()) {
            return result;
        }

        try {
            List<Performance_Alert_History__c> records = new List<Performance_Alert_History__c>();
            for (AlertData alert : alerts) {
                Performance_Alert_History__c record = new Performance_Alert_History__c(
                    Metric__c = alert.metric,
                    Value__c = alert.value,
                    Threshold__c = alert.threshold,
                    Context_Record__c = alert.contextRecordId,
                    Stack__c = alert.stack
                );
                records.add(record);
            }

            // Use USER_MODE for FLS enforcement and add structured error tracking
            List<Database.SaveResult> results = Database.insert(records, AccessLevel.USER_MODE, false);

            for (Integer i = 0; i < results.size(); i++) {
                Database.SaveResult sr = results[i];
                if (sr.isSuccess()) {
                    result.saved++;
                } else {
                    result.failed++;
                    // Structured error logging with correlation ID for monitoring
                    String correlationId = generateCorrelationId(alerts[i].metric, alerts[i].value);
                    List<String> errorMessages = new List<String>();
                    for (Database.Error err : sr.getErrors()) {
                        errorMessages.add(err.getMessage() + ' (' + err.getStatusCode() + ')');
                    }
                    String errorMsg = String.join(errorMessages, '; ');
                    
                    // Log with structured format for monitoring systems
                    System.debug(LoggingLevel.ERROR, 
                        '[PerformanceRuleEngine] Alert save failed - ' +
                        'CorrelationId: ' + correlationId + ', ' +
                        'Metric: ' + alerts[i].metric + ', ' +
                        'Value: ' + alerts[i].value + ', ' +
                        'Errors: ' + errorMsg);
                }
            }
        } catch (DmlException e) {
            // Structured error logging with correlation ID
            String correlationId = generateCorrelationId('BULK_SAVE', String.valueOf(alerts.size()));
            System.debug(LoggingLevel.ERROR, 
                '[PerformanceRuleEngine] DML exception saving alerts - ' +
                'CorrelationId: ' + correlationId + ', ' +
                'AlertCount: ' + alerts.size() + ', ' +
                'Error: ' + e.getMessage() + ', ' +
                'StackTrace: ' + e.getStackTraceString());
            result.failed = alerts.size();
        } catch (Exception e) {
            // Structured error logging with correlation ID
            String correlationId = generateCorrelationId('BULK_SAVE', String.valueOf(alerts.size()));
            System.debug(LoggingLevel.ERROR, 
                '[PerformanceRuleEngine] Unexpected exception saving alerts - ' +
                'CorrelationId: ' + correlationId + ', ' +
                'AlertCount: ' + alerts.size() + ', ' +
                'Error: ' + e.getMessage() + ', ' +
                'StackTrace: ' + e.getStackTraceString());
            result.failed = alerts.size();
        }

        return result;
    }

    /**
     * Generate correlation ID for structured logging and monitoring
     */
    private static String generateCorrelationId(String metric, Decimal value) {
        String input = metric + '|' + String.valueOf(value) + '|' + UserInfo.getUserId();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
    }

    private static String generateCorrelationId(String prefix, String suffix) {
        String input = prefix + '|' + suffix + '|' + UserInfo.getUserId();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
    }

    /**
     * Helper class for alert data
     */
    private class AlertData {
        String metric;
        Decimal value;
        Integer threshold;
        String contextRecordId;
        String stack;
    }

    /**
     * Helper class for thresholds
     */
    private class Thresholds {
        Integer cpuWarn;
        Integer cpuCrit;
        Integer heapWarn;
        Integer heapCrit;
        Integer soqlWarn;
        Integer soqlCrit;
        Integer dmlWarn;
        Integer dmlCrit;
    }

    /**
     * Helper class for save results
     */
    private class SaveResult {
        Integer saved;
        Integer failed;
    }
}
