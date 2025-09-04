public with sharing class ApiUsageDashboardController {
    public class Row { @AuraEnabled public Datetime takenOn; @AuraEnabled public Integer used; @AuraEnabled public Integer limit; @AuraEnabled public Decimal percent; @AuraEnabled public Datetime projected; }
    @AuraEnabled(cacheable=true)
    public static List<Row> recent(Integer limitSize){
        List<Row> out = new List<Row>();
        for (API_Usage_Snapshot__c r : [
            SELECT Taken_On__c, Daily_Used__c, Daily_Limit__c, Percent_Used__c, Projected_Exhaustion__c
            FROM API_Usage_Snapshot__c ORDER BY Taken_On__c DESC LIMIT :Math.max(1, limitSize)
        ]){
            Row x = new Row(); x.takenOn = r.Taken_On__c; x.used = (Integer) r.Daily_Used__c; x.limit = (Integer) r.Daily_Limit__c; x.percent = r.Percent_Used__c; x.projected = r.Projected_Exhaustion__c; out.add(x);
        }
        return out;
    }
}
