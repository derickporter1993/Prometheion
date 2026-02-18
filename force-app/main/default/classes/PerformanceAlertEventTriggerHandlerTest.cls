/**
 * @description Unit tests for PerformanceAlertEventTriggerHandler
 * @group Tests
 * @author Elaro Team
 */
@IsTest(SeeAllData=false)
private class PerformanceAlertEventTriggerHandlerTest {
    
    /**
     * @description Test successful processing of performance alert events
     */
    @IsTest
    static void testHandleAfterInsert_Success() {
        // Create test data
        List<Performance_Alert__e> events = new List<Performance_Alert__e>();
        
        for (Integer i = 0; i < 5; i++) {
            events.add(new Performance_Alert__e(
                Metric__c = 'CPU Usage',
                Value__c = 85.0 + i,
                Threshold__c = 80.0,
                Context_Record__c = 'test-record-' + i,
                Stack__c = 'Test stack trace ' + i
            ));
        }
        
        Test.startTest();
        PerformanceAlertEventTriggerHandler.handleAfterInsert(events);
        Test.stopTest();
        
        // Verify history records were created
        List<Performance_Alert_History__c> history = [
            SELECT Id, Metric__c, Value__c, Threshold__c
            FROM Performance_Alert_History__c
            WITH USER_MODE
        ];
        
        Assert.areEqual(5, history.size(), 'Should create 5 history records');
        Assert.areEqual('CPU Usage', history[0].Metric__c, 'Metric should match');
        Assert.isTrue(history[0].Value__c >= 85.0, 'Value should be >= 85.0');
    }
    
    /**
     * @description Test handling of null input
     */
    @IsTest
    static void testHandleAfterInsert_NullInput() {
        Test.startTest();
        PerformanceAlertEventTriggerHandler.handleAfterInsert(null);
        Test.stopTest();
        
        // Should complete without error
        List<Performance_Alert_History__c> history = [
            SELECT Id FROM Performance_Alert_History__c WITH USER_MODE
        ];
        Assert.areEqual(0, history.size(), 'Should not create any records for null input');
    }
    
    /**
     * @description Test handling of empty list
     */
    @IsTest
    static void testHandleAfterInsert_EmptyList() {
        Test.startTest();
        PerformanceAlertEventTriggerHandler.handleAfterInsert(new List<Performance_Alert__e>());
        Test.stopTest();
        
        // Should complete without error
        List<Performance_Alert_History__c> history = [
            SELECT Id FROM Performance_Alert_History__c WITH USER_MODE
        ];
        Assert.areEqual(0, history.size(), 'Should not create any records for empty list');
    }
    
    /**
     * @description Test bulk processing of performance alerts
     */
    @IsTest
    static void testHandleAfterInsert_BulkProcessing() {
        List<Performance_Alert__e> events = new List<Performance_Alert__e>();
        
        // Create 200 events to test bulk processing
        for (Integer i = 0; i < 200; i++) {
            events.add(new Performance_Alert__e(
                Metric__c = 'Memory Usage',
                Value__c = 70.0 + Math.mod(i, 20),
                Threshold__c = 75.0,
                Context_Record__c = 'bulk-test-' + i,
                Stack__c = 'Bulk stack trace ' + i
            ));
        }
        
        Test.startTest();
        PerformanceAlertEventTriggerHandler.handleAfterInsert(events);
        Test.stopTest();
        
        // Verify all records were created
        List<Performance_Alert_History__c> history = [
            SELECT Id FROM Performance_Alert_History__c WITH USER_MODE
        ];
        
        Assert.areEqual(200, history.size(), 'Should create 200 history records');
    }
}
