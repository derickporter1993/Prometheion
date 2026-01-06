/**
 * PCIAccessAlertHandler - Handles PCI DSS security alerts
 *
 * Processes various security events and triggers appropriate alerts:
 * - Failed access attempts
 * - After-hours access
 * - Bulk data access
 * - Suspicious patterns
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionPCIAccessAlertHandler {

    private static final Integer FAILED_ACCESS_THRESHOLD = 3;
    private static final Integer BULK_ACCESS_THRESHOLD = 50;

    /**
     * Handle failed access attempts
     * @param events - List of failed access events
     */
    public static void handleFailedAccess(List<Prometheion_Raw_Event__e> events) {
        // Group by user to detect repeated failures
        Map<String, List<Prometheion_Raw_Event__e>> eventsByUser = new Map<String, List<Prometheion_Raw_Event__e>>();

        for (Prometheion_Raw_Event__e event : events) {
            if (!eventsByUser.containsKey(parseEventField(event, 'userId'))) {
                eventsByUser.put(parseEventField(event, 'userId'), new List<Prometheion_Raw_Event__e>());
            }
            eventsByUser.get(parseEventField(event, 'userId')).add(event);
        }

        // Check for users with multiple failures
        for (String userId : eventsByUser.keySet()) {
            List<Prometheion_Raw_Event__e> userEvents = eventsByUser.get(userId);

            if (userEvents.size() >= FAILED_ACCESS_THRESHOLD) {
                // Critical alert - potential security incident
                sendSecurityAlert(
                    'CRITICAL: Multiple Failed Access Attempts',
                    'User ' + parseEventField(userEvents[0], 'username') + ' has ' + userEvents.size() +
                    ' failed attempts to access cardholder data.\n' +
                    'IP Address: ' + parseEventField(userEvents[0], 'ipAddress') + '\n' +
                    'Action: Investigate immediately and consider account lockout.',
                    'Critical'
                );
            } else {
                // Warning level
                for (Prometheion_Raw_Event__e event : userEvents) {
                    logSecurityEvent(event, 'Failed Access Attempt');
                }
            }
        }
    }

    /**
     * Handle after-hours access events
     * @param events - List of after-hours events
     */
    public static void handleAfterHoursAccess(List<Prometheion_Raw_Event__e> events) {
        for (Prometheion_Raw_Event__e event : events) {
            String timeStr = event.Timestamp__c.format('HH:mm:ss');

            sendSecurityAlert(
                'WARNING: After-Hours Access to Payment Data',
                'User ' + parseEventField(event, 'username') + ' accessed cardholder data at ' + timeStr + '.\n' +
                'Access Type: ' + parseEventField(event, 'accessType') + '\n' +
                'Record ID: ' + parseEventField(event, 'recordId') + '\n' +
                'IP Address: ' + parseEventField(event, 'ipAddress') + '\n' +
                'Action: Verify this access was authorized.',
                'Warning'
            );

            logSecurityEvent(event, 'After-Hours Access');
        }
    }

    /**
     * Handle bulk access events
     * @param events - List of bulk access events
     */
    public static void handleBulkAccess(List<Prometheion_Raw_Event__e> events) {
        for (Prometheion_Raw_Event__e event : events) {
            // Extract record count from action string
            String action = parseEventField(event, 'userAction');
            Integer recordCount = extractRecordCount(action);

            if (recordCount >= BULK_ACCESS_THRESHOLD) {
                sendSecurityAlert(
                    'ALERT: Large Bulk Access to Payment Data',
                    'User ' + parseEventField(event, 'username') + ' accessed ' + recordCount +
                    ' payment records in bulk operation.\n' +
                    'Access Type: ' + parseEventField(event, 'accessType') + '\n' +
                    'IP Address: ' + parseEventField(event, 'ipAddress') + '\n' +
                    'Action: Review if this volume is appropriate for user role.',
                    'High'
                );
            }

            logSecurityEvent(event, 'Bulk Data Access');
        }
    }

    /**
     * Extract record count from action string
     * @param action - User action string
     * @return Record count
     */
    private static Integer extractRecordCount(String action) {
        if (String.isBlank(action)) return 0;

        // Pattern: "Bulk: 123 records"
        Pattern p = Pattern.compile('Bulk:\\s*(\\d+)\\s*records');
        Matcher m = p.matcher(action);

        if (m.find()) {
            return Integer.valueOf(m.group(1));
        }
        return 0;
    }

    /**
     * Send security alert to appropriate channels
     * @param subject - Alert subject
     * @param body - Alert body
     * @param severity - Severity level
     */
    private static void sendSecurityAlert(String subject, String body, String severity) {
        // Log the alert
        System.debug(LoggingLevel.ERROR,
            '[PCIAccessAlertHandler] ' + severity + ': ' + subject + '\n' + body);

        // In production, would:
        // 1. Send email to security team
        // 2. Post to Slack/Teams security channel
        // 3. Create case for investigation
        // 4. Send to SIEM system
    }

    /**
     * Log security event for audit
     * @param event - PCI Access Event
     * @param eventType - Type of security event
     */
    private static void logSecurityEvent(Prometheion_Raw_Event__e event, String eventType) {
        System.debug(LoggingLevel.WARN,
            '[PCIAccessAlertHandler] Security Event: ' + eventType + '\n' +
            'User: ' + parseEventField(event, 'username') + '\n' +
            'Timestamp: ' + event.Timestamp__c + '\n' +
            'IP: ' + parseEventField(event, 'ipAddress') + '\n' +
            'Action: ' + parseEventField(event, 'userAction'));
    }

    /**
     * Create security incident case
     * @param subject - Incident subject
     * @param description - Incident description
     * @param priority - Case priority
     */
    public static void createSecurityIncident(String subject, String description, String priority) {
        // Would create a Case record for security team to investigate
        System.debug(LoggingLevel.ERROR,
            '[PCIAccessAlertHandler] Creating security incident: ' + subject);
    }

    /**
     * Parse field from generic event JSON payload
     * @param event - The Prometheion_Raw_Event__e
     * @param fieldName - Name of field to extract from JSON
     * @return Field value as String, or empty string if not found
     */
    private static String parseEventField(Prometheion_Raw_Event__e event, String fieldName) {
        try {
            if (String.isBlank(event.Event_Data__c)) {
                return '';
            }

            Map<String, Object> data = (Map<String, Object>) JSON.deserializeUntyped(event.Event_Data__c);
            Object value = data.get(fieldName);
            return value != null ? String.valueOf(value) : '';
        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Failed to parse event field ' + fieldName + ': ' + e.getMessage());
            return '';
        }
    }
}
