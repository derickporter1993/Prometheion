/**
 * Unit tests for ElaroHistoricalEventBatch
 * @group Tests
 */
@IsTest(testFor=ElaroHistoricalEventBatch.class)
private class ElaroHistoricalEventBatchTest {
    
    @isTest
    static void testBatch_ExecutesSuccessfully() {
        Test.startTest();
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        Id batchId = Database.executeBatch(batch, 10);
        Test.stopTest();
        
        Assert.areNotEqual(null, batchId, 'Batch should return job ID');
        
        // Verify batch completed
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual('Completed', job.Status, 'Batch should complete');
    }
    
    @isTest
    static void testBatch_HandlesEmptyResults() {
        Test.startTest();
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-1), // Very recent, likely empty
            Date.today()
        );
        Id batchId = Database.executeBatch(batch, 10);
        Test.stopTest();
        
        AsyncApexJob job = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual('Completed', job.Status, 'Batch should complete even with no data');
    }
    
    @isTest
    static void testBatch_DifferentEventTypes() {
        List&lt;String&gt; eventTypes = new List&lt;String&gt;{
            'Login', 'LoginAs', 'API', 'ReportExport'
        };
        
        Test.startTest();
        for (String eventType : eventTypes) {
            ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
                eventType,
                Date.today().addDays(-7),
                Date.today()
            );
            Id batchId = Database.executeBatch(batch, 5);
        }
        Test.stopTest();
        
        // Verify all batches completed
        List&lt;AsyncApexJob&gt; jobs = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE ApexClass.Name = 'ElaroHistoricalEventBatch'
            AND Status = 'Completed'
        ];
        
        Assert.isTrue(jobs.size() &gt; 0, 'Batches should complete');
    }
    
    @isTest
    static void testBatch_LargeDateRange() {
        Test.startTest();
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'API',
            Date.today().addDays(-90),
            Date.today()
        );
        Id batchId = Database.executeBatch(batch, 5);
        Test.stopTest();
        
        // Batch should complete without errors
        AsyncApexJob job = [
            SELECT Status, NumberOfErrors
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual(0, job.NumberOfErrors, 'Batch should have no errors');
    }
    
    @isTest
    static void testBatch_GetStatistics() {
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        
        Test.startTest();
        Map&lt;String, Object&gt; stats = batch.getStatistics();
        Test.stopTest();
        
        Assert.areEqual('Login', stats.get('eventType'), 'Should return event type');
        Assert.areEqual(0, stats.get('filesProcessed'), 'Should have 0 files processed initially');
        Assert.areEqual(0, stats.get('eventsProcessed'), 'Should have 0 events processed initially');
        Assert.areEqual(0, stats.get('errors'), 'Should have 0 errors initially');
    }
    
    @isTest
    static void testBatch_StartMethod() {
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        
        Test.startTest();
        Database.QueryLocator locator = batch.start(null);
        Test.stopTest();
        
        Assert.areNotEqual(null, locator, 'Should return query locator');
    }
    
    @isTest
    static void testBatch_ExecuteWithEmptyScope() {
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        
        Test.startTest();
        // Execute with empty list
        batch.execute(null, new List&lt;EventLogFile&gt;());
        Test.stopTest();
        
        // Should not throw exception
        Map&lt;String, Object&gt; stats = batch.getStatistics();
        Assert.areEqual(0, stats.get('filesProcessed'), 'Should handle empty scope');
    }
    
    @isTest
    static void testBatch_FinishMethod() {
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );

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
    
    @isTest
    static void testBatch_ScheduledExecution() {
        Test.startTest();
        ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-30),
            Date.today()
        );
        
        // Execute batch with small batch size
        Id batchId = Database.executeBatch(batch, 1);
        Test.stopTest();
        
        // Verify completion
        AsyncApexJob job = [
            SELECT Status, JobItemsProcessed, TotalJobItems
            FROM AsyncApexJob
            WHERE Id = :batchId
        ];
        Assert.areEqual('Completed', job.Status, 'Batch should complete');
    }
    
    @isTest
    static void testBatch_MultipleBatchesSequential() {
        Test.startTest();
        
        // Execute first batch
        ElaroHistoricalEventBatch batch1 = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-15),
            Date.today().addDays(-8)
        );
        Id batchId1 = Database.executeBatch(batch1, 10);
        
        // Execute second batch
        ElaroHistoricalEventBatch batch2 = new ElaroHistoricalEventBatch(
            'Login',
            Date.today().addDays(-7),
            Date.today()
        );
        Id batchId2 = Database.executeBatch(batch2, 10);
        
        Test.stopTest();
        
        // Both batches should complete
        List&lt;AsyncApexJob&gt; jobs = [
            SELECT Status
            FROM AsyncApexJob
            WHERE Id IN (:batchId1, :batchId2)
        ];
        
        for (AsyncApexJob job : jobs) {
            Assert.areEqual('Completed', job.Status, 'All batches should complete');
        }
    }
    
    @isTest
    static void testBatch_WithRealEventTypes() {
        // Test with all supported event types
        List&lt;String&gt; eventTypes = new List&lt;String&gt;{
            'Login', 'LoginAs', 'API', 'ReportExport',
            'ContentDistribution', 'ApexExecution', 'PermissionSetEventLog'
        };
        
        Test.startTest();
        Integer count = 0;
        for (String eventType : eventTypes) {
            if (count &lt; 5) { // Limit to avoid too many batches
                ElaroHistoricalEventBatch batch = new ElaroHistoricalEventBatch(
                    eventType,
                    Date.today().addDays(-7),
                    Date.today()
                );
                Database.executeBatch(batch, 10);
                count++;
            }
        }
        Test.stopTest();
        
        // Verify batches were queued
        List&lt;AsyncApexJob&gt; jobs = [
            SELECT Status FROM AsyncApexJob
            WHERE ApexClass.Name = 'ElaroHistoricalEventBatch'
            AND Status = 'Completed'
        ];
        Assert.isTrue(jobs.size() &gt; 0, 'At least one batch should complete for event types');
    }
}
