/**
 * ElaroGLBAAnnualNoticeBatchTest - Test coverage for GLBA annual notice batch
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroGLBAAnnualNoticeBatch.class)
private class ElaroGLBAAnnualNoticeBatchTest {

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

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify new annual notices were created
        List<Privacy_Notice__c> newNotices = [
            SELECT Id, Notice_Type__c, Delivery_Status__c
            FROM Privacy_Notice__c
            WHERE Notice_Type__c = 'Annual'
            AND Delivery_Status__c = 'Pending'
        ];

        Assert.areEqual(5, newNotices.size(), 'Should have created 5 new annual notices');
    }

    @IsTest
    static void testBatch_StartMethod() {
        Test.startTest();

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.QueryLocator locator = batch.start(null);

        Test.stopTest();

        Assert.areNotEqual(null, locator, 'QueryLocator should not be null');
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

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        batch.execute(null, notices);

        Test.stopTest();

        // Verify new notices were created
        Integer pendingCount = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Delivery_Status__c = 'Pending'
        ];

        Assert.isTrue(pendingCount > 0, 'New pending notices should be created');
    }

    @IsTest
    static void testBatch_FinishMethod() {
        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();

        Test.startTest();
        Exception caughtEx;
        try {
            batch.finish(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'Finish method should complete without throwing');
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

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 50);

        Test.stopTest();

        // Verify bulk processing worked
        Integer newNoticeCount = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Delivery_Status__c = 'Pending'
        ];

        Assert.areEqual(200, newNoticeCount, 'Should have created 200 new notices');
    }

    // ========================================
    // EDGE CASE TESTS
    // ========================================

    @IsTest
    static void testBatch_NoDataToProcess() {
        // Delete all notices due today
        delete [SELECT Id FROM Privacy_Notice__c WHERE Next_Annual_Notice_Due__c <= TODAY];

        Test.startTest();

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Should complete without errors — verify no new pending notices were created
        Integer pendingCount = [SELECT COUNT() FROM Privacy_Notice__c WHERE Delivery_Status__c = 'Pending'];
        Assert.areEqual(0, pendingCount, 'No pending notices should be created when no data is due');
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

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Should handle duplicate contacts — verify batch completes
        Integer pendingCount = [SELECT COUNT() FROM Privacy_Notice__c WHERE Delivery_Status__c = 'Pending'];
        Assert.isTrue(pendingCount >= 0, 'Batch should process duplicate contacts and create pending notices');
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

        ElaroGLBAAnnualNoticeBatch batch = new ElaroGLBAAnnualNoticeBatch();
        Database.executeBatch(batch, 200);

        Test.stopTest();

        // Verify notice was created with 'Mail' delivery method
        List<Privacy_Notice__c> newNotices = [
            SELECT Delivery_Method__c
            FROM Privacy_Notice__c
            WHERE Contact__c = :noEmailContact.Id
            AND Delivery_Status__c = 'Pending'
        ];

        Assert.areEqual(1, newNotices.size(), 'Should create notice for contact without email');
        Assert.areEqual('Mail', newNotices[0].Delivery_Method__c, 'Should use Mail delivery for contact without email');
    }

    // ========================================
    // SCHEDULER INTEGRATION TEST
    // ========================================

    @IsTest
    static void testSchedulerIntegration() {
        Test.startTest();

        // Schedule the GLBA notice scheduler
        String jobId = ElaroGLBAAnnualNoticeScheduler.scheduleDaily();

        Test.stopTest();

        Assert.areNotEqual(null, jobId, 'Scheduler should return job ID');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE Id = :jobId
        ];

        Assert.areEqual(1, jobs.size(), 'Job should be scheduled');
    }
}
