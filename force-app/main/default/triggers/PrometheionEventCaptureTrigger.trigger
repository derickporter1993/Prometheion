/**
 * PrometheionEventCaptureTrigger
 *
 * Captures Prometheion_Event__e Platform Events and processes them
 */
trigger PrometheionEventCaptureTrigger on Prometheion_Event__e (after insert) {
    if (!Trigger.isAfter || !Trigger.isInsert) return;
    if (!TriggerRecursionGuard.isFirstRun('PrometheionEventCaptureTrigger')) return;

    try {
        PrometheionEventProcessor.processEvents(Trigger.new);
    } finally {
        TriggerRecursionGuard.reset('PrometheionEventCaptureTrigger');
    }
}
