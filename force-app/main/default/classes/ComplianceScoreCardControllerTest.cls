/**
 * ComplianceScoreCardControllerTest
 * 
 * Test class for ComplianceScoreCardController
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ComplianceScoreCardControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser2@elaro.test',
            Username = 'testuser2' + System.now().getTime() + '@elaro.test',
            Alias = 'tuser2',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create test audit package
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Test SOC2 Package',
            Framework__c = 'SOC2',
            Status__c = 'IN_PROGRESS',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today(),
            Created_By__c = testUser.Id,
            Last_Modified_By__c = testUser.Id
        );
        insert pkg;
        
        // Create framework mappings
        List<Elaro_Framework_Mapping__c> mappings = new List<Elaro_Framework_Mapping__c>();
        mappings.add(new Elaro_Framework_Mapping__c(
            Audit_Package__c = pkg.Id,
            Framework__c = 'SOC2',
            Requirement_Code__c = 'SOC2-CC6.1',
            Requirement_Description__c = 'Logical and physical access controls',
            Entity_Type__c = 'PERMISSION_SET',
            Is_Active__c = true
        ));
        mappings.add(new Elaro_Framework_Mapping__c(
            Audit_Package__c = pkg.Id,
            Framework__c = 'SOC2',
            Requirement_Code__c = 'SOC2-CC6.2',
            Requirement_Description__c = 'Prior authorization for access',
            Entity_Type__c = 'PERMISSION_SET',
            Is_Active__c = true
        ));
        insert mappings;
        
        // Create evidence items
        List<Elaro_Evidence_Item__c> evidenceItems = new List<Elaro_Evidence_Item__c>();
        for (Integer i = 0; i < 3; i++) {
            evidenceItems.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'SETUP_AUDIT_TRAIL',
                Evidence_Date__c = Date.today().addDays(-i),
                Status__c = i == 0 ? 'APPROVED' : 'COLLECTED'
            ));
        }
        insert evidenceItems;
    }
    
    @IsTest
    static void testGetFrameworkDetails_Success() {
        Test.startTest();
        ComplianceScoreCardController.FrameworkDetails details = 
            ComplianceScoreCardController.getFrameworkDetails('SOC2');
        Test.stopTest();
        
        System.assertNotEquals(null, details, 'Details should not be null');
        System.assertEquals('SOC2', details.framework, 'Framework should match');
        System.assert(details.mappingCount >= 0, 'Mapping count should be non-negative');
        System.assert(details.evidenceCount >= 0, 'Evidence count should be non-negative');
        System.assert(details.requirementCount > 0, 'Should have requirements');
    }
    
    @IsTest
    static void testGetFrameworkDetails_BlankFramework() {
        Test.startTest();
        try {
            ComplianceScoreCardController.getFrameworkDetails('');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('blank'), 'Should mention blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetFrameworkDetails_InvalidFramework() {
        Test.startTest();
        try {
            ComplianceScoreCardController.getFrameworkDetails('INVALID');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Unsupported'), 'Should mention unsupported framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetFrameworkDetails_HIPAA() {
        Test.startTest();
        ComplianceScoreCardController.FrameworkDetails details = 
            ComplianceScoreCardController.getFrameworkDetails('HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, details, 'Details should not be null');
        System.assertEquals('HIPAA', details.framework, 'Framework should match');
    }
}
