/**
 * ComplianceFrameworkServiceTest
 * 
 * Test class for ComplianceFrameworkService
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ComplianceFrameworkService.class)
private class ComplianceFrameworkServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test compliance gaps for SOX framework
        List<Compliance_Gap__c> gaps = ComplianceTestDataFactory.createComplianceGaps('SOX', 5);
        insert gaps;
    }
    
    @IsTest
    static void testEvaluateFramework_Success() {
        Test.startTest();
        ComplianceFrameworkService.FrameworkEvaluationResult result = 
            ComplianceFrameworkService.evaluateFramework('SOX');
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('SOX', result.framework, 'Framework should match');
        Assert.areNotEqual(null, result.overallScore, 'Overall score should not be null');
        Assert.areNotEqual(null, result.status, 'Status should not be null');
        Assert.areNotEqual(null, result.totalPolicies, 'Total policies should not be null');
    }
    
    @IsTest
    static void testEvaluateFramework_BlankFramework() {
        Test.startTest();
        try {
            ComplianceFrameworkService.evaluateFramework('');
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('blank'), 'Exception should mention blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEvaluateFramework_NullFramework() {
        Test.startTest();
        try {
            ComplianceFrameworkService.evaluateFramework(null);
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isTrue(e.getMessage().contains('blank'), 'Exception should mention blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEvaluateMultipleFrameworks() {
        List<String> frameworks = new List<String>{'SOX', 'SOC2'};
        
        Test.startTest();
        Map<String, ComplianceFrameworkService.FrameworkEvaluationResult> results = 
            ComplianceFrameworkService.evaluateMultipleFrameworks(frameworks);
        Test.stopTest();
        
        Assert.areNotEqual(null, results, 'Results should not be null');
        Assert.areEqual(frameworks.size(), results.size(), 'Should have results for all frameworks');
    }
    
    @IsTest
    static void testGetSupportedFrameworks() {
        Test.startTest();
        List<String> frameworks = ComplianceFrameworkService.getSupportedFrameworks();
        Test.stopTest();
        
        Assert.areNotEqual(null, frameworks, 'Frameworks list should not be null');
        Assert.isTrue(!frameworks.isEmpty(), 'Should have at least one framework');
    }
}
