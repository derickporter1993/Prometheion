/**
 * LimitMetrics - Governor Limit Metrics
 * 
 * Provides current governor limit usage statistics.
 * 
 * @author Solentra
 * @version 1.0
 */
public with sharing class LimitMetrics {
    
    public class GovernorStats {
        @AuraEnabled public Integer cpuMs;
        @AuraEnabled public Integer soql;
        @AuraEnabled public Integer dml;
        @AuraEnabled public Integer heapKb;
        
        public GovernorStats() {
            this.cpuMs = 0;
            this.soql = 0;
            this.dml = 0;
            this.heapKb = 0;
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static GovernorStats fetchGovernorStats() {
        GovernorStats g = new GovernorStats();
        g.cpuMs = System.Limits.getCpuTime();
        g.soql = System.Limits.getQueries();
        g.dml = System.Limits.getDmlStatements();
        g.heapKb = (Integer) Math.round(System.Limits.getHeapSize() / 1024.0);
        return g;
    }
}
