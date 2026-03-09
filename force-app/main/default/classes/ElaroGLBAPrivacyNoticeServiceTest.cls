/**
 * Test class for ElaroGLBAPrivacyNoticeService
 * 
 * Tests GLBA Privacy Rule compliance including:
 * - Positive path: Initial and annual notice sending
 * - Negative path: Permission denied scenarios
 * - Bulk operations: Multiple contacts
 * - Opt-out processing
 * - Revised notice handling
 * 
 * Target Coverage: 90%+
 */
@IsTest
private class ElaroGLBAPrivacyNoticeServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test account
        Account testAccount = new Account(
            Name = 'Financial Institution',
            BillingCountry = 'US',
            Industry = 'Banking'
        );
        insert testAccount;
        
        // Create test contacts
        List<Contact> testContacts = new List<Contact>();
        for (Integer i = 0; i < 5; i++) {
            testContacts.add(new Contact(
                FirstName = 'GLBA',
                LastName = 'Customer ' + i,
                Email = 'glba' + i + '@example.com',
                AccountId = testAccount.Id
            ));
        }
        insert testContacts;
        
        // Create existing privacy notices for some contacts
        List<Privacy_Notice__c> existingNotices = new List<Privacy_Notice__c>();
        existingNotices.add(new Privacy_Notice__c(
            Contact__c = testContacts[0].Id,
            Account__c = testAccount.Id,
            Notice_Type__c = 'Initial',
            Sent_Date__c = System.now().addDays(-400), // Past due for annual
            Next_Annual_Notice_Due__c = Date.today().addDays(-35),
            Notice_Version__c = '1.0'
        ));
        existingNotices.add(new Privacy_Notice__c(
            Contact__c = testContacts[1].Id,
            Account__c = testAccount.Id,
            Notice_Type__c = 'Annual',
            Sent_Date__c = System.now().addDays(-200),
            Next_Annual_Notice_Due__c = Date.today().addDays(165), // Not due yet
            Notice_Version__c = '1.0'
        ));
        insert existingNotices;
    }
    
    @IsTest
    static void testSendInitialNotice_PositivePath() {
        // Given: New contact without notice
        Contact testContact = [SELECT Id, AccountId, Email FROM Contact WHERE LastName = 'Customer 2' LIMIT 1];
        
        Test.startTest();
        Privacy_Notice__c notice = ElaroGLBAPrivacyNoticeService.sendInitialNotice(
            testContact.Id,
            testContact.AccountId,
            'Email'
        );
        Test.stopTest();
        
        // Then: Notice should be created
        Assert.areNotEqual(null, notice.Id, 'Notice should be created');
        Assert.areEqual('Initial', notice.Notice_Type__c, 'Should be initial notice');
        Assert.areEqual('Sent', notice.Delivery_Status__c, 'Status should be Sent');
        Assert.areNotEqual(null, notice.Opt_Out_Deadline__c, 'Opt-out deadline should be set');
        Assert.areNotEqual(null, notice.Next_Annual_Notice_Due__c, 'Next annual notice should be set');
        
        // Verify notice in database
        List<Privacy_Notice__c> notices = [
            SELECT Id, Notice_Type__c, Delivery_Status__c
            FROM Privacy_Notice__c
            WHERE Id = :notice.Id
        ];
        Assert.areEqual(1, notices.size(), 'Notice should exist in database');
    }
    
    @IsTest
    static void testSendAnnualNotices() {
        // Given: Contacts due for annual notice
        
        Test.startTest();
        List<Privacy_Notice__c> notices = ElaroGLBAPrivacyNoticeService.sendAnnualNotices();
        Test.stopTest();
        
        // Then: Annual notices should be created
        Assert.isTrue(!notices.isEmpty(), 'Should create annual notices');
        for (Privacy_Notice__c notice : notices) {
            Assert.areEqual('Annual', notice.Notice_Type__c, 'Should be annual notice');
            Assert.areEqual('Pending', notice.Delivery_Status__c, 'Status should be Pending');
        }
    }
    
    @IsTest
    static void testSendRevisedNotices() {
        // Given: Set of contacts
        List<Contact> testContacts = [SELECT Id, AccountId FROM Contact LIMIT 3];
        Set<Id> contactIds = new Set<Id>();
        for (Contact c : testContacts) {
            contactIds.add(c.Id);
        }
        
        Test.startTest();
        List<Privacy_Notice__c> notices = ElaroGLBAPrivacyNoticeService.sendRevisedNotices(
            contactIds,
            'Privacy policy updated to reflect new data sharing practices'
        );
        Test.stopTest();
        
        // Then: Revised notices should be created
        Assert.areEqual(3, notices.size(), 'Should create revised notices for all contacts');
        for (Privacy_Notice__c notice : notices) {
            Assert.areEqual('Revised', notice.Notice_Type__c, 'Should be revised notice');
        }
    }
    
    @IsTest
    static void testProcessOptOut() {
        // Given: Privacy notice
        Privacy_Notice__c notice = [
            SELECT Id, Contact__c, Opt_Out_Deadline__c
            FROM Privacy_Notice__c
            WHERE Notice_Type__c = 'Initial'
            LIMIT 1
        ];
        List<String> optOutCategories = new List<String>{'Marketing', 'Third-Party Sharing'};
        
        Test.startTest();
        ElaroGLBAPrivacyNoticeService.processOptOut(notice.Id, optOutCategories);
        Test.stopTest();
        
        // Then: Notice should be updated
        Privacy_Notice__c updatedNotice = [
            SELECT Id, Customer_Opted_Out__c, Opt_Out_Date__c
            FROM Privacy_Notice__c
            WHERE Id = :notice.Id
        ];
        Assert.areEqual(true, updatedNotice.Customer_Opted_Out__c, 'Should be opted out');
        Assert.areNotEqual(null, updatedNotice.Opt_Out_Date__c, 'Opt-out date should be set');
    }
    
    @IsTest
    static void testSendInitialNotice_InsufficientPermissions() {
        // Given: Limited user
        User limitedUser = createLimitedUser();
        Contact testContact = [SELECT Id, AccountId FROM Contact WHERE LastName = 'Customer 2' LIMIT 1];
        
        Test.startTest();
        System.runAs(limitedUser) {
            try {
                ElaroGLBAPrivacyNoticeService.sendInitialNotice(
                    testContact.Id,
                    testContact.AccountId,
                    'Email'
                );
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
    static void testGetComplianceMetrics() {
        // Given: Existing notices
        
        Test.startTest();
        Map<String, Object> metrics = ElaroGLBAPrivacyNoticeService.getComplianceMetrics();
        Test.stopTest();
        
        // Then: Metrics should be returned
        Assert.areNotEqual(null, metrics, 'Metrics should be returned');
        Assert.isTrue(metrics.containsKey('totalNoticesThisYear'), 'Should have total notices metric');
    }
    
    @IsTest
    static void testSendAnnualNotices_BulkOperation() {
        // Given: Many contacts due for annual notice
        Account bulkAccount = new Account(Name = 'Bulk Account');
        insert bulkAccount;
        
        List<Contact> bulkContacts = new List<Contact>();
        List<Privacy_Notice__c> bulkNotices = new List<Privacy_Notice__c>();
        
        for (Integer i = 0; i < 200; i++) {
            Contact c = new Contact(
                FirstName = 'Bulk',
                LastName = 'Customer ' + i,
                Email = 'bulk' + i + '@example.com',
                AccountId = bulkAccount.Id
            );
            bulkContacts.add(c);
        }
        insert bulkContacts;
        
        // Create initial notices for all (to make them due for annual)
        for (Contact c : bulkContacts) {
            bulkNotices.add(new Privacy_Notice__c(
                Contact__c = c.Id,
                Account__c = bulkAccount.Id,
                Notice_Type__c = 'Initial',
                Sent_Date__c = System.now().addDays(-400),
                Next_Annual_Notice_Due__c = Date.today().addDays(-1), // Due
                Notice_Version__c = '1.0'
            ));
        }
        insert bulkNotices;
        
        Test.startTest();
        List<Privacy_Notice__c> annualNotices = ElaroGLBAPrivacyNoticeService.sendAnnualNotices();
        Test.stopTest();
        
        // Then: Should process bulk contacts
        Assert.isTrue(annualNotices.size() >= 200, 'Should create annual notices for bulk contacts');
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
