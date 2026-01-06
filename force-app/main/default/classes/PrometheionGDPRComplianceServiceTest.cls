/**
 * Test class for PrometheionGDPRComplianceService
 */
@IsTest
private class PrometheionGDPRComplianceServiceTest {
    
    @IsTest
    static void testCalculateRiskScore_Field() {
        // Given: Field metadata (personal data)
        Map<String, Object> metadata = new Map<String, Object>{
            'fieldType' => 'Email'
        };
        
        Test.startTest();
        PrometheionGDPRComplianceService service = new PrometheionGDPRComplianceService();
        Decimal score = service.calculateRiskScore('FIELD', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
        System.assert(score > 3.0, 'Personal data fields should have higher risk');
    }
    
    @IsTest
    static void testCalculateRiskScore_OtherEntity() {
        // Given: Non-field entity
        Map<String, Object> metadata = new Map<String, Object>();
        
        Test.startTest();
        PrometheionGDPRComplianceService service = new PrometheionGDPRComplianceService();
        Decimal score = service.calculateRiskScore('PERMISSION_SET', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should return base risk score
        System.assert(score >= 3.0 && score <= 10, 'Should return base or calculated risk score');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        PrometheionGDPRComplianceService service = new PrometheionGDPRComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        PrometheionGDPRComplianceService service = new PrometheionGDPRComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        PrometheionGDPRComplianceService service = new PrometheionGDPRComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return GDPR framework name
        System.assertEquals('GDPR', framework, 'Should return GDPR framework name');
    }
}
