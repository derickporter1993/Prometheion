public with sharing class DeploymentMetrics {
    public class Row {
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime startedOn;
        @AuraEnabled public Datetime finishedOn;
        @AuraEnabled public Integer testsPassed;
        @AuraEnabled public Integer testsFailed;

        public Row(Deployment_Job__c job) {
            this.name = job.Name;
            this.status = job.Status__c;
            this.startedOn = job.Started_On__c;
            this.finishedOn = job.Finished_On__c;
            this.testsPassed = (Integer)job.Tests_Passed__c;
            this.testsFailed = (Integer)job.Tests_Failed__c;
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<Row> getRecentDeployments(Integer limitSize) {
        Integer recordLimit = Math.max(1, limitSize);
        List<Row> out = new List<Row>();
        
        for (Deployment_Job__c r : [
            SELECT Name, Status__c, Started_On__c, Finished_On__c, Tests_Passed__c, Tests_Failed__c
            FROM Deployment_Job__c
            WITH USER_MODE
            ORDER BY Started_On__c DESC
            LIMIT :recordLimit
        ]) {
            out.add(new Row(r));
        }
        return out;
    }
    
    /**
     * Legacy method - Use getRecentDeployments instead
     */
    @AuraEnabled(cacheable=true)
    public static List<Row> recent(Integer limitSize) {
        return getRecentDeployments(limitSize);
    }
}
