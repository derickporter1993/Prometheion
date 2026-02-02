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
        // Validate CRUD access
        ElaroSecurityUtils.validateCRUDAccess('Flow_Execution__c', ElaroSecurityUtils.DmlOperation.INSERT);
        
        // Validate FLS for required fields
        List<String> requiredFields = new List<String>{
            'Flow_Name__c', 'Status__c', 'CPU__c', 'SOQL__c', 'DML__c', 'Run_Time__c'
        };
        ElaroSecurityUtils.validateFLSAccess('Flow_Execution__c', requiredFields, true);
        
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
        
        if (!toInsert.isEmpty()) {
            // Strip inaccessible fields before insert
            List<SObject> accessibleRecords = ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.CREATABLE,
                toInsert
            );
            if (!accessibleRecords.isEmpty()) {
                insert accessibleRecords;
            }
        }
    }
    @AuraEnabled
    public static void log(String flowName, Id primaryRecordId, String status, Integer cpu, Integer soql, Integer dml) {
        LogInput input = new LogInput();
        input.flowName = flowName;
        input.primaryRecordId = primaryRecordId;
        input.status = status;
        input.cpu = cpu;
        input.soql = soql;
        input.dml = dml;
        logInvocable(new List<LogInput>{ input });
    }
}
