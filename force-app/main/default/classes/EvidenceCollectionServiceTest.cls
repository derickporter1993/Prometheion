/**
 * EvidenceCollectionServiceTest
 * 
 * Test class for EvidenceCollectionService
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class EvidenceCollectionServiceTest {
    
    @IsTest
    static void testCollectEvidence_Success() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        List<Compliance_Evidence__c> evidence = 
            EvidenceCollectionService.collectEvidence('SOX', startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, evidence, 'Evidence list should not be null');
        System.assert(evidence.size() > 0, 'Should have collected evidence');
        
        // Verify evidence was inserted
        List<Compliance_Evidence__c> insertedEvidence = [
            SELECT Id, Framework__c, Evidence_Type__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = 'SOX'
            WITH SECURITY_ENFORCED
        ];
        System.assert(insertedEvidence.size() > 0, 'Evidence should be inserted');
    }
    
    @IsTest
    static void testCollectEvidence_BlankFramework() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        try {
            EvidenceCollectionService.collectEvidence('', startDate, endDate);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCollectEvidence_NullDates() {
        Test.startTest();
        try {
            EvidenceCollectionService.collectEvidence('SOX', null, null);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for null dates');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCollectEvidence_InvalidDateRange() {
        Date startDate = System.today();
        Date endDate = System.today().addDays(-30);
        
        Test.startTest();
        try {
            EvidenceCollectionService.collectEvidence('SOX', startDate, endDate);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for invalid date range');
        }
        Test.stopTest();
    }
}
