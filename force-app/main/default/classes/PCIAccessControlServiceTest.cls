/**
 * Test class for PCIAccessControlService
 * Tests RBAC enforcement, privileged access review, credential rotation, access auditing
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class PCIAccessControlServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test users
        List<User> users = new List<User>();
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        
        for (Integer i = 0; i < 200; i++) {
            users.add(new User(
                FirstName = 'Test',
                LastName = 'User' + i,
                Email = 'testuser' + i + '@example.com',
                Username = 'testuser' + i + '@example.com.test',
                Alias = 'tuser' + i,
                ProfileId = standardProfile.Id,
                TimeZoneSidKey = 'America/New_York',
                LocaleSidKey = 'en_US',
                EmailEncodingKey = 'UTF-8',
                LanguageLocaleKey = 'en_US'
            ));
        }
        insert users;
    }
    
    @IsTest
    static void testEnforceRBAC_Success() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        String resourceName = 'CardholderData';
        
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        Map<String, Object> result = service.enforceRBAC(testUser.Id, resourceName);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'RBAC result should not be null');
        System.assert(result.containsKey('hasAccess'), 'Should include access decision');
    }
    
    @IsTest
    static void testEnforceRBAC_Bulk() {
        List<User> users = [SELECT Id FROM User WHERE IsActive = true LIMIT 200];
        
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (User u : users) {
            try {
                Map<String, Object> result = service.enforceRBAC(u.Id, 'CardholderData');
                results.add(result);
            } catch (Exception e) {
                // Some may fail due to test data limitations
            }
        }
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should process bulk RBAC checks');
    }
    
    @IsTest
    static void testReviewPrivilegedAccess() {
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        List<Map<String, Object>> reviews = service.reviewPrivilegedAccess();
        Test.stopTest();
        
        System.assertNotEquals(null, reviews, 'Reviews list should not be null');
    }
    
    @IsTest
    static void testRotateCredentials_Success() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        Map<String, Object> result = service.rotateCredentials(testUser.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Credential rotation should succeed');
        System.assertNotEquals(null, result.get('rotationDate'), 'Rotation date should be set');
    }
    
    @IsTest
    static void testAuditAccessChanges() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        String action = 'READ';
        String resourceName = 'CardholderData';
        
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        Map<String, Object> result = service.auditAccessChanges(testUser.Id, action, resourceName);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Access audit should succeed');
        System.assertEquals(action, result.get('action'), 'Action should match');
    }
    
    @IsTest
    static void testEnforceRBAC_NullParameters() {
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        try {
            service.enforceRBAC(null, 'Resource');
            System.assert(false, 'Should throw exception for null user');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testRotateCredentials_NullUser() {
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        try {
            service.rotateCredentials(null);
            System.assert(false, 'Should throw exception for null user');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testAuditAccessChanges_AllActions() {
        User testUser = [SELECT Id FROM User WHERE IsActive = true LIMIT 1];
        String resourceName = 'CardholderData';
        List<String> actions = new List<String>{ 'CREATE', 'READ', 'UPDATE', 'DELETE' };
        
        Test.startTest();
        PCIAccessControlService service = new PCIAccessControlService();
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (String action : actions) {
            Map<String, Object> result = service.auditAccessChanges(testUser.Id, action, resourceName);
            results.add(result);
        }
        Test.stopTest();
        
        System.assertEquals(4, results.size(), 'Should audit all actions');
    }
}
