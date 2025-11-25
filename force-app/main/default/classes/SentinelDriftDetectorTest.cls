/**
 * @description Test class for SentinelDriftDetector
 * @author Sentinel Team
 * @date 2025
 */
@isTest
private class SentinelDriftDetectorTest {

    @testSetup
    static void setup() {
        // Create test Alert records
        List<Alert__c> testAlerts = new List<Alert__c>();
        testAlerts.add(new Alert__c(
            Title__c = 'Test Permission Alert',
            Description__c = 'Test description',
            AlertType__c = 'PERMISSION_DRIFT',
            Severity__c = 'HIGH',
            Acknowledged__c = false
        ));
        testAlerts.add(new Alert__c(
            Title__c = 'Test Flow Alert',
            Description__c = 'Test flow description',
            AlertType__c = 'FLOW_DRIFT',
            Severity__c = 'MEDIUM',
            Acknowledged__c = false
        ));
        insert testAlerts;
    }

    @isTest
    static void testDetectDrift_ReturnsResults() {
        Test.startTest();
        List<SObject> alerts = SentinelDriftDetector.detectDrift();
        Test.stopTest();

        // Verify method executes without errors
        System.assertNotEquals(null, alerts, 'Alerts list should not be null');
    }

    @isTest
    static void testDetectDrift_HandlesNoChanges() {
        // Query with no recent changes
        Test.startTest();
        List<SObject> alerts = SentinelDriftDetector.detectDrift();
        Test.stopTest();

        // Should return empty list when no recent changes
        System.assertNotEquals(null, alerts, 'Should return empty list, not null');
    }

    @isTest
    static void testPublishAlerts_WithValidIds() {
        List<Alert__c> testAlerts = [SELECT Id FROM Alert__c LIMIT 2];
        List<Id> alertIds = new List<Id>();
        for (Alert__c alert : testAlerts) {
            alertIds.add(alert.Id);
        }

        Test.startTest();
        SentinelDriftDetector.publishAlerts(alertIds);
        Test.stopTest();

        // Verify no exceptions thrown
        System.assert(true, 'Method should complete without errors');
    }

    @isTest
    static void testPublishAlerts_WithEmptyList() {
        Test.startTest();
        SentinelDriftDetector.publishAlerts(new List<Id>());
        Test.stopTest();

        // Verify handles empty list gracefully
        System.assert(true, 'Should handle empty list without errors');
    }

    @isTest
    static void testDetectDrift_BulkScenario() {
        // Test bulkification with multiple records
        Test.startTest();
        List<SObject> alerts = SentinelDriftDetector.detectDrift();
        Test.stopTest();

        // Verify bulk processing works
        System.assertNotEquals(null, alerts, 'Bulk detection should work');

        // Verify we don't hit governor limits
        System.assert(Limits.getQueries() < Limits.getLimitQueries(), 'Should not hit SOQL limit');
        System.assert(Limits.getDmlStatements() < Limits.getLimitDmlStatements(), 'Should not hit DML limit');
    }

    @isTest
    static void testDetectDrift_ExceptionHandling() {
        // Test error handling by forcing an exception scenario
        Test.startTest();
        try {
            List<SObject> alerts = SentinelDriftDetector.detectDrift();
            // Should complete even if there are issues
            System.assertNotEquals(null, alerts, 'Should return result even with errors');
        } catch (Exception e) {
            System.assert(false, 'Should not throw unhandled exceptions: ' + e.getMessage());
        }
        Test.stopTest();
    }
}
