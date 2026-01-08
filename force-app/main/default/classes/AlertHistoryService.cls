public with sharing class AlertHistoryService {
    private class AlertRow {
        @AuraEnabled public String metric;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Decimal threshold;
        @AuraEnabled public String contextRecordId;
        @AuraEnabled public Datetime createdDate;
        
        public AlertRow(Performance_Alert_History__c record) {
            this.metric = record.Metric__c;
            this.value = record.Value__c;
            this.threshold = record.Threshold__c;
            this.contextRecordId = record.Context_Record__c;
            this.createdDate = record.CreatedDate;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AlertRow> recent(Integer limitSize) {
        // Validate read access
        if (!PrometheionSecurityUtils.hasReadAccess('Performance_Alert_History__c')) {
            throw new AuraHandledException('Insufficient access to Performance Alert History');
        }
        
        // Validate FLS for queried fields
        List<String> queriedFields = new List<String>{
            'Metric__c', 'Value__c', 'Threshold__c', 'Context_Record__c', 'CreatedDate'
        };
        PrometheionSecurityUtils.validateFLSAccess('Performance_Alert_History__c', queriedFields, false);
        
        Integer limit = Math.max(1, limitSize);
        List<AlertRow> out = new List<AlertRow>();
        for (Performance_Alert_History__c r : [
            SELECT Metric__c, Value__c, Threshold__c, Context_Record__c, CreatedDate
            FROM Performance_Alert_History__c
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT :limit
        ]) {
            out.add(new AlertRow(r));
        }
        return out;
    }
}
