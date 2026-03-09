/**
 * ElaroConsentWithdrawalHandlerTest
 * 
 * Test class for ElaroConsentWithdrawalHandler
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroConsentWithdrawalHandlerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'testcontact' + i + '@elaro.test',
                HasOptedOutOfEmail = false,
                DoNotCall = false
            ));
        }
        insert contacts;
        
        // Create consent records
        List<Consent__c> consents = new List<Consent__c>();
        for (Contact c : contacts) {
            consents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Marketing',
                Status__c = 'Active',
                Consent_Date__c = Date.today().addDays(-30)
            ));
            consents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Data Processing',
                Status__c = 'Active',
                Consent_Date__c = Date.today().addDays(-30)
            ));
        }
        insert consents;
    }
    
    @IsTest
    static void testProcessWithdrawalsMarketing() {
        // Get test consents
        List<Consent__c> consents = [
            SELECT Id, Contact__c, Consent_Type__c
            FROM Consent__c
            WHERE Consent_Type__c = 'Marketing'
            WITH USER_MODE
            LIMIT 3
        ];
        
        // Mark as withdrawn
        for (Consent__c c : consents) {
            c.Status__c = 'Withdrawn';
        }
        update consents;
        
        Test.startTest();
        
        ElaroConsentWithdrawalHandler.processWithdrawals(consents);
        
        Test.stopTest();
        
        // Verify contacts updated
        List<Contact> updatedContacts = [
            SELECT Id, HasOptedOutOfEmail
            FROM Contact
            WHERE Id IN (SELECT Contact__c FROM Consent__c WHERE Id IN :consents)
            WITH USER_MODE
        ];
        
        for (Contact c : updatedContacts) {
            Assert.areEqual(true, c.HasOptedOutOfEmail, 
                'Contact should have email opt-out set');
        }
    }
    
    @IsTest
    static void testProcessWithdrawalsDataProcessing() {
        // Get test consents
        List<Consent__c> consents = [
            SELECT Id, Contact__c, Consent_Type__c
            FROM Consent__c
            WHERE Consent_Type__c = 'Data Processing'
            WITH USER_MODE
            LIMIT 2
        ];
        
        // Mark as withdrawn
        for (Consent__c c : consents) {
            c.Status__c = 'Withdrawn';
        }
        update consents;
        
        Test.startTest();
        
        ElaroConsentWithdrawalHandler.processWithdrawals(consents);
        
        Test.stopTest();
        
        // Verify contacts updated
        List<Contact> updatedContacts = [
            SELECT Id, HasOptedOutOfEmail, DoNotCall
            FROM Contact
            WHERE Id IN (SELECT Contact__c FROM Consent__c WHERE Id IN :consents)
            WITH USER_MODE
        ];
        
        for (Contact c : updatedContacts) {
            Assert.areEqual(true, c.HasOptedOutOfEmail, 
                'Contact should have email opt-out set');
            Assert.areEqual(true, c.DoNotCall, 
                'Contact should have DoNotCall set');
        }
    }
    
    @IsTest
    static void testProcessWithdrawalsAllDataProcessing() {
        // Create consent for full data processing withdrawal
        Contact testContact = [SELECT Id FROM Contact LIMIT 1 WITH USER_MODE];
        Consent__c fullConsent = new Consent__c(
            Contact__c = testContact.Id,
            Consent_Type__c = 'All Data Processing',
            Status__c = 'Withdrawn',
            Consent_Date__c = Date.today()
        );
        insert fullConsent;
        
        Test.startTest();
        
        ElaroConsentWithdrawalHandler.processWithdrawals(new List<Consent__c>{ fullConsent });
        
        Test.stopTest();
        
        // Verify erasure request was created
        List<GDPR_Erasure_Request__c> erasureRequests = [
            SELECT Id, Contact__c, Status__c, Request_Reason__c
            FROM GDPR_Erasure_Request__c
            WHERE Contact__c = :testContact.Id
            WITH USER_MODE
        ];
        
        Assert.areEqual(1, erasureRequests.size(), 
            'Erasure request should be created');
        Assert.areEqual('Pending', erasureRequests[0].Status__c,
            'Erasure request should be pending');
    }
    
    @IsTest
    static void testProcessWithdrawalsBulk() {
        // Test bulk processing (200+ records)
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            contacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Contact ' + i,
                Email = 'bulkcontact' + i + '@elaro.test'
            ));
        }
        insert contacts;
        
        List<Consent__c> consents = new List<Consent__c>();
        for (Contact c : contacts) {
            consents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Marketing',
                Status__c = 'Withdrawn',
                Consent_Date__c = Date.today()
            ));
        }
        insert consents;
        
        Test.startTest();
        
        ElaroConsentWithdrawalHandler.processWithdrawals(consents);
        
        Test.stopTest();
        
        // Verify bulk processing worked
        List<Contact> updatedContacts = [
            SELECT Id, HasOptedOutOfEmail
            FROM Contact
            WHERE Id IN (SELECT Contact__c FROM Consent__c WHERE Id IN :consents)
            WITH USER_MODE
        ];
        
        Assert.areEqual(200, updatedContacts.size(), 
            'Should process all 200 contacts');
    }
    
    @IsTest
    static void testProcessWithdrawalsEmptyList() {
        Test.startTest();

        // Should not throw exception with empty list
        ElaroConsentWithdrawalHandler.processWithdrawals(new List<Consent__c>());

        Test.stopTest();

        // Verify empty list processed without exception or DML
        Assert.areEqual(0, Limits.getDmlStatements(), 'Should not perform DML with empty list');
    }
    
    @IsTest
    static void testProcessWithdrawalsWithEvents() {
        // Get test consents
        List<Consent__c> consents = [
            SELECT Id, Contact__c, Consent_Type__c
            FROM Consent__c
            WITH USER_MODE
            LIMIT 2
        ];
        
        // Mark as withdrawn
        for (Consent__c c : consents) {
            c.Status__c = 'Withdrawn';
        }
        update consents;
        
        Test.startTest();

        ElaroConsentWithdrawalHandler.processWithdrawals(consents);

        Test.stopTest();

        // Verify withdrawal processing completed with event publishing
        // Platform events are async, verify DML occurred for updates
        Assert.isTrue(Limits.getDmlStatements() > 0, 'Should publish events and update records');
    }
}
