/**
 * Test class for ElaroCCPAComplianceService
 */
@IsTest
private class ElaroCCPAComplianceServiceTest {
    
    @IsTest
    static void testCalculateRiskScore() {
        // Given: Entity metadata
        Map<String, Object> metadata = new Map<String, Object>{
            'entityType' => 'CONTACT'
        };
        
        Test.startTest();
        ElaroCCPAComplianceService service = new ElaroCCPAComplianceService();
        Decimal score = service.calculateRiskScore('CONTACT', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        ElaroCCPAComplianceService service = new ElaroCCPAComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        ElaroCCPAComplianceService service = new ElaroCCPAComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        ElaroCCPAComplianceService service = new ElaroCCPAComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return CCPA framework name
        System.assertEquals('CCPA', framework, 'Should return CCPA framework name');
    }
}
