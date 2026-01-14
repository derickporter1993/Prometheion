/**
 * @description Test class for RetentionEnforcementBatch
 * Tests batch processing of data retention enforcement and erasure workflows
 * @group Tests
 * @see RetentionEnforcementBatch
 */
@isTest
private class RetentionEnforcementBatchTest {

    @TestSetup
    static void setup() {
        // Create test Data Processing Activities
        List<Data_Processing_Activity__c> activities = new List<Data_Processing_Activity__c>();
        for (Integer i = 0; i < 10; i++) {
            activities.add(new Data_Processing_Activity__c(
                Activity_Name__c = 'Test Activity ' + i,
                Retention_Period__c = 365 + (i * 30),
                Legal_Basis__c = 'Consent'
            ));
        }
        insert activities;
    }

    @isTest
    static void testBatchExecution() {
        // Arrange
        Integer activityCount = [SELECT COUNT() FROM Data_Processing_Activity__c];
        System.assert(activityCount > 0, 'Test data should exist');

        // Act
        Test.startTest();
        RetentionEnforcementBatch batch = new RetentionEnforcementBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete successfully');
    }

    @isTest
    static void testBatchWithNoActivities() {
        // Arrange - delete all activities
        delete [SELECT Id FROM Data_Processing_Activity__c];

        // Act
        Test.startTest();
        RetentionEnforcementBatch batch = new RetentionEnforcementBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete even with no activities');
    }

    @isTest
    static void testBatchWithNullRetentionPeriod() {
        // Arrange - create activity without retention period
        Data_Processing_Activity__c activityNoRetention = new Data_Processing_Activity__c(
            Activity_Name__c = 'No Retention Activity',
            Legal_Basis__c = 'Legitimate Interest'
        );
        insert activityNoRetention;

        // Act
        Test.startTest();
        RetentionEnforcementBatch batch = new RetentionEnforcementBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should handle null retention periods');
    }

    @isTest
    static void testBatchBulkProcessing() {
        // Arrange - create 200+ activities for bulk testing
        List<Data_Processing_Activity__c> bulkActivities = new List<Data_Processing_Activity__c>();
        for (Integer i = 0; i < 250; i++) {
            bulkActivities.add(new Data_Processing_Activity__c(
                Activity_Name__c = 'Bulk Activity ' + i,
                Retention_Period__c = 365,
                Legal_Basis__c = 'Contract'
            ));
        }
        insert bulkActivities;

        // Act
        Test.startTest();
        RetentionEnforcementBatch batch = new RetentionEnforcementBatch();
        Id batchId = Database.executeBatch(batch, 200);
        Test.stopTest();

        // Assert
        AsyncApexJob job = [SELECT Status, NumberOfErrors FROM AsyncApexJob WHERE Id = :batchId];
        System.assertEquals('Completed', job.Status, 'Batch should complete bulk processing');
        System.assertEquals(0, job.NumberOfErrors, 'Batch should complete without errors');
    }

    @isTest
    static void testStartMethod() {
        // Arrange
        RetentionEnforcementBatch batch = new RetentionEnforcementBatch();

        // Act
        Test.startTest();
        Database.QueryLocator queryLocator = batch.start(null);
        Test.stopTest();

        // Assert
        System.assertNotEquals(null, queryLocator, 'QueryLocator should not be null');
    }
}
