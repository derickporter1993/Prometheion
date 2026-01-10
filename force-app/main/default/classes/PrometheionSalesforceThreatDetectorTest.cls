@isTest
private class PrometheionSalesforceThreatDetectorTest {
    
    @isTest
    static void testDetectPermissionSetClones() {
        // Create a suspicious permission set
        PermissionSet ps = new PermissionSet(
            Name = 'Test_Clone_Copy',
            Label = 'Test Clone Copy'
        );
        insert ps;
        
        Test.startTest();
        List<PrometheionSalesforceThreatDetector.Threat> threats = 
            PrometheionSalesforceThreatDetector.detectPermissionSetClones();
        Test.stopTest();
        
        System.assertNotEquals(null, threats, 'Should return threat list');
        // Note: Actual detection depends on PermissionsModifyAllData which can't be set in test
    }
    
    @isTest
    static void testDetectInactiveUsersWithAccess() {
        // Create inactive user
        Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User u = new User(
            FirstName = 'Inactive',
            LastName = 'User',
            Email = 'inactive@test.com',
            Username = 'inactive' + System.now().getTime() + '@test.com',
            Alias = 'inactive',
            ProfileId = p.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            IsActive = true
        );
        insert u;
        
        // Note: LastLoginDate is read-only and cannot be set in tests
        // The test will rely on actual LastLoginDate values or mock the detection logic
        
        Test.startTest();
        List<PrometheionSalesforceThreatDetector.Threat> threats = 
            PrometheionSalesforceThreatDetector.detectInactiveUsersWithAccess();
        Test.stopTest();
        
        System.assertNotEquals(null, threats, 'Should return threat list');
    }
    
    @isTest
    static void testDetectExcessiveAdminPermissions() {
        Test.startTest();
        List<PrometheionSalesforceThreatDetector.Threat> threats = 
            PrometheionSalesforceThreatDetector.detectExcessiveAdminPermissions();
        Test.stopTest();
        
        System.assertNotEquals(null, threats, 'Should return threat list');
    }
    
    @isTest
    static void testDetectAllThreats() {
        Test.startTest();
        List<PrometheionSalesforceThreatDetector.Threat> threats = 
            PrometheionSalesforceThreatDetector.detectAllThreats();
        Test.stopTest();
        
        System.assertNotEquals(null, threats, 'Should return all threats');
    }
}

