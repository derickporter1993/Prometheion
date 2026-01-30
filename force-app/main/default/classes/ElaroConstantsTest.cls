/**
 * ElaroConstantsTest - Test class for ElaroConstants
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ElaroConstantsTest {
    
    @IsTest
    static void testFrameworkConstants() {
        // Verify all framework constants are defined
        System.assertEquals('HIPAA', ElaroConstants.FRAMEWORK_HIPAA, 'HIPAA framework constant should be defined');
        System.assertEquals('SOC2', ElaroConstants.FRAMEWORK_SOC2, 'SOC2 framework constant should be defined');
        System.assertEquals('NIST', ElaroConstants.FRAMEWORK_NIST, 'NIST framework constant should be defined');
        System.assertEquals('FedRAMP', ElaroConstants.FRAMEWORK_FEDRAMP, 'FedRAMP framework constant should be defined');
        System.assertEquals('GDPR', ElaroConstants.FRAMEWORK_GDPR, 'GDPR framework constant should be defined');
        System.assertEquals('SOX', ElaroConstants.FRAMEWORK_SOX, 'SOX framework constant should be defined');
        System.assertEquals('PCI_DSS', ElaroConstants.FRAMEWORK_PCI_DSS, 'PCI_DSS framework constant should be defined');
        
        // Verify ALL_FRAMEWORKS contains all frameworks (10 total: HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO27001)
        System.assertEquals(10, ElaroConstants.ALL_FRAMEWORKS.size(), 'ALL_FRAMEWORKS should contain 10 frameworks');
        System.assert(ElaroConstants.ALL_FRAMEWORKS.contains('HIPAA'), 'ALL_FRAMEWORKS should contain HIPAA');
        System.assert(ElaroConstants.ALL_FRAMEWORKS.contains('SOC2'), 'ALL_FRAMEWORKS should contain SOC2');
    }
    
    @IsTest
    static void testSeverityConstants() {
        System.assertEquals('CRITICAL', ElaroConstants.SEVERITY_CRITICAL, 'CRITICAL severity should be defined');
        System.assertEquals('HIGH', ElaroConstants.SEVERITY_HIGH, 'HIGH severity should be defined');
        System.assertEquals('MEDIUM', ElaroConstants.SEVERITY_MEDIUM, 'MEDIUM severity should be defined');
        System.assertEquals('LOW', ElaroConstants.SEVERITY_LOW, 'LOW severity should be defined');
    }
    
    @IsTest
    static void testRiskThresholds() {
        System.assertEquals(9.0, ElaroConstants.RISK_THRESHOLD_CRITICAL, 'Critical threshold should be 9.0');
        System.assertEquals(7.0, ElaroConstants.RISK_THRESHOLD_HIGH, 'High threshold should be 7.0');
        System.assertEquals(5.0, ElaroConstants.RISK_THRESHOLD_MEDIUM, 'Medium threshold should be 5.0');
        System.assertEquals(3.0, ElaroConstants.RISK_THRESHOLD_LOW, 'Low threshold should be 3.0');
        System.assertEquals(10.0, ElaroConstants.RISK_SCORE_MAX, 'Max risk score should be 10.0');
    }
    
    @IsTest
    static void testScoreThresholds() {
        System.assertEquals(90, ElaroConstants.SCORE_THRESHOLD_EXCELLENT, 'Excellent threshold should be 90');
        System.assertEquals(80, ElaroConstants.SCORE_THRESHOLD_GOOD, 'Good threshold should be 80');
        System.assertEquals(70, ElaroConstants.SCORE_THRESHOLD_FAIR, 'Fair threshold should be 70');
        System.assertEquals(50, ElaroConstants.SCORE_THRESHOLD_NEEDS_IMPROVEMENT, 'Needs improvement threshold should be 50');
    }
    
    @IsTest
    static void testGetSeverityFromRiskScore() {
        // Test null
        System.assertEquals('LOW', ElaroConstants.getSeverityFromRiskScore(null), 'Null should return LOW');
        
        // Test critical
        System.assertEquals('CRITICAL', ElaroConstants.getSeverityFromRiskScore(9.5), '9.5 should be CRITICAL');
        System.assertEquals('CRITICAL', ElaroConstants.getSeverityFromRiskScore(10.0), '10.0 should be CRITICAL');
        
        // Test high
        System.assertEquals('HIGH', ElaroConstants.getSeverityFromRiskScore(7.0), '7.0 should be HIGH');
        System.assertEquals('HIGH', ElaroConstants.getSeverityFromRiskScore(8.9), '8.9 should be HIGH');
        
        // Test medium
        System.assertEquals('MEDIUM', ElaroConstants.getSeverityFromRiskScore(5.0), '5.0 should be MEDIUM');
        System.assertEquals('MEDIUM', ElaroConstants.getSeverityFromRiskScore(6.9), '6.9 should be MEDIUM');
        
        // Test low
        System.assertEquals('LOW', ElaroConstants.getSeverityFromRiskScore(0.0), '0.0 should be LOW');
        System.assertEquals('LOW', ElaroConstants.getSeverityFromRiskScore(4.9), '4.9 should be LOW');
    }
    
    @IsTest
    static void testGetRatingFromScore() {
        // Test null
        System.assertEquals('CRITICAL', ElaroConstants.getRatingFromScore(null), 'Null should return CRITICAL');
        
        // Test excellent
        System.assertEquals('EXCELLENT', ElaroConstants.getRatingFromScore(95), '95 should be EXCELLENT');
        System.assertEquals('EXCELLENT', ElaroConstants.getRatingFromScore(90), '90 should be EXCELLENT');
        
        // Test good
        System.assertEquals('GOOD', ElaroConstants.getRatingFromScore(85), '85 should be GOOD');
        System.assertEquals('GOOD', ElaroConstants.getRatingFromScore(80), '80 should be GOOD');
        
        // Test fair
        System.assertEquals('FAIR', ElaroConstants.getRatingFromScore(75), '75 should be FAIR');
        System.assertEquals('FAIR', ElaroConstants.getRatingFromScore(70), '70 should be FAIR');
        
        // Test needs improvement
        System.assertEquals('NEEDS_IMPROVEMENT', ElaroConstants.getRatingFromScore(60), '60 should be NEEDS_IMPROVEMENT');
        System.assertEquals('NEEDS_IMPROVEMENT', ElaroConstants.getRatingFromScore(50), '50 should be NEEDS_IMPROVEMENT');
        
        // Test critical
        System.assertEquals('CRITICAL', ElaroConstants.getRatingFromScore(40), '40 should be CRITICAL');
        System.assertEquals('CRITICAL', ElaroConstants.getRatingFromScore(0), '0 should be CRITICAL');
    }
    
    @IsTest
    static void testGetScoreEmoji() {
        System.assertEquals('🔴', ElaroConstants.getScoreEmoji(null), 'Null should return red');
        System.assertEquals('🟢', ElaroConstants.getScoreEmoji(95), '95 should return green');
        System.assertEquals('🟡', ElaroConstants.getScoreEmoji(85), '85 should return yellow');
        System.assertEquals('🟠', ElaroConstants.getScoreEmoji(75), '75 should return orange');
        System.assertEquals('🔴', ElaroConstants.getScoreEmoji(50), '50 should return red');
    }
    
    @IsTest
    static void testGetScoreColor() {
        System.assertEquals('#e74c3c', ElaroConstants.getScoreColor(null), 'Null should return red hex');
        System.assertEquals('#2ecc71', ElaroConstants.getScoreColor(95), '95 should return green hex');
        System.assertEquals('#f39c12', ElaroConstants.getScoreColor(85), '85 should return yellow hex');
        System.assertEquals('#e67e22', ElaroConstants.getScoreColor(75), '75 should return orange hex');
        System.assertEquals('#e74c3c', ElaroConstants.getScoreColor(50), '50 should return red hex');
    }
    
    @IsTest
    static void testIsValidFramework() {
        // Valid frameworks
        System.assert(ElaroConstants.isValidFramework('HIPAA'), 'HIPAA should be valid');
        System.assert(ElaroConstants.isValidFramework('hipaa'), 'hipaa (lowercase) should be valid');
        System.assert(ElaroConstants.isValidFramework('SOC2'), 'SOC2 should be valid');
        System.assert(ElaroConstants.isValidFramework('NIST'), 'NIST should be valid');
        System.assert(ElaroConstants.isValidFramework('FedRAMP'), 'FedRAMP should be valid');
        System.assert(ElaroConstants.isValidFramework('GDPR'), 'GDPR should be valid');
        
        // Invalid frameworks
        System.assert(!ElaroConstants.isValidFramework(null), 'Null should be invalid');
        System.assert(!ElaroConstants.isValidFramework(''), 'Empty string should be invalid');
        System.assert(!ElaroConstants.isValidFramework('INVALID'), 'INVALID should be invalid');
    }
    
    @IsTest
    static void testEntityTypeConstants() {
        System.assertEquals('PERMISSION_SET', ElaroConstants.ENTITY_PERMISSION_SET);
        System.assertEquals('PROFILE', ElaroConstants.ENTITY_PROFILE);
        System.assertEquals('FLOW', ElaroConstants.ENTITY_FLOW);
        System.assertEquals('FIELD', ElaroConstants.ENTITY_FIELD);
        System.assertEquals('ENCRYPTION', ElaroConstants.ENTITY_ENCRYPTION);
    }
    
    @IsTest
    static void testDriftCategoryConstants() {
        System.assertEquals('POLICY_VIOLATION', ElaroConstants.DRIFT_POLICY_VIOLATION);
        System.assertEquals('AUTO_REMEDIATED', ElaroConstants.DRIFT_AUTO_REMEDIATED);
        System.assertEquals('HUMAN_APPROVED', ElaroConstants.DRIFT_HUMAN_APPROVED);
        System.assertEquals('PENDING_REVIEW', ElaroConstants.DRIFT_PENDING_REVIEW);
    }
    
    @IsTest
    static void testQueryTypeConstants() {
        System.assertEquals('SCORE_CHANGE', ElaroConstants.QUERY_SCORE_CHANGE);
        System.assertEquals('VIOLATION_SEARCH', ElaroConstants.QUERY_VIOLATION_SEARCH);
        System.assertEquals('EVIDENCE_REQUEST', ElaroConstants.QUERY_EVIDENCE_REQUEST);
        System.assertEquals('RISKY_FLOWS', ElaroConstants.QUERY_RISKY_FLOWS);
        System.assertEquals('USER_ACCESS', ElaroConstants.QUERY_USER_ACCESS);
        System.assertEquals('FRAMEWORK_STATUS', ElaroConstants.QUERY_FRAMEWORK_STATUS);
        System.assertEquals('GENERAL', ElaroConstants.QUERY_GENERAL);
    }
    
    @IsTest
    static void testVersionAndLogging() {
        System.assertEquals('64.0', ElaroConstants.SALESFORCE_API_VERSION);
        System.assertEquals('3.0.0', ElaroConstants.ELARO_VERSION);
        System.assertEquals('[Elaro] ', ElaroConstants.LOG_PREFIX);
    }
}

