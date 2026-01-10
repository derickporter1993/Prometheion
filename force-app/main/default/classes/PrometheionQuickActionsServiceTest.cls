@isTest
private class PrometheionQuickActionsServiceTest {
    
    @isTest
    static void testAutoRemediateTopViolations() {
        Test.startTest();
        PrometheionQuickActionsService.RemediationResult result = 
            PrometheionQuickActionsService.autoRemediateTopViolations();
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return remediation result');
        System.assertNotEquals(null, result.messages, 'Should have messages');
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
        insert u;
        
        Test.startTest();
        PrometheionQuickActionsService.ActionResult result = 
            PrometheionQuickActionsService.revokeModifyAllData(new List<Id>{u.Id});
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return action result');
    }
    
    @isTest
    static void testDeactivateInactiveUsers() {
        Test.startTest();
        PrometheionQuickActionsService.ActionResult result = 
            PrometheionQuickActionsService.deactivateInactiveUsers(90);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return action result');
    }
    
    @isTest
    static void testRemovePermissionSetAssignment() {
        // Create permission set and assignment
        PermissionSet ps = new PermissionSet(
            Name = 'Test_PS',
            Label = 'Test Permission Set'
        );
        insert ps;
        
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
        insert u;
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = u.Id,
            PermissionSetId = ps.Id
        );
        insert psa;
        
        Test.startTest();
        PrometheionQuickActionsService.ActionResult result = 
            PrometheionQuickActionsService.removePermissionSetAssignment(psa.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Should return action result');
        System.assertEquals(true, result.success, 'Should succeed');
    }
}

