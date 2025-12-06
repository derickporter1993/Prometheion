public with sharing class LimitMetrics {
    public class GovernorStats {
        @AuraEnabled public Integer cpuMs;
        @AuraEnabled public Integer soql;
        @AuraEnabled public Integer dml;
        @AuraEnabled public Integer heapKb;
    }
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
