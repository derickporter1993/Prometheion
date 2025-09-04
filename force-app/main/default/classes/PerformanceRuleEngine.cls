public with sharing class PerformanceRuleEngine {
    public class EvalResult {
        @AuraEnabled public Boolean warning;
        @AuraEnabled public Boolean critical;
        @AuraEnabled public String message;
    }
    @AuraEnabled
    public static EvalResult evaluateAndPublish(LimitMetrics.GovernorStats stats, String contextRecordId) {
        CCX_Settings__c s = CCX_Settings__c.getInstance();
        Integer cpuWarn = (s != null && s.CPU_Warn__c != null) ? Integer.valueOf(s.CPU_Warn__c) : 8000;
        Integer cpuCrit = (s != null && s.CPU_Crit__c != null) ? Integer.valueOf(s.CPU_Crit__c) : 9000;
        Integer heapWarn = (s != null && s.Heap_Warn__c != null) ? Integer.valueOf(s.Heap_Warn__c) : 4500;
        Integer heapCrit = (s != null && s.Heap_Crit__c != null) ? Integer.valueOf(s.Heap_Crit__c) : 5000;
        Integer soqlWarn = (s != null && s.SOQL_Warn__c != null) ? Integer.valueOf(s.SOQL_Warn__c) : 90;
        Integer soqlCrit = (s != null && s.SOQL_Crit__c != null) ? Integer.valueOf(s.SOQL_Crit__c) : 100;
        Integer dmlWarn = (s != null && s.DML_Warn__c != null) ? Integer.valueOf(s.DML_Warn__c) : 140;
        Integer dmlCrit = (s != null && s.DML_Crit__c != null) ? Integer.valueOf(s.DML_Crit__c) : 150;

        EvalResult out = new EvalResult();
        if (stats.cpuMs >= cpuCrit) { PerformanceAlertPublisher.publish('CPU', stats.cpuMs, cpuCrit, contextRecordId, 'CPU critical threshold exceeded'); out.critical = true; }
        else if (stats.cpuMs >= cpuWarn) { PerformanceAlertPublisher.publish('CPU', stats.cpuMs, cpuWarn, contextRecordId, 'CPU warning threshold exceeded'); out.warning = true; }

        if (stats.heapKb >= heapCrit) { PerformanceAlertPublisher.publish('HEAP', stats.heapKb, heapCrit, contextRecordId, 'Heap critical threshold exceeded'); out.critical = true; }
        else if (stats.heapKb >= heapWarn) { PerformanceAlertPublisher.publish('HEAP', stats.heapKb, heapWarn, contextRecordId, 'Heap warning threshold exceeded'); out.warning = true; }

        if (stats.soql >= soqlCrit) { PerformanceAlertPublisher.publish('SOQL', stats.soql, soqlCrit, contextRecordId, 'SOQL critical threshold exceeded'); out.critical = true; }
        else if (stats.soql >= soqlWarn) { PerformanceAlertPublisher.publish('SOQL', stats.soql, soqlWarn, contextRecordId, 'SOQL warning threshold exceeded'); out.warning = true; }

        if (stats.dml >= dmlCrit) { PerformanceAlertPublisher.publish('DML', stats.dml, dmlCrit, contextRecordId, 'DML critical threshold exceeded'); out.critical = true; }
        else if (stats.dml >= dmlWarn) { PerformanceAlertPublisher.publish('DML', stats.dml, dmlWarn, contextRecordId, 'DML warning threshold exceeded'); out.warning = true; }

        out.message = 'Evaluated current governor stats against thresholds.';
        return out;
    }
}
