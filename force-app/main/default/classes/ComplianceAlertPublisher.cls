/**
 * Publishes ComplianceAlert__e Platform Events for real-time compliance
 * monitoring notifications. Events are published in Publish Immediately
 * mode so they survive transaction rollbacks.
 *
 * SECURITY: without sharing required because this class publishes Platform Events
 * for audit logging which must succeed regardless of the running user's record access.
 * Caller permission validation happens in the controller/service layer.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see ComplianceAlert__e
 * @see EventCorrelationEngine
 */
public without sharing class ComplianceAlertPublisher {

    private static final String CLASS_NAME = 'ComplianceAlertPublisher';

    /**
     * Alert types supported by the publisher.
     */
    public static final String ALERT_TYPE_FINDING = 'FINDING';
    public static final String ALERT_TYPE_DRIFT = 'DRIFT';
    public static final String ALERT_TYPE_BREACH = 'BREACH';
    public static final String ALERT_TYPE_THRESHOLD = 'THRESHOLD';
    public static final String ALERT_TYPE_POLICY = 'POLICY_VIOLATION';

    /**
     * Publishes a single compliance alert event.
     *
     * @param framework The compliance framework (e.g., SOC2, HIPAA)
     * @param controlReference The control identifier (e.g., CC6.1)
     * @param severity The alert severity (CRITICAL, HIGH, MEDIUM, LOW)
     * @param findingSummary Description of the finding
     * @param alertType The type of alert (FINDING, DRIFT, BREACH, THRESHOLD, POLICY_VIOLATION)
     * @param sourceRecordId The Id of the source record that triggered the alert
     * @return Database.SaveResult from the event publish operation
     */
    public static Database.SaveResult publishAlert(
        String framework,
        String controlReference,
        String severity,
        String findingSummary,
        String alertType,
        String sourceRecordId
    ) {
        ComplianceAlert__e alert = new ComplianceAlert__e(
            Framework__c = framework,
            Control_Reference__c = controlReference,
            Severity__c = severity ?? ElaroConstants.SEVERITY_MEDIUM,
            Finding_Summary__c = findingSummary,
            Alert_Type__c = alertType ?? ALERT_TYPE_FINDING,
            Source_Record_Id__c = sourceRecordId
        );

        Database.SaveResult result = EventBus.publish(alert);

        if (!result.isSuccess()) {
            ElaroLogger.error(CLASS_NAME + '.publishAlert: Failed to publish alert', new Map<String, Object>{
                'framework' => framework,
                'severity' => severity,
                'alertType' => alertType,
                'errors' => formatErrors(result.getErrors())
            });
        } else {
            ElaroLogger.info(CLASS_NAME + '.publishAlert: Alert published', new Map<String, Object>{
                'framework' => framework,
                'severity' => severity,
                'alertType' => alertType
            });
        }

        return result;
    }

    /**
     * Publishes multiple compliance alert events in bulk.
     *
     * @param alerts List of ComplianceAlert__e events to publish
     * @return List of Database.SaveResult from the bulk publish
     */
    public static List<Database.SaveResult> publishAlerts(List<ComplianceAlert__e> alerts) {
        if (alerts == null || alerts.isEmpty()) {
            return new List<Database.SaveResult>();
        }

        List<Database.SaveResult> results = EventBus.publish(alerts);
        Integer failCount = 0;

        for (Integer i = 0; i < results.size(); i++) {
            if (!results[i].isSuccess()) {
                failCount++;
                ElaroLogger.error(CLASS_NAME + '.publishAlerts: Failed to publish alert ' + i, new Map<String, Object>{
                    'errors' => formatErrors(results[i].getErrors())
                });
            }
        }

        ElaroLogger.info(CLASS_NAME + '.publishAlerts: Bulk publish complete', new Map<String, Object>{
            'total' => alerts.size(),
            'succeeded' => alerts.size() - failCount,
            'failed' => failCount
        });

        return results;
    }

    /**
     * Publishes a drift detection alert when configuration drift is detected.
     *
     * @param changeType The type of configuration change detected
     * @param changedBy The user who made the change
     * @param changedObject The object/setting that was changed
     * @param oldValue The previous value
     * @param newValue The new value
     * @param riskLevel The risk level of the drift (CRITICAL, HIGH, MEDIUM, LOW)
     * @return Database.SaveResult from the event publish operation
     */
    public static Database.SaveResult publishDriftAlert(
        String changeType,
        String changedBy,
        String changedObject,
        String oldValue,
        String newValue,
        String riskLevel
    ) {
        ConfigurationDrift__e drift = new ConfigurationDrift__e(
            Change_Type__c = changeType,
            Changed_By__c = changedBy,
            Changed_Object__c = changedObject,
            Old_Value__c = oldValue,
            New_Value__c = newValue,
            Risk_Level__c = riskLevel ?? ElaroConstants.SEVERITY_MEDIUM,
            Detection_Timestamp__c = System.now()
        );

        Database.SaveResult result = EventBus.publish(drift);

        if (!result.isSuccess()) {
            ElaroLogger.error(CLASS_NAME + '.publishDriftAlert: Failed to publish drift', new Map<String, Object>{
                'changeType' => changeType,
                'changedObject' => changedObject,
                'errors' => formatErrors(result.getErrors())
            });
        }

        return result;
    }

    /**
     * Publishes a breach indicator event when a breach pattern is matched.
     *
     * @param patternName The name of the matched breach pattern
     * @param severity The severity level of the breach indicator
     * @param eventSequence JSON array of event types that triggered the match
     * @param timeWindowMinutes The time window in which the events occurred
     * @param affectedUserId The Id of the user involved in the breach pattern
     * @return Database.SaveResult from the event publish operation
     */
    public static Database.SaveResult publishBreachIndicator(
        String patternName,
        String severity,
        String eventSequence,
        Decimal timeWindowMinutes,
        String affectedUserId
    ) {
        BreachIndicator__e breach = new BreachIndicator__e(
            Pattern_Name__c = patternName,
            Severity__c = severity ?? ElaroConstants.SEVERITY_CRITICAL,
            Event_Sequence__c = eventSequence,
            Time_Window_Minutes__c = timeWindowMinutes,
            Affected_User_Id__c = affectedUserId
        );

        Database.SaveResult result = EventBus.publish(breach);

        if (!result.isSuccess()) {
            ElaroLogger.error(CLASS_NAME + '.publishBreachIndicator: Failed to publish breach', new Map<String, Object>{
                'patternName' => patternName,
                'severity' => severity,
                'errors' => formatErrors(result.getErrors())
            });
        } else {
            ElaroLogger.warn(CLASS_NAME + '.publishBreachIndicator: Breach indicator published', new Map<String, Object>{
                'patternName' => patternName,
                'severity' => severity,
                'affectedUserId' => affectedUserId
            });
        }

        return result;
    }

    /**
     * Formats Database.Error list into a readable string for logging.
     *
     * @param errors List of Database.Error objects
     * @return Comma-separated error messages
     */
    private static String formatErrors(List<Database.Error> errors) {
        List<String> messages = new List<String>();
        for (Database.Error err : errors) {
            messages.add(err.getStatusCode() + ': ' + err.getMessage());
        }
        return String.join(messages, ', ');
    }
}
