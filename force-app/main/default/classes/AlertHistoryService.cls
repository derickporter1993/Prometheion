public with sharing class AlertHistoryService {
    public class AlertRow {
        @AuraEnabled public String metric;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Decimal threshold;
        @AuraEnabled public String contextRecordId;
        @AuraEnabled public Datetime createdDate;
    }
    @AuraEnabled(cacheable=true)
    public static List<AlertRow> recent(Integer limitSize) {
        List<AlertRow> out = new List<AlertRow>();
        for (Performance_Alert_History__c r : [
            SELECT Metric__c, Value__c, Threshold__c, Context_Record__c, CreatedDate
            FROM Performance_Alert_History__c
            ORDER BY CreatedDate DESC
            LIMIT :Math.max(1, limitSize)
        ]) {
            AlertRow a = new AlertRow();
            a.metric = r.Metric__c;
            a.value = r.Value__c;
            a.threshold = r.Threshold__c;
            a.contextRecordId = r.Context_Record__c;
            a.createdDate = r.CreatedDate;
            out.add(a);
        }
        return out;
    }
}
