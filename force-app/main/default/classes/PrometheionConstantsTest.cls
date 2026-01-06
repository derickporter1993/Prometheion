/**
 * PrometheionConstantsTest - Test class for PrometheionConstants
 * 
 * @author Prometheion
 * @version 1.0
 */
@IsTest
private class PrometheionConstantsTest {
    
    @IsTest
    static void testFrameworkConstants() {
        // Verify all framework constants are defined
        System.assertEquals('HIPAA', PrometheionConstants.FRAMEWORK_HIPAA, 'HIPAA framework constant should be defined');
        System.assertEquals('SOC2', PrometheionConstants.FRAMEWORK_SOC2, 'SOC2 framework constant should be defined');
        System.assertEquals('NIST', PrometheionConstants.FRAMEWORK_NIST, 'NIST framework constant should be defined');
        System.assertEquals('FedRAMP', PrometheionConstants.FRAMEWORK_FEDRAMP, 'FedRAMP framework constant should be defined');
        System.assertEquals('GDPR', PrometheionConstants.FRAMEWORK_GDPR, 'GDPR framework constant should be defined');
        System.assertEquals('SOX', PrometheionConstants.FRAMEWORK_SOX, 'SOX framework constant should be defined');
        System.assertEquals('PCI_DSS', PrometheionConstants.FRAMEWORK_PCI_DSS, 'PCI_DSS framework constant should be defined');
        
        // Verify ALL_FRAMEWORKS contains all frameworks (10 total: HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO27001)
        System.assertEquals(10, PrometheionConstants.ALL_FRAMEWORKS.size(), 'ALL_FRAMEWORKS should contain 10 frameworks');
        System.assert(PrometheionConstants.ALL_FRAMEWORKS.contains('HIPAA'), 'ALL_FRAMEWORKS should contain HIPAA');
        System.assert(PrometheionConstants.ALL_FRAMEWORKS.contains('SOC2'), 'ALL_FRAMEWORKS should contain SOC2');
    }
    
    @IsTest
    static void testSeverityConstants() {
        System.assertEquals('CRITICAL', PrometheionConstants.SEVERITY_CRITICAL, 'CRITICAL severity should be defined');
        System.assertEquals('HIGH', PrometheionConstants.SEVERITY_HIGH, 'HIGH severity should be defined');
        System.assertEquals('MEDIUM', PrometheionConstants.SEVERITY_MEDIUM, 'MEDIUM severity should be defined');
        System.assertEquals('LOW', PrometheionConstants.SEVERITY_LOW, 'LOW severity should be defined');
    }
    
    @IsTest
    static void testRiskThresholds() {
        System.assertEquals(9.0, PrometheionConstants.RISK_THRESHOLD_CRITICAL, 'Critical threshold should be 9.0');
        System.assertEquals(7.0, PrometheionConstants.RISK_THRESHOLD_HIGH, 'High threshold should be 7.0');
        System.assertEquals(5.0, PrometheionConstants.RISK_THRESHOLD_MEDIUM, 'Medium threshold should be 5.0');
        System.assertEquals(3.0, PrometheionConstants.RISK_THRESHOLD_LOW, 'Low threshold should be 3.0');
        System.assertEquals(10.0, PrometheionConstants.RISK_SCORE_MAX, 'Max risk score should be 10.0');
    }
    
    @IsTest
    static void testScoreThresholds() {
        System.assertEquals(90, PrometheionConstants.SCORE_THRESHOLD_EXCELLENT, 'Excellent threshold should be 90');
        System.assertEquals(80, PrometheionConstants.SCORE_THRESHOLD_GOOD, 'Good threshold should be 80');
        System.assertEquals(70, PrometheionConstants.SCORE_THRESHOLD_FAIR, 'Fair threshold should be 70');
        System.assertEquals(50, PrometheionConstants.SCORE_THRESHOLD_NEEDS_IMPROVEMENT, 'Needs improvement threshold should be 50');
    }
    
    @IsTest
    static void testGetSeverityFromRiskScore() {
        // Test null
        System.assertEquals('LOW', PrometheionConstants.getSeverityFromRiskScore(null), 'Null should return LOW');
        
        // Test critical
        System.assertEquals('CRITICAL', PrometheionConstants.getSeverityFromRiskScore(9.5), '9.5 should be CRITICAL');
        System.assertEquals('CRITICAL', PrometheionConstants.getSeverityFromRiskScore(10.0), '10.0 should be CRITICAL');
        
        // Test high
        System.assertEquals('HIGH', PrometheionConstants.getSeverityFromRiskScore(7.0), '7.0 should be HIGH');
        System.assertEquals('HIGH', PrometheionConstants.getSeverityFromRiskScore(8.9), '8.9 should be HIGH');
        
        // Test medium
        System.assertEquals('MEDIUM', PrometheionConstants.getSeverityFromRiskScore(5.0), '5.0 should be MEDIUM');
        System.assertEquals('MEDIUM', PrometheionConstants.getSeverityFromRiskScore(6.9), '6.9 should be MEDIUM');
        
        // Test low
        System.assertEquals('LOW', PrometheionConstants.getSeverityFromRiskScore(0.0), '0.0 should be LOW');
        System.assertEquals('LOW', PrometheionConstants.getSeverityFromRiskScore(4.9), '4.9 should be LOW');
    }
    
    @IsTest
    static void testGetRatingFromScore() {
        // Test null
        System.assertEquals('CRITICAL', PrometheionConstants.getRatingFromScore(null), 'Null should return CRITICAL');
        
        // Test excellent
        System.assertEquals('EXCELLENT', PrometheionConstants.getRatingFromScore(95), '95 should be EXCELLENT');
        System.assertEquals('EXCELLENT', PrometheionConstants.getRatingFromScore(90), '90 should be EXCELLENT');
        
        // Test good
        System.assertEquals('GOOD', PrometheionConstants.getRatingFromScore(85), '85 should be GOOD');
        System.assertEquals('GOOD', PrometheionConstants.getRatingFromScore(80), '80 should be GOOD');
        
        // Test fair
        System.assertEquals('FAIR', PrometheionConstants.getRatingFromScore(75), '75 should be FAIR');
        System.assertEquals('FAIR', PrometheionConstants.getRatingFromScore(70), '70 should be FAIR');
        
        // Test needs improvement
        System.assertEquals('NEEDS_IMPROVEMENT', PrometheionConstants.getRatingFromScore(60), '60 should be NEEDS_IMPROVEMENT');
        System.assertEquals('NEEDS_IMPROVEMENT', PrometheionConstants.getRatingFromScore(50), '50 should be NEEDS_IMPROVEMENT');
        
        // Test critical
        System.assertEquals('CRITICAL', PrometheionConstants.getRatingFromScore(40), '40 should be CRITICAL');
        System.assertEquals('CRITICAL', PrometheionConstants.getRatingFromScore(0), '0 should be CRITICAL');
    }
    
    @IsTest
    static void testGetScoreEmoji() {
        System.assertEquals('🔴', PrometheionConstants.getScoreEmoji(null), 'Null should return red');
        System.assertEquals('🟢', PrometheionConstants.getScoreEmoji(95), '95 should return green');
        System.assertEquals('🟡', PrometheionConstants.getScoreEmoji(85), '85 should return yellow');
        System.assertEquals('🟠', PrometheionConstants.getScoreEmoji(75), '75 should return orange');
        System.assertEquals('🔴', PrometheionConstants.getScoreEmoji(50), '50 should return red');
    }
    
