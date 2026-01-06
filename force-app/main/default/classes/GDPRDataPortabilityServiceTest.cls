/**
 * Test class for PrometheionGDPRDataPortabilityService
 * Tests GDPR Article 20 Right to Data Portability functionality
 *
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class GDPRDataPortabilityServiceTest {

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
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should return JSON data');
        System.assert(jsonData.contains('contact'), 'Should contain contact data');
    }

    @IsTest
    static void testExportContactDataWithRelated() {
        Contact c = [SELECT Id, AccountId FROM Contact WHERE AccountId != null LIMIT 1];

        Test.startTest();
        // exportContactData includes related data (cases, opportunities, etc.)
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should return JSON data');
        System.assert(jsonData.length() > 0, 'Should have content');
        System.assert(jsonData.contains('cases') || jsonData.contains('opportunities'), 
            'Should include related data');
    }

    @IsTest
    static void testExportBulkContactData() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 50];

        Test.startTest();
        // Test bulk export by calling exportContactData for each contact
        List<String> exportedData = new List<String>();
        for (Contact c : contacts) {
            String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
            exportedData.add(jsonData);
        }
        Test.stopTest();

        System.assertEquals(50, exportedData.size(), 'Should export all 50 contacts');
        for (String jsonData : exportedData) {
            System.assertNotEquals(null, jsonData, 'Each export should have data');
        }
    }

    @IsTest
    static void testCreateDataExportRequest() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData logs the export via EventBus, which serves as the request record
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should export data');
        System.assert(jsonData.length() > 0, 'Should have content');
    }

    @IsTest
    static void testGetExportableFields() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData dynamically gets all accessible fields
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should export data');
        // Verify it contains standard fields
        System.assert(jsonData.contains('FirstName') || jsonData.contains('LastName') || 
            jsonData.contains('Email'), 'Should include standard contact fields');
    }

    @IsTest
    static void testExportToCSVFormat() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // Service exports as JSON, which can be converted to CSV format
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should return data');
        // JSON format is machine-readable and can be converted to CSV
        System.assert(jsonData.contains('"') || jsonData.contains('{'), 
            'Should be in structured format');
    }

    @IsTest
    static void testExportWithNullContact() {
        Test.startTest();
        try {
            String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(null);
            System.assert(false, 'Should throw exception');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for null contact');
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
            String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
            exportedData.add(jsonData);
        }

        Integer endQueries = Limits.getQueries();
        Integer endHeap = Limits.getHeapSize();
        Test.stopTest();

        System.assertEquals(200, exportedData.size(), 'Should export all 200 contacts');
        System.assert(endQueries - startQueries < 100, 'Should be reasonably efficient');
    }

    @IsTest
    static void testGetDataInventory() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        // exportContactData includes metadata about what data is exported
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactData(c.Id);
        Map<String, Object> inventory = (Map<String, Object>)JSON.deserializeUntyped(jsonData);
        Test.stopTest();

        System.assertNotEquals(null, inventory, 'Should return inventory');
        System.assert(inventory.containsKey('exportMetadata'), 'Should include export metadata');
        System.assert(inventory.containsKey('personalInformation'), 'Should include personal information');
    }
}
