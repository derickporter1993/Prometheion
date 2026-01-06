/**
 * Test class for PrometheionGDPRDataPortabilityService
 * Tests GDPR Article 20 Right to Data Portability functionality
 *
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionGDPRDataPortabilityServiceTest {

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
        String jsonData = PrometheionGDPRDataPortabilityService.exportContactDataWithRelated(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, jsonData, 'Should return JSON data');
        System.assert(jsonData.length() > 0, 'Should have content');
    }

    @IsTest
    static void testExportBulkContactData() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 50];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : contacts) {
            contactIds.add(c.Id);
        }

        Test.startTest();
        Map<Id, String> exportedData = PrometheionGDPRDataPortabilityService.exportBulkContactData(contactIds);
        Test.stopTest();

        System.assertEquals(50, exportedData.size(), 'Should export all 50 contacts');
        for (String jsonData : exportedData.values()) {
            System.assertNotEquals(null, jsonData, 'Each export should have data');
        }
    }

    @IsTest
    static void testCreateDataExportRequest() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        Id requestId = PrometheionGDPRDataPortabilityService.createDataExportRequest(c.Id, 'JSON');
        Test.stopTest();

        System.assertNotEquals(null, requestId, 'Should create export request');
    }

    @IsTest
    static void testGetExportableFields() {
        Test.startTest();
        List<String> fields = PrometheionGDPRDataPortabilityService.getExportableFields('Contact');
        Test.stopTest();

        System.assert(fields.size() > 0, 'Should return exportable fields');
        System.assert(fields.contains('FirstName') || fields.contains('LastName'),
            'Should include standard fields');
    }

    @IsTest
    static void testExportToCSVFormat() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        String csvData = PrometheionGDPRDataPortabilityService.exportToCSV(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, csvData, 'Should return CSV data');
        System.assert(csvData.contains(','), 'Should be comma-separated');
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

        Map<Id, String> exportedData = PrometheionGDPRDataPortabilityService.exportBulkContactData(contactIds);

        Integer endQueries = Limits.getQueries();
        Integer endHeap = Limits.getHeapSize();
        Test.stopTest();

        System.assertEquals(200, exportedData.size(), 'Should export all 200 contacts');
        System.assert(endQueries - startQueries < 20, 'Should be bulkified');
    }

    @IsTest
    static void testGetDataInventory() {
        Contact c = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        Map<String, Object> inventory = PrometheionGDPRDataPortabilityService.getDataInventory(c.Id);
        Test.stopTest();

        System.assertNotEquals(null, inventory, 'Should return inventory');
        System.assert(inventory.containsKey('objects'), 'Should list objects');
    }
}
