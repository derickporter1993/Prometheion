/**
 * PCIAccessAlertTrigger - PCI DSS Requirement 10 Real-time Alerting
 *
 * Listens for PCI Access Events via Elaro_Raw_Event__e and triggers alerts for:
 * - Failed access attempts
 * - Access to sensitive data outside business hours
 * - Bulk data access patterns
 *
 * Note: Uses generic Elaro_Raw_Event__e filtered by Event_Type__c = 'PCI_ACCESS'
 * due to org custom object limit.
 *
 * @author Elaro Team
 * @version 1.1 (Updated to use generic event)
 */
trigger ElaroPCIAccessAlertTrigger on Elaro_Raw_Event__e (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('ElaroPCIAccessAlertTrigger')) return;

    try {
        List<Elaro_Raw_Event__e> pciEvents = new List<Elaro_Raw_Event__e>();

        // Filter for PCI_ACCESS events only
        for (Elaro_Raw_Event__e event : Trigger.new) {
            if (event.Event_Type__c == 'PCI_ACCESS') {
                pciEvents.add(event);
            }
        }

        // If no PCI events, exit early
        if (pciEvents.isEmpty()) {
            return;
        }

        List<Elaro_Raw_Event__e> failedAccessEvents = new List<Elaro_Raw_Event__e>();
        List<Elaro_Raw_Event__e> afterHoursEvents = new List<Elaro_Raw_Event__e>();
        List<Elaro_Raw_Event__e> bulkAccessEvents = new List<Elaro_Raw_Event__e>();

        // Track access counts by user for bulk detection
        Map<String, Integer> accessCountByUser = new Map<String, Integer>();

        for (Elaro_Raw_Event__e event : pciEvents) {
            // Parse JSON payload
            Map<String, Object> pciData = null;
            try {
                pciData = (Map<String, Object>) JSON.deserializeUntyped(event.Event_Data__c);
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to parse PCI event data: ' + e.getMessage());
                continue;
            }

            String accessType = (String) pciData.get('accessType');
            String userAction = (String) pciData.get('userAction');
            String userId = (String) pciData.get('userId');

            // Check for failed access
            if (accessType == 'Access Denied') {
                failedAccessEvents.add(event);
            }

            // Check for after-hours access (before 7 AM or after 7 PM)
            if (event.Timestamp__c != null) {
                Integer hour = event.Timestamp__c.hour();
                if (hour < 7 || hour >= 19) {
                    afterHoursEvents.add(event);
                }
            }

            // Track access count by user
            if (accessCountByUser.containsKey(userId)) {
                accessCountByUser.put(userId, accessCountByUser.get(userId) + 1);
            } else {
                accessCountByUser.put(userId, 1);
            }

            // Check for bulk action indicator
            if (userAction != null && userAction.contains('Bulk:')) {
                bulkAccessEvents.add(event);
            }
        }

        // Process alerts
        if (!failedAccessEvents.isEmpty()) {
            ElaroPCIAccessAlertHandler.handleFailedAccess(failedAccessEvents);
        }

        if (!afterHoursEvents.isEmpty()) {
            ElaroPCIAccessAlertHandler.handleAfterHoursAccess(afterHoursEvents);
        }

        if (!bulkAccessEvents.isEmpty()) {
            ElaroPCIAccessAlertHandler.handleBulkAccess(bulkAccessEvents);
        }
    } finally {
        TriggerRecursionGuard.reset('ElaroPCIAccessAlertTrigger');
    }
}
