public with sharing class DeploymentMetrics {
    private class DeployRow {
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime startedOn;
        @AuraEnabled public Datetime finishedOn;
        @AuraEnabled public Integer testsPassed;
        @AuraEnabled public Integer testsFailed;
        
        public DeployRow(Deployment_Job__c record) {
            this.name = record.Name;
            this.status = record.Status__c;
            this.startedOn = record.Started_On__c;
            this.finishedOn = record.Finished_On__c;
            this.testsPassed = (Integer)record.Tests_Passed__c;
            this.testsFailed = (Integer)record.Tests_Failed__c;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DeployRow> recent(Integer limitSize) {
        Integer limit = Math.max(1, limitSize);
        List<DeployRow> out = new List<DeployRow>();
        for (Deployment_Job__c d : [
            SELECT Name, Status__c, Started_On__c, Finished_On__c, Tests_Passed__c, Tests_Failed__c
            FROM Deployment_Job__c
            ORDER BY CreatedDate DESC
            LIMIT :limit
        ]) {
            out.add(new DeployRow(d));
        }
        return out;
    }
}
