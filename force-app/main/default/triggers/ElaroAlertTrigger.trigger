trigger ElaroAlertTrigger on Alert__c (after insert) {
    if (!Trigger.isAfter || !Trigger.isInsert) return;
    if (!TriggerRecursionGuard.isFirstRun('ElaroAlertTrigger')) return;

    try {
        List<Elaro_Alert_Event__e> events = new List<Elaro_Alert_Event__e>();

        for (Alert__c alert : Trigger.new) {
            if (!alert.Acknowledged__c) {
                events.add(new Elaro_Alert_Event__e(
                    Alert_Id__c = alert.Id,
                    Alert_Type__c = alert.Alert_Type__c,
                    Severity__c = alert.Severity__c,
                    Title__c = alert.Title__c,
                    Description__c = alert.Description__c
                ));
            }
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    } finally {
        TriggerRecursionGuard.reset('ElaroAlertTrigger');
    }
}
