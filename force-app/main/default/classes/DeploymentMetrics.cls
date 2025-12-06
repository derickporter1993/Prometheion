/**
 * DeploymentMetrics - Deployment Metrics Service (Stub)
 * 
 * Provides deployment job metrics for monitoring.
 * Stub implementation - full version requires Deployment_Job__c custom object.
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
public with sharing class DeploymentMetrics {
    
    public class DeployRow {
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime startedOn;
        @AuraEnabled public Datetime finishedOn;
        @AuraEnabled public Integer testsPassed;
        @AuraEnabled public Integer testsFailed;
        
        public DeployRow() {
            this.testsPassed = 0;
            this.testsFailed = 0;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<DeployRow> recent(Integer limitSize) {
        // Stub implementation - return empty list
        // Full implementation requires Deployment_Job__c custom object
        return new List<DeployRow>();
    }
}
