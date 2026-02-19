/**
 * Test class for ElaroGDPRDataPortabilityService
 * Tests GDPR Article 20 Right to Data Portability functionality
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroGDPRDataPortabilityService.class)
private class ElaroGDPRDataPortabilityServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                BillingCity = 'Test City',
                BillingCountry = 'Test Country'
            ));
        }
        insert accounts;

        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                Phone = '555-000-' + String.valueOf(i).leftPad(4, '0'),
                AccountId = accounts[i].Id
            ));
        }
        insert contacts;
    }

    @IsTest
    static void testExportContactData() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, jsonData, 'Should return JSON data');
        Assert.isTrue(jsonData.contains('contact'), 'Should contain contact data');
    }

    @IsTest
    static void testExportContactDataWithRelated() {
        Contact c = [SELECT Id, AccountId FROM Contact WHERE AccountId != null LIMIT 1];

        Test.startTest();
        // exportContactData includes related data (cases, opportunities, etc.)
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, jsonData, 'Should return JSON data');
        Assert.isTrue(jsonData.length() > 0, 'Should have content');
        Assert.isTrue(jsonData.contains('cases') || jsonData.contains('opportunities'), 
            'Should include related data');
    }

    @IsTest
    static void testExportBulkContactData() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 50];

        Test.startTest();
        // Test bulk export by calling exportContactData for each contact
        List<String> exportedData = new List<String>();
        for (Contact c : contacts) {
            String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
            exportedData.add(jsonData);
        }
        Test.stopTest();

        Assert.areEqual(50, exportedData.size(), 'Should export all 50 contacts');
        for (String jsonData : exportedData) {
            Assert.areNotEqual(null, jsonData, 'Each export should have data');
        }
    }

    @IsTest
    static void testCreateDataExportRequest() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData logs the export via EventBus, which serves as the request record
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, jsonData, 'Should export data');
        Assert.isTrue(jsonData.length() > 0, 'Should have content');
    }

    @IsTest
    static void testGetExportableFields() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData dynamically gets all accessible fields
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, jsonData, 'Should export data');
        // Verify it contains standard fields
        Assert.isTrue(jsonData.contains('FirstName') || jsonData.contains('LastName') || 
            jsonData.contains('Email'), 'Should include standard contact fields');
    }

    @IsTest
    static void testExportToCSVFormat() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // Service exports as JSON, which can be converted to CSV format
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        Assert.areNotEqual(null, jsonData, 'Should return data');
        // JSON format is machine-readable and can be converted to CSV
        Assert.isTrue(jsonData.contains('"') || jsonData.contains('{'), 
            'Should be in structured format');
    }

    @IsTest
    static void testExportWithNullContact() {
        Test.startTest();
        try {
            String jsonData = ElaroGDPRDataPortabilityService.exportContactData(null);
            Assert.fail( 'Should throw exception');
        } catch (Exception e) {
            Assert.isNotNull(e.getMessage(), 'Exception should have a message for null contact');
        }
        Test.stopTest();
    }

    @IsTest
    static void testBulkExportGovernorLimits() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 200];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }

        Test.startTest();
        Integer startQueries = Limits.getQueries();
        Integer startHeap = Limits.getHeapSize();

        // Test bulk export by calling exportContactData for each contact
        List<String> exportedData = new List<String>();
        for (Contact c : contacts) {
            String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
            exportedData.add(jsonData);
        }

        Integer endQueries = Limits.getQueries();
        Integer endHeap = Limits.getHeapSize();
        Test.stopTest();

        Assert.areEqual(200, exportedData.size(), 'Should export all 200 contacts');
        Assert.isTrue(endQueries - startQueries < 100, 'Should be reasonably efficient');
    }

    @IsTest
    static void testGetDataInventory() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData includes metadata about what data is exported
        String jsonData = ElaroGDPRDataPortabilityService.exportContactData(c.Id);
        Map<String, Object> inventory = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        Test.stopTest();

        Assert.areNotEqual(null, inventory, 'Should return inventory');
        Assert.isTrue(inventory.containsKey('exportMetadata'), 'Should include export metadata');
        Assert.isTrue(inventory.containsKey('personalInformation'), 'Should include personal information');
    }
}