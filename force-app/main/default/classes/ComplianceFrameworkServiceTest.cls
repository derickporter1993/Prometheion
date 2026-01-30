/**
 * ComplianceFrameworkServiceTest
 * 
 * Test class for ComplianceFrameworkService
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
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
        
        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('SOX', result.framework, 'Framework should match');
        System.assertNotEquals(null, result.overallScore, 'Overall score should not be null');
        System.assertNotEquals(null, result.status, 'Status should not be null');
        System.assertNotEquals(null, result.totalPolicies, 'Total policies should not be null');
    }
    
    @IsTest
    static void testEvaluateFramework_BlankFramework() {
        Test.startTest();
        try {
            ComplianceFrameworkService.evaluateFramework('');
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testEvaluateFramework_NullFramework() {
        Test.startTest();
        try {
            ComplianceFrameworkService.evaluateFramework(null);
            System.assert(false, 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            System.assert(true, 'Expected exception for null framework');
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
        
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(frameworks.size(), results.size(), 'Should have results for all frameworks');
    }
    
    @IsTest
    static void testGetSupportedFrameworks() {
        Test.startTest();
        List<String> frameworks = ComplianceFrameworkService.getSupportedFrameworks();
        Test.stopTest();
        
        System.assertNotEquals(null, frameworks, 'Frameworks list should not be null');
        System.assert(!frameworks.isEmpty(), 'Should have at least one framework');
    }
}
