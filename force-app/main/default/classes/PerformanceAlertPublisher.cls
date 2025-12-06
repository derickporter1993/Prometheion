public with sharing class PerformanceAlertPublisher {
    @AuraEnabled
    public static void publish(String metric, Decimal value, Decimal threshold, String contextRecordId, String stack) {
        Performance_Alert__e evt = new Performance_Alert__e(
            Metric__c = metric, Value__c = value, Threshold__c = threshold,
            Context_Record__c = contextRecordId, Stack__c = stack
        );
        Database.SaveResult sr = EventBus.publish(evt);
        if (!sr.isSuccess()) {
            throw new AuraHandledException('Failed to publish Performance_Alert__e');
        }
    }
}
