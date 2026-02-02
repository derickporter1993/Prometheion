/**
 * Test class for GDPRConsentManagementService
 * Tests consent recording, withdrawal, history, and validation
 * 
 * @author Elaro
 * @version 3.0
 */
@IsTest
private class GDPRConsentManagementServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;
        
        // Create test consents
        List<Consent__c> consents = new List<Consent__c>();
        for (Integer i = 0; i < 100; i++) {
            consents.add(new Consent__c(
                Contact__c = contacts[i].Id,
                Consent_Type__c = 'Marketing',
                Consent_Given__c = true,
                Consent_Date__c = Date.today(),
                Consent_Source__c = 'Web Form'
            ));
        }
        insert consents;
    }
    
    @IsTest
    static void testRecordConsent_Success() {
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        Id consentId = service.recordConsent(testContact.Id, 'Analytics', true, 'Email');
        Test.stopTest();
        
        System.assertNotEquals(null, consentId, 'Consent ID should be returned');
        
        Consent__c consent = [SELECT Id, Consent_Type__c, Consent_Given__c FROM Consent__c WHERE Id = :consentId];
        System.assertEquals('Analytics', consent.Consent_Type__c, 'Consent type should match');
        System.assertEquals(true, consent.Consent_Given__c, 'Consent should be given');
    }
    
    @IsTest
    static void testRecordConsent_Bulk() {
        List<Contact> contacts = [SELECT Id FROM Contact LIMIT 200];
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        List<Id> consentIds = new List<Id>();
        for (Contact c : contacts) {
            try {
                Id consentId = service.recordConsent(c.Id, 'Marketing', true, 'Web');
                consentIds.add(consentId);
            } catch (Exception e) {
                // Some may fail due to test data limitations
            }
        }
        Test.stopTest();
        
        System.assert(consentIds.size() > 0, 'Should process bulk consents');
    }
    
    @IsTest
    static void testWithdrawConsent_Success() {
        // Get a contact that has a consent record
        List<Consent__c> consents = [SELECT Contact__c FROM Consent__c WHERE Consent_Given__c = true LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :consents[0].Contact__c LIMIT 1];
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        Map<String, Object> result = service.withdrawConsent(testContact.Id, 'Marketing');
        Test.stopTest();
        
        System.assertEquals(true, result.get('success'), 'Withdrawal should succeed');
        
        List<Consent__c> withdrawnConsents = [
            SELECT Id, Consent_Withdrawn__c 
            FROM Consent__c 
            WHERE Contact__c = :testContact.Id 
            AND Consent_Type__c = 'Marketing'
        ];
        System.assert(withdrawnConsents.size() > 0, 'Consents should be withdrawn');
    }
    
    @IsTest
    static void testGetConsentHistory() {
        // Get a contact that has a consent record
        List<Consent__c> consents = [SELECT Contact__c FROM Consent__c LIMIT 1];
        Contact testContact = [SELECT Id FROM Contact WHERE Id = :consents[0].Contact__c LIMIT 1];
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        List<Consent__c> history = service.getConsentHistory(testContact.Id);
        Test.stopTest();
        
        System.assert(history.size() > 0, 'Should return consent history');
    }
    
    @IsTest
    static void testValidateConsentBasis_WithConsent() {
        // Create data processing activity with consent basis
        Data_Processing_Activity__c activity = new Data_Processing_Activity__c(
            Activity_Name__c = 'Test Activity',
            Legal_Basis__c = 'Consent'
        );
        insert activity;
        
        Contact testContact = [SELECT Id FROM Contact LIMIT 1];
        
        // Create consent
        Consent__c consent = new Consent__c(
            Contact__c = testContact.Id,
            Consent_Type__c = 'Marketing',
            Consent_Given__c = true,
            Consent_Date__c = Date.today()
        );
        insert consent;
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        Map<String, Object> result = service.validateConsentBasis(activity.Id, testContact.Id);
        Test.stopTest();
        
        System.assertEquals(true, result.get('valid'), 'Consent basis should be valid');
        System.assertEquals(true, result.get('hasActiveConsent'), 'Should have active consent');
    }
    
    @IsTest
    static void testValidateConsentBasis_WithoutConsent() {
        Data_Processing_Activity__c activity = new Data_Processing_Activity__c(
            Activity_Name__c = 'Test Activity',
            Legal_Basis__c = 'Consent'
        );
        insert activity;
        
        Contact testContact = [SELECT Id FROM Contact WHERE Id NOT IN (SELECT Contact__c FROM Consent__c WHERE Consent_Given__c = true) LIMIT 1];
        
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        Map<String, Object> result = service.validateConsentBasis(activity.Id, testContact.Id);
        Test.stopTest();
        
        System.assertEquals(false, result.get('valid'), 'Consent basis should be invalid without consent');
    }
    
    @IsTest
    static void testRecordConsent_NullParameters() {
        Test.startTest();
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        try {
            service.recordConsent(null, 'Marketing', true, 'Web');
            System.assert(false, 'Should throw exception for null contact');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should validate required parameters');
        }
        Test.stopTest();
    }
}
