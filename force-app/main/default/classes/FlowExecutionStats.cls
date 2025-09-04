public with sharing class FlowExecutionStats {
    public class ExecAgg {
        @AuraEnabled public String flowName;
        @AuraEnabled public Integer runs;
        @AuraEnabled public Integer faults;
        @AuraEnabled public Datetime lastRun;
    }
    @AuraEnabled(cacheable=true)
    public static List<ExecAgg> topFlows(Integer limitSize) {
        List<AggregateResult> ars = [
            SELECT Flow_Name__c fn,
                   COUNT(Id) runs,
                   SUM(CASE WHEN Status__c = 'Fault' THEN 1 ELSE 0 END) faults,
                   MAX(Run_Time__c) lastRun
            FROM Flow_Execution__c
            GROUP BY Flow_Name__c
            ORDER BY runs DESC
            LIMIT :Math.max(1, limitSize)
        ];
        List<ExecAgg> out = new List<ExecAgg>();
        for (AggregateResult ar : ars) {
            ExecAgg e = new ExecAgg();
            e.flowName = (String) ar.get('fn');
            e.runs = (Integer) ar.get('runs');
            e.faults = (Integer) ar.get('faults');
            e.lastRun = (Datetime) ar.get('lastRun');
            out.add(e);
        }
        return out;
    }
}
