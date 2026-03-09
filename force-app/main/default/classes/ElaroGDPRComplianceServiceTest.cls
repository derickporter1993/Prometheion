/**
 * Test class for ElaroGDPRComplianceService
 */
@IsTest
private class ElaroGDPRComplianceServiceTest {
    
    @IsTest
    static void testCalculateRiskScore_Field() {
        // Given: Field metadata (personal data)
        Map<String, Object> metadata = new Map<String, Object>{
            'fieldType' => 'Email'
        };
        
        Test.startTest();
        ElaroGDPRComplianceService service = new ElaroGDPRComplianceService();
        Decimal score = service.calculateRiskScore('FIELD', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        Assert.areNotEqual(null, score, 'Risk score should not be null');
        Assert.isTrue(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
        Assert.isTrue(score > 3.0, 'Personal data fields should have higher risk');
    }
    
    @IsTest
    static void testCalculateRiskScore_OtherEntity() {
        // Given: Non-field entity
        Map<String, Object> metadata = new Map<String, Object>();
        
        Test.startTest();
        ElaroGDPRComplianceService service = new ElaroGDPRComplianceService();
        Decimal score = service.calculateRiskScore('PERMISSION_SET', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should return base risk score
        Assert.isTrue(score >= 3.0 && score <= 10, 'Should return base or calculated risk score');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        ElaroGDPRComplianceService service = new ElaroGDPRComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        Assert.areNotEqual(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        ElaroGDPRComplianceService service = new ElaroGDPRComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        Assert.areNotEqual(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        ElaroGDPRComplianceService service = new ElaroGDPRComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return GDPR framework name
        Assert.areEqual('GDPR', framework, 'Should return GDPR framework name');
    }
}
