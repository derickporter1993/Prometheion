@IsTest
private class FlowExecutionLoggerTest {
    @IsTest
    static void testLogInvocable() {
        // Test the invocable method directly
        FlowExecutionLogger.LogInput input = new FlowExecutionLogger.LogInput();
        input.flowName = 'TestFlow';
        input.primaryRecordId = null;
        input.status = 'SUCCESS';
        input.cpu = 100;
        input.soql = 5;
        input.dml = 2;

        Test.startTest();
        FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>{ input });
        Test.stopTest();

        List<Flow_Execution__c> logs = [
            SELECT Flow_Name__c, Status__c, CPU__c, SOQL__c, DML__c
            FROM Flow_Execution__c
            WHERE Flow_Name__c = 'TestFlow'
        ];
        System.assertEquals(1, logs.size(), 'Should have created 1 log record');
        System.assertEquals('SUCCESS', logs[0].Status__c, 'Status should match');
        System.assertEquals(100, logs[0].CPU__c, 'CPU should match');
        System.assertEquals(5, logs[0].SOQL__c, 'SOQL should match');
        System.assertEquals(2, logs[0].DML__c, 'DML should match');
    }

    @IsTest
    static void testLogAuraEnabled() {
        // Test the AuraEnabled method
        Test.startTest();
        FlowExecutionLogger.log('AuraTestFlow', null, 'ERROR', 500, 10, 5);
        Test.stopTest();

        List<Flow_Execution__c> logs = [
            SELECT Flow_Name__c, Status__c, CPU__c, SOQL__c, DML__c
            FROM Flow_Execution__c
            WHERE Flow_Name__c = 'AuraTestFlow'
        ];
        System.assertEquals(1, logs.size(), 'Should have created 1 log record');
        System.assertEquals('ERROR', logs[0].Status__c, 'Status should be ERROR');
        System.assertEquals(500, logs[0].CPU__c, 'CPU should match');
        System.assertEquals(10, logs[0].SOQL__c, 'SOQL should match');
        System.assertEquals(5, logs[0].DML__c, 'DML should match');
    }

    @IsTest
    static void testBulkInsert() {
        // Test bulk processing
        List<FlowExecutionLogger.LogInput> inputs = new List<FlowExecutionLogger.LogInput>();
        for (Integer i = 0; i < 10; i++) {
            FlowExecutionLogger.LogInput input = new FlowExecutionLogger.LogInput();
            input.flowName = 'BulkFlow' + i;
            input.status = 'SUCCESS';
            input.cpu = 100 * i;
            input.soql = i;
            input.dml = i;
            inputs.add(input);
        }

        Test.startTest();
        FlowExecutionLogger.logInvocable(inputs);
        Test.stopTest();

        List<Flow_Execution__c> logs = [
            SELECT Id
            FROM Flow_Execution__c
            WHERE Flow_Name__c LIKE 'BulkFlow%'
        ];
        System.assertEquals(10, logs.size(), 'Should have created 10 log records');
    }
}
