/**
 * Test class for PrometheionGDPRDataErasureService
 * 
 * Tests GDPR Article 17 Right to Erasure functionality including:
 * - Positive path: Successful erasure with audit trail
 * - Negative path: Permission denied scenarios
 * - Bulk operations: 200+ records
 * - Validation: Blockers preventing erasure
 * - Edge cases: Missing contacts, dependencies
 * 
 * Target Coverage: 90%+
 */
@IsTest
private class PrometheionGDPRDataErasureServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCountry = 'US'
        );
        insert testAccount;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            testContacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'test' + i + '@example.com',
                AccountId = testAccount.Id
            ));
        }
        insert testContacts;
        
        // Create test cases for some contacts (to test blockers)
        List<Case> testCases = new List<Case>();
        testCases.add(new Case(
            Subject = 'Open Case',
            Status = 'New',
            ContactId = testContacts[0].Id
        ));
        testCases.add(new Case(
            Subject = 'Closed Case',
            Status = 'Closed',
            ContactId = testContacts[1].Id
        ));
        insert testCases;
        
        // Create test opportunities for some contacts
        List<Opportunity> testOpps = new List<Opportunity>();
        testOpps.add(new Opportunity(
            Name = 'Open Opp',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30),
            AccountId = testAccount.Id
        ));
        insert testOpps;
        
        // Link opportunity to contact via ContactRole (if custom field exists)
        // Otherwise, we'll test with Account-based opportunities
    }
    
    @IsTest
    static void testProcessErasureRequest_PositivePath() {
        // Given: Valid contact with no blockers
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        
        Test.startTest();
        PrometheionGDPRDataErasureService.ErasureResult result = 
            PrometheionGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                'Data subject request'
            );
        Test.stopTest();
        
        // Then: Erasure should succeed
        System.assert(result.success, 'Erasure should succeed');
        System.assertNotEquals(null, result.auditLogId, 'Audit log should be created');
        System.assertNotEquals(null, result.message, 'Message should be provided');
        
        // Verify contact is deleted
        List<Contact> deletedContacts = [
            SELECT Id FROM Contact WHERE Id = :testContact.Id
        ];
        System.assertEquals(0, deletedContacts.size(), 'Contact should be deleted');
        
        // Verify audit log exists
        List<GDPR_Erasure_Request__c> auditLogs = [
            SELECT Id, Status__c, Contact_Email__c
            FROM GDPR_Erasure_Request__c
            WHERE Id = :result.auditLogId
        ];
        System.assertEquals(1, auditLogs.size(), 'Audit log should exist');
        System.assertEquals('Completed', auditLogs[0].Status__c, 'Status should be Completed');
    }
    
    @IsTest
    static void testProcessErasureRequest_ContactNotFound() {
        // Given: Invalid contact ID
        Id invalidContactId = '003000000000000AAA';
        
        Test.startTest();
        try {
            PrometheionGDPRDataErasureService.processErasureRequest(
                invalidContactId,
                'Test reason'
            );
            System.assert(false, 'Should have thrown exception');
        } catch (PrometheionGDPRDataErasureService.GDPRException e) {
            // Then: Exception should be thrown
            System.assert(e.getMessage().contains('Contact not found'), 
                'Error message should indicate contact not found');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testValidateForErasure_NoBlockers() {
        // Given: Contact with no open cases or opportunities
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        
        Test.startTest();
        PrometheionGDPRDataErasureService.ValidationResult result = 
            PrometheionGDPRDataErasureService.validateForErasure(testContact.Id);
        Test.stopTest();
        
        // Then: Should be able to erase
        System.assertEquals(true, result.canErase, 'Should be able to erase');
        System.assertEquals(0, result.blockers.size(), 'No blockers should exist');
    }
    
    @IsTest
    static void testValidateForErasure_WithBlockers() {
        // Given: Contact with open case
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 0' LIMIT 1];
        
        Test.startTest();
        PrometheionGDPRDataErasureService.ValidationResult result = 
            PrometheionGDPRDataErasureService.validateForErasure(testContact.Id);
        Test.stopTest();
        
        // Then: Should not be able to erase
        System.assertEquals(false, result.canErase, 'Should not be able to erase');
        System.assert(result.blockers.size() > 0, 'Blockers should exist');
        System.assert(result.blockers[0].contains('open case'), 
            'Blocker should mention open case');
    }
    
    @IsTest
    static void testProcessErasureRequest_InsufficientPermissions() {
        // Given: Limited user without delete permissions
        User limitedUser = createLimitedUser();
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                PrometheionGDPRDataErasureService.processErasureRequest(
                    testContact.Id,
                    'Test reason'
                );
                System.assert(false, 'Should have thrown InsufficientAccessException');
            } catch (System.InsufficientAccessException e) {
                // Then: Permission exception should be thrown
                System.assert(true, 'InsufficientAccessException expected');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetRecentErasureRequests() {
        // Given: Existing erasure requests
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        PrometheionGDPRDataErasureService.processErasureRequest(
            testContact.Id,
            'Test request'
        );
        
        Test.startTest();
        List<GDPR_Erasure_Request__c> requests = 
            PrometheionGDPRDataErasureService.getRecentErasureRequests(10);
        Test.stopTest();
        
        // Then: Should return requests
        System.assert(requests.size() > 0, 'Should return at least one request');
        System.assertEquals(testContact.Email, requests[0].Contact_Email__c, 
            'Should match contact email');
    }
    
    @IsTest
    static void testProcessErasureRequest_BulkOperation() {
        // Given: 200+ contacts
        List<Contact> bulkContacts = new List<Contact>();
        Account bulkAccount = new Account(Name = 'Bulk Account');
        insert bulkAccount;
        
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Contact ' + i,
                Email = 'bulk' + i + '@example.com',
                AccountId = bulkAccount.Id
            ));
        }
        insert bulkContacts;
        
        Test.startTest();
        List<PrometheionGDPRDataErasureService.ErasureResult> results = 
            new List<PrometheionGDPRDataErasureService.ErasureResult>();
        
        for (Contact c : bulkContacts) {
            PrometheionGDPRDataErasureService.ErasureResult result = 
                PrometheionGDPRDataErasureService.processErasureRequest(
                    c.Id,
                    'Bulk erasure test'
                );
            results.add(result);
        }
        Test.stopTest();
        
        // Then: All should succeed
        System.assertEquals(200, results.size(), 'Should process all contacts');
        for (PrometheionGDPRDataErasureService.ErasureResult result : results) {
            System.assertEquals(true, result.success, 'Each erasure should succeed');
        }
        
        // Verify all contacts deleted
        List<Contact> remainingContacts = [
            SELECT Id FROM Contact WHERE Id IN :bulkContacts
        ];
        System.assertEquals(0, remainingContacts.size(), 'All contacts should be deleted');
    }
    
    @IsTest
    static void testGetErasureRequestById() {
        // Given: Existing erasure request
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        PrometheionGDPRDataErasureService.ErasureResult erasureResult = 
            PrometheionGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                'Test request'
            );
        
        Test.startTest();
        GDPR_Erasure_Request__c request = 
            PrometheionGDPRDataErasureService.getErasureRequestById(erasureResult.auditLogId);
        Test.stopTest();
        
        // Then: Should return request
        System.assertNotEquals(null, request, 'Request should be returned');
        System.assertEquals(testContact.Email, request.Contact_Email__c, 
            'Should match contact email');
    }
    
    @IsTest
    static void testGetErasureRequestById_NotFound() {
        // Given: Invalid ID
        Id invalidId = 'a0000000000000AAA';
        
        Test.startTest();
        GDPR_Erasure_Request__c request = 
            PrometheionGDPRDataErasureService.getErasureRequestById(invalidId);
        Test.stopTest();
        
        // Then: Should return null
        System.assertEquals(null, request, 'Should return null for invalid ID');
    }
    
    // Helper method to create limited user for permission testing
    private static User createLimitedUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User limitedUser = new User(
            FirstName = 'Limited',
            LastName = 'User',
            Email = 'limited@test.com',
            Username = 'limited@test' + System.now().getTime() + '.com',
            Alias = 'limuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert limitedUser;
        return limitedUser;
    }
}
