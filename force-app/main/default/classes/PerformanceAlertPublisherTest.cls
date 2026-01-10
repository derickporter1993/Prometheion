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
    static void testPublishWithBlankMetric() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PerformanceAlertPublisher.publish('', 8500, 10000, null, null);
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
    static void testPublishWithNullThreshold() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PerformanceAlertPublisher.publish('CPU', 8500, null, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Threshold cannot be null'), 'Expected validation error');
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

    @isTest
    static void testPublishWithVeryLongStackTrace() {
        // Create a stack trace longer than 32768 characters
        String veryLongStack = '';
        for (Integer i = 0; i < 35000; i++) {
            veryLongStack += 'y';
        }

        Test.startTest();
        PerformanceAlertPublisher.publish('QUERIES', 150, 100, null, veryLongStack);
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'QUERIES'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        // Stack should be truncated to 32768 (32765 + '...')
        System.assert(alerts[0].Stack__c.endsWith('...'), 'Stack should end with ellipsis when truncated');
    }

    @isTest
    static void testPublishWithXSSInStackTrace() {
        String xssStack = '<script>alert("xss")</script>';

        Test.startTest();
        PerformanceAlertPublisher.publish('DML', 100, 50, null, xssStack);
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'DML'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        // Verify XSS characters are escaped
        System.assert(!alerts[0].Stack__c.contains('<script>'), 'Script tags should be escaped');
        System.assert(alerts[0].Stack__c.contains('&lt;'), 'Less than should be escaped');
        System.assert(alerts[0].Stack__c.contains('&gt;'), 'Greater than should be escaped');
    }

    @isTest
    static void testPublishWithContextRecord() {
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Test.startTest();
        PerformanceAlertPublisher.publish('SOQL', 95, 100, testAccount.Id, 'Context test');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Context_Record__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'SOQL'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(testAccount.Id, alerts[0].Context_Record__c, 'Context record should match');
    }

    @isTest
    static void testPublishWithNullStack() {
        Test.startTest();
        PerformanceAlertPublisher.publish('CPU_TIME', 9000, 10000, null, null);
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'CPU_TIME'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(null, alerts[0].Stack__c, 'Stack should be null');
    }

    @isTest
    static void testPublishWithEmptyStack() {
        Test.startTest();
        PerformanceAlertPublisher.publish('HEAP_SIZE', 5000, 6000, null, '');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Stack__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'HEAP_SIZE'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
    }

    @isTest
    static void testPublishMultipleAlerts() {
        Test.startTest();
        PerformanceAlertPublisher.publish('METRIC_1', 100, 50, null, 'Stack 1');
        PerformanceAlertPublisher.publish('METRIC_2', 200, 100, null, 'Stack 2');
        PerformanceAlertPublisher.publish('METRIC_3', 300, 150, null, 'Stack 3');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Metric__c
            FROM Performance_Alert_History__c
            WHERE Metric__c LIKE 'METRIC_%'
        ];
        System.assertEquals(3, alerts.size(), 'Expected three alerts to be saved');
    }

    @isTest
    static void testPublishWithDecimalValues() {
        Test.startTest();
        PerformanceAlertPublisher.publish('DECIMAL_TEST', 85.75, 90.50, null, 'Decimal test');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Value__c, Threshold__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'DECIMAL_TEST'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(85.75, alerts[0].Value__c, 'Value should match decimal');
        System.assertEquals(90.50, alerts[0].Threshold__c, 'Threshold should match decimal');
    }

    @isTest
    static void testPublishWithNegativeValues() {
        Test.startTest();
        PerformanceAlertPublisher.publish('NEGATIVE_TEST', -10, 0, null, 'Negative test');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Value__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'NEGATIVE_TEST'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(-10, alerts[0].Value__c, 'Negative value should be saved');
    }

    @isTest
    static void testPublishWithZeroValues() {
        Test.startTest();
        PerformanceAlertPublisher.publish('ZERO_TEST', 0, 0, null, 'Zero test');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Value__c, Threshold__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'ZERO_TEST'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
        System.assertEquals(0, alerts[0].Value__c, 'Zero value should be saved');
        System.assertEquals(0, alerts[0].Threshold__c, 'Zero threshold should be saved');
    }

    @isTest
    static void testPublishWithSpecialCharactersInMetric() {
        Test.startTest();
        PerformanceAlertPublisher.publish('CPU_TIME_MS', 8500, 10000, null, 'Special chars test');
        Test.stopTest();

        List<Performance_Alert_History__c> alerts = [
            SELECT Metric__c
            FROM Performance_Alert_History__c
            WHERE Metric__c = 'CPU_TIME_MS'
        ];
        System.assertEquals(1, alerts.size(), 'Expected one alert to be saved');
    }

    @isTest
    static void testPublishWithWhitespaceMetric() {
        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            PerformanceAlertPublisher.publish('   ', 8500, 10000, null, null);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            System.assert(e.getMessage().contains('Metric cannot be blank'), 'Expected validation error');
        }
        Test.stopTest();
        System.assert(exceptionThrown, 'Expected AuraHandledException for whitespace metric');
    }
}
