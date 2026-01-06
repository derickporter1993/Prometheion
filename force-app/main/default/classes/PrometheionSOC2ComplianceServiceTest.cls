/**
 * Test class for PrometheionSOC2ComplianceService
 */
@IsTest
private class PrometheionSOC2ComplianceServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test permission set
        PermissionSet ps = new PermissionSet(
            Name='SOC2_Test_PS',
            Label='SOC2 Test Permission Set',
            Description='Test permission set for SOC2 compliance'
        );
        insert ps;
    }
    
    @IsTest
    static void testCalculateRiskScore_PermissionSet() {
        // Given: Permission set metadata
        Map<String, Object> metadata = new Map<String, Object>{
            'objectPermissionCount' => 50
        };
        
        Test.startTest();
        PrometheionSOC2ComplianceService service = new PrometheionSOC2ComplianceService();
        Decimal score = service.calculateRiskScore('PERMISSION_SET', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        PrometheionSOC2ComplianceService service = new PrometheionSOC2ComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        PrometheionSOC2ComplianceService service = new PrometheionSOC2ComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        PrometheionSOC2ComplianceService service = new PrometheionSOC2ComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return SOC2 framework name
        System.assertEquals('SOC2', framework, 'Should return SOC2 framework name');
    }
}
