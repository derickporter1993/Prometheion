/**
 * AnomalyDetectionServiceTest
 * 
 * Test class for AnomalyDetectionService
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class AnomalyDetectionServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create test metadata changes with varying risk levels
        List<Metadata_Change__c> changes = new List<Metadata_Change__c>();

        // Create CRITICAL risk changes to trigger anomaly detection
        for (Integer i = 0; i < 5; i++) {
            changes.add(new Metadata_Change__c(
                Metadata_Type__c = 'ApexClass',
                Metadata_Name__c = 'CriticalClass' + i,
                Change_Type__c = 'Modified',
                Risk_Level__c = 'CRITICAL',
                Change_Date__c = Date.today()
            ));
        }

        // Create non-critical changes
        for (Integer i = 0; i < 5; i++) {
            changes.add(new Metadata_Change__c(
                Metadata_Type__c = 'CustomField',
                Metadata_Name__c = 'Field' + i,
                Change_Type__c = 'Created',
                Risk_Level__c = 'LOW',
                Change_Date__c = Date.today()
            ));
        }

        insert changes;
    }

    @IsTest
    static void testDetectAnomalies_Success() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 30);
        Test.stopTest();

        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testDetectAnomalies_BlankFramework() {
        Test.startTest();
        try {
            AnomalyDetectionService.detectAnomalies('', 30);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetectAnomalies_NullFramework() {
        Test.startTest();
        try {
            AnomalyDetectionService.detectAnomalies(null, 30);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Framework is required'),
                'Exception should mention framework');
        }
        Test.stopTest();
    }

    @IsTest
    static void testDetectAnomalies_DefaultDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', null);
        Test.stopTest();

        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testDetectAnomalies_NegativeDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', -5);
        Test.stopTest();

        // Should default to 30 days when negative
        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testDetectAnomalies_ZeroDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 0);
        Test.stopTest();

        // Should default to 30 days when zero
        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testDetectAnomalies_CriticalChangesDetected() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 30);
        Test.stopTest();

        // Should detect the CRITICAL metadata changes
        Boolean foundCritical = false;
        for (AnomalyDetectionService.Anomaly a : anomalies) {
            if (a.type == 'HIGH_RISK_CHANGE' && a.severity == 'CRITICAL') {
                foundCritical = true;
                break;
            }
        }
        System.assertEquals(true, foundCritical, 'Should detect critical metadata changes');
    }

    @IsTest
    static void testDetectAnomalies_DifferentFrameworks() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> soxAnomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 30);
        List<AnomalyDetectionService.Anomaly> gdprAnomalies =
            AnomalyDetectionService.detectAnomalies('GDPR', 30);
        List<AnomalyDetectionService.Anomaly> hipaaAnomalies =
            AnomalyDetectionService.detectAnomalies('HIPAA', 30);
        Test.stopTest();

        System.assertNotEquals(null, soxAnomalies, 'SOX anomalies should not be null');
        System.assertNotEquals(null, gdprAnomalies, 'GDPR anomalies should not be null');
        System.assertNotEquals(null, hipaaAnomalies, 'HIPAA anomalies should not be null');
    }

    @IsTest
    static void testDetectAnomalies_LargeDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 365);
        Test.stopTest();

        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testAnomalyClass_Properties() {
        Test.startTest();
        AnomalyDetectionService.Anomaly anomaly = new AnomalyDetectionService.Anomaly();
        anomaly.type = 'TEST_TYPE';
        anomaly.severity = 'HIGH';
        anomaly.description = 'Test description';
        anomaly.entityId = '001000000000000AAA';
        Test.stopTest();

        System.assertEquals('TEST_TYPE', anomaly.type, 'Type should match');
        System.assertEquals('HIGH', anomaly.severity, 'Severity should match');
        System.assertEquals('Test description', anomaly.description, 'Description should match');
        System.assertEquals('001000000000000AAA', anomaly.entityId, 'EntityId should match');
        System.assertNotEquals(null, anomaly.detectedDate, 'DetectedDate should be set');
    }

    @IsTest
    static void testAnomalyClass_DefaultDetectedDate() {
        Test.startTest();
        Datetime beforeCreate = System.now();
        AnomalyDetectionService.Anomaly anomaly = new AnomalyDetectionService.Anomaly();
        Datetime afterCreate = System.now();
        Test.stopTest();

        System.assert(anomaly.detectedDate >= beforeCreate, 'DetectedDate should be at or after test start');
        System.assert(anomaly.detectedDate <= afterCreate, 'DetectedDate should be at or before test end');
    }

    @IsTest
    static void testDetectAnomalies_SmallDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 1);
        Test.stopTest();

        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }

    @IsTest
    static void testDetectAnomalies_VerifyAnomalyDetails() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies =
            AnomalyDetectionService.detectAnomalies('SOX', 30);
        Test.stopTest();

        for (AnomalyDetectionService.Anomaly anomaly : anomalies) {
            if (anomaly.type == 'HIGH_RISK_CHANGE') {
                System.assertNotEquals(null, anomaly.description, 'Description should not be null');
                System.assertNotEquals(null, anomaly.entityId, 'EntityId should not be null');
                System.assertEquals('CRITICAL', anomaly.severity, 'Severity should be CRITICAL');
            }
        }
    }
}
