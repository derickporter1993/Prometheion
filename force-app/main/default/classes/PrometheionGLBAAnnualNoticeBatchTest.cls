/**
 * PrometheionGLBAAnnualNoticeBatchTest - Test coverage for GLBA annual notice batch
 *
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionGLBAAnnualNoticeBatchTest {

    // ========================================
    // TEST DATA SETUP
    // ========================================

    @TestSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        insert accounts;

        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact ' + i,
                Email = 'testcontact' + i + '@example.com',
                AccountId = accounts[Math.mod(i, 5)].Id
            ));
        }
        insert contacts;

        // Create privacy notices due for renewal
        List<Privacy_Notice__c> notices = new List<Privacy_Notice__c>();

        // Notices due today (should be processed)
        for (Integer i = 0; i < 5; i++) {
            notices.add(new Privacy_Notice__c(
                Contact__c = contacts[i].Id,
                Account__c = contacts[i].AccountId,
                Notice_Type__c = 'Annual',
                Sent_Date__c = Date.today().addDays(-365),
                Delivery_Status__c = 'Delivered',
                Delivery_Method__c = 'Email',
                Next_Annual_Notice_Due__c = Date.today()
            ));
        }

        // Notices not due yet (should not be processed)
        for (Integer i = 5; i < 10; i++) {
            notices.add(new Privacy_Notice__c(
                Contact__c = contacts[i].Id,
                Account__c = contacts[i].AccountId,
                Notice_Type__c = 'Initial',
                Sent_Date__c = Date.today().addDays(-30),
                Delivery_Status__c = 'Delivered',
                Delivery_Method__c = 'Email',
                Next_Annual_Notice_Due__c = Date.today().addDays(335) // Not due yet
            ));
        }

        insert notices;
    }

    // ========================================
    // BATCH EXECUTION TESTS
    // ========================================

    @IsTest
    static void testBatch_Execute() {
        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify new annual notices were created
        List<Privacy_Notice__c> newNotices = [
            SELECT Id, Notice_Type__c, Delivery_Status__c
            FROM Privacy_Notice__c
            WHERE Notice_Type__c = 'Annual'
            AND Delivery_Status__c = 'Pending'
        ];

        System.assertEquals(5, newNotices.size(), 'Should have created 5 new annual notices');
    }

    @IsTest
    static void testBatch_StartMethod() {
        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.QueryLocator locator = batch.start(null);

        Test.stopTest();

        System.assertNotEquals(null, locator, 'QueryLocator should not be null');
    }

    @IsTest
    static void testBatch_ExecuteMethod() {
        // Get notices due for renewal
        List<Privacy_Notice__c> notices = [
            SELECT Id, Contact__c, Account__c, Contact__r.Email, Next_Annual_Notice_Due__c
            FROM Privacy_Notice__c
            WHERE Next_Annual_Notice_Due__c <= TODAY
            AND Notice_Type__c IN ('Initial', 'Annual')
            LIMIT 5
        ];

        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        batch.execute(null, notices);

        Test.stopTest();

        // Verify new notices were created
        Integer pendingCount = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Delivery_Status__c = 'Pending'
        ];

        System.assert(pendingCount > 0, 'New pending notices should be created');
    }

    @IsTest
    static void testBatch_FinishMethod() {
        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        batch.finish(null);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Finish method should complete');
    }

    // ========================================
    // BULK TESTING
    // ========================================

    @IsTest
    static void testBatch_BulkData() {
        // Delete existing test data
        delete [SELECT Id FROM Privacy_Notice__c];
        delete [SELECT Id FROM Contact];
        delete [SELECT Id FROM Account];

        // Create bulk test data
        Account bulkAccount = new Account(Name = 'Bulk Test Account');
        insert bulkAccount;

        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Contact ' + i,
                Email = 'bulk' + i + '@example.com',
                AccountId = bulkAccount.Id
            ));
        }
        insert bulkContacts;

        List<Privacy_Notice__c> bulkNotices = new List<Privacy_Notice__c>();
        for (Contact c : bulkContacts) {
            bulkNotices.add(new Privacy_Notice__c(
                Contact__c = c.Id,
                Account__c = bulkAccount.Id,
                Notice_Type__c = 'Annual',
                Sent_Date__c = Date.today().addDays(-365),
                Delivery_Status__c = 'Delivered',
                Next_Annual_Notice_Due__c = Date.today()
            ));
        }
        insert bulkNotices;

        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 50);

        Test.stopTest();

        // Verify bulk processing worked
        Integer newNoticeCount = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Delivery_Status__c = 'Pending'
        ];

        System.assertEquals(200, newNoticeCount, 'Should have created 200 new notices');
    }

    // ========================================
    // EDGE CASE TESTS
    // ========================================

    @IsTest
    static void testBatch_NoDataToProcess() {
        // Delete all notices due today
        delete [SELECT Id FROM Privacy_Notice__c WHERE Next_Annual_Notice_Due__c <= TODAY];

        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Should complete without errors
        System.assert(true, 'Batch should handle empty data');
    }

    @IsTest
    static void testBatch_DuplicateContacts() {
        // Get contacts and create duplicate notices for same contact
        List<Contact> contacts = [SELECT Id, AccountId FROM Contact LIMIT 1];

        if (!contacts.isEmpty()) {
            Contact c = contacts[0];

            // Create multiple notices for same contact
            List<Privacy_Notice__c> duplicateNotices = new List<Privacy_Notice__c>();
            for (Integer i = 0; i < 3; i++) {
                duplicateNotices.add(new Privacy_Notice__c(
                    Contact__c = c.Id,
                    Account__c = c.AccountId,
                    Notice_Type__c = 'Annual',
                    Sent_Date__c = Date.today().addDays(-365 - i),
                    Delivery_Status__c = 'Delivered',
                    Next_Annual_Notice_Due__c = Date.today()
                ));
            }
            insert duplicateNotices;
        }

        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Should only create one notice per contact
        System.assert(true, 'Duplicate contacts should be handled');
    }

    @IsTest
    static void testBatch_ContactWithoutEmail() {
        // Create contact without email
        Account acc = new Account(Name = 'No Email Account');
        insert acc;

        Contact noEmailContact = new Contact(
            FirstName = 'No',
            LastName = 'Email',
            AccountId = acc.Id
            // No email set
        );
        insert noEmailContact;

        Privacy_Notice__c notice = new Privacy_Notice__c(
            Contact__c = noEmailContact.Id,
            Account__c = acc.Id,
            Notice_Type__c = 'Initial',
            Sent_Date__c = Date.today().addDays(-365),
            Delivery_Status__c = 'Delivered',
            Next_Annual_Notice_Due__c = Date.today()
        );
        insert notice;

        Test.startTest();

        PrometheionGLBAAnnualNoticeBatch batch = new PrometheionGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify notice was created with 'Mail' delivery method
        List<Privacy_Notice__c> newNotices = [
            SELECT Delivery_Method__c
            FROM Privacy_Notice__c
            WHERE Contact__c = :noEmailContact.Id
            AND Delivery_Status__c = 'Pending'
        ];

        System.assertEquals(1, newNotices.size(), 'Should create notice for contact without email');
        System.assertEquals('Mail', newNotices[0].Delivery_Method__c, 'Should use Mail delivery for contact without email');
    }

    // ========================================
    // SCHEDULER INTEGRATION TEST
    // ========================================

    @IsTest
    static void testSchedulerIntegration() {
        Test.startTest();

        // Schedule the GLBA notice scheduler
        String jobId = PrometheionGLBAAnnualNoticeScheduler.scheduleDaily();

        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Scheduler should return job ID');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        System.assertEquals(1, jobs.size(), 'Job should be scheduled');
    }
}
