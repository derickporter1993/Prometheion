/**
 * AuditReportControllerTest
 * 
 * Test class for AuditReportController
 * 
 * @author Elaro
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
        
        Assert.areNotEqual(null, report, 'Report should not be null');
        Assert.areEqual('SOX', report.framework, 'Framework should match');
        Assert.areNotEqual(null, report.evaluation, 'Evaluation should not be null');
        Assert.areNotEqual(null, report.gaps, 'Gaps should not be null');
        Assert.areNotEqual(null, report.evidence, 'Evidence should not be null');
    }
    
    @IsTest
    static void testGenerateAuditReport_BlankFramework() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();
        
        Test.startTest();
        try {
            AuditReportController.generateAuditReport('', startDate, endDate);
            Assert.fail('Expected IllegalArgumentException for blank framework');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('framework') || e.getMessage().containsIgnoreCase('required') || e.getMessage().containsIgnoreCase('blank'),
                'Should have descriptive error message, got: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testGenerateAuditReport_NullDates() {
        Test.startTest();
        try {
            AuditReportController.generateAuditReport('SOX', null, null);
            Assert.fail('Expected IllegalArgumentException for null dates');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().containsIgnoreCase('date') || e.getMessage().containsIgnoreCase('required') || e.getMessage().containsIgnoreCase('null'),
                'Should have descriptive error message, got: ' + e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    static void testExportReportAsPDF_NullReport() {
        Test.startTest();
        try {
            AuditReportController.exportReportAsPDF(null);
            Assert.fail( 'Expected exception for null report');
        } catch (Exception e) {
            Assert.areNotEqual(null, e, 'Should throw exception for null report');
        }
        Test.stopTest();
    }

    @IsTest
    static void testExportReportAsPDF_ValidReport() {
        Date startDate = System.today().addDays(-30);
        Date endDate = System.today();

        Test.startTest();
        AuditReportController.AuditReport report =
            AuditReportController.generateAuditReport('SOX', startDate, endDate);
        String result = AuditReportController.exportReportAsPDF(report);
        Test.stopTest();

        Assert.areNotEqual(null, result, 'PDF result should not be null');
    }
}
