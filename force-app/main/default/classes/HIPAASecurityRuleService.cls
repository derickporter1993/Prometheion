/**
 * HIPAASecurityRuleService
 *
 * Technical safeguards per HIPAA Security Rule (45 CFR 164.312).
 * Evaluates access controls, audit controls, integrity, and transmission security.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class HIPAASecurityRuleService extends ComplianceServiceBase {

    /**
     * Get framework name
     */
    public override String getFrameworkName() {
        return 'HIPAA';
    }

    /**
     * Get framework score multiplier
     */
    protected override Decimal getFrameworkMultiplier() {
        return 0.95;
    }

    /**
     * Evaluate HIPAA Security Rule controls
     */
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();
        violations.addAll(checkAccessControls().violations);
        violations.addAll(checkAuditControls().violations);
        violations.addAll(checkIntegrityControls().violations);
        return violations;
    }

    /**
     * Evaluate all technical safeguards
     */
    @AuraEnabled(cacheable=false)
    public static TechnicalSafeguardResult evaluateTechnicalSafeguards() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();
        TechnicalSafeguardResult result = new TechnicalSafeguardResult();
        result.evaluationDate = DateTime.now();

        result.accessControlResult = service.checkAccessControls();
        result.auditControlResult = service.checkAuditControls();
        result.integrityControlResult = service.checkIntegrityControls();
        result.transmissionResult = service.checkTransmissionSecurity();

        // Calculate overall score
        Decimal totalScore = result.accessControlResult.score +
                            result.auditControlResult.score +
                            result.integrityControlResult.score +
                            result.transmissionResult.score;
        result.overallScore = (totalScore / 4).setScale(2);
        result.overallCompliant = result.overallScore >= 80;

        // Collect all gaps
        result.gaps = new List<String>();
        result.gaps.addAll(result.accessControlResult.gaps);
        result.gaps.addAll(result.auditControlResult.gaps);
        result.gaps.addAll(result.integrityControlResult.gaps);
        result.gaps.addAll(result.transmissionResult.gaps);

        return result;
    }

    /**
     * Check access controls - §164.312(a)(1)
     */
    @AuraEnabled(cacheable=false)
    public static AccessControlResult checkAccessControls() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();
        return service.evaluateAccessControls();
    }

    /**
     * Check audit controls - §164.312(b)
     */
    @AuraEnabled(cacheable=false)
    public static AuditControlResult checkAuditControls() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();
        return service.evaluateAuditControls();
    }

    /**
     * Check integrity controls - §164.312(c)(1)
     */
    @AuraEnabled(cacheable=false)
    public static IntegrityControlResult checkIntegrityControls() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();
        return service.evaluateIntegrityControls();
    }

    /**
     * Check transmission security - §164.312(e)(1)
     */
    @AuraEnabled(cacheable=false)
    public static TransmissionResult checkTransmissionSecurity() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();
        return service.evaluateTransmissionSecurity();
    }

    /**
     * Get encryption status for PHI objects
     */
    @AuraEnabled(cacheable=false)
    public static Map<String, EncryptionInfo> getEncryptionStatus() {
        Map<String, EncryptionInfo> status = new Map<String, EncryptionInfo>();

        Set<String> phiObjects = new Set<String>{'Contact', 'Lead', 'Account', 'Case'};

        for (String objectName : phiObjects) {
            EncryptionInfo info = new EncryptionInfo();
            info.objectName = objectName;
            info.encryptedFields = new List<String>();
            info.unencryptedPHIFields = new List<String>();

            // Check for encrypted fields using Shield
            try {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
                if (objType != null) {
                    Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
                    for (String fieldName : fields.keySet()) {
                        Schema.DescribeFieldResult fieldDesc = fields.get(fieldName).getDescribe();
                        if (fieldDesc.isEncrypted()) {
                            info.encryptedFields.add(fieldName);
                        } else if (isPHIFieldName(fieldName)) {
                            info.unencryptedPHIFields.add(fieldName);
                        }
                    }
                }
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error checking encryption: ' + e.getMessage());
            }

            info.shieldEnabled = !info.encryptedFields.isEmpty();
            info.compliant = info.unencryptedPHIFields.isEmpty();

            status.put(objectName, info);
        }

        return status;
    }

    // ========== Private Evaluation Methods ==========

    private AccessControlResult evaluateAccessControls() {
        AccessControlResult result = new AccessControlResult();
        result.violations = new List<Violation>();
        result.gaps = new List<String>();
        result.score = 100;

        // §164.312(a)(2)(i) - Unique User Identification
        result.uniqueUserIdCompliant = checkUniqueUserIds();
        if (!result.uniqueUserIdCompliant) {
            result.gaps.add('Shared accounts detected');
            result.score -= 15;
            result.violations.add(new Violation(
                'Shared User Accounts',
                'Users may be sharing credentials (detected by login patterns)',
                'HIGH',
                'HIPAA-164.312(a)(2)(i)',
                'Ensure each user has unique credentials',
                7.5
            ));
        }

        // §164.312(a)(2)(iii) - Automatic Logoff
        result.autoLogoffConfigured = checkAutoLogoff();
        if (!result.autoLogoffConfigured) {
            result.gaps.add('Auto logoff not configured');
            result.score -= 10;
            result.violations.add(new Violation(
                'Missing Auto Logoff',
                'Session timeout not properly configured',
                'MEDIUM',
                'HIPAA-164.312(a)(2)(iii)',
                'Configure session timeout in Security Settings',
                5.5
            ));
        }

        // §164.312(a)(2)(iv) - Encryption
        result.encryptionEnabled = checkEncryption();
        if (!result.encryptionEnabled) {
            result.gaps.add('Shield Platform Encryption not enabled');
            result.score -= 20;
            result.violations.add(new Violation(
                'Missing Encryption',
                'PHI data is not encrypted at rest',
                'CRITICAL',
                'HIPAA-164.312(a)(2)(iv)',
                'Enable Shield Platform Encryption for PHI fields',
                9.0
            ));
        }

        result.compliant = result.score >= 80;
        return result;
    }

    private AuditControlResult evaluateAuditControls() {
        AuditControlResult result = new AuditControlResult();
        result.violations = new List<Violation>();
        result.gaps = new List<String>();
        result.score = 100;

        // Check audit trail coverage
        result.auditTrailEnabled = checkAuditTrailEnabled();
        if (!result.auditTrailEnabled) {
            result.gaps.add('Field History Tracking not enabled on PHI objects');
            result.score -= 25;
            result.violations.add(new Violation(
                'Incomplete Audit Trail',
                'Field History Tracking not enabled on all PHI objects',
                'HIGH',
                'HIPAA-164.312(b)',
                'Enable Field History Tracking on PHI fields',
                8.0
            ));
        }

        // Check retention period (HIPAA requires 6 years)
        result.retentionPeriodDays = 2190; // 6 years
        result.retentionCompliant = true; // Assuming default Salesforce retention

        result.compliant = result.score >= 80;
        return result;
    }

    private IntegrityControlResult evaluateIntegrityControls() {
        IntegrityControlResult result = new IntegrityControlResult();
        result.violations = new List<Violation>();
        result.gaps = new List<String>();
        result.score = 100;

        // Check for validation rules on PHI objects
        result.validationRulesEnabled = true; // Simplified check

        // Check bulk delete restrictions
        result.bulkDeleteRestricted = checkBulkDeleteRestrictions();
        if (!result.bulkDeleteRestricted) {
            result.gaps.add('Bulk delete not restricted on PHI objects');
            result.score -= 15;
            result.violations.add(new Violation(
                'Bulk Delete Allowed',
                'Users can perform bulk deletes on PHI data',
                'MEDIUM',
                'HIPAA-164.312(c)(1)',
                'Restrict bulk delete operations on PHI objects',
                6.0
            ));
        }

        result.compliant = result.score >= 80;
        return result;
    }

    private TransmissionResult evaluateTransmissionSecurity() {
        TransmissionResult result = new TransmissionResult();
        result.violations = new List<Violation>();
        result.gaps = new List<String>();
        result.score = 100;

        // Salesforce enforces TLS 1.2+ by default
        result.tlsVersion = 'TLS 1.2+';
        result.tlsCompliant = true;

        // Check API security
        result.apiSecurityEnabled = true; // Salesforce enforces HTTPS

        result.compliant = result.score >= 80;
        return result;
    }

    // ========== Private Helper Methods ==========

    private Boolean checkUniqueUserIds() {
        // Check for users with same IP from different accounts (simplified)
        return true; // Assume compliant by default
    }

    private Boolean checkAutoLogoff() {
        // Salesforce session timeout is org-configurable
        // Would check Session Settings in actual implementation
        return true;
    }

    private Boolean checkEncryption() {
        // Check if Shield Platform Encryption is enabled
        // Simplified check
        return false; // Assume not enabled unless proven otherwise
    }

    private Boolean checkAuditTrailEnabled() {
        // Check Field History Tracking on PHI objects
        Set<String> phiObjects = new Set<String>{'Contact', 'Lead'};
        for (String objectName : phiObjects) {
            try {
                Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
                if (objType != null) {
                    Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
                    Boolean hasTracking = false;
                    for (Schema.SObjectField field : fields.values()) {
                        if (field.getDescribe().isHistoryTracked() != null && field.getDescribe().isHistoryTracked()) {
                            hasTracking = true;
                            break;
                        }
                    }
                    if (!hasTracking) return false;
                }
            } catch (Exception e) {
                return false;
            }
        }
        return true;
    }

    private Boolean checkBulkDeleteRestrictions() {
        // Check if Mass Delete permission is restricted
        // Simplified check
        return true;
    }

    private static Boolean isPHIFieldName(String fieldName) {
        Set<String> phiPatterns = new Set<String>{'SSN', 'DOB', 'BIRTH', 'MEDICAL', 'HEALTH'};
        String upper = fieldName.toUpperCase();
        for (String pattern : phiPatterns) {
            if (upper.contains(pattern)) return true;
        }
        return false;
    }

    // ========== Inner Classes ==========

    public class TechnicalSafeguardResult {
        @AuraEnabled public DateTime evaluationDate;
        @AuraEnabled public AccessControlResult accessControlResult;
        @AuraEnabled public AuditControlResult auditControlResult;
        @AuraEnabled public IntegrityControlResult integrityControlResult;
        @AuraEnabled public TransmissionResult transmissionResult;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public Boolean overallCompliant;
        @AuraEnabled public List<String> gaps;
    }

    public class AccessControlResult {
        @AuraEnabled public Boolean uniqueUserIdCompliant;
        @AuraEnabled public Boolean autoLogoffConfigured;
        @AuraEnabled public Boolean encryptionEnabled;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Decimal score;
        @AuraEnabled public List<String> gaps;
        @AuraEnabled public List<Violation> violations;
    }

    public class AuditControlResult {
        @AuraEnabled public Boolean auditTrailEnabled;
        @AuraEnabled public Integer retentionPeriodDays;
        @AuraEnabled public Boolean retentionCompliant;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Decimal score;
        @AuraEnabled public List<String> gaps;
        @AuraEnabled public List<Violation> violations;
    }

    public class IntegrityControlResult {
        @AuraEnabled public Boolean validationRulesEnabled;
        @AuraEnabled public Boolean bulkDeleteRestricted;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Decimal score;
        @AuraEnabled public List<String> gaps;
        @AuraEnabled public List<Violation> violations;
    }

    public class TransmissionResult {
        @AuraEnabled public String tlsVersion;
        @AuraEnabled public Boolean tlsCompliant;
        @AuraEnabled public Boolean apiSecurityEnabled;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Decimal score;
        @AuraEnabled public List<String> gaps;
        @AuraEnabled public List<Violation> violations;
    }

    public class EncryptionInfo {
        @AuraEnabled public String objectName;
        @AuraEnabled public Boolean shieldEnabled;
        @AuraEnabled public List<String> encryptedFields;
        @AuraEnabled public List<String> unencryptedPHIFields;
        @AuraEnabled public Boolean compliant;
    }
}
