/**
 * Test class for ElaroGDPRDataErasureService
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
private class ElaroGDPRDataErasureServiceTest {
    
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
        ElaroGDPRDataErasureService.ErasureResult result = 
            ElaroGDPRDataErasureService.processErasureRequest(
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
            ElaroGDPRDataErasureService.processErasureRequest(
                invalidContactId,
                'Test reason'
            );
            System.assert(false, 'Should have thrown exception');
        } catch (ElaroGDPRDataErasureService.GDPRException e) {
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
        ElaroGDPRDataErasureService.ValidationResult result = 
            ElaroGDPRDataErasureService.validateForErasure(testContact.Id);
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
        ElaroGDPRDataErasureService.ValidationResult result = 
            ElaroGDPRDataErasureService.validateForErasure(testContact.Id);
        Test.stopTest();
        
        // Then: Should not be able to erase
        System.assertEquals(false, result.canErase, 'Should not be able to erase');
        System.assert(!result.blockers.isEmpty(), 'Blockers should exist');
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
                ElaroGDPRDataErasureService.processErasureRequest(
                    testContact.Id,
                    'Test reason'
                );
                System.assert(false, 'Should have thrown InsufficientAccessException');
            } catch (Exception e) {
                // Then: Permission exception should be thrown
                // Note: InsufficientAccessException may not be available, catch generic Exception
                System.assert(e.getMessage().contains('insufficient') || 
                    e.getMessage().contains('access') || 
                    e.getMessage().contains('permission'), 
                    'Should throw permission-related exception: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetRecentErasureRequests() {
        // Given: Existing erasure requests
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        ElaroGDPRDataErasureService.processErasureRequest(
            testContact.Id,
            'Test request'
        );
        
        Test.startTest();
        List<GDPR_Erasure_Request__c> requests = 
            ElaroGDPRDataErasureService.getRecentErasureRequests(10);
        Test.stopTest();
        
        // Then: Should return requests
        System.assert(!requests.isEmpty(), 'Should return at least one request');
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
        List<ElaroGDPRDataErasureService.ErasureResult> results = 
            new List<ElaroGDPRDataErasureService.ErasureResult>();
        
        for (Contact c : bulkContacts) {
            ElaroGDPRDataErasureService.ErasureResult result = 
                ElaroGDPRDataErasureService.processErasureRequest(
                    c.Id,
                    'Bulk erasure test'
                );
            results.add(result);
        }
        Test.stopTest();
        
        // Then: All should succeed
        System.assertEquals(200, results.size(), 'Should process all contacts');
        for (ElaroGDPRDataErasureService.ErasureResult result : results) {
            System.assertEquals(true, result.success, 'Each erasure should succeed');
        }
        
        // Verify all contacts deleted
        List<Contact> remainingContacts = [
            SELECT Id FROM Contact WHERE Id IN :bulkContacts
        ];
        System.assertEquals(0, remainingContacts.size(), 'All contacts should be deleted');
    }
    
    @IsTest
    static void testGetErasureStatus_Success() {
        // Given: Existing erasure request
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        ElaroGDPRDataErasureService.ErasureResult erasureResult =
            ElaroGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                'Test request'
            );

        Test.startTest();
        GDPR_Erasure_Request__c request =
            ElaroGDPRDataErasureService.getErasureStatus(erasureResult.auditLogId);
        Test.stopTest();

        // Then: Should return request with all fields
        System.assertNotEquals(null, request, 'Request should be returned');
        System.assertEquals('Completed', request.Status__c, 'Status should be Completed');
        System.assertNotEquals(null, request.Request_Date__c, 'Request date should be set');
        System.assertNotEquals(null, request.Completion_Date__c, 'Completion date should be set');
    }

    @IsTest
    static void testGetErasureStatus_NotFound() {
        // Given: Invalid ID - use a fake ID that looks valid
        GDPR_Erasure_Request__c tempRecord = new GDPR_Erasure_Request__c(
            Contact_Email__c = 'temp@test.com',
            Status__c = 'In Progress'
        );
        insert tempRecord;
        Id validId = tempRecord.Id;
        delete tempRecord;

        Test.startTest();
        GDPR_Erasure_Request__c request =
            ElaroGDPRDataErasureService.getErasureStatus(validId);
        Test.stopTest();

        // Then: Should return null
        System.assertEquals(null, request, 'Should return null for deleted ID');
    }

    @IsTest
    static void testProcessErasureRequest_CascadeDeletion() {
        // Given: Contact with related records
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 3' LIMIT 1];

        // Create related records
        Task testTask = new Task(
            Subject = 'Test Task',
            WhoId = testContact.Id,
            Status = 'Not Started'
        );
        insert testTask;

        Event testEvent = new Event(
            Subject = 'Test Event',
            WhoId = testContact.Id,
            StartDateTime = DateTime.now(),
            EndDateTime = DateTime.now().addHours(1)
        );
        insert testEvent;

        Test.startTest();
        ElaroGDPRDataErasureService.ErasureResult result =
            ElaroGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                'Cascade deletion test'
            );
        Test.stopTest();

        // Then: All related records should be deleted
        System.assertEquals(true, result.success, 'Erasure should succeed');

        List<Task> remainingTasks = [SELECT Id FROM Task WHERE Id = :testTask.Id];
        System.assertEquals(0, remainingTasks.size(), 'Task should be deleted');

        List<Event> remainingEvents = [SELECT Id FROM Event WHERE Id = :testEvent.Id];
        System.assertEquals(0, remainingEvents.size(), 'Event should be deleted');

        // Verify audit log has correct count
        GDPR_Erasure_Request__c auditLog = [
            SELECT Records_Deleted__c
            FROM GDPR_Erasure_Request__c
            WHERE Id = :result.auditLogId
        ];
        System.assert(auditLog.Records_Deleted__c >= 3,
            'Should count contact + task + event as deleted');
    }

    @IsTest
    static void testErasureResult_Class() {
        Test.startTest();
        ElaroGDPRDataErasureService.ErasureResult result =
            new ElaroGDPRDataErasureService.ErasureResult(
                true,
                null,
                'Test message'
            );
        Test.stopTest();

        System.assertEquals(true, result.success, 'Success should match');
        System.assertEquals(null, result.auditLogId, 'AuditLogId should be null');
        System.assertEquals('Test message', result.message, 'Message should match');
    }

    @IsTest
    static void testValidationResult_Class() {
        Test.startTest();
        ElaroGDPRDataErasureService.ValidationResult result =
            new ElaroGDPRDataErasureService.ValidationResult();
        result.canErase = false;
        result.blockers = new List<String>{'Blocker 1', 'Blocker 2'};
        Test.stopTest();

        System.assertEquals(false, result.canErase, 'CanErase should be false');
        System.assertEquals(2, result.blockers.size(), 'Should have 2 blockers');
    }

    @IsTest
    static void testProcessErasureRequest_WithConsents() {
        // Given: Contact with consent records
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 4' LIMIT 1];

        Consent__c consent = new Consent__c(
            Contact__c = testContact.Id,
            Consent_Type__c = 'Marketing',
            Status__c = 'Active'
        );
        insert consent;

        Test.startTest();
        ElaroGDPRDataErasureService.ErasureResult result =
            ElaroGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                'Consent deletion test'
            );
        Test.stopTest();

        // Then: Consent should be deleted
        System.assertEquals(true, result.success, 'Erasure should succeed');

        List<Consent__c> remainingConsents = [SELECT Id FROM Consent__c WHERE Id = :consent.Id];
        System.assertEquals(0, remainingConsents.size(), 'Consent should be deleted');
    }

    @IsTest
    static void testGetRecentErasureRequests_EmptyList() {
        // Given: No erasure requests exist yet (delete any from setup)
        delete [SELECT Id FROM GDPR_Erasure_Request__c];

        Test.startTest();
        List<GDPR_Erasure_Request__c> requests =
            ElaroGDPRDataErasureService.getRecentErasureRequests(10);
        Test.stopTest();

        // Then: Should return empty list
        System.assertEquals(0, requests.size(), 'Should return empty list');
    }

    @IsTest
    static void testGetRecentErasureRequests_LimitEnforced() {
        // Given: Multiple erasure requests
        List<Contact> contacts = [SELECT Id FROM Contact WHERE LastName LIKE 'Contact%' LIMIT 3];

        for (Contact c : contacts) {
            ElaroGDPRDataErasureService.processErasureRequest(
                c.Id,
                'Limit test'
            );
        }

        Test.startTest();
        List<GDPR_Erasure_Request__c> requests =
            ElaroGDPRDataErasureService.getRecentErasureRequests(2);
        Test.stopTest();

        // Then: Should respect limit
        System.assertEquals(2, requests.size(), 'Should return only 2 requests');
    }

    @IsTest
    static void testProcessErasureRequest_AuditLogFields() {
        // Given: Contact to erase
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];
        String testReason = 'Subject requested data deletion';

        Test.startTest();
        ElaroGDPRDataErasureService.ErasureResult result =
            ElaroGDPRDataErasureService.processErasureRequest(
                testContact.Id,
                testReason
            );
        Test.stopTest();

        // Then: Audit log should have all fields populated
        GDPR_Erasure_Request__c auditLog = [
            SELECT Contact_Email__c, Contact_Id__c, Request_Reason__c,
                   Status__c, Requested_By__c, Records_Deleted__c
            FROM GDPR_Erasure_Request__c
            WHERE Id = :result.auditLogId
        ];

        System.assertEquals(testContact.Email, auditLog.Contact_Email__c, 'Email should match');
        System.assertEquals(String.valueOf(testContact.Id), auditLog.Contact_Id__c, 'Contact ID should match');
        System.assertEquals(testReason, auditLog.Request_Reason__c, 'Reason should match');
        System.assertEquals('Completed', auditLog.Status__c, 'Status should be Completed');
        System.assertEquals(UserInfo.getUserId(), auditLog.Requested_By__c, 'Requested by should match current user');
        System.assert(auditLog.Records_Deleted__c >= 1, 'At least one record should be deleted');
    }

    @IsTest
    static void testGDPRException() {
        Test.startTest();
        try {
            throw new ElaroGDPRDataErasureService.GDPRException('Test GDPR error');
        } catch (ElaroGDPRDataErasureService.GDPRException e) {
            System.assertEquals('Test GDPR error', e.getMessage(),
                'Exception message should match');
        }
        Test.stopTest();
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
