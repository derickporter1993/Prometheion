/**
 * FlowExecutionStats - Flow Execution Statistics (Stub)
 * 
 * Provides flow execution statistics for monitoring.
 * Stub implementation - full version requires Flow_Execution__c custom object.
 * 
 * @author Solentra
 * @version 1.0 (Stub)
 */
public with sharing class FlowExecutionStats {
    
    public class ExecAgg {
        @AuraEnabled public String flowName;
        @AuraEnabled public Integer runs;
        @AuraEnabled public Integer faults;
        @AuraEnabled public Datetime lastRun;
        
        public ExecAgg() {
            this.runs = 0;
            this.faults = 0;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static List<ExecAgg> topFlows(Integer limitSize) {
        // Stub implementation - return empty list
        // Full implementation requires Flow_Execution__c custom object
        return new List<ExecAgg>();
    }
}
