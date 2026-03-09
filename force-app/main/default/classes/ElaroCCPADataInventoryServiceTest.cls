/**
 * Test class for ElaroCCPADataInventoryService
 * 
 * Tests CCPA Section 1798.100 Right to Know functionality including:
 * - Positive path: Successful inventory report generation
 * - Negative path: Permission denied scenarios
 * - Bulk operations: Multiple contacts
 * - SLA compliance: 45-day deadline
 * - Do Not Sell opt-out processing
 * 
 * Target Coverage: 90%+
 */
@IsTest
private class ElaroCCPADataInventoryServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Test Account',
            BillingCountry = 'US',
            BillingState = 'CA'
        );
        insert testAccount;
        
        // Create test contacts with CCPA fields
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            testContacts.add(new Contact(
                FirstName = 'CCPA',
                LastName = 'Contact ' + i,
                Email = 'ccpa' + i + '@example.com',
                Phone = '555-000' + i,
                MailingStreet = '123 Test St',
                MailingCity = 'San Francisco',
                MailingState = 'CA',
                MailingPostalCode = '94102',
                AccountId = testAccount.Id,
                CCPA_Do_Not_Sell__c = (i == 0), // First contact has opt-out
                CCPA_OptOut_Date__c = (i == 0) ? Date.today() : null
            ));
        }
        insert testContacts;
        
        // Create test CCPA requests
        // Note: Response_Deadline__c may be a formula field, so we set Request_Date__c
        // and let the formula calculate the deadline
        List<CCPA_Request__c> testRequests = new List<CCPA_Request__c>();
        testRequests.add(new CCPA_Request__c(
            Contact__c = testContacts[0].Id,
            Request_Type__c = 'Right to Know',
            Request_Date__c = System.now().addDays(-10),
            Status__c = 'Pending'
            // Response_Deadline__c is likely a formula field (Request_Date__c + 45 days)
        ));
        testRequests.add(new CCPA_Request__c(
            Contact__c = testContacts[1].Id,
            Request_Type__c = 'Right to Know',
            Request_Date__c = System.now().addDays(-50), // Overdue (>45 days)
            Status__c = 'Pending'
            // Response_Deadline__c is likely a formula field
        ));
        insert testRequests;
    }
    
    @IsTest
    static void testGenerateInventoryReport_PositivePath() {
        // Given: Valid contact
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 0' LIMIT 1];
        
        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report = 
            ElaroCCPADataInventoryService.generateInventoryReport(testContact.Id);
        Test.stopTest();
        
        // Then: Report should be generated
        Assert.areNotEqual(null, report, 'Report should be generated');
        Assert.areEqual(testContact.Email, report.dataSubject, 'Should match contact email');
        Assert.areNotEqual(null, report.reportDate, 'Report date should be set');
        Assert.areNotEqual(null, report.responseDeadline, 'Response deadline should be set');
        Assert.areEqual(true, report.doNotSellStatus, 'Should reflect opt-out status');
        Assert.isTrue(!report.categoriesCollected.isEmpty(), 'Should have categories');
        Assert.isTrue(!report.sources.isEmpty(), 'Should have sources');
        Assert.isTrue(!report.businessPurposes.isEmpty(), 'Should have business purposes');
        Assert.areNotEqual(null, report.requestId, 'Request ID should be set');
        
        // Verify audit log created
        List<CCPA_Request__c> auditLogs = [
            SELECT Id, Status__c, Request_Type__c
            FROM CCPA_Request__c
            WHERE Id = :report.requestId
        ];
        Assert.areEqual(1, auditLogs.size(), 'Audit log should exist');
        Assert.areEqual('Completed', auditLogs[0].Status__c, 'Status should be Completed');
    }
    
    @IsTest
    static void testGenerateInventoryReport_ContactNotFound() {
        // Given: Invalid contact ID
        Id invalidContactId = '003000000000000AAA';
        
        Test.startTest();
        try {
            ElaroCCPADataInventoryService.generateInventoryReport(invalidContactId);
            Assert.fail( 'Should have thrown exception');
        } catch (ElaroCCPADataInventoryService.CCPAException e) {
            // Then: Exception should be thrown
            Assert.isTrue(e.getMessage().contains('Contact not found'), 
                'Error message should indicate contact not found');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessDoNotSellRequest_PositivePath() {
        // Given: Contact without opt-out
        Contact testContact = [SELECT Id, CCPA_Do_Not_Sell__c FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        Assert.areEqual(false, testContact.CCPA_Do_Not_Sell__c, 'Should not be opted out initially');
        
        Test.startTest();
        Boolean result = ElaroCCPADataInventoryService.processDoNotSellRequest(testContact.Id);
        Test.stopTest();
        
        // Then: Opt-out should succeed
        Assert.areEqual(true, result, 'Opt-out should succeed');
        
        // Verify contact updated
        Contact updatedContact = [SELECT CCPA_Do_Not_Sell__c, CCPA_OptOut_Date__c FROM Contact WHERE Id = :testContact.Id];
        Assert.areEqual(true, updatedContact.CCPA_Do_Not_Sell__c, 'Should be opted out');
        Assert.areEqual(Date.today(), updatedContact.CCPA_OptOut_Date__c, 'Opt-out date should be set');
        
        // Verify audit log created
        List<CCPA_Request__c> auditLogs = [
            SELECT Id, Request_Type__c, Status__c
            FROM CCPA_Request__c
            WHERE Contact__c = :testContact.Id
            AND Request_Type__c = 'Do Not Sell'
        ];
        Assert.areEqual(1, auditLogs.size(), 'Audit log should exist');
    }
    
    @IsTest
    static void testProcessDoNotSellRequest_InsufficientPermissions() {
        // Given: Limited user without update permissions
        User limitedUser = createLimitedUser();
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                ElaroCCPADataInventoryService.processDoNotSellRequest(testContact.Id);
                Assert.fail( 'Should have thrown InsufficientAccessException');
            } catch (Exception e) {
                // Then: Permission exception should be thrown
                // Note: InsufficientAccessException may not be available, catch generic Exception
                Assert.isTrue(e.getMessage().contains('insufficient') || 
                    e.getMessage().contains('access') || 
                    e.getMessage().contains('permission'), 
                    'Should throw permission-related exception: ' + e.getMessage());
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPendingRequests() {
        // Given: Pending requests exist
        
        Test.startTest();
        List<CCPA_Request__c> requests = 
            ElaroCCPADataInventoryService.getPendingRequests();
        Test.stopTest();
        
        // Then: Should return pending requests
        Assert.isTrue(!requests.isEmpty(), 'Should return pending requests');
        for (CCPA_Request__c req : requests) {
            Assert.isTrue(req.Status__c == 'Pending' || req.Status__c == 'In Progress', 
                'Should only return pending/in progress requests');
        }
    }
    
    @IsTest
    static void testIsRequestOverdue_Overdue() {
        // Given: Overdue request
        CCPA_Request__c overdueRequest = [
            SELECT Id, Status__c, Response_Deadline__c
            FROM CCPA_Request__c
            WHERE Response_Deadline__c < TODAY
            LIMIT 1
        ];
        
        Test.startTest();
        Boolean isOverdue = ElaroCCPADataInventoryService.isRequestOverdue(overdueRequest);
        Test.stopTest();
        
        // Then: Should be overdue
        Assert.areEqual(true, isOverdue, 'Request should be overdue');
    }
    
    @IsTest
    static void testIsRequestOverdue_NotOverdue() {
        // Given: Request with future deadline
        CCPA_Request__c futureRequest = [
            SELECT Id, Status__c, Response_Deadline__c
            FROM CCPA_Request__c
            WHERE Response_Deadline__c >= TODAY
            LIMIT 1
        ];
        
        Test.startTest();
        Boolean isOverdue = ElaroCCPADataInventoryService.isRequestOverdue(futureRequest);
        Test.stopTest();
        
        // Then: Should not be overdue
        Assert.areEqual(false, isOverdue, 'Request should not be overdue');
    }
    
    @IsTest
    static void testIsRequestOverdue_Completed() {
        // Given: Completed request
        CCPA_Request__c completedRequest = [
            SELECT Id, Status__c, Response_Deadline__c
            FROM CCPA_Request__c
            LIMIT 1
        ];
        completedRequest.Status__c = 'Completed';
        update completedRequest;
        
        Test.startTest();
        Boolean isOverdue = ElaroCCPADataInventoryService.isRequestOverdue(completedRequest);
        Test.stopTest();
        
        // Then: Should not be overdue (completed requests are not overdue)
        Assert.areEqual(false, isOverdue, 'Completed request should not be overdue');
    }
    
    @IsTest
    static void testGenerateInventoryReport_BulkOperation() {
        // Given: Multiple contacts
        List<Contact> testContacts = [SELECT Id FROM Contact LIMIT 5];
        
        Test.startTest();
        List<ElaroCCPADataInventoryService.DataInventoryReport> reports = 
            new List<ElaroCCPADataInventoryService.DataInventoryReport>();
        
        for (Contact c : testContacts) {
            ElaroCCPADataInventoryService.DataInventoryReport report = 
                ElaroCCPADataInventoryService.generateInventoryReport(c.Id);
            reports.add(report);
        }
        Test.stopTest();
        
        // Then: All should succeed
        Assert.areEqual(testContacts.size(), reports.size(), 'Should process all contacts');
        for (ElaroCCPADataInventoryService.DataInventoryReport report : reports) {
            Assert.areNotEqual(null, report, 'Each report should be generated');
            Assert.areNotEqual(null, report.requestId, 'Each should have request ID');
        }
    }
    
    @IsTest
    static void testGenerateInventoryReport_PartialData() {
        // Given: Contact with minimal data (tests buildSpecificDataPoints partial branches)
        Contact minimalContact = new Contact(
            LastName = 'MinimalContact',
            Email = 'minimal@test.com'
            // Missing: FirstName, Phone, MailingStreet, etc.
        );
        insert minimalContact;

        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report =
            ElaroCCPADataInventoryService.generateInventoryReport(minimalContact.Id);
        Test.stopTest();

        // Then: Report should still be generated with available data
        Assert.areNotEqual(null, report, 'Report should be generated');
        Assert.areEqual('minimal@test.com', report.dataSubject, 'Should have email');
        Assert.isTrue(report.specificData.containsKey('Email Address'), 'Should have email data point');
        Assert.isTrue(!report.specificData.containsKey('Mailing Address'), 'Should not have mailing address');
    }

    @IsTest
    static void testGenerateInventoryReport_WithRelatedRecords() {
        // Given: Contact with related records (tests getRelatedDataCounts)
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 2' LIMIT 1];

        // Create related records
        List<Task> tasks = new List<Task>();
        for (Integer i = 0; i < 5; i++) {
            tasks.add(new Task(
                Subject = 'CCPA Test Task ' + i,
                WhoId = testContact.Id,
                Status = 'Not Started'
            ));
        }
        insert tasks;

        List<Event> events = new List<Event>();
        for (Integer i = 0; i < 3; i++) {
            events.add(new Event(
                Subject = 'CCPA Test Event ' + i,
                WhoId = testContact.Id,
                StartDateTime = DateTime.now().addDays(i),
                EndDateTime = DateTime.now().addDays(i).addHours(1)
            ));
        }
        insert events;

        Case testCase = new Case(
            Subject = 'CCPA Test Case',
            ContactId = testContact.Id,
            Status = 'New'
        );
        insert testCase;

        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report =
            ElaroCCPADataInventoryService.generateInventoryReport(testContact.Id);
        Test.stopTest();

        // Then: Related data counts should be populated
        Assert.areNotEqual(null, report.relatedDataCounts, 'Should have related data counts');
        Assert.areEqual(5, report.relatedDataCounts.get('Tasks'), 'Should count 5 tasks');
        Assert.areEqual(3, report.relatedDataCounts.get('Events'), 'Should count 3 events');
        Assert.areEqual(1, report.relatedDataCounts.get('Cases'), 'Should count 1 case');
    }

    @IsTest
    static void testGenerateInventoryReport_ThirdPartySharing() {
        // Given: Valid contact (tests getThirdPartySharing private method)
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 3' LIMIT 1];

        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report =
            ElaroCCPADataInventoryService.generateInventoryReport(testContact.Id);
        Test.stopTest();

        // Then: Third parties should be populated
        Assert.areNotEqual(null, report.thirdParties, 'Should have third parties list');
        Assert.isTrue(!report.thirdParties.isEmpty(), 'Third parties should not be empty');
        Assert.isTrue(report.thirdParties.size() >= 3, 'Should have at least 3 third parties');
    }

    @IsTest
    static void testDataInventoryReport_Class() {
        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report =
            new ElaroCCPADataInventoryService.DataInventoryReport();
        report.dataSubject = 'test@example.com';
        report.reportDate = System.now();
        report.responseDeadline = System.now().addDays(45);
        report.doNotSellStatus = true;
        report.categoriesCollected = new List<String>{'Category 1'};
        report.sources = new List<String>{'Source 1'};
        report.businessPurposes = new List<String>{'Purpose 1'};
        report.thirdParties = new List<String>{'Third Party 1'};
        report.specificData = new Map<String, String>{'Key' => 'Value'};
        report.relatedDataCounts = new Map<String, Integer>{'Cases' => 5};
        report.requestId = null;
        Test.stopTest();

        Assert.areEqual('test@example.com', report.dataSubject, 'dataSubject should match');
        Assert.areEqual(true, report.doNotSellStatus, 'doNotSellStatus should match');
        Assert.areEqual(1, report.categoriesCollected.size(), 'Should have 1 category');
        Assert.areEqual(5, report.relatedDataCounts.get('Cases'), 'Should have 5 cases');
    }

    @IsTest
    static void testCCPAException() {
        Test.startTest();
        try {
            throw new ElaroCCPADataInventoryService.CCPAException('Test CCPA error');
        } catch (ElaroCCPADataInventoryService.CCPAException e) {
            Assert.areEqual('Test CCPA error', e.getMessage(),
                'Exception message should match');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetPendingRequests_NoPending() {
        // Given: No pending requests
        List<CCPA_Request__c> existingRequests = [SELECT Id FROM CCPA_Request__c WHERE Status__c IN ('Pending', 'In Progress')];
        for (CCPA_Request__c req : existingRequests) {
            req.Status__c = 'Completed';
        }
        update existingRequests;

        Test.startTest();
        List<CCPA_Request__c> requests =
            ElaroCCPADataInventoryService.getPendingRequests();
        Test.stopTest();

        // Then: Should return empty list
        Assert.areEqual(0, requests.size(), 'Should return empty list');
    }

    @IsTest
    static void testProcessDoNotSellRequest_ContactNotFound() {
        // Given: Invalid contact ID
        Id invalidContactId = '003000000000000AAA';

        Test.startTest();
        try {
            ElaroCCPADataInventoryService.processDoNotSellRequest(invalidContactId);
            Assert.fail( 'Should have thrown exception');
        } catch (ElaroCCPADataInventoryService.CCPAException e) {
            Assert.isTrue(e.getMessage().contains('Contact not found'),
                'Error message should indicate contact not found');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGenerateInventoryReport_FullContactData() {
        // Given: Contact with all data filled in (tests all buildSpecificDataPoints branches)
        Contact fullContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 0' LIMIT 1];

        Test.startTest();
        ElaroCCPADataInventoryService.DataInventoryReport report =
            ElaroCCPADataInventoryService.generateInventoryReport(fullContact.Id);
        Test.stopTest();

        // Then: All data points should be present
        Assert.isTrue(report.specificData.containsKey('Full Name'), 'Should have full name');
        Assert.isTrue(report.specificData.containsKey('Email Address'), 'Should have email');
        Assert.isTrue(report.specificData.containsKey('Phone Number'), 'Should have phone');
        Assert.isTrue(report.specificData.containsKey('Mailing Address'), 'Should have mailing address');
    }

    @IsTest
    static void testIsRequestOverdue_WithRequest_Date() {
        // Given: Request created directly with specific date for testing
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 4' LIMIT 1];

        CCPA_Request__c newRequest = new CCPA_Request__c(
            Contact__c = testContact.Id,
            Request_Type__c = 'Right to Know',
            Request_Date__c = System.now().addDays(-46), // 46 days ago - overdue
            Status__c = 'Pending'
        );
        insert newRequest;

        // Re-query to get formula fields
        CCPA_Request__c queriedRequest = [
            SELECT Id, Status__c, Request_Date__c, Response_Deadline__c
            FROM CCPA_Request__c
            WHERE Id = :newRequest.Id
        ];

        Test.startTest();
        Boolean isOverdue = ElaroCCPADataInventoryService.isRequestOverdue(queriedRequest);
        Test.stopTest();

        // Then: Should be overdue
        Assert.areEqual(true, isOverdue, 'Request older than 45 days should be overdue');
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
