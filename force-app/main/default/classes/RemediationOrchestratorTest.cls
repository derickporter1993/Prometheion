/**
 * Test class for RemediationOrchestrator
 * Tests automated remediation actions for compliance events
 * @group Tests
 * @see RemediationOrchestrator
 */
@IsTest(testFor=RemediationOrchestrator.class)
private class RemediationOrchestratorTest {

    @TestSetup
    static void setup() {
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Test Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user pkg;

        Elaro_Evidence_Item__c evidence = new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'LoginAs',
            Evidence_Date__c = Date.today(),
            Description__c = 'Test impersonation event',
            Status__c = 'COLLECTED'
        );
        insert as user evidence;
    }

    @isTest
    static void testCreateRemediationCase() {
        Elaro_Evidence_Item__c evidence = [SELECT Id FROM Elaro_Evidence_Item__c LIMIT 1];

        Test.startTest();
        Id caseId = RemediationOrchestrator.createRemediationCase(evidence.Id, 'High');
        Test.stopTest();

        Assert.areNotEqual(null, caseId, 'Case should be created');
        Case remedCase = [SELECT Subject, Priority, Status FROM Case WHERE Id = :caseId];
        Assert.areEqual('High', remedCase.Priority, 'Priority should match');
        Assert.areEqual('New', remedCase.Status, 'Status should be New');
    }

    @isTest
    static void testCreateRemediationCaseDefaultPriority() {
        Elaro_Evidence_Item__c evidence = [SELECT Id FROM Elaro_Evidence_Item__c LIMIT 1];

        Test.startTest();
        Id caseId = RemediationOrchestrator.createRemediationCase(evidence.Id, null);
        Test.stopTest();

        Case remedCase = [SELECT Priority FROM Case WHERE Id = :caseId];
        Assert.areEqual('High', remedCase.Priority, 'Default priority should be High');
    }

    @isTest
    static void testCreateRemediationCaseBlankEventId() {
        Test.startTest();
        try {
            RemediationOrchestrator.createRemediationCase('', 'Medium');
            Assert.fail( 'Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'), 'Error message should indicate missing ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAvailableActionsLoginAs() {
        Test.startTest();
        List<RemediationOrchestrator.ActionOption> actions = RemediationOrchestrator.getAvailableActions('LoginAs');
        Test.stopTest();

        Assert.isTrue(actions.size() >= 2, 'Should have multiple actions available');
        Boolean hasRevoke = false;
        Boolean hasLock = false;
        for (RemediationOrchestrator.ActionOption action : actions) {
            if (action.value == 'REVOKE_PERMISSION') { hasRevoke = true; }
            if (action.value == 'LOCK_USER') { hasLock = true; }
        }
        Assert.isTrue(hasRevoke, 'LoginAs should have REVOKE_PERMISSION action');
        Assert.isTrue(hasLock, 'LoginAs should have LOCK_USER action');
    }

    @isTest
    static void testGetAvailableActionsAPI() {
        Test.startTest();
        List<RemediationOrchestrator.ActionOption> actions = RemediationOrchestrator.getAvailableActions('API');
        Test.stopTest();

        Boolean hasDisableAPI = false;
        for (RemediationOrchestrator.ActionOption action : actions) {
            if (action.value == 'DISABLE_API_ACCESS') { hasDisableAPI = true; }
        }
        Assert.isTrue(hasDisableAPI, 'API event should have DISABLE_API_ACCESS action');
    }

    @isTest
    static void testExecuteCreateCaseAction() {
        Map<String, Object> context = new Map<String, Object>{
            'eventDescription' => 'Test compliance event',
            'priority' => 'Medium'
        };

        Test.startTest();
        RemediationOrchestrator.RemediationResult result = RemediationOrchestrator.executeRemediationAction(
            'CREATE_CASE', null, context
        );
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Action should succeed');
        Assert.areNotEqual(null, result.resultId, 'Case ID should be returned');
    }

    @isTest
    static void testExecuteNotifyManagerAction() {
        Test.startTest();
        RemediationOrchestrator.RemediationResult result = RemediationOrchestrator.executeRemediationAction(
            'NOTIFY_MANAGER', UserInfo.getUserId(), new Map<String, Object>{'eventDescription' => 'Test event'}
        );
        Test.stopTest();

        Assert.areNotEqual(null, result.message, 'Message should be set');
    }

    @isTest
    static void testExecuteInvalidAction() {
        Test.startTest();
        try {
            RemediationOrchestrator.executeRemediationAction('INVALID_ACTION', null, new Map<String, Object>());
            Assert.fail( 'Should throw exception');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid'), 'Error should indicate invalid action');
        }
        Test.stopTest();
    }

    @isTest
    static void testExecuteQuarantineDataAction() {
        Test.startTest();
        RemediationOrchestrator.RemediationResult result = RemediationOrchestrator.executeRemediationAction(
            'QUARANTINE_DATA', '001000000000001AAA', new Map<String, Object>()
        );
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Quarantine action should succeed');
    }

    @isTest
    static void testGetRemediationHistory() {
        Elaro_Evidence_Item__c evidence = [SELECT Id FROM Elaro_Evidence_Item__c LIMIT 1];

        Test.startTest();
        List<RemediationOrchestrator.RemediationResult> history = RemediationOrchestrator.getRemediationHistory(evidence.Id);
        Test.stopTest();

        Assert.areNotEqual(null, history, 'History should not be null');
    }
}
