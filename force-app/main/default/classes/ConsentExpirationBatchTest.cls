/**
 * @description Test class for ConsentExpirationBatch
 * Tests batch processing of expiring consents and renewal reminders
 * @group Tests
 * @see ConsentExpirationBatch
 */
@isTest
private class ConsentExpirationBatchTest {

    @TestSetup
    static void setup() {
        // Create test contacts
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Contact' + i,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;

        // Create test consents
        List<Consent__c> consents = new List<Consent__c>();
        for (Contact c : contacts) {
            consents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Marketing',
                Consent_Given__c = true,
                Consent_Withdrawn__c = false,
                Consent_Date__c = Date.today().addDays(-30)
            ));
        }
        insert consents;
    }

    @isTest
    static void testBatchExecutionWithDefaultWarningDays() {
        // Arrange
        Integer consentCount = [SELECT COUNT() FROM Consent__c WHERE Consent_Given__c = true];
        System.assert(consentCount > 0, 'Test data should exist');

        // Act
        Test.startTest();
        ConsentExpirationBatch batch = new ConsentExpirationBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }

    @isTest
    static void testBatchExecutionWithCustomWarningDays() {
        // Arrange
        Integer customWarningDays = 60;

        // Act
        Test.startTest();
        ConsentExpirationBatch batch = new ConsentExpirationBatch(customWarningDays);
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully with custom warning days');
    }

    @isTest
    static void testBatchWithNoActiveConsents() {
        // Arrange - withdraw all consents
        List<Consent__c> consents = [SELECT Id FROM Consent__c];
        for (Consent__c c : consents) {
            c.Consent_Withdrawn__c = true;
        }
        update consents;

        // Act
        Test.startTest();
        ConsentExpirationBatch batch = new ConsentExpirationBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete even with no active consents');
    }

    @isTest
    static void testBatchWithNullContacts() {
        // Arrange - create consent without contact
        Consent__c consentNoContact = new Consent__c(
            Consent_Type__c = 'Marketing',
            Consent_Given__c = true,
            Consent_Withdrawn__c = false,
            Consent_Date__c = Date.today()
        );
        insert consentNoContact;

        // Act
        Test.startTest();
        ConsentExpirationBatch batch = new ConsentExpirationBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should handle null contacts gracefully');
    }

    @isTest
    static void testBatchBulkProcessing() {
        // Arrange - create 200+ consents for bulk testing
        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 250; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Contact' + i,
                Email = 'bulk' + i + '@example.com'
            ));
        }
        insert bulkContacts;

        List<Consent__c> bulkConsents = new List<Consent__c>();
        for (Contact c : bulkContacts) {
            bulkConsents.add(new Consent__c(
                Contact__c = c.Id,
                Consent_Type__c = 'Marketing',
                Consent_Given__c = true,
                Consent_Withdrawn__c = false,
                Consent_Date__c = Date.today().addDays(-15)
            ));
        }
        insert bulkConsents;

        // Act
        Test.startTest();
        ConsentExpirationBatch batch = new ConsentExpirationBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete bulk processing');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should complete without errors');
    }
}
