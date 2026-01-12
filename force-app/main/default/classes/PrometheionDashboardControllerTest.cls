/**
 * PrometheionDashboardControllerTest
 * 
 * Test class for PrometheionDashboardController
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionDashboardControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@prometheion.test',
            Username = 'testuser' + System.now().getTime() + '@prometheion.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create test audit packages
        List<Prometheion_Audit_Package__c> packages = new List<Prometheion_Audit_Package__c>();
        for (Integer i = 0; i < 5; i++) {
            packages.add(new Prometheion_Audit_Package__c(
                Package_Name__c = 'Test Package ' + i,
                Framework__c = i < 3 ? 'SOC2' : 'HIPAA',
                Status__c = 'DRAFT',
                Audit_Period_Start__c = Date.today().addDays(-30),
                Audit_Period_End__c = Date.today(),
                Created_By__c = testUser.Id,
                Last_Modified_By__c = testUser.Id
            ));
        }
        insert packages;
        
        // Create framework mappings
        List<Prometheion_Framework_Mapping__c> mappings = new List<Prometheion_Framework_Mapping__c>();
        for (Prometheion_Audit_Package__c pkg : packages) {
            mappings.add(new Prometheion_Framework_Mapping__c(
                Audit_Package__c = pkg.Id,
                Framework__c = pkg.Framework__c,
                Requirement_Code__c = pkg.Framework__c + '-001',
                Requirement_Description__c = 'Test requirement',
                Entity_Type__c = 'PERMISSION_SET',
                Is_Active__c = true
            ));
        }
        insert mappings;
        
        // Create evidence items
        List<Prometheion_Evidence_Item__c> evidenceItems = new List<Prometheion_Evidence_Item__c>();
        for (Prometheion_Audit_Package__c pkg : packages) {
            evidenceItems.add(new Prometheion_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'SETUP_AUDIT_TRAIL',
                Evidence_Date__c = Date.today(),
                Status__c = 'COLLECTED'
            ));
        }
        insert evidenceItems;
    }
    
    @IsTest
    static void testGetAuditPackages_AllFrameworks() {
        Test.startTest();
        List<PrometheionDashboardController.AuditPackageInfo> packages = 
            PrometheionDashboardController.getAuditPackages('ALL');
        Test.stopTest();
        
        System.assertNotEquals(null, packages, 'Packages should not be null');
        System.assert(packages.size() > 0, 'Should return at least one package');
    }
    
    @IsTest
    static void testGetAuditPackages_SpecificFramework() {
        Test.startTest();
        List<PrometheionDashboardController.AuditPackageInfo> packages = 
            PrometheionDashboardController.getAuditPackages('SOC2');
        Test.stopTest();
        
        System.assertNotEquals(null, packages, 'Packages should not be null');
        for (PrometheionDashboardController.AuditPackageInfo pkg : packages) {
            System.assertEquals('SOC2', pkg.framework, 'Framework should match');
        }
    }
    
    @IsTest
    static void testGetAuditPackages_BlankFramework() {
        Test.startTest();
        List<PrometheionDashboardController.AuditPackageInfo> packages = 
            PrometheionDashboardController.getAuditPackages(null);
        Test.stopTest();
        
        System.assertNotEquals(null, packages, 'Packages should not be null');
    }
    
    @IsTest
    static void testGetAuditPackageStats() {
        Prometheion_Audit_Package__c pkg = [
            SELECT Id
            FROM Prometheion_Audit_Package__c
            LIMIT 1
        ];
        
        Test.startTest();
        PrometheionDashboardController.AuditPackageStats stats = 
            PrometheionDashboardController.getAuditPackageStats(pkg.Id);
        Test.stopTest();
        
        System.assertNotEquals(null, stats, 'Stats should not be null');
        System.assertEquals(pkg.Id, stats.id, 'Package ID should match');
        System.assert(stats.mappingCount > 0, 'Should have mappings');
        System.assert(stats.evidenceCount > 0, 'Should have evidence');
    }
    
    @IsTest
    static void testGetAuditPackageStats_BlankId() {
        Test.startTest();
        try {
            PrometheionDashboardController.getAuditPackageStats('');
            System.assert(false, 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('blank'), 'Should mention blank ID');
        }
        Test.stopTest();
    }
}
