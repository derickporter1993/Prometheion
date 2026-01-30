/**
 * Test class for ElaroPCIDSSComplianceService
 */
@IsTest
private class ElaroPCIDSSComplianceServiceTest {
    
    @IsTest
    static void testCalculateRiskScore_Field() {
        // Given: Field metadata (cardholder data)
        Map<String, Object> metadata = new Map<String, Object>{
            'fieldType' => 'CreditCard'
        };
        
        Test.startTest();
        ElaroPCIDSSComplianceService service = new ElaroPCIDSSComplianceService();
        Decimal score = service.calculateRiskScore('FIELD', 'test123', metadata);
        Test.stopTest();
        
        // Then: Should calculate risk score
        System.assertNotEquals(null, score, 'Risk score should not be null');
        System.assert(score >= 0 && score <= 10, 'Risk score should be between 0 and 10');
        System.assert(score > 3.0, 'Cardholder data fields should have higher risk');
    }
    
    @IsTest
    static void testGetComplianceScore() {
        Test.startTest();
        ElaroPCIDSSComplianceService service = new ElaroPCIDSSComplianceService();
        Decimal score = service.getComplianceScore();
        Test.stopTest();
        
        // Then: Should return compliance score
        System.assertNotEquals(null, score, 'Compliance score should not be null');
    }
    
    @IsTest
    static void testGetViolations() {
        Test.startTest();
        ElaroPCIDSSComplianceService service = new ElaroPCIDSSComplianceService();
        List<Violation> violations = service.getViolations();
        Test.stopTest();
        
        // Then: Should return violations list (may be empty)
        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testGetFrameworkName() {
        Test.startTest();
        ElaroPCIDSSComplianceService service = new ElaroPCIDSSComplianceService();
        String framework = service.getFrameworkName();
        Test.stopTest();
        
        // Then: Should return PCI-DSS framework name (note: constant uses PCI_DSS with underscore)
        System.assertEquals('PCI_DSS', framework, 'Should return PCI_DSS framework name');
    }
}
