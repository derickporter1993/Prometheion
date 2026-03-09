/**
 * ElaroDashboardControllerTest
 * 
 * Test class for ElaroDashboardController
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroDashboardControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@elaro.test',
            Username = 'testuser' + System.now().getTime() + '@elaro.test',
            Alias = 'tuser',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            ProfileId = UserInfo.getProfileId(),
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        
        // Create test audit packages
        List<Elaro_Audit_Package__c> packages = new List<Elaro_Audit_Package__c>();
        for (Integer i = 0; i < 5; i++) {
            packages.add(new Elaro_Audit_Package__c(
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
        List<Elaro_Framework_Mapping__c> mappings = new List<Elaro_Framework_Mapping__c>();
        for (Elaro_Audit_Package__c pkg : packages) {
            mappings.add(new Elaro_Framework_Mapping__c(
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
        List<Elaro_Evidence_Item__c> evidenceItems = new List<Elaro_Evidence_Item__c>();
        for (Elaro_Audit_Package__c pkg : packages) {
            evidenceItems.add(new Elaro_Evidence_Item__c(
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
        List<ElaroDashboardController.AuditPackageInfo> packages = 
            ElaroDashboardController.getAuditPackages('ALL');
        Test.stopTest();
        
        Assert.areNotEqual(null, packages, 'Packages should not be null');
        Assert.isTrue(packages.size() > 0, 'Should return at least one package');
    }
    
    @IsTest
    static void testGetAuditPackages_SpecificFramework() {
        Test.startTest();
        List<ElaroDashboardController.AuditPackageInfo> packages = 
            ElaroDashboardController.getAuditPackages('SOC2');
        Test.stopTest();
        
        Assert.areNotEqual(null, packages, 'Packages should not be null');
        for (ElaroDashboardController.AuditPackageInfo pkg : packages) {
            Assert.areEqual('SOC2', pkg.framework, 'Framework should match');
        }
    }
    
    @IsTest
    static void testGetAuditPackages_BlankFramework() {
        Test.startTest();
        List<ElaroDashboardController.AuditPackageInfo> packages = 
            ElaroDashboardController.getAuditPackages(null);
        Test.stopTest();
        
        Assert.areNotEqual(null, packages, 'Packages should not be null');
    }
    
    @IsTest
    static void testGetAuditPackageStats() {
        Elaro_Audit_Package__c pkg = [
            SELECT Id
            FROM Elaro_Audit_Package__c
            LIMIT 1
        ];
        
        Test.startTest();
        ElaroDashboardController.AuditPackageStats stats = 
            ElaroDashboardController.getAuditPackageStats(pkg.Id);
        Test.stopTest();
        
        Assert.areNotEqual(null, stats, 'Stats should not be null');
        Assert.areEqual(pkg.Id, stats.id, 'Package ID should match');
        Assert.isTrue(stats.mappingCount > 0, 'Should have mappings');
        Assert.isTrue(stats.evidenceCount > 0, 'Should have evidence');
    }
    
    @IsTest
    static void testGetAuditPackageStats_BlankId() {
        Test.startTest();
        try {
            ElaroDashboardController.getAuditPackageStats('');
            Assert.fail( 'Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('blank'), 'Should mention blank ID');
        }
        Test.stopTest();
    }
}
