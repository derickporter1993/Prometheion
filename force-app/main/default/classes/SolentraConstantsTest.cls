/**
 * SolentraConstantsTest - Test class for SolentraConstants
 * 
 * @author Solentra
 * @version 1.0
 */
@IsTest
private class SolentraConstantsTest {
    
    @IsTest
    static void testFrameworkConstants() {
        // Verify all framework constants are defined
        System.assertEquals('HIPAA', SolentraConstants.FRAMEWORK_HIPAA, 'HIPAA framework constant should be defined');
        System.assertEquals('SOC2', SolentraConstants.FRAMEWORK_SOC2, 'SOC2 framework constant should be defined');
        System.assertEquals('NIST', SolentraConstants.FRAMEWORK_NIST, 'NIST framework constant should be defined');
        System.assertEquals('FedRAMP', SolentraConstants.FRAMEWORK_FEDRAMP, 'FedRAMP framework constant should be defined');
        System.assertEquals('GDPR', SolentraConstants.FRAMEWORK_GDPR, 'GDPR framework constant should be defined');
        System.assertEquals('SOX', SolentraConstants.FRAMEWORK_SOX, 'SOX framework constant should be defined');
        System.assertEquals('PCI_DSS', SolentraConstants.FRAMEWORK_PCI_DSS, 'PCI_DSS framework constant should be defined');
        
        // Verify ALL_FRAMEWORKS contains all frameworks
        System.assertEquals(7, SolentraConstants.ALL_FRAMEWORKS.size(), 'ALL_FRAMEWORKS should contain 7 frameworks');
        System.assert(SolentraConstants.ALL_FRAMEWORKS.contains('HIPAA'), 'ALL_FRAMEWORKS should contain HIPAA');
        System.assert(SolentraConstants.ALL_FRAMEWORKS.contains('SOC2'), 'ALL_FRAMEWORKS should contain SOC2');
    }
    
    @IsTest
    static void testSeverityConstants() {
        System.assertEquals('CRITICAL', SolentraConstants.SEVERITY_CRITICAL, 'CRITICAL severity should be defined');
        System.assertEquals('HIGH', SolentraConstants.SEVERITY_HIGH, 'HIGH severity should be defined');
        System.assertEquals('MEDIUM', SolentraConstants.SEVERITY_MEDIUM, 'MEDIUM severity should be defined');
        System.assertEquals('LOW', SolentraConstants.SEVERITY_LOW, 'LOW severity should be defined');
    }
    
    @IsTest
    static void testRiskThresholds() {
        System.assertEquals(9.0, SolentraConstants.RISK_THRESHOLD_CRITICAL, 'Critical threshold should be 9.0');
        System.assertEquals(7.0, SolentraConstants.RISK_THRESHOLD_HIGH, 'High threshold should be 7.0');
        System.assertEquals(5.0, SolentraConstants.RISK_THRESHOLD_MEDIUM, 'Medium threshold should be 5.0');
        System.assertEquals(3.0, SolentraConstants.RISK_THRESHOLD_LOW, 'Low threshold should be 3.0');
        System.assertEquals(10.0, SolentraConstants.RISK_SCORE_MAX, 'Max risk score should be 10.0');
    }
    
    @IsTest
    static void testScoreThresholds() {
        System.assertEquals(90, SolentraConstants.SCORE_THRESHOLD_EXCELLENT, 'Excellent threshold should be 90');
        System.assertEquals(80, SolentraConstants.SCORE_THRESHOLD_GOOD, 'Good threshold should be 80');
        System.assertEquals(70, SolentraConstants.SCORE_THRESHOLD_FAIR, 'Fair threshold should be 70');
        System.assertEquals(50, SolentraConstants.SCORE_THRESHOLD_NEEDS_IMPROVEMENT, 'Needs improvement threshold should be 50');
    }
    
    @IsTest
    static void testGetSeverityFromRiskScore() {
        // Test null
        System.assertEquals('LOW', SolentraConstants.getSeverityFromRiskScore(null), 'Null should return LOW');
        
        // Test critical
        System.assertEquals('CRITICAL', SolentraConstants.getSeverityFromRiskScore(9.5), '9.5 should be CRITICAL');
        System.assertEquals('CRITICAL', SolentraConstants.getSeverityFromRiskScore(10.0), '10.0 should be CRITICAL');
        
        // Test high
        System.assertEquals('HIGH', SolentraConstants.getSeverityFromRiskScore(7.0), '7.0 should be HIGH');
        System.assertEquals('HIGH', SolentraConstants.getSeverityFromRiskScore(8.9), '8.9 should be HIGH');
        
        // Test medium
        System.assertEquals('MEDIUM', SolentraConstants.getSeverityFromRiskScore(5.0), '5.0 should be MEDIUM');
        System.assertEquals('MEDIUM', SolentraConstants.getSeverityFromRiskScore(6.9), '6.9 should be MEDIUM');
        
        // Test low
        System.assertEquals('LOW', SolentraConstants.getSeverityFromRiskScore(0.0), '0.0 should be LOW');
        System.assertEquals('LOW', SolentraConstants.getSeverityFromRiskScore(4.9), '4.9 should be LOW');
    }
    
