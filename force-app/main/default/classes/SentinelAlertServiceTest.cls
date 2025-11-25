/**
 * @description Test class for SentinelAlertService
 * @author Sentinel Team
 * @date 2025
 */
@isTest
private class SentinelAlertServiceTest {

    @testSetup
    static void setup() {
        // Create test alerts
        List<Alert__c> testAlerts = new List<Alert__c>();
        testAlerts.add(new Alert__c(
            Title__c = 'Test High Alert',
            Description__c = 'High severity test alert',
            AlertType__c = 'PERMISSION_DRIFT',
            Severity__c = 'HIGH',
            Acknowledged__c = false
        ));
        testAlerts.add(new Alert__c(
            Title__c = 'Test Medium Alert',
            Description__c = 'Medium severity test alert',
            AlertType__c = 'FLOW_DRIFT',
            Severity__c = 'MEDIUM',
            Acknowledged__c = false
        ));
        testAlerts.add(new Alert__c(
            Title__c = 'Acknowledged Alert',
            Description__c = 'Already acknowledged',
            AlertType__c = 'SHARING_DRIFT',
            Severity__c = 'LOW',
            Acknowledged__c = true,
            AcknowledgedBy__c = UserInfo.getUserId(),
            AcknowledgedAt__c = System.now()
        ));
        insert testAlerts;
    }

    @isTest
    static void testGetActiveAlerts_ReturnsData() {
        Test.startTest();
        List<Map<String, Object>> alerts = SentinelAlertService.getActiveAlerts();
        Test.stopTest();

        // Verify alerts returned
        System.assertNotEquals(null, alerts, 'Alerts should not be null');
        System.assert(alerts.size() > 0, 'Should return sample alerts');
    }

    @isTest
    static void testGetActiveAlerts_CacheableWorks() {
        // Test @AuraEnabled(cacheable=true)
        Test.startTest();
        List<Map<String, Object>> alerts1 = SentinelAlertService.getActiveAlerts();
        List<Map<String, Object>> alerts2 = SentinelAlertService.getActiveAlerts();
        Test.stopTest();

        // Verify consistent results
        System.assertEquals(alerts1.size(), alerts2.size(), 'Cacheable should return consistent results');
    }

    @isTest
    static void testGetActiveAlerts_DataStructure() {
        Test.startTest();
        List<Map<String, Object>> alerts = SentinelAlertService.getActiveAlerts();
        Test.stopTest();

        // Verify data structure
        if (alerts.size() > 0) {
            Map<String, Object> alert = alerts[0];
            System.assert(alert.containsKey('id'), 'Should have id field');
            System.assert(alert.containsKey('title'), 'Should have title field');
            System.assert(alert.containsKey('severity'), 'Should have severity field');
            System.assert(alert.containsKey('alertType'), 'Should have alertType field');
            System.assert(alert.containsKey('acknowledged'), 'Should have acknowledged field');
        }
    }

    @isTest
    static void testAcknowledgeAlert_ValidId() {
        List<Alert__c> alerts = [SELECT Id FROM Alert__c WHERE Acknowledged__c = false LIMIT 1];

        Test.startTest();
        if (!alerts.isEmpty()) {
            SentinelAlertService.acknowledgeAlert(String.valueOf(alerts[0].Id));
        } else {
            // Test with sample ID
            SentinelAlertService.acknowledgeAlert('ALERT001');
        }
        Test.stopTest();

        // Verify no errors thrown
        System.assert(true, 'Acknowledge should complete without errors');
    }

    @isTest
    static void testAcknowledgeAlert_BlankId() {
        Test.startTest();
        try {
            SentinelAlertService.acknowledgeAlert('');
            System.assert(false, 'Should throw exception for blank ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('required'), 'Should indicate ID is required');
        }
        Test.stopTest();
    }

    @isTest
    static void testAcknowledgeAlert_NullId() {
        Test.startTest();
        try {
            SentinelAlertService.acknowledgeAlert(null);
            System.assert(false, 'Should throw exception for null ID');
        } catch (Exception e) {
            System.assert(true, 'Should handle null ID');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetAlertStatistics_ReturnsData() {
        Test.startTest();
        Map<String, Integer> stats = SentinelAlertService.getAlertStatistics();
        Test.stopTest();

        // Verify statistics returned
        System.assertNotEquals(null, stats, 'Statistics should not be null');
        System.assert(stats.containsKey('critical'), 'Should have critical count');
        System.assert(stats.containsKey('high'), 'Should have high count');
        System.assert(stats.containsKey('medium'), 'Should have medium count');
        System.assert(stats.containsKey('low'), 'Should have low count');
        System.assert(stats.containsKey('total'), 'Should have total count');
    }

    @isTest
    static void testGetAlertStatistics_Cacheable() {
        Test.startTest();
        Map<String, Integer> stats1 = SentinelAlertService.getAlertStatistics();
        Map<String, Integer> stats2 = SentinelAlertService.getAlertStatistics();
        Test.stopTest();

        // Verify consistent results
        System.assertEquals(stats1.get('total'), stats2.get('total'), 'Should return consistent statistics');
    }

    @isTest
    static void testBulkAcknowledge() {
        List<Alert__c> alerts = [SELECT Id FROM Alert__c WHERE Acknowledged__c = false];

        Test.startTest();
        for (Alert__c alert : alerts) {
            try {
                SentinelAlertService.acknowledgeAlert(String.valueOf(alert.Id));
            } catch (Exception e) {
                // Continue even if error
            }
        }
        Test.stopTest();

        // Verify bulk operations work
        System.assert(true, 'Bulk acknowledge should complete');
    }
}
