/**
 * @description Handler for Performance Alert Platform Event trigger
 * Processes performance alert events and creates history records
 * @group Event Handlers
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 */
public with sharing class PerformanceAlertEventTriggerHandler {
    
    /**
     * @description Handle after insert events for Performance_Alert__e
     * @param events List of Performance Alert events
     */
    public static void handleAfterInsert(List<Performance_Alert__e> events) {
        if (events == null || events.isEmpty()) {
            return;
        }

        List<Performance_Alert_History__c> hist = new List<Performance_Alert_History__c>();
        
        for (Performance_Alert__e e : events) {
            hist.add(new Performance_Alert_History__c(
                Metric__c = e.Metric__c,
                Value__c = e.Value__c,
                Threshold__c = e.Threshold__c,
                Context_Record__c = e.Context_Record__c,
                Stack__c = e.Stack__c
            ));
        }
        
        if (!hist.isEmpty() && Schema.sObjectType.Performance_Alert_History__c.isCreateable()) {
            insert hist;
        }
        
        // Bulk Slack notification (single future call for all events)
        SlackNotifier.notifyPerformanceEventsBulk(events);
    }
}
