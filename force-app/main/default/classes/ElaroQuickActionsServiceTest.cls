@IsTest(testFor=ElaroQuickActionsService.class)
private class ElaroQuickActionsServiceTest {
    
    @isTest
    static void testAutoRemediateTopViolations() {
        Test.startTest();
        ElaroQuickActionsService.RemediationResult result = 
            ElaroQuickActionsService.autoRemediateTopViolations();
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Should return remediation result');
        Assert.areNotEqual(null, result.messages, 'Should have messages');
    }
    
    @isTest
    static void testRevokeModifyAllData() {
        // Create test user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test@test.com',
            Username = 'testuser' + System.now().getTime() + '@test.com',
            Alias = 'tuser',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert as user u;
        
        Test.startTest();
        ElaroQuickActionsService.ActionResult result = 
            ElaroQuickActionsService.revokeModifyAllData(new List<Id>{u.Id});
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Should return action result');
    }
    
    @isTest
    static void testDeactivateInactiveUsers() {
        Test.startTest();
        ElaroQuickActionsService.ActionResult result = 
            ElaroQuickActionsService.deactivateInactiveUsers(90);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Should return action result');
    }
    
    @isTest
    static void testRemovePermissionSetAssignment() {
        // Create permission set and assignment
        PermissionSet ps = new PermissionSet(
            Name = 'Test_PS',
            Label = 'Test Permission Set'
        );
        insert as user ps;
        
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'test2@test.com',
            Username = 'testuser2' + System.now().getTime() + '@test.com',
            Alias = 'tuser2',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert as user u;
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
        insert as user psa;
        
        Test.startTest();
        ElaroQuickActionsService.ActionResult result = 
            ElaroQuickActionsService.removePermissionSetAssignment(psa.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Should return action result');
        Assert.areEqual(true, result.success, 'Should succeed');
    }
}

