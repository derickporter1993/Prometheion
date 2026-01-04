/**
 * SolentraConstants - Centralized constants for Solentra application
 * 
 * Provides a single source of truth for:
 * - Compliance framework names
 * - Severity levels
 * - Risk score thresholds
 * - API versions
 * - Channel names
 * - Entity types
 * 
 * @author Solentra
 * @version 1.0
 */
public class SolentraConstants {
    
    // ============================================
    // COMPLIANCE FRAMEWORKS
    // ============================================
    public static final String FRAMEWORK_HIPAA = 'HIPAA';
    public static final String FRAMEWORK_SOC2 = 'SOC2';
    public static final String FRAMEWORK_NIST = 'NIST';
    public static final String FRAMEWORK_FEDRAMP = 'FedRAMP';
    public static final String FRAMEWORK_GDPR = 'GDPR';
    public static final String FRAMEWORK_SOX = 'SOX';
    public static final String FRAMEWORK_PCI_DSS = 'PCI_DSS';
    
    public static final Set<String> ALL_FRAMEWORKS = new Set<String>{
        FRAMEWORK_HIPAA,
        FRAMEWORK_SOC2,
        FRAMEWORK_NIST,
        FRAMEWORK_FEDRAMP,
        FRAMEWORK_GDPR,
        FRAMEWORK_SOX,
        FRAMEWORK_PCI_DSS
    };
    
    // ============================================
    // SEVERITY LEVELS
    // ============================================
    public static final String SEVERITY_CRITICAL = 'CRITICAL';
    public static final String SEVERITY_HIGH = 'HIGH';
    public static final String SEVERITY_MEDIUM = 'MEDIUM';
    public static final String SEVERITY_LOW = 'LOW';
    
    // ============================================
    // RISK SCORE THRESHOLDS
    // ============================================
    public static final Decimal RISK_THRESHOLD_CRITICAL = 9.0;
    public static final Decimal RISK_THRESHOLD_HIGH = 7.0;
    public static final Decimal RISK_THRESHOLD_MEDIUM = 5.0;
    public static final Decimal RISK_THRESHOLD_LOW = 3.0;
    
    // Auto-fix suggestion threshold (higher than general high-risk)
    public static final Decimal RISK_THRESHOLD_AUTO_FIX = 8.0;
    
    // Maximum risk score
    public static final Decimal RISK_SCORE_MAX = 10.0;
    
    // ============================================
    // COMPLIANCE SCORE RATINGS
    // ============================================
    public static final String RATING_EXCELLENT = 'EXCELLENT';
    public static final String RATING_GOOD = 'GOOD';
    public static final String RATING_FAIR = 'FAIR';
    public static final String RATING_NEEDS_IMPROVEMENT = 'NEEDS_IMPROVEMENT';
    public static final String RATING_CRITICAL = 'CRITICAL';
    
    // Score thresholds for ratings
    public static final Decimal SCORE_THRESHOLD_EXCELLENT = 90;
    public static final Decimal SCORE_THRESHOLD_GOOD = 80;
    public static final Decimal SCORE_THRESHOLD_FAIR = 70;
    public static final Decimal SCORE_THRESHOLD_NEEDS_IMPROVEMENT = 50;
    
    // ============================================
    // NOTIFICATION CHANNELS
    // ============================================
    public static final String CHANNEL_SLACK = 'Slack';
    public static final String CHANNEL_TEAMS = 'Teams';
    public static final String CHANNEL_BOTH = 'Both';
    public static final String CHANNEL_EMAIL = 'Email';
    
    // Named Credential names
    public static final String NAMED_CREDENTIAL_SLACK = 'Slack_Webhook';
    public static final String NAMED_CREDENTIAL_TEAMS = 'Teams_Webhook';
    
    // ============================================
    // ENTITY TYPES
    // ============================================
    public static final String ENTITY_PERMISSION_SET = 'PERMISSION_SET';
    public static final String ENTITY_PROFILE = 'PROFILE';
    public static final String ENTITY_PERMISSION_SET_ASSIGNMENT = 'PERMISSION_SET_ASSIGNMENT';
    public static final String ENTITY_USER = 'USER';
    public static final String ENTITY_SHARING_RULE = 'SHARING_RULE';
    public static final String ENTITY_OBJECT = 'OBJECT';
    public static final String ENTITY_FIELD = 'FIELD';
    public static final String ENTITY_FIELD_HISTORY = 'FIELD_HISTORY';
    public static final String ENTITY_FLOW = 'FLOW';
    public static final String ENTITY_ENCRYPTION = 'ENCRYPTION';
    public static final String ENTITY_AUDIT_LOG = 'AUDIT_LOG';
    public static final String ENTITY_EVENT_MONITORING = 'EVENT_MONITORING';
    
