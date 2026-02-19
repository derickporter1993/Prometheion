/**
 * Captures and stores Flow execution statistics and metrics.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Data Structures
 */
public with sharing class FlowExecutionStats {
    public class ExecAgg {
        @AuraEnabled public String flowName;
        @AuraEnabled public Integer runs;
        @AuraEnabled public Integer faults;
        @AuraEnabled public Datetime lastRun;

        public ExecAgg(AggregateResult ar) {
            this.flowName = (String) ar.get('fn');
            this.runs = (Integer) ar.get('runs');
            this.faults = (Integer) ar.get('faults');
            this.lastRun = (Datetime) ar.get('lastRun');
        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ExecAgg> getTopFlows(Integer limitSize) {
        Integer recordLimit = Math.max(1, limitSize);
        // SOQL doesn't support CASE WHEN in aggregate queries, so we'll count faults separately
        List<AggregateResult> ars = [
            SELECT Flow_Name__c fn,
                   COUNT(Id) runs,
                   MAX(Run_Time__c) lastRun
            FROM Flow_Execution__c
            WITH USER_MODE
            GROUP BY Flow_Name__c
            ORDER BY COUNT(Id) DESC
            LIMIT :recordLimit
        ];

        // Count faults separately for each flow
        Set<String> flowNames = new Set<String>();
        for (AggregateResult ar : ars) {
            flowNames.add((String)ar.get('fn'));
        }

        Map<String, Integer> faultCounts = new Map<String, Integer>();
        if (!flowNames.isEmpty()) {
            List<AggregateResult> faultArs = [
                SELECT Flow_Name__c fn, COUNT(Id) faultCount
                FROM Flow_Execution__c
                WHERE Flow_Name__c IN :flowNames AND Status__c = 'Fault'
                WITH USER_MODE
                GROUP BY Flow_Name__c
            ];
            for (AggregateResult fa : faultArs) {
                faultCounts.put((String)fa.get('fn'), (Integer)fa.get('faultCount'));
            }
        }
        List<ExecAgg> out = new List<ExecAgg>();
        for (AggregateResult ar : ars) {
            ExecAgg agg = new ExecAgg(ar);
            agg.faults = faultCounts.containsKey(agg.flowName) ? faultCounts.get(agg.flowName) : 0;
            out.add(agg);
        }
        return out;
    }
    
}
