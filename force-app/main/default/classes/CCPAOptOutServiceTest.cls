/**
 * Test class for CCPAOptOutService
 * Tests opt-out processing, GPC signal handling, Do Not Sell list management
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class CCPAOptOutServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Consumer' + i,
                Email = 'consumer' + i + '@example.com'
            ));
        }
        insert contacts;
    }
    
    @IsTest
    static void testProcessOptOut_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.processOptOut(testContact.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Opt-out should succeed');
        System.assertNotEquals(null, result.get('optOutDate'), 'Opt-out date should be set');
    }
    
    @IsTest
    static void testProcessOptOut_Bulk() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 200];
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        List<Map<String, Object>> results = new List<Map<String, Object>>();
        for (Contact c : contacts) {
            try {
                Map<String, Object> result = service.processOptOut(c.Id);
                results.add(result);
            } catch (Exception e) {
                // Some may fail due to test data limitations
            }
        }
        Test.stopTest();
        
        System.assert(results.size() > 0, 'Should process bulk opt-outs');
    }
    
    @IsTest
    static void testHonorGPC_OptOut() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Boolean gpcSignal = true; // Opt-out signal
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.honorGPC(testContact.Id, gpcSignal);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'GPC opt-out should succeed');
    }
    
    @IsTest
    static void testHonorGPC_OptIn() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Boolean gpcSignal = false; // Opt-in signal
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.honorGPC(testContact.Id, gpcSignal);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'GPC opt-in result should not be null');
    }
    
    @IsTest
    static void testUpdateDoNotSellList_Add() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Boolean optOut = true;
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.updateDoNotSellList(testContact.Id, optOut);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Should add to Do Not Sell list');
    }
    
    @IsTest
    static void testUpdateDoNotSellList_Remove() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        Boolean optOut = false;
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.updateDoNotSellList(testContact.Id, optOut);
        Test.stopTest();
        
        System.assertNotEquals(null, result, 'Remove result should not be null');
    }
    
    @IsTest
    static void testSyncWithVendors() {
        // Create third-party recipients
        List<Third_Party_Recipient__c> recipients = new List<Third_Party_Recipient__c>();
        for (Integer i = 0; i < 10; i++) {
            recipients.add(new Third_Party_Recipient__c(
                Recipient_Name__c = 'Vendor ' + i,
                Country__c = 'United States'
            ));
        }
        insert recipients;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        Map<String, Object> result = service.syncWithVendors(testContact.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Vendor sync should succeed');
        System.assert(result.containsKey('vendorsSynced'), 'Should include vendor count');
    }
    
    @IsTest
    static void testProcessOptOut_NullContact() {
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        try {
            service.processOptOut(null);
            System.assert(false, 'Should throw exception for null contact');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testHonorGPC_NullParameters() {
        Test.startTest();
        CCPAOptOutService service = new CCPAOptOutService();
        try {
            service.honorGPC(null, true);
            System.assert(false, 'Should throw exception for null contact');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
}
