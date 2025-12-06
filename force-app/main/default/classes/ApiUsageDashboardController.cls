/**
 * ApiUsageDashboardController - API Usage Dashboard Controller (Stub)
 * 
 * Provides API usage data for dashboard visualization.
 * Stub implementation - full version requires API_Usage_Snapshot__c custom object.
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
public with sharing class ApiUsageDashboardController {
    
    public class Row {
        @AuraEnabled public Datetime takenOn;
        @AuraEnabled public Integer used;
        @AuraEnabled public Integer apiLimit;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public Datetime projected;
        
        public Row() {
            this.used = 0;
            this.apiLimit = 0;
            this.percent = 0;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Row> recent(Integer limitSize) {
        // Stub implementation - return empty list
        // Full implementation requires API_Usage_Snapshot__c custom object
        return new List<Row>();
    }
}
