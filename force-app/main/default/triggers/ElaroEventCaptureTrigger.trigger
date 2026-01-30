/**
 * ElaroEventCaptureTrigger
 *
 * Captures Elaro_Event__e Platform Events and processes them
 */
trigger ElaroEventCaptureTrigger on Elaro_Event__e (after insert) {
    if (!Trigger.isAfter || !Trigger.isInsert) return;
    if (!TriggerRecursionGuard.isFirstRun('ElaroEventCaptureTrigger')) return;

    try {
        ElaroEventProcessor.processEvents(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('ElaroEventCaptureTrigger');
    }
}
