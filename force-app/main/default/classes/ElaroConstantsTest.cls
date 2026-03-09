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
        Assert.areEqual('HIPAA', ElaroConstants.FRAMEWORK_HIPAA, 'HIPAA framework constant should be defined');
        Assert.areEqual('SOC2', ElaroConstants.FRAMEWORK_SOC2, 'SOC2 framework constant should be defined');
        Assert.areEqual('NIST', ElaroConstants.FRAMEWORK_NIST, 'NIST framework constant should be defined');
        Assert.areEqual('FedRAMP', ElaroConstants.FRAMEWORK_FEDRAMP, 'FedRAMP framework constant should be defined');
        Assert.areEqual('GDPR', ElaroConstants.FRAMEWORK_GDPR, 'GDPR framework constant should be defined');
        Assert.areEqual('SOX', ElaroConstants.FRAMEWORK_SOX, 'SOX framework constant should be defined');
        Assert.areEqual('PCI_DSS', ElaroConstants.FRAMEWORK_PCI_DSS, 'PCI_DSS framework constant should be defined');
        
        // Verify ALL_FRAMEWORKS contains all frameworks (10 total: HIPAA, SOC2, NIST, FedRAMP, GDPR, SOX, PCI-DSS, CCPA, GLBA, ISO27001)
        Assert.areEqual(10, ElaroConstants.ALL_FRAMEWORKS.size(), 'ALL_FRAMEWORKS should contain 10 frameworks');
        Assert.isTrue(ElaroConstants.ALL_FRAMEWORKS.contains('HIPAA'), 'ALL_FRAMEWORKS should contain HIPAA');
        Assert.isTrue(ElaroConstants.ALL_FRAMEWORKS.contains('SOC2'), 'ALL_FRAMEWORKS should contain SOC2');
    }
    
    @IsTest
    static void testSeverityConstants() {
        Assert.areEqual('CRITICAL', ElaroConstants.SEVERITY_CRITICAL, 'CRITICAL severity should be defined');
        Assert.areEqual('HIGH', ElaroConstants.SEVERITY_HIGH, 'HIGH severity should be defined');
        Assert.areEqual('MEDIUM', ElaroConstants.SEVERITY_MEDIUM, 'MEDIUM severity should be defined');
        Assert.areEqual('LOW', ElaroConstants.SEVERITY_LOW, 'LOW severity should be defined');
    }
    
    @IsTest
    static void testRiskThresholds() {
        Assert.areEqual(9.0, ElaroConstants.RISK_THRESHOLD_CRITICAL, 'Critical threshold should be 9.0');
        Assert.areEqual(7.0, ElaroConstants.RISK_THRESHOLD_HIGH, 'High threshold should be 7.0');
        Assert.areEqual(5.0, ElaroConstants.RISK_THRESHOLD_MEDIUM, 'Medium threshold should be 5.0');
        Assert.areEqual(3.0, ElaroConstants.RISK_THRESHOLD_LOW, 'Low threshold should be 3.0');
        Assert.areEqual(10.0, ElaroConstants.RISK_SCORE_MAX, 'Max risk score should be 10.0');
    }
    
    @IsTest
    static void testScoreThresholds() {
        Assert.areEqual(90, ElaroConstants.SCORE_THRESHOLD_EXCELLENT, 'Excellent threshold should be 90');
        Assert.areEqual(80, ElaroConstants.SCORE_THRESHOLD_GOOD, 'Good threshold should be 80');
        Assert.areEqual(70, ElaroConstants.SCORE_THRESHOLD_FAIR, 'Fair threshold should be 70');
        Assert.areEqual(50, ElaroConstants.SCORE_THRESHOLD_NEEDS_IMPROVEMENT, 'Needs improvement threshold should be 50');
    }
    
    @IsTest
    static void testGetSeverityFromRiskScore() {
        // Test null
        Assert.areEqual('LOW', ElaroConstants.getSeverityFromRiskScore(null), 'Null should return LOW');
        
        // Test critical
        Assert.areEqual('CRITICAL', ElaroConstants.getSeverityFromRiskScore(9.5), '9.5 should be CRITICAL');
        Assert.areEqual('CRITICAL', ElaroConstants.getSeverityFromRiskScore(10.0), '10.0 should be CRITICAL');
        
        // Test high
        Assert.areEqual('HIGH', ElaroConstants.getSeverityFromRiskScore(7.0), '7.0 should be HIGH');
        Assert.areEqual('HIGH', ElaroConstants.getSeverityFromRiskScore(8.9), '8.9 should be HIGH');
        
        // Test medium
        Assert.areEqual('MEDIUM', ElaroConstants.getSeverityFromRiskScore(5.0), '5.0 should be MEDIUM');
        Assert.areEqual('MEDIUM', ElaroConstants.getSeverityFromRiskScore(6.9), '6.9 should be MEDIUM');
        
        // Test low
        Assert.areEqual('LOW', ElaroConstants.getSeverityFromRiskScore(0.0), '0.0 should be LOW');
        Assert.areEqual('LOW', ElaroConstants.getSeverityFromRiskScore(4.9), '4.9 should be LOW');
    }
    
    @IsTest
    static void testGetRatingFromScore() {
        // Test null
        Assert.areEqual('CRITICAL', ElaroConstants.getRatingFromScore(null), 'Null should return CRITICAL');
        
        // Test excellent
        Assert.areEqual('EXCELLENT', ElaroConstants.getRatingFromScore(95), '95 should be EXCELLENT');
        Assert.areEqual('EXCELLENT', ElaroConstants.getRatingFromScore(90), '90 should be EXCELLENT');
        
        // Test good
        Assert.areEqual('GOOD', ElaroConstants.getRatingFromScore(85), '85 should be GOOD');
        Assert.areEqual('GOOD', ElaroConstants.getRatingFromScore(80), '80 should be GOOD');
        
        // Test fair
        Assert.areEqual('FAIR', ElaroConstants.getRatingFromScore(75), '75 should be FAIR');
        Assert.areEqual('FAIR', ElaroConstants.getRatingFromScore(70), '70 should be FAIR');
        
        // Test needs improvement
        Assert.areEqual('NEEDS_IMPROVEMENT', ElaroConstants.getRatingFromScore(60), '60 should be NEEDS_IMPROVEMENT');
        Assert.areEqual('NEEDS_IMPROVEMENT', ElaroConstants.getRatingFromScore(50), '50 should be NEEDS_IMPROVEMENT');
        
        // Test critical
        Assert.areEqual('CRITICAL', ElaroConstants.getRatingFromScore(40), '40 should be CRITICAL');
        Assert.areEqual('CRITICAL', ElaroConstants.getRatingFromScore(0), '0 should be CRITICAL');
    }
    
    @IsTest
    static void testGetScoreEmoji() {
        Assert.areEqual('🔴', ElaroConstants.getScoreEmoji(null), 'Null should return red');
        Assert.areEqual('🟢', ElaroConstants.getScoreEmoji(95), '95 should return green');
        Assert.areEqual('🟡', ElaroConstants.getScoreEmoji(85), '85 should return yellow');
        Assert.areEqual('🟠', ElaroConstants.getScoreEmoji(75), '75 should return orange');
        Assert.areEqual('🔴', ElaroConstants.getScoreEmoji(50), '50 should return red');
    }
    
    @IsTest
    static void testGetScoreColor() {
        Assert.areEqual('#e74c3c', ElaroConstants.getScoreColor(null), 'Null should return red hex');
        Assert.areEqual('#2ecc71', ElaroConstants.getScoreColor(95), '95 should return green hex');
        Assert.areEqual('#f39c12', ElaroConstants.getScoreColor(85), '85 should return yellow hex');
        Assert.areEqual('#e67e22', ElaroConstants.getScoreColor(75), '75 should return orange hex');
        Assert.areEqual('#e74c3c', ElaroConstants.getScoreColor(50), '50 should return red hex');
    }
    
    @IsTest
    static void testIsValidFramework() {
        // Valid frameworks
        Assert.isTrue(ElaroConstants.isValidFramework('HIPAA'), 'HIPAA should be valid');
        Assert.isTrue(ElaroConstants.isValidFramework('hipaa'), 'hipaa (lowercase) should be valid');
        Assert.isTrue(ElaroConstants.isValidFramework('SOC2'), 'SOC2 should be valid');
        Assert.isTrue(ElaroConstants.isValidFramework('NIST'), 'NIST should be valid');
        Assert.isTrue(ElaroConstants.isValidFramework('FedRAMP'), 'FedRAMP should be valid');
        Assert.isTrue(ElaroConstants.isValidFramework('GDPR'), 'GDPR should be valid');
        
        // Invalid frameworks
        Assert.isTrue(!ElaroConstants.isValidFramework(null), 'Null should be invalid');
        Assert.isTrue(!ElaroConstants.isValidFramework(''), 'Empty string should be invalid');
        Assert.isTrue(!ElaroConstants.isValidFramework('INVALID'), 'INVALID should be invalid');
    }
    
    @IsTest
    static void testEntityTypeConstants() {
        Assert.areEqual('PERMISSION_SET', ElaroConstants.ENTITY_PERMISSION_SET);
        Assert.areEqual('PROFILE', ElaroConstants.ENTITY_PROFILE);
        Assert.areEqual('FLOW', ElaroConstants.ENTITY_FLOW);
        Assert.areEqual('FIELD', ElaroConstants.ENTITY_FIELD);
        Assert.areEqual('ENCRYPTION', ElaroConstants.ENTITY_ENCRYPTION);
    }
    
    @IsTest
    static void testDriftCategoryConstants() {
        Assert.areEqual('POLICY_VIOLATION', ElaroConstants.DRIFT_POLICY_VIOLATION);
        Assert.areEqual('AUTO_REMEDIATED', ElaroConstants.DRIFT_AUTO_REMEDIATED);
        Assert.areEqual('HUMAN_APPROVED', ElaroConstants.DRIFT_HUMAN_APPROVED);
        Assert.areEqual('PENDING_REVIEW', ElaroConstants.DRIFT_PENDING_REVIEW);
    }
    
    @IsTest
    static void testQueryTypeConstants() {
        Assert.areEqual('SCORE_CHANGE', ElaroConstants.QUERY_SCORE_CHANGE);
        Assert.areEqual('VIOLATION_SEARCH', ElaroConstants.QUERY_VIOLATION_SEARCH);
        Assert.areEqual('EVIDENCE_REQUEST', ElaroConstants.QUERY_EVIDENCE_REQUEST);
        Assert.areEqual('RISKY_FLOWS', ElaroConstants.QUERY_RISKY_FLOWS);
        Assert.areEqual('USER_ACCESS', ElaroConstants.QUERY_USER_ACCESS);
        Assert.areEqual('FRAMEWORK_STATUS', ElaroConstants.QUERY_FRAMEWORK_STATUS);
        Assert.areEqual('GENERAL', ElaroConstants.QUERY_GENERAL);
    }
    
    @IsTest
    static void testVersionAndLogging() {
        Assert.areEqual('66.0', ElaroConstants.SALESFORCE_API_VERSION);
        Assert.areEqual('3.0.0', ElaroConstants.ELARO_VERSION);
        Assert.areEqual('[Elaro] ', ElaroConstants.LOG_PREFIX);
    }
}