    // ============================================
    // DRIFT CATEGORIES
    // ============================================
    public static final String DRIFT_POLICY_VIOLATION = 'POLICY_VIOLATION';
    public static final String DRIFT_AUTO_REMEDIATED = 'AUTO_REMEDIATED';
    public static final String DRIFT_HUMAN_APPROVED = 'HUMAN_APPROVED';
    public static final String DRIFT_PENDING_REVIEW = 'PENDING_REVIEW';
    
    // ============================================
    // QUERY TYPES (Copilot)
    // ============================================
    public static final String QUERY_SCORE_CHANGE = 'SCORE_CHANGE';
    public static final String QUERY_VIOLATION_SEARCH = 'VIOLATION_SEARCH';
    public static final String QUERY_EVIDENCE_REQUEST = 'EVIDENCE_REQUEST';
    public static final String QUERY_RISKY_FLOWS = 'RISKY_FLOWS';
    public static final String QUERY_USER_ACCESS = 'USER_ACCESS';
    public static final String QUERY_FRAMEWORK_STATUS = 'FRAMEWORK_STATUS';
    public static final String QUERY_GENERAL = 'GENERAL';
    
    // ============================================
    // ACTION TYPES
    // ============================================
    public static final String ACTION_AUTO_FIX = 'AUTO_FIX';
    public static final String ACTION_EXPORT = 'EXPORT';
    public static final String ACTION_APPROVE = 'APPROVE';
    public static final String ACTION_ROLLBACK = 'ROLLBACK';
    public static final String ACTION_REVIEW = 'REVIEW';
    
    // ============================================
    // TIME THRESHOLDS
    // ============================================
    public static final Integer INACTIVE_USER_THRESHOLD_DAYS = 90;
    public static final Integer AUDIT_RETENTION_DAYS = 180;
    public static final Integer HIGH_RISK_REVIEW_HOURS = 24;
    public static final Integer GDPR_BREACH_NOTIFICATION_HOURS = 72;
    
    // ============================================
    // API & VERSION INFO
    // ============================================
    public static final String SALESFORCE_API_VERSION = '64.0';
    public static final String SOLENTRA_VERSION = '1.0.0';
    
    // ============================================
    // LOGGING
    // ============================================
    public static final String LOG_PREFIX = '[Solentra] ';
    
    // ============================================
    // HELPER METHODS
    // ============================================
    
    /**
     * Get severity from risk score
     */
    public static String getSeverityFromRiskScore(Decimal riskScore) {
        if (riskScore == null) return SEVERITY_LOW;
        if (riskScore >= RISK_THRESHOLD_CRITICAL) return SEVERITY_CRITICAL;
        if (riskScore >= RISK_THRESHOLD_HIGH) return SEVERITY_HIGH;
        if (riskScore >= RISK_THRESHOLD_MEDIUM) return SEVERITY_MEDIUM;
        return SEVERITY_LOW;
    }
    
    /**
     * Get rating from compliance score
     */
    public static String getRatingFromScore(Decimal score) {
        if (score == null) return RATING_CRITICAL;
        if (score >= SCORE_THRESHOLD_EXCELLENT) return RATING_EXCELLENT;
        if (score >= SCORE_THRESHOLD_GOOD) return RATING_GOOD;
        if (score >= SCORE_THRESHOLD_FAIR) return RATING_FAIR;
        if (score >= SCORE_THRESHOLD_NEEDS_IMPROVEMENT) return RATING_NEEDS_IMPROVEMENT;
        return RATING_CRITICAL;
    }
    
    /**
     * Get emoji for score
     */
    public static String getScoreEmoji(Decimal score) {
        if (score == null) return '🔴';
        if (score >= SCORE_THRESHOLD_EXCELLENT) return '🟢';
        if (score >= SCORE_THRESHOLD_GOOD) return '🟡';
        if (score >= SCORE_THRESHOLD_FAIR) return '🟠';
        return '🔴';
    }
    
    /**
     * Get color hex for score
     */
    public static String getScoreColor(Decimal score) {
        if (score == null) return '#e74c3c';
        if (score >= SCORE_THRESHOLD_EXCELLENT) return '#2ecc71';
        if (score >= SCORE_THRESHOLD_GOOD) return '#f39c12';
        if (score >= SCORE_THRESHOLD_FAIR) return '#e67e22';
        return '#e74c3c';
    }
    
    /**
     * Check if framework is valid (case-insensitive)
     */
    public static Boolean isValidFramework(String framework) {
        if (String.isBlank(framework)) {
            return false;
        }
        String upperFramework = framework.toUpperCase();
        for (String validFramework : ALL_FRAMEWORKS) {
            if (validFramework.toUpperCase().equals(upperFramework)) {
                return true;
            }
        }
        return false;
    }
}

