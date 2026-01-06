/**
 * AnomalyDetectionServiceTest
 * 
 * Test class for AnomalyDetectionService
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class AnomalyDetectionServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test metadata changes
        List<Metadata_Change__c> changes = ComplianceTestDataFactory.createMetadataChanges(10);
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
    static void testDetectAnomalies_DefaultDaysBack() {
        Test.startTest();
        List<AnomalyDetectionService.Anomaly> anomalies = 
            AnomalyDetectionService.detectAnomalies('SOX', null);
        Test.stopTest();
        
        System.assertNotEquals(null, anomalies, 'Anomalies list should not be null');
    }
}
