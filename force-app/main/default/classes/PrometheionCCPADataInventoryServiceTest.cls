/**
 * Test class for PrometheionCCPADataInventoryService
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
private class PrometheionCCPADataInventoryServiceTest {
    
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
        List<CCPA_Request__c> testRequests = new List<CCPA_Request__c>();
        testRequests.add(new CCPA_Request__c(
            Contact__c = testContacts[0].Id,
            Request_Type__c = 'Right to Know',
            Request_Date__c = System.now().addDays(-10),
            Status__c = 'Pending',
            Response_Deadline__c = Date.today().addDays(35)
        ));
        testRequests.add(new CCPA_Request__c(
            Contact__c = testContacts[1].Id,
            Request_Type__c = 'Right to Know',
            Request_Date__c = System.now().addDays(-50), // Overdue
            Status__c = 'Pending',
            Response_Deadline__c = Date.today().addDays(-5)
        ));
        insert testRequests;
    }
    
    @IsTest
    static void testGenerateInventoryReport_PositivePath() {
        // Given: Valid contact
        Contact testContact = [SELECT Id, Email FROM Contact WHERE LastName = 'Contact 0' LIMIT 1];
        
        Test.startTest();
        PrometheionCCPADataInventoryService.DataInventoryReport report = 
            PrometheionCCPADataInventoryService.generateInventoryReport(testContact.Id);
        Test.stopTest();
        
        // Then: Report should be generated
        System.assertNotEquals(null, report, 'Report should be generated');
        System.assertEquals(testContact.Email, report.dataSubject, 'Should match contact email');
        System.assertNotEquals(null, report.reportDate, 'Report date should be set');
        System.assertNotEquals(null, report.responseDeadline, 'Response deadline should be set');
        System.assertEquals(true, report.doNotSellStatus, 'Should reflect opt-out status');
        System.assert(report.categoriesCollected.size() > 0, 'Should have categories');
        System.assert(report.sources.size() > 0, 'Should have sources');
        System.assert(report.businessPurposes.size() > 0, 'Should have business purposes');
        System.assertNotEquals(null, report.requestId, 'Request ID should be set');
        
        // Verify audit log created
        List<CCPA_Request__c> auditLogs = [
            SELECT Id, Status__c, Request_Type__c
            FROM CCPA_Request__c
            WHERE Id = :report.requestId
        ];
        System.assertEquals(1, auditLogs.size(), 'Audit log should exist');
        System.assertEquals('Completed', auditLogs[0].Status__c, 'Status should be Completed');
    }
    
    @IsTest
    static void testGenerateInventoryReport_ContactNotFound() {
        // Given: Invalid contact ID
        Id invalidContactId = '003000000000000AAA';
        
        Test.startTest();
        try {
            PrometheionCCPADataInventoryService.generateInventoryReport(invalidContactId);
            System.assert(false, 'Should have thrown exception');
        } catch (PrometheionCCPADataInventoryService.CCPAException e) {
            // Then: Exception should be thrown
            System.assert(e.getMessage().contains('Contact not found'), 
                'Error message should indicate contact not found');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testProcessDoNotSellRequest_PositivePath() {
        // Given: Contact without opt-out
        Contact testContact = [SELECT Id, CCPA_Do_Not_Sell__c FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        System.assertEquals(false, testContact.CCPA_Do_Not_Sell__c, 'Should not be opted out initially');
        
        Test.startTest();
        Boolean result = PrometheionCCPADataInventoryService.processDoNotSellRequest(testContact.Id);
        Test.stopTest();
        
        // Then: Opt-out should succeed
        System.assertEquals(true, result, 'Opt-out should succeed');
        
        // Verify contact updated
        Contact updatedContact = [SELECT CCPA_Do_Not_Sell__c, CCPA_OptOut_Date__c FROM Contact WHERE Id = :testContact.Id];
        System.assertEquals(true, updatedContact.CCPA_Do_Not_Sell__c, 'Should be opted out');
        System.assertEquals(Date.today(), updatedContact.CCPA_OptOut_Date__c, 'Opt-out date should be set');
        
        // Verify audit log created
        List<CCPA_Request__c> auditLogs = [
            SELECT Id, Request_Type__c, Status__c
            FROM CCPA_Request__c
            WHERE Contact__c = :testContact.Id
            AND Request_Type__c = 'Do Not Sell'
        ];
        System.assertEquals(1, auditLogs.size(), 'Audit log should exist');
    }
    
    @IsTest
    static void testProcessDoNotSellRequest_InsufficientPermissions() {
        // Given: Limited user without update permissions
        User limitedUser = createLimitedUser();
        Contact testContact = [SELECT Id FROM Contact WHERE LastName = 'Contact 1' LIMIT 1];
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                PrometheionCCPADataInventoryService.processDoNotSellRequest(testContact.Id);
                System.assert(false, 'Should have thrown InsufficientAccessException');
            } catch (System.InsufficientAccessException e) {
                // Then: Permission exception should be thrown
                System.assert(true, 'InsufficientAccessException expected');
            }
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGetPendingRequests() {
        // Given: Pending requests exist
        
        Test.startTest();
        List<CCPA_Request__c> requests = 
            PrometheionCCPADataInventoryService.getPendingRequests();
        Test.stopTest();
        
        // Then: Should return pending requests
        System.assert(requests.size() > 0, 'Should return pending requests');
        for (CCPA_Request__c req : requests) {
            System.assert(req.Status__c == 'Pending' || req.Status__c == 'In Progress', 
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
        Boolean isOverdue = PrometheionCCPADataInventoryService.isRequestOverdue(overdueRequest);
        Test.stopTest();
        
        // Then: Should be overdue
        System.assertEquals(true, isOverdue, 'Request should be overdue');
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
        Boolean isOverdue = PrometheionCCPADataInventoryService.isRequestOverdue(futureRequest);
        Test.stopTest();
        
        // Then: Should not be overdue
        System.assertEquals(false, isOverdue, 'Request should not be overdue');
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
        Boolean isOverdue = PrometheionCCPADataInventoryService.isRequestOverdue(completedRequest);
        Test.stopTest();
        
        // Then: Should not be overdue (completed requests are not overdue)
        System.assertEquals(false, isOverdue, 'Completed request should not be overdue');
    }
    
    @IsTest
    static void testGenerateInventoryReport_BulkOperation() {
        // Given: Multiple contacts
        List<Contact> testContacts = [SELECT Id FROM Contact LIMIT 5];
        
        Test.startTest();
        List<PrometheionCCPADataInventoryService.DataInventoryReport> reports = 
            new List<PrometheionCCPADataInventoryService.DataInventoryReport>();
        
        for (Contact c : testContacts) {
            PrometheionCCPADataInventoryService.DataInventoryReport report = 
                PrometheionCCPADataInventoryService.generateInventoryReport(c.Id);
            reports.add(report);
        }
        Test.stopTest();
        
        // Then: All should succeed
        System.assertEquals(testContacts.size(), reports.size(), 'Should process all contacts');
        for (PrometheionCCPADataInventoryService.DataInventoryReport report : reports) {
            System.assertNotEquals(null, report, 'Each report should be generated');
            System.assertNotEquals(null, report.requestId, 'Each should have request ID');
        }
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
