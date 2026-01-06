/**
 * Test class for PrometheionHIPAAComplianceService
 */
@IsTest
private class PrometheionHIPAAComplianceServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test permission set
        PermissionSet ps = new PermissionSet(
            Name='HIPAA_Test_PS',
            Label='HIPAA Test Permission Set',
            Description='Test permission set for HIPAA compliance'
        );
        insert ps;
    }
    
    @IsTest
    static void testCalculateRiskScore_PermissionSet() {
        // Given: Permission set metadata
        Map<String, Object> metadata = new Map<String, Object>{
            'objectPermissionCount' => 60
        };
        
        Test.startTest();
        PrometheionHIPAAComplianceService service = new PrometheionHIPAAComplianceService();
        Decimal score = service.calculateRiskScore('PERMISSION_SET', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
        System.assert(score > 3.0, 'High permission count should increase risk score');
    }
    
    @IsTest
    static void testCalculateRiskScore_LowRisk() {
        // Given: Permission set with low permission count
        Map<String, Object> metadata = new Map<String, Object>{
            'objectPermissionCount' => 10
        };
        
        Test.startTest();
        PrometheionHIPAAComplianceService service = new PrometheionHIPAAComplianceService();
        Decimal score = service.calculateRiskScore('PERMISSION_SET', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should have lower risk score
        System.assert(score <= 5.0, 'Low permission count should result in lower risk');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        PrometheionHIPAAComplianceService service = new PrometheionHIPAAComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        PrometheionHIPAAComplianceService service = new PrometheionHIPAAComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        PrometheionHIPAAComplianceService service = new PrometheionHIPAAComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return HIPAA framework name
        System.assertEquals('HIPAA', framework, 'Should return HIPAA framework name');
    }
}
