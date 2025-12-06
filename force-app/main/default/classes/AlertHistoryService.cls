/**
 * AlertHistoryService - Alert History Service (Stub)
 * 
 * Provides alert history for monitoring dashboards.
 * Stub implementation - full version requires Performance_Alert_History__c custom object.
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
public with sharing class AlertHistoryService {
    
    public class AlertRow {
        @AuraEnabled public String metric;
        @AuraEnabled public Decimal value;
        @AuraEnabled public Decimal threshold;
        @AuraEnabled public String contextRecordId;
        @AuraEnabled public Datetime createdDate;
        
        public AlertRow() {
            this.value = 0;
            this.threshold = 0;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<AlertRow> recent(Integer limitSize) {
        // Stub implementation - return empty list
        // Full implementation requires Performance_Alert_History__c custom object
        return new List<AlertRow>();
    }
}