    @IsTest
    static void testGetRatingFromScore() {
        // Test null
        System.assertEquals('CRITICAL', SolentraConstants.getRatingFromScore(null), 'Null should return CRITICAL');
        
        // Test excellent
        System.assertEquals('EXCELLENT', SolentraConstants.getRatingFromScore(95), '95 should be EXCELLENT');
        System.assertEquals('EXCELLENT', SolentraConstants.getRatingFromScore(90), '90 should be EXCELLENT');
        
        // Test good
        System.assertEquals('GOOD', SolentraConstants.getRatingFromScore(85), '85 should be GOOD');
        System.assertEquals('GOOD', SolentraConstants.getRatingFromScore(80), '80 should be GOOD');
        
        // Test fair
        System.assertEquals('FAIR', SolentraConstants.getRatingFromScore(75), '75 should be FAIR');
        System.assertEquals('FAIR', SolentraConstants.getRatingFromScore(70), '70 should be FAIR');
        
        // Test needs improvement
        System.assertEquals('NEEDS_IMPROVEMENT', SolentraConstants.getRatingFromScore(60), '60 should be NEEDS_IMPROVEMENT');
        System.assertEquals('NEEDS_IMPROVEMENT', SolentraConstants.getRatingFromScore(50), '50 should be NEEDS_IMPROVEMENT');
        
        // Test critical
        System.assertEquals('CRITICAL', SolentraConstants.getRatingFromScore(40), '40 should be CRITICAL');
        System.assertEquals('CRITICAL', SolentraConstants.getRatingFromScore(0), '0 should be CRITICAL');
    }
    
    @IsTest
    static void testGetScoreEmoji() {
        System.assertEquals('🔴', SolentraConstants.getScoreEmoji(null), 'Null should return red');
        System.assertEquals('🟢', SolentraConstants.getScoreEmoji(95), '95 should return green');
        System.assertEquals('🟡', SolentraConstants.getScoreEmoji(85), '85 should return yellow');
        System.assertEquals('🟠', SolentraConstants.getScoreEmoji(75), '75 should return orange');
        System.assertEquals('🔴', SolentraConstants.getScoreEmoji(50), '50 should return red');
    }
    
    @IsTest
    static void testGetScoreColor() {
        System.assertEquals('#e74c3c', SolentraConstants.getScoreColor(null), 'Null should return red hex');
        System.assertEquals('#2ecc71', SolentraConstants.getScoreColor(95), '95 should return green hex');
        System.assertEquals('#f39c12', SolentraConstants.getScoreColor(85), '85 should return yellow hex');
        System.assertEquals('#e67e22', SolentraConstants.getScoreColor(75), '75 should return orange hex');
        System.assertEquals('#e74c3c', SolentraConstants.getScoreColor(50), '50 should return red hex');
    }
    
    @IsTest
    static void testIsValidFramework() {
        // Valid frameworks
        System.assert(SolentraConstants.isValidFramework('HIPAA'), 'HIPAA should be valid');
        System.assert(SolentraConstants.isValidFramework('hipaa'), 'hipaa (lowercase) should be valid');
        System.assert(SolentraConstants.isValidFramework('SOC2'), 'SOC2 should be valid');
        System.assert(SolentraConstants.isValidFramework('NIST'), 'NIST should be valid');
        System.assert(SolentraConstants.isValidFramework('FedRAMP'), 'FedRAMP should be valid');
        System.assert(SolentraConstants.isValidFramework('GDPR'), 'GDPR should be valid');
        
        // Invalid frameworks
        System.assert(!SolentraConstants.isValidFramework(null), 'Null should be invalid');
        System.assert(!SolentraConstants.isValidFramework(''), 'Empty string should be invalid');
        System.assert(!SolentraConstants.isValidFramework('INVALID'), 'INVALID should be invalid');
    }
    
    @IsTest
    static void testEntityTypeConstants() {
        System.assertEquals('PERMISSION_SET', SolentraConstants.ENTITY_PERMISSION_SET);
        System.assertEquals('PROFILE', SolentraConstants.ENTITY_PROFILE);
        System.assertEquals('FLOW', SolentraConstants.ENTITY_FLOW);
        System.assertEquals('FIELD', SolentraConstants.ENTITY_FIELD);
        System.assertEquals('ENCRYPTION', SolentraConstants.ENTITY_ENCRYPTION);
    }
    
    @IsTest
    static void testDriftCategoryConstants() {
        System.assertEquals('POLICY_VIOLATION', SolentraConstants.DRIFT_POLICY_VIOLATION);
        System.assertEquals('AUTO_REMEDIATED', SolentraConstants.DRIFT_AUTO_REMEDIATED);
        System.assertEquals('HUMAN_APPROVED', SolentraConstants.DRIFT_HUMAN_APPROVED);
        System.assertEquals('PENDING_REVIEW', SolentraConstants.DRIFT_PENDING_REVIEW);
    }
    
    @IsTest
    static void testQueryTypeConstants() {
        System.assertEquals('SCORE_CHANGE', SolentraConstants.QUERY_SCORE_CHANGE);
        System.assertEquals('VIOLATION_SEARCH', SolentraConstants.QUERY_VIOLATION_SEARCH);
        System.assertEquals('EVIDENCE_REQUEST', SolentraConstants.QUERY_EVIDENCE_REQUEST);
        System.assertEquals('RISKY_FLOWS', SolentraConstants.QUERY_RISKY_FLOWS);
        System.assertEquals('USER_ACCESS', SolentraConstants.QUERY_USER_ACCESS);
        System.assertEquals('FRAMEWORK_STATUS', SolentraConstants.QUERY_FRAMEWORK_STATUS);
        System.assertEquals('GENERAL', SolentraConstants.QUERY_GENERAL);
    }
    
    @IsTest
    static void testVersionAndLogging() {
        System.assertEquals('64.0', SolentraConstants.SALESFORCE_API_VERSION);
        System.assertEquals('1.0.0', SolentraConstants.SOLENTRA_VERSION);
        System.assertEquals('[Solentra] ', SolentraConstants.LOG_PREFIX);
    }
}

