public with sharing class LimitMetrics {
    public class GovernorStats {
        @AuraEnabled public Integer cpuMs;
        @AuraEnabled public Integer soql;
        @AuraEnabled public Integer dml;
        @AuraEnabled public Integer heapKb;
    }
    /**
     * Returns a snapshot of the current transaction's governor limit consumption.
     * Includes CPU time (ms), SOQL query count, DML statement count, and heap size (KB).
     *
     * @return GovernorStats wrapper containing current governor limit usage for the running transaction
     */
    @AuraEnabled(cacheable=true)
    public static GovernorStats fetchGovernorStats() {
        GovernorStats g = new GovernorStats();
        g.cpuMs = Limits.getCpuTime();
        g.soql  = Limits.getSOQLQueries();
        g.dml   = Limits.getDmlStatements();
        g.heapKb= Math.round(Limits.getHeapSize() / 1024.0);
        return g;
    }
}
