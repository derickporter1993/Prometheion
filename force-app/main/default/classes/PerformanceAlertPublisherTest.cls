/**
 * Test class for PerformanceAlertPublisher
 */
@isTest
private class PerformanceAlertPublisherTest {
    
    @isTest
    static void testPublishSuccess() {
        Test.startTest();
        PerformanceAlertPublisher.publish('CPU', 8500, 10000, null, 'Test stack trace');
        Test.stopTest();
        
        // Verify alert was saved to history
        List<Performance_Alert_History__c> alerts = [
            SELECT Metric__c, Value__c, Threshold__c, Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'CPU'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(8500, alerts[0].Value__c, 'Value should match');
        System.assertEquals(10000, alerts[0].Threshold__c, 'Threshold should match');
    }
    
    @isTest
    static void testPublishWithNullMetric() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PerformanceAlertPublisher.publish(null, 8500, 10000, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Metric cannot be blank'), 'Expected validation error');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    @isTest
    static void testPublishWithNullValue() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PerformanceAlertPublisher.publish('CPU', null, 10000, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Value cannot be null'), 'Expected validation error');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected AuraHandledException to be thrown');
    }
    
    @isTest
    static void testPublishWithLongStackTrace() {
        String longStack = '';
        for (Integer i = 0; i < 4000; i++) {
            longStack += 'x';
        }
        
        Test.startTest();
        PerformanceAlertPublisher.publish('HEAP', 5000, 6000, 'someRecordId', longStack);
        Test.stopTest();
        
        List<Performance_Alert_History__c> alerts = [
            SELECT Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'HEAP'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assert(alerts[0].Stack__c.length() <= 32768, 'Stack should be truncated');
    }
}
