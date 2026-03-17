/**
 * Provides real-time Salesforce governor limit metrics for performance monitoring.
 *
 * Returns both consumed and maximum limit values, enabling callers to calculate
 * headroom and detect approaching governor limits before they cause failures.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group System Monitoring
 * @see PerformanceRuleEngine
 */
public with sharing class LimitMetrics {
    public class GovernorStats {
        @AuraEnabled public Integer cpuMs;
        @AuraEnabled public Integer cpuMax;
        @AuraEnabled public Integer soql;
        @AuraEnabled public Integer soqlMax;
        @AuraEnabled public Integer dml;
        @AuraEnabled public Integer dmlMax;
        @AuraEnabled public Integer heapKb;
        @AuraEnabled public Integer heapMaxKb;
    }

    /**
     * Fetches current governor limit consumption and maximum values.
     *
     * @return GovernorStats containing consumed and max values for CPU, SOQL, DML, and heap
     */
    @AuraEnabled(cacheable=true)
    public static GovernorStats fetchGovernorStats() {
        try {
            GovernorStats g = new GovernorStats();
            g.cpuMs = Limits.getCpuTime();
            g.cpuMax = Limits.getLimitCpuTime();
            g.soql  = Limits.getSOQLQueries();
            g.soqlMax = Limits.getLimitSOQLQueries();
            g.dml   = Limits.getDmlStatements();
            g.dmlMax = Limits.getLimitDmlStatements();
            g.heapKb = Math.round(Limits.getHeapSize() / 1024.0);
            g.heapMaxKb = Math.round(Limits.getLimitHeapSize() / 1024.0);
            return g;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('LimitMetrics.fetchGovernorStats', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }
}
