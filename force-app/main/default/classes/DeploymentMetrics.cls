public with sharing class DeploymentMetrics {
    public class DeployRow {
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime startedOn;
        @AuraEnabled public Datetime finishedOn;
        @AuraEnabled public Integer testsPassed;
        @AuraEnabled public Integer testsFailed;
    }
    @AuraEnabled(cacheable=true)
    public static List<DeployRow> recent(Integer limitSize) {
        List<DeployRow> out = new List<DeployRow>();
        for (Deployment_Job__c d : [
            SELECT Name, Status__c, Started_On__c, Finished_On__c, Tests_Passed__c, Tests_Failed__c
            FROM Deployment_Job__c
            ORDER BY CreatedDate DESC
            LIMIT :Math.max(1, limitSize)
        ]) {
            DeployRow r = new DeployRow();
            r.name = d.Name; r.status = d.Status__c; r.startedOn = d.Started_On__c; r.finishedOn = d.Finished_On__c;
            r.testsPassed = (Integer)d.Tests_Passed__c; r.testsFailed = (Integer)d.Tests_Failed__c;
            out.add(r);
        }
        return out;
    }
}
