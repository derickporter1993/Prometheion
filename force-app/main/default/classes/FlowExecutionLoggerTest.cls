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

    @IsTest
    static void testBulkInsert200Records() {
        // Test bulk processing with 200+ records (P1 requirement)
        List<FlowExecutionLogger.LogInput> inputs = new List<FlowExecutionLogger.LogInput>();
        for (Integer i = 0; i < 200; i++) {
            Integer mod2 = Math.mod(i, 2);
            Integer mod10 = Math.mod(i, 10);
            Integer mod5 = Math.mod(i, 5);
            Integer mod3 = Math.mod(i, 3);
            
            FlowExecutionLogger.LogInput input = new FlowExecutionLogger.LogInput();
            input.flowName = 'Bulk200Flow' + i;
            input.status = mod2 == 0 ? 'SUCCESS' : 'Fault';
            input.cpu = 100 * mod10;
            input.soql = mod5;
            input.dml = mod3;
            inputs.add(input);
        }

        Test.startTest();
        FlowExecutionLogger.logInvocable(inputs);
        Test.stopTest();

        List<Flow_Execution__c> logs = [
            SELECT Id, Flow_Name__c, Status__c, CPU__c, SOQL__c, DML__c
            FROM Flow_Execution__c
            WHERE Flow_Name__c LIKE 'Bulk200Flow%'
        ];
        System.assertEquals(200, logs.size(), 'Should have created 200 log records');
        
        // Verify data integrity
        for (Flow_Execution__c log : logs) {
            System.assertNotEquals(null, log.Flow_Name__c, 'Flow name should not be null');
            System.assertNotEquals(null, log.Status__c, 'Status should not be null');
        }
    }
    
    @IsTest
    static void testInputValidation() {
        // Test input validation
        Test.startTest();

        // Test null inputs
        try {
            FlowExecutionLogger.logInvocable(null);
            System.assert(false, 'Should have thrown exception for null inputs');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for null inputs');
        }

        // Test empty inputs
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>());
            System.assert(false, 'Should have thrown exception for empty inputs');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for empty inputs');
        }

        // Test blank flow name
        FlowExecutionLogger.LogInput invalidInput = new FlowExecutionLogger.LogInput();
        invalidInput.flowName = '';
        invalidInput.status = 'SUCCESS';
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>{ invalidInput });
            System.assert(false, 'Should have thrown exception for blank flow name');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank flow name');
        }

        // Test negative CPU
        FlowExecutionLogger.LogInput negativeInput = new FlowExecutionLogger.LogInput();
        negativeInput.flowName = 'TestFlow';
        negativeInput.status = 'SUCCESS';
        negativeInput.cpu = -1;
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>{ negativeInput });
            System.assert(false, 'Should have thrown exception for negative CPU');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for negative CPU');
        }

        Test.stopTest();
    }

    @IsTest
    static void testLogAuraEnabledInputValidation() {
        // Test AuraEnabled method input validation
        Test.startTest();

        // Test blank flow name
        try {
            FlowExecutionLogger.log('', null, 'SUCCESS', 100, 5, 2);
            System.assert(false, 'Should have thrown exception for blank flow name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Flow name cannot be blank'), 'Expected flow name validation error');
        }

        // Test null flow name
        try {
            FlowExecutionLogger.log(null, null, 'SUCCESS', 100, 5, 2);
            System.assert(false, 'Should have thrown exception for null flow name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Flow name cannot be blank'), 'Expected flow name validation error');
        }

        // Test blank status
        try {
            FlowExecutionLogger.log('TestFlow', null, '', 100, 5, 2);
            System.assert(false, 'Should have thrown exception for blank status');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Status cannot be blank'), 'Expected status validation error');
        }

        // Test null status
        try {
            FlowExecutionLogger.log('TestFlow', null, null, 100, 5, 2);
            System.assert(false, 'Should have thrown exception for null status');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Status cannot be blank'), 'Expected status validation error');
        }

        Test.stopTest();
    }

    @IsTest
    static void testRateLimitingGracefulDegradation() {
        // Test that rate limiting degrades gracefully when cache is unavailable
        // The rate limit check should not block execution if cache fails
        Test.startTest();

        // This should work even if cache partition doesn't exist
        // (graceful degradation - logs warning but doesn't throw)
        FlowExecutionLogger.log('RateLimitTest', null, 'SUCCESS', 100, 5, 2);

        Test.stopTest();

        List<Flow_Execution__c> logs = [
            SELECT Id FROM Flow_Execution__c WHERE Flow_Name__c = 'RateLimitTest'
        ];
        System.assertEquals(1, logs.size(), 'Should create record even if rate limit cache unavailable');
    }
}
