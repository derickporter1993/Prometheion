@IsTest(testFor=FlowExecutionLogger.class)
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
        Assert.areEqual(1, logs.size(), 'Should have created 1 log record');
        Assert.areEqual('SUCCESS', logs[0].Status__c, 'Status should match');
        Assert.areEqual(100, logs[0].CPU__c, 'CPU should match');
        Assert.areEqual(5, logs[0].SOQL__c, 'SOQL should match');
        Assert.areEqual(2, logs[0].DML__c, 'DML should match');
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
        Assert.areEqual(1, logs.size(), 'Should have created 1 log record');
        Assert.areEqual('ERROR', logs[0].Status__c, 'Status should be ERROR');
        Assert.areEqual(500, logs[0].CPU__c, 'CPU should match');
        Assert.areEqual(10, logs[0].SOQL__c, 'SOQL should match');
        Assert.areEqual(5, logs[0].DML__c, 'DML should match');
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
        Assert.areEqual(10, logs.size(), 'Should have created 10 log records');
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
        Assert.areEqual(200, logs.size(), 'Should have created 200 log records');
        
        // Verify data integrity
        for (Flow_Execution__c log : logs) {
            Assert.areNotEqual(null, log.Flow_Name__c, 'Flow name should not be null');
            Assert.areNotEqual(null, log.Status__c, 'Status should not be null');
        }
    }
    
    @IsTest
    static void testInputValidation() {
        // Test input validation
        Test.startTest();

        // Test null inputs
        try {
            FlowExecutionLogger.logInvocable(null);
            Assert.fail('Should have thrown exception for null inputs');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for null inputs should have a message');
        }

        // Test empty inputs
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>());
            Assert.fail('Should have thrown exception for empty inputs');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for empty inputs should have a message');
        }

        // Test blank flow name
        FlowExecutionLogger.LogInput invalidInput = new FlowExecutionLogger.LogInput();
        invalidInput.flowName = '';
        invalidInput.status = 'SUCCESS';
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>{ invalidInput });
            Assert.fail('Should have thrown exception for blank flow name');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for blank flow name should have a message');
        }

        // Test negative CPU
        FlowExecutionLogger.LogInput negativeInput = new FlowExecutionLogger.LogInput();
        negativeInput.flowName = 'TestFlow';
        negativeInput.status = 'SUCCESS';
        negativeInput.cpu = -1;
        try {
            FlowExecutionLogger.logInvocable(new List<FlowExecutionLogger.LogInput>{ negativeInput });
            Assert.fail('Should have thrown exception for negative CPU');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for negative CPU should have a message');
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
            Assert.fail( 'Should have thrown exception for blank flow name');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Flow name cannot be blank'), 'Expected flow name validation error');
        }

        // Test null flow name
        try {
            FlowExecutionLogger.log(null, null, 'SUCCESS', 100, 5, 2);
            Assert.fail( 'Should have thrown exception for null flow name');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Flow name cannot be blank'), 'Expected flow name validation error');
        }

        // Test blank status
        try {
            FlowExecutionLogger.log('TestFlow', null, '', 100, 5, 2);
            Assert.fail( 'Should have thrown exception for blank status');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Status cannot be blank'), 'Expected status validation error');
        }

        // Test null status
        try {
            FlowExecutionLogger.log('TestFlow', null, null, 100, 5, 2);
            Assert.fail( 'Should have thrown exception for null status');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Status cannot be blank'), 'Expected status validation error');
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
        Assert.areEqual(1, logs.size(), 'Should create record even if rate limit cache unavailable');
    }
}
