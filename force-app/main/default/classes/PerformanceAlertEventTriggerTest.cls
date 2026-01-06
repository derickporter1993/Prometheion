/**
 * Test class for Performance Alert functionality
 * Note: Performance_Alert__e platform event not available due to org limits.
 * Tests use Performance_Alert_History__c instead.
 */
@isTest
private class PerformanceAlertEventTriggerTest {
    
    @isTest
    static void testPerformanceAlertHistoryCreation() {
        Performance_Alert_History__c alert = new Performance_Alert_History__c(
            Metric__c = 'CPU',
            Value__c = 9500,
            Threshold__c = 10000,
            Context_Record__c = 'testContext',
            Stack__c = 'Test stack trace'
        );
        
        Test.startTest();
        insert alert;
        Test.stopTest();
        
        Performance_Alert_History__c savedAlert = [
            SELECT Id, Metric__c, Value__c, Threshold__c
            FROM Performance_Alert_History__c
            WHERE Id = :alert.Id
        ];
        
        System.assertEquals('CPU', savedAlert.Metric__c, 'Metric should match');
        System.assertEquals(9500, savedAlert.Value__c, 'Value should match');
        System.assertEquals(10000, savedAlert.Threshold__c, 'Threshold should match');
    }
    
    @isTest
    static void testPerformanceAlertHistoryBulk() {
        List<Performance_Alert_History__c> alerts = new List<Performance_Alert_History__c>();
        for (Integer i = 0; i < 200; i++) {
            alerts.add(new Performance_Alert_History__c(
                Metric__c = 'HEAP',
                Value__c = 5000 + i,
                Threshold__c = 6000
            ));
        }
        
        Test.startTest();
        insert alerts;
        Test.stopTest();
        
        Integer count = [SELECT COUNT() FROM Performance_Alert_History__c WHERE Metric__c = 'HEAP'];
        System.assertEquals(200, count, 'Should have created 200 alerts');
    }
    
    @isTest
    static void testPerformanceAlertPublisherIntegration() {
        Test.startTest();
        PerformanceAlertPublisher.publish('SOQL', 95, 100, 'integrationTest', null);
        Test.stopTest();
        
        List<Performance_Alert_History__c> alerts = [
            SELECT Metric__c, Value__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'SOQL'
        ];
        System.assertEquals(1, alerts.size(), 'Should have one SOQL alert');
        System.assertEquals(95, alerts[0].Value__c, 'Value should be 95');
    }
}
