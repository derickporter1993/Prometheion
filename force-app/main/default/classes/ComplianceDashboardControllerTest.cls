/**
 * ComplianceDashboardControllerTest
 * 
 * Test class for ComplianceDashboardController
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class ComplianceDashboardControllerTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test gaps and evidence
        List<Compliance_Gap__c> gaps = ComplianceTestDataFactory.createComplianceGaps('SOX', 3);
        List<Compliance_Evidence__c> evidence = ComplianceTestDataFactory.createComplianceEvidence('SOX', 3);
        insert gaps;
        insert evidence;
    }
    
    @IsTest
    static void testGetDashboardSummary() {
        Test.startTest();
        ComplianceDashboardController.DashboardSummary summary = 
            ComplianceDashboardController.getDashboardSummary();
        Test.stopTest();
        
        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assertNotEquals(null, summary.lastUpdated, 'Last updated should not be null');
        System.assertNotEquals(null, summary.frameworks, 'Frameworks should not be null');
    }
    
    @IsTest
    static void testGetFrameworkDashboard_Success() {
        Test.startTest();
        ComplianceDashboardController.FrameworkDashboardData data = 
            ComplianceDashboardController.getFrameworkDashboard('SOX');
        Test.stopTest();
        
        System.assertNotEquals(null, data, 'Data should not be null');
        System.assertEquals('SOX', data.framework, 'Framework should match');
        System.assertNotEquals(null, data.evaluation, 'Evaluation should not be null');
        System.assertNotEquals(null, data.gaps, 'Gaps should not be null');
        System.assertNotEquals(null, data.evidence, 'Evidence should not be null');
    }
    
    @IsTest
    static void testGetFrameworkDashboard_BlankFramework() {
        Test.startTest();
        try {
            ComplianceDashboardController.getFrameworkDashboard('');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        Test.stopTest();
    }
}
