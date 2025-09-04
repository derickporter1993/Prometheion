public with sharing class FlowExecutionLogger {
    public class LogInput {
        @InvocableVariable(required=true) public String flowName;
        @InvocableVariable public Id primaryRecordId;
        @InvocableVariable(required=true) public String status;
        @InvocableVariable public Integer cpu;
        @InvocableVariable public Integer soql;
        @InvocableVariable public Integer dml;
    }
    @InvocableMethod(label='Log Flow Execution')
    public static void logInvocable(List<LogInput> inputs) {
        List<Flow_Execution__c> toInsert = new List<Flow_Execution__c>();
        for (LogInput i : inputs) {
            toInsert.add(new Flow_Execution__c(
                Flow_Name__c = i.flowName,
                Primary_Record__c = i.primaryRecordId,
                Status__c = i.status,
                CPU__c = i.cpu, SOQL__c = i.soql, DML__c = i.dml,
                Run_Time__c = System.now()
            ));
        }
        if (!toInsert.isEmpty()) insert toInsert;
    }
    @AuraEnabled
    public static void log(String flowName, Id primaryRecordId, String status, Integer cpu, Integer soql, Integer dml) {
        logInvocable(new List<LogInput>{ new LogInput(flowName=flowName, primaryRecordId=primaryRecordId, status=status, cpu=cpu, soql=soql, dml=dml) });
    }
}
