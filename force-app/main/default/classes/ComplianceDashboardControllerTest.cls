/**
 * ComplianceDashboardControllerTest
 * 
 * Test class for ComplianceDashboardController
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ComplianceDashboardController.class)
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
        
        Assert.areNotEqual(null, summary, 'Summary should not be null');
        Assert.areNotEqual(null, summary.lastUpdated, 'Last updated should not be null');
        Assert.areNotEqual(null, summary.frameworks, 'Frameworks should not be null');
    }
    
    @IsTest
    static void testGetFrameworkDashboard_Success() {
        Test.startTest();
        ComplianceDashboardController.FrameworkDashboardData data = 
            ComplianceDashboardController.getFrameworkDashboard('SOX');
        Test.stopTest();
        
        Assert.areNotEqual(null, data, 'Data should not be null');
        Assert.areEqual('SOX', data.framework, 'Framework should match');
        Assert.areNotEqual(null, data.evaluation, 'Evaluation should not be null');
        Assert.areNotEqual(null, data.gaps, 'Gaps should not be null');
        Assert.areNotEqual(null, data.evidence, 'Evidence should not be null');
    }
    
    @IsTest
    static void testGetFrameworkDashboard_BlankFramework() {
        Test.startTest();
        try {
            ComplianceDashboardController.getFrameworkDashboard('');
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('blank'), 'Exception should mention blank framework');
        }
        Test.stopTest();
    }
}
