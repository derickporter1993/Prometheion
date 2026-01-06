/**
 * PCIAccessLogger - PCI DSS Requirement 10 Implementation
 *
 * Tracks and monitors all access to cardholder data.
 * Creates immutable audit trail via Platform Events.
 *
 * Uses Prometheion_Raw_Event__e with JSON payload due to org custom object limit.
 *
 * Compliance Coverage:
 * - PCI DSS Requirement 10: Track All Access to Network Resources
 * - PCI DSS Requirement 10.1: Link Access to Individual Users
 * - PCI DSS Requirement 10.2: Audit Trail for All System Components
 *
 * @author Prometheion Team
 * @version 1.1 (Updated to use generic event)
 */
public with sharing class PrometheionPCIAccessLogger {

    /**
     * Log payment data access
     * Creates immutable audit trail via Platform Events
     * @param recordId - ID of the payment or sensitive record accessed
     * @param accessType - Type of access (Query, Insert, Update, Delete, View)
     * @param userAction - Description of the action performed
     */
    public static void logPaymentDataAccess(
        Id recordId,
        String accessType,
        String userAction
    ) {
        String ipAddress = null;
        try {
            Map<String, String> sessionInfo = Auth.SessionManagement.getCurrentSession();
            if (sessionInfo != null) {
                ipAddress = sessionInfo.get('SourceIp');
            }
        } catch (Exception e) {
            // Session info may not be available in all contexts
            ipAddress = 'Unknown';
        }

        // Build PCI access data as JSON
        Map<String, Object> pciData = new Map<String, Object>{
            'recordId' => String.valueOf(recordId),
            'userId' => UserInfo.getUserId(),
            'username' => UserInfo.getUserName(),
            'accessType' => accessType,
            'userAction' => userAction,
            'ipAddress' => ipAddress,
            'sessionId' => UserInfo.getSessionId(),
            'timestamp' => System.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
        };

        // Publish using generic Prometheion_Raw_Event__e
        EventBus.publish(new Prometheion_Raw_Event__e(
            Event_Type__c = 'PCI_ACCESS',
            Event_Data__c = JSON.serialize(pciData),
            Timestamp__c = System.now()
        ));
    }

    /**
     * Log bulk payment data access
     * @param recordIds - Set of record IDs accessed
     * @param accessType - Type of access
     * @param userAction - Description of the action
     */
    public static void logBulkPaymentDataAccess(
        Set<Id> recordIds,
        String accessType,
        String userAction
    ) {
        List<Prometheion_Raw_Event__e> events = new List<Prometheion_Raw_Event__e>();

        String ipAddress = null;
        try {
            Map<String, String> sessionInfo = Auth.SessionManagement.getCurrentSession();
            if (sessionInfo != null) {
                ipAddress = sessionInfo.get('SourceIp');
            }
        } catch (Exception e) {
            ipAddress = 'Unknown';
        }

        String sessionId = UserInfo.getSessionId();
        String userId = UserInfo.getUserId();
        String username = UserInfo.getUserName();
        Datetime now = System.now();

        for (Id recordId : recordIds) {
            Map<String, Object> pciData = new Map<String, Object>{
                'recordId' => String.valueOf(recordId),
                'userId' => userId,
                'username' => username,
                'accessType' => accessType,
                'userAction' => userAction + ' (Bulk: ' + recordIds.size() + ' records)',
                'ipAddress' => ipAddress,
                'sessionId' => sessionId,
                'timestamp' => now.format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'')
            };

            events.add(new Prometheion_Raw_Event__e(
                Event_Type__c = 'PCI_ACCESS',
                Event_Data__c = JSON.serialize(pciData),
                Timestamp__c = now
            ));
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    /**
     * Log failed access attempt (security event)
     * @param recordId - ID of record that was attempted to access
     * @param reason - Reason for failure
     */
    public static void logFailedAccess(Id recordId, String reason) {
        logPaymentDataAccess(
            recordId,
            'Access Denied',
            'Failed access attempt: ' + reason
        );
    }

    /**
     * Log sensitive data view (for audit compliance)
     * @param recordId - Record being viewed
     * @param dataElements - List of sensitive data elements viewed
     */
    public static void logSensitiveDataView(Id recordId, List<String> dataElements) {
        String elementsViewed = String.join(dataElements, ', ');
        logPaymentDataAccess(
            recordId,
            'View',
            'Viewed sensitive data elements: ' + elementsViewed
        );
    }

    /**
     * Get recent access logs for a record
     * Note: Queries Prometheion_Raw_Event__e filtered by Event_Type__c = 'PCI_ACCESS'
     * @param recordId - Record to get access logs for
     * @param limitSize - Number of logs to return
     * @return List of access log entries
     */
    @AuraEnabled(cacheable=true)
    public static List<AccessLogEntry> getRecentAccessLogs(Id recordId, Integer limitSize) {
        List<AccessLogEntry> logs = new List<AccessLogEntry>();

        // Query Platform Events (note: limited retention, typically 72 hours)
        // In production, consider storing in Big Object for long-term retention

        // Platform Events can't be queried directly, so this returns empty
        // Implementation would use Event Relay or Big Object storage

        return logs;
    }

    /**
     * Access log entry wrapper class
     */
    public class AccessLogEntry {
        @AuraEnabled public String recordId;
        @AuraEnabled public String userId;
        @AuraEnabled public String username;
        @AuraEnabled public String accessType;
        @AuraEnabled public String userAction;
        @AuraEnabled public String ipAddress;
        @AuraEnabled public Datetime timestamp;
    }
}
