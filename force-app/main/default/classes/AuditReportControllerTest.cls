/**
 * AuditReportControllerTest
 * 
 * Test class for AuditReportController
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class AuditReportControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test gaps and evidence
        List<Compliance_Gap__c> gaps = ComplianceTestDataFactory.createComplianceGaps('SOX', 5);
        List<Compliance_Evidence__c> evidence = ComplianceTestDataFactory.createComplianceEvidence('SOX', 5);
        insert gaps;
        insert evidence;
    }
    
    @IsTest
    static void testGenerateAuditReport_Success() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        AuditReportController.AuditReport report = 
            AuditReportController.generateAuditReport('SOX', startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, report, 'Report should not be null');
        System.assertEquals('SOX', report.framework, 'Framework should match');
        System.assertNotEquals(null, report.evaluation, 'Evaluation should not be null');
        System.assertNotEquals(null, report.gaps, 'Gaps should not be null');
        System.assertNotEquals(null, report.evidence, 'Evidence should not be null');
    }
    
    @IsTest
    static void testGenerateAuditReport_BlankFramework() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        try {
            AuditReportController.generateAuditReport('', startDate, endDate);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateAuditReport_NullDates() {
        Test.startTest();
        try {
            AuditReportController.generateAuditReport('SOX', null, null);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for null dates');
        }
        Test.stopTest();
    }
}
