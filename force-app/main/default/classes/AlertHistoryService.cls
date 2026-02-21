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
    
    /**
     * Retrieves the most recent performance alert history records, ordered by creation date descending.
     * Validates object-level read access and field-level security before querying.
     *
     * @param limitSize Maximum number of alert records to return (minimum 1)
     * @return List of AlertRow wrappers containing metric, value, threshold, context record, and timestamp
     * @throws AuraHandledException When the running user lacks read access to Performance_Alert_History__c
     */
    @AuraEnabled(cacheable=true)
    public static List<AlertRow> getRecentAlerts(Integer limitSize) {
        // Validate read access
        if (!ElaroSecurityUtils.hasReadAccess('Performance_Alert_History__c')) {
            throw new AuraHandledException('Insufficient access to Performance Alert History');
        }
        
        // Validate FLS for queried fields
        List<String> queriedFields = new List<String>{
            'Metric__c', 'Value__c', 'Threshold__c', 'Context_Record__c', 'CreatedDate'
        };
        ElaroSecurityUtils.validateFLSAccess('Performance_Alert_History__c', queriedFields, false);
        
        Integer recordLimit = Math.max(1, limitSize);
        List<AlertRow> out = new List<AlertRow>();
        for (Performance_Alert_History__c r : [
            SELECT Metric__c, Value__c, Threshold__c, Context_Record__c, CreatedDate
            FROM Performance_Alert_History__c
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT :recordLimit
        ]) {
            out.add(new AlertRow(r));
        }
        return out;
    }
}