    @IsTest
    static void testGetScoreColor() {
        System.assertEquals('#e74c3c', PrometheionConstants.getScoreColor(null), 'Null should return red hex');
        System.assertEquals('#2ecc71', PrometheionConstants.getScoreColor(95), '95 should return green hex');
        System.assertEquals('#f39c12', PrometheionConstants.getScoreColor(85), '85 should return yellow hex');
        System.assertEquals('#e67e22', PrometheionConstants.getScoreColor(75), '75 should return orange hex');
        System.assertEquals('#e74c3c', PrometheionConstants.getScoreColor(50), '50 should return red hex');
    }
    
    @IsTest
    static void testIsValidFramework() {
        // Valid frameworks
        System.assert(PrometheionConstants.isValidFramework('HIPAA'), 'HIPAA should be valid');
        System.assert(PrometheionConstants.isValidFramework('hipaa'), 'hipaa (lowercase) should be valid');
        System.assert(PrometheionConstants.isValidFramework('SOC2'), 'SOC2 should be valid');
        System.assert(PrometheionConstants.isValidFramework('NIST'), 'NIST should be valid');
        System.assert(PrometheionConstants.isValidFramework('FedRAMP'), 'FedRAMP should be valid');
        System.assert(PrometheionConstants.isValidFramework('GDPR'), 'GDPR should be valid');
        
        // Invalid frameworks
        System.assert(!PrometheionConstants.isValidFramework(null), 'Null should be invalid');
        System.assert(!PrometheionConstants.isValidFramework(''), 'Empty string should be invalid');
        System.assert(!PrometheionConstants.isValidFramework('INVALID'), 'INVALID should be invalid');
    }
    
    @IsTest
    static void testEntityTypeConstants() {
        System.assertEquals('PERMISSION_SET', PrometheionConstants.ENTITY_PERMISSION_SET);
        System.assertEquals('PROFILE', PrometheionConstants.ENTITY_PROFILE);
        System.assertEquals('FLOW', PrometheionConstants.ENTITY_FLOW);
        System.assertEquals('FIELD', PrometheionConstants.ENTITY_FIELD);
        System.assertEquals('ENCRYPTION', PrometheionConstants.ENTITY_ENCRYPTION);
    }
    
    @IsTest
    static void testDriftCategoryConstants() {
        System.assertEquals('POLICY_VIOLATION', PrometheionConstants.DRIFT_POLICY_VIOLATION);
        System.assertEquals('AUTO_REMEDIATED', PrometheionConstants.DRIFT_AUTO_REMEDIATED);
        System.assertEquals('HUMAN_APPROVED', PrometheionConstants.DRIFT_HUMAN_APPROVED);
        System.assertEquals('PENDING_REVIEW', PrometheionConstants.DRIFT_PENDING_REVIEW);
    }
    
    @IsTest
    static void testQueryTypeConstants() {
        System.assertEquals('SCORE_CHANGE', PrometheionConstants.QUERY_SCORE_CHANGE);
        System.assertEquals('VIOLATION_SEARCH', PrometheionConstants.QUERY_VIOLATION_SEARCH);
        System.assertEquals('EVIDENCE_REQUEST', PrometheionConstants.QUERY_EVIDENCE_REQUEST);
        System.assertEquals('RISKY_FLOWS', PrometheionConstants.QUERY_RISKY_FLOWS);
        System.assertEquals('USER_ACCESS', PrometheionConstants.QUERY_USER_ACCESS);
        System.assertEquals('FRAMEWORK_STATUS', PrometheionConstants.QUERY_FRAMEWORK_STATUS);
        System.assertEquals('GENERAL', PrometheionConstants.QUERY_GENERAL);
    }
    
    @IsTest
    static void testVersionAndLogging() {
        System.assertEquals('64.0', PrometheionConstants.SALESFORCE_API_VERSION);
        System.assertEquals('3.0.0', PrometheionConstants.PROMETHEION_VERSION);
        System.assertEquals('[Prometheion] ', PrometheionConstants.LOG_PREFIX);
    }
}

