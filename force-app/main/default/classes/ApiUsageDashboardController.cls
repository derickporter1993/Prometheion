public with sharing class ApiUsageDashboardController {
    public class Row {
        @AuraEnabled
        public Datetime takenOn;
        @AuraEnabled
        public Integer used;
        @AuraEnabled
        public Integer apiLimit;
        @AuraEnabled
        public Decimal percent;
        @AuraEnabled
        public Datetime projected;

        public Row(API_Usage_Snapshot__c snapshot) {
            this.takenOn = snapshot.Taken_On__c;
            this.used = (Integer) snapshot.Daily_Used__c;
            this.apiLimit = (Integer) snapshot.Daily_Limit__c;
            this.percent = snapshot.Percent_Used__c;
            this.projected = snapshot.Projected_Exhaustion__c;
        }
    }

    @AuraEnabled(cacheable = true)
    public static List<Row> getRecentSnapshots(Integer limitSize) {
        List<Row> out = new List<Row>();
        Integer recordLimit = Math.max(1, limitSize);

        for (API_Usage_Snapshot__c r : [
            SELECT
                Taken_On__c,
                Daily_Used__c,
                Daily_Limit__c,
                Percent_Used__c,
                Projected_Exhaustion__c
            FROM API_Usage_Snapshot__c
            WITH USER_MODE
            ORDER BY Taken_On__c DESC
            LIMIT :recordLimit
        ]) {
            out.add(new Row(r));
        }
        return out;
    }
    
    /**
     * Legacy method - Use getRecentSnapshots instead
     */
    @AuraEnabled(cacheable = true)
    public static List<Row> recent(Integer limitSize) {
        return getRecentSnapshots(limitSize);
    }
}
