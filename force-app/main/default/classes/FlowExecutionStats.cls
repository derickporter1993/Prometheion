public with sharing class FlowExecutionStats {
    private class ExecAgg {
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
    public static List<ExecAgg> topFlows(Integer limitSize) {
        Integer limit = Math.max(1, limitSize);
        List<AggregateResult> ars = [
            SELECT Flow_Name__c fn,
                   COUNT(Id) runs,
                   SUM(CASE WHEN Status__c = 'Fault' THEN 1 ELSE 0 END) faults,
                   MAX(Run_Time__c) lastRun
            FROM Flow_Execution__c
            GROUP BY Flow_Name__c
            ORDER BY runs DESC
            LIMIT :limit
        ];
        List<ExecAgg> out = new List<ExecAgg>();
        for (AggregateResult ar : ars) {
            out.add(new ExecAgg(ar));
        }
        return out;
    }
}
