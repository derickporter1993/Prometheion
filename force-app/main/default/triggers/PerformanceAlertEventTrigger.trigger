trigger PerformanceAlertEventTrigger on Performance_Alert__e (after insert) {
    if (!TriggerRecursionGuard.isFirstRun('PerformanceAlertEventTrigger')) return;

    try {
        PerformanceAlertEventTriggerHandler.handleAfterInsert(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('PerformanceAlertEventTrigger');
    }
}
