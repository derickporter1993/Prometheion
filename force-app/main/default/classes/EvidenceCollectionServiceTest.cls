/**
 * EvidenceCollectionServiceTest
 * 
 * Test class for EvidenceCollectionService
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=EvidenceCollectionService.class)
private class EvidenceCollectionServiceTest {
    
    @IsTest
    static void testCollectEvidence_Success() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        List<Compliance_Evidence__c> evidence = 
            EvidenceCollectionService.collectEvidence('SOX', startDate, endDate);
        Test.stopTest();
        
        Assert.areNotEqual(null, evidence, 'Evidence list should not be null');
        Assert.isTrue(!evidence.isEmpty(), 'Should have collected evidence');
        
        // Verify evidence was inserted
        List<Compliance_Evidence__c> insertedEvidence = [
            SELECT Id, Framework__c, Evidence_Type__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = 'SOX'
            WITH USER_MODE
        ];
        Assert.isTrue(!insertedEvidence.isEmpty(), 'Evidence should be inserted');
    }
    
    @IsTest
    static void testCollectEvidence_BlankFramework() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        try {
            EvidenceCollectionService.collectEvidence('', startDate, endDate);
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for blank framework should have a message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCollectEvidence_NullDates() {
        Test.startTest();
        try {
            EvidenceCollectionService.collectEvidence('SOX', null, null);
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for null dates should have a message');
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
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for invalid date range should have a message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testCollectEvidence_BulkMultipleFrameworks() {
        // Test evidence collection across all supported frameworks
        List<String> frameworks = new List<String>{
            'HIPAA', 'SOC2', 'NIST', 'FedRAMP', 'GDPR', 
            'SOX', 'PCI_DSS', 'CCPA', 'GLBA', 'ISO27001'
        };
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        List<Compliance_Evidence__c> allEvidence = new List<Compliance_Evidence__c>();
        for (String framework : frameworks) {
            List<Compliance_Evidence__c> evidence = 
                EvidenceCollectionService.collectEvidence(framework, startDate, endDate);
            allEvidence.addAll(evidence);
        }
        Test.stopTest();
        
        Assert.isTrue(!allEvidence.isEmpty(), 'Should collect evidence for all frameworks');
        
        // Verify evidence was inserted for each framework
        Integer totalEvidenceCount = [
            SELECT COUNT() FROM Compliance_Evidence__c
        ];
        Assert.isTrue(totalEvidenceCount >= frameworks.size(), 
            'Should have at least one evidence record per framework');
    }
    
    @IsTest
    static void testCollectEvidence_LargeDateRange() {
        // Test with a large date range (6 months)
        Date startDate = System.today().addMonths(-6);
        Date endDate = System.today();

        Test.startTest();
        List<Compliance_Evidence__c> evidence =
            EvidenceCollectionService.collectEvidence('HIPAA', startDate, endDate);
        Test.stopTest();

        Assert.areNotEqual(null, evidence, 'Evidence list should not be null');
        Assert.isTrue(!evidence.isEmpty(), 'Should collect evidence for large date range');
    }

    @IsTest
    static void testCollectEvidence_Bulk200Records() {
        // Test processing 200+ evidence records to verify governor limit handling
        // Pre-create accounts to have related audit history
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Test Account ' + i));
        }
        insert accounts;

        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();

        Test.startTest();
        // Collect evidence - should handle bulk operations without governor limit issues
        List<Compliance_Evidence__c> evidence =
            EvidenceCollectionService.collectEvidence('SOC2', startDate, endDate);
        Test.stopTest();

        Assert.areNotEqual(null, evidence, 'Evidence list should not be null');

        // Verify governor limits were not exceeded
        Assert.isTrue(Limits.getQueries() < 100,
            'SOQL queries should be within limits: ' + Limits.getQueries());
        Assert.isTrue(Limits.getDmlStatements() < 150,
            'DML statements should be within limits: ' + Limits.getDmlStatements());
    }

    @IsTest
    static void testCollectEvidence_BulkInsertVerification() {
        // Test that bulk evidence collection properly inserts records
        Date startDate = System.today().addDays(-90);
        Date endDate = System.today();

        // Run evidence collection for multiple frameworks sequentially
        Test.startTest();
        Integer totalEvidence = 0;
        for (String framework : new List<String>{'SOC2', 'HIPAA', 'GDPR', 'NIST', 'PCI_DSS'}) {
            List<Compliance_Evidence__c> evidence =
                EvidenceCollectionService.collectEvidence(framework, startDate, endDate);
            totalEvidence += evidence.size();
        }
        Test.stopTest();

        // Verify all evidence records were created
        Integer insertedCount = [SELECT COUNT() FROM Compliance_Evidence__c];
        Assert.areEqual(totalEvidence, insertedCount,
            'All evidence records should be inserted');
    }
}
