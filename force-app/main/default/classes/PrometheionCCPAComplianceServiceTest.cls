/**
 * Test class for PrometheionCCPAComplianceService
 */
@IsTest
private class PrometheionCCPAComplianceServiceTest {
    
    @IsTest
    static void testCalculateRiskScore() {
        // Given: Entity metadata
        Map<String, Object> metadata = new Map<String, Object>{
            'entityType' => 'CONTACT'
        };
        
        Test.startTest();
        PrometheionCCPAComplianceService service = new PrometheionCCPAComplianceService();
        Decimal score = service.calculateRiskScore('CONTACT', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        PrometheionCCPAComplianceService service = new PrometheionCCPAComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        PrometheionCCPAComplianceService service = new PrometheionCCPAComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        PrometheionCCPAComplianceService service = new PrometheionCCPAComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return CCPA framework name
        System.assertEquals('CCPA', framework, 'Should return CCPA framework name');
    }
}
