trigger PerformanceAlertEventTrigger on Performance_Alert__e (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('PerformanceAlertEventTrigger')) return;

    try {
        List<Performance_Alert_History__c> hist = new List<Performance_Alert_History__c>();
        for (Performance_Alert__e e : Trigger.new) {
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
        SlackNotifier.notifyPerformanceEventsBulk(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('PerformanceAlertEventTrigger');
    }
}
