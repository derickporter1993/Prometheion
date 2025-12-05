public with sharing class PerformanceRuleEngine {
    public class EvalResult {
        @AuraEnabled
        public Boolean warning;
        @AuraEnabled
        public Boolean critical;
        @AuraEnabled
        public String message;
    }

    @AuraEnabled
    public static EvalResult evaluateAndPublish(
        LimitMetrics.GovernorStats stats,
        String contextRecordId
    ) {
        CCX_Settings__c s = CCX_Settings__c.getInstance();
        Integer cpuWarn = (s != null && s.CPU_Warn__c != null)
            ? Integer.valueOf(s.CPU_Warn__c)
            : 8000;
        Integer cpuCrit = (s != null && s.CPU_Crit__c != null)
            ? Integer.valueOf(s.CPU_Crit__c)
            : 9000;
        Integer heapWarn = (s != null && s.Heap_Warn__c != null)
            ? Integer.valueOf(s.Heap_Warn__c)
            : 4500;
        Integer heapCrit = (s != null && s.Heap_Crit__c != null)
            ? Integer.valueOf(s.Heap_Crit__c)
            : 5000;
        Integer soqlWarn = (s != null && s.SOQL_Warn__c != null)
            ? Integer.valueOf(s.SOQL_Warn__c)
            : 90;
        Integer soqlCrit = (s != null && s.SOQL_Crit__c != null)
            ? Integer.valueOf(s.SOQL_Crit__c)
            : 100;
        Integer dmlWarn = (s != null && s.DML_Warn__c != null)
            ? Integer.valueOf(s.DML_Warn__c)
            : 140;
        Integer dmlCrit = (s != null && s.DML_Crit__c != null)
            ? Integer.valueOf(s.DML_Crit__c)
            : 150;

        EvalResult out = new EvalResult();
        List<Performance_Alert__e> eventsToPublish = new List<Performance_Alert__e>();

        // Check CPU threshold
        checkThreshold(
            'CPU',
            stats.cpuMs,
            cpuWarn,
            cpuCrit,
            contextRecordId,
            out,
            eventsToPublish
        );

        // Check Heap threshold
        checkThreshold(
            'HEAP',
            stats.heapKb,
            heapWarn,
            heapCrit,
            contextRecordId,
            out,
            eventsToPublish
        );

        // Check SOQL threshold
        checkThreshold(
            'SOQL',
            stats.soql,
            soqlWarn,
            soqlCrit,
            contextRecordId,
            out,
            eventsToPublish
        );

        // Check DML threshold
        checkThreshold('DML', stats.dml, dmlWarn, dmlCrit, contextRecordId, out, eventsToPublish);

        // Bulk publish all events at once
        if (!eventsToPublish.isEmpty()) {
            List<Database.SaveResult> results = EventBus.publish(eventsToPublish);
            for (Database.SaveResult sr : results) {
                if (!sr.isSuccess()) {
                    System.debug(
                        LoggingLevel.ERROR,
                        'Failed to publish Performance_Alert__e: ' + sr.getErrors()
                    );
                }
            }
        }

        out.message = 'Evaluated current governor stats against thresholds.';
        return out;
    }

    private static void checkThreshold(
        String metric,
        Decimal value,
        Integer warnThreshold,
        Integer critThreshold,
        String contextRecordId,
        EvalResult result,
        List<Performance_Alert__e> events
    ) {
        if (value >= critThreshold) {
            events.add(
                new Performance_Alert__e(
                    Metric__c = metric,
                    Value__c = value,
                    Threshold__c = critThreshold,
                    Context_Record__c = contextRecordId,
                    Stack__c = metric + ' critical threshold exceeded'
                )
            );
            result.critical = true;
        } else if (value >= warnThreshold) {
            events.add(
                new Performance_Alert__e(
                    Metric__c = metric,
                    Value__c = value,
                    Threshold__c = warnThreshold,
                    Context_Record__c = contextRecordId,
                    Stack__c = metric + ' warning threshold exceeded'
                )
            );
            result.warning = true;
        }
    }
}
