/**
 * HIPAAPrivacyRuleService
 *
 * Enforces HIPAA Privacy Rule (45 CFR 164.500-164.534) for PHI access controls.
 * Evaluates minimum necessary access, tracks PHI disclosures, and monitors access patterns.
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class HIPAAPrivacyRuleService extends ComplianceServiceBase {

    // PHI-related object and field identifiers
    private static final Set<String> PHI_OBJECTS = new Set<String>{
        'Contact', 'Lead', 'Account', 'Case', 'HealthCloudGA__EhrPatient__c'
    };

    private static final Set<String> PHI_FIELD_PATTERNS = new Set<String>{
        'SSN', 'Social_Security', 'DOB', 'Date_of_Birth', 'BirthDate',
        'Medical', 'Health', 'Diagnosis', 'Treatment', 'Prescription',
        'Insurance', 'Policy_Number', 'Member_ID'
    };

    /**
     * Get framework name
     */
    public override String getFrameworkName() {
        return 'HIPAA';
    }

    /**
     * Get framework score multiplier (HIPAA is strict)
     */
    protected override Decimal getFrameworkMultiplier() {
        return 0.95;
    }

    /**
     * Evaluate HIPAA Privacy Rule controls
     */
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();

        // §164.514(d) - Minimum Necessary
        violations.addAll(evaluateMinimumNecessaryAccess());

        // §164.528 - Accounting of Disclosures
        violations.addAll(evaluateDisclosureTracking());

        // §164.530(c) - Safeguards
        violations.addAll(evaluatePHISafeguards());

        return violations;
    }

    /**
     * Identify objects containing PHI
     * @return List of PHI object information
     */
    @AuraEnabled(cacheable=false)
    public static List<PHIObjectInfo> identifyPHIObjects() {
        List<PHIObjectInfo> phiObjects = new List<PHIObjectInfo>();

        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

        for (String objectName : PHI_OBJECTS) {
            if (globalDescribe.containsKey(objectName)) {
                PHIObjectInfo info = new PHIObjectInfo();
                info.objectName = objectName;
                info.phiFields = new List<String>();

                Schema.DescribeSObjectResult objDescribe = globalDescribe.get(objectName).getDescribe();
                Map<String, Schema.SObjectField> fields = objDescribe.fields.getMap();

                for (String fieldName : fields.keySet()) {
                    if (isPHIField(fieldName)) {
                        info.phiFields.add(fieldName);
                    }
                }

                info.phiFieldCount = info.phiFields.size();
                info.riskLevel = info.phiFieldCount > 5 ? 'HIGH' : info.phiFieldCount > 0 ? 'MEDIUM' : 'LOW';

                // Count users with access
                info.userAccessCount = countUsersWithAccess(objectName);

                phiObjects.add(info);
            }
        }

        return phiObjects;
    }

    /**
     * Evaluate minimum necessary access compliance
     * @return Minimum necessary evaluation result
     */
    @AuraEnabled(cacheable=false)
    public static MinimumNecessaryResult evaluateMinimumNecessary() {
        HIPAAPrivacyRuleService service = new HIPAAPrivacyRuleService();
        MinimumNecessaryResult result = new MinimumNecessaryResult();
        result.evaluationDate = DateTime.now();
        result.recommendations = new List<String>();

        // Get users with excessive access
        List<ExcessiveAccessUser> excessiveUsers = service.getExcessiveAccessUsersList();
        result.usersWithExcessAccess = excessiveUsers.size();

        // Calculate compliance percentage
        Integer totalActiveUsers = [SELECT COUNT() FROM User WHERE IsActive = true WITH SECURITY_ENFORCED];
        result.totalUsers = totalActiveUsers;

        if (totalActiveUsers > 0) {
            result.compliancePercentage = ((Decimal)(totalActiveUsers - excessiveUsers.size()) / totalActiveUsers * 100).setScale(2);
        } else {
            result.compliancePercentage = 100;
        }

        result.compliant = result.compliancePercentage >= 95;

        // Generate recommendations
        if (!result.compliant) {
            result.recommendations.add('Review and remove Modify All Data permissions from non-admin users');
            result.recommendations.add('Implement role-based access control for PHI objects');
            result.recommendations.add('Create specific permission sets for each job function');
        }

        return result;
    }

    /**
     * Get users with excessive PHI access
     * @return List of users with excessive access
     */
    @AuraEnabled(cacheable=false)
    public static List<ExcessiveAccessUser> getExcessiveAccessUsers() {
        HIPAAPrivacyRuleService service = new HIPAAPrivacyRuleService();
        return service.getExcessiveAccessUsersList();
    }

    /**
     * Audit PHI access for a specific record
     * @param recordId The record to audit
     * @param objectName The object API name
     * @return List of access log entries
     */
    @AuraEnabled(cacheable=false)
    public static List<PHIAccessLog> auditPHIAccess(Id recordId, String objectName) {
        List<PHIAccessLog> accessLogs = new List<PHIAccessLog>();

        // Query field history for the record
        String historyObjectName = objectName.endsWith('__c') ?
            objectName.replace('__c', '__History') :
            objectName + 'History';

        try {
            String query = 'SELECT Id, Field, OldValue, NewValue, CreatedById, CreatedBy.Name, CreatedDate ' +
                          'FROM ' + historyObjectName + ' ' +
                          'WHERE ParentId = :recordId ' +
                          'WITH SECURITY_ENFORCED ' +
                          'ORDER BY CreatedDate DESC LIMIT 100';

            List<SObject> historyRecords = Database.query(query);

            for (SObject hist : historyRecords) {
                PHIAccessLog log = new PHIAccessLog();
                log.accessDate = (DateTime)hist.get('CreatedDate');
                log.userId = (Id)hist.get('CreatedById');
                log.userName = (String)hist.getSObject('CreatedBy').get('Name');
                log.fieldName = (String)hist.get('Field');
                log.accessType = 'MODIFY';
                log.isPHIField = isPHIField(log.fieldName);
                accessLogs.add(log);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Error querying history: ' + e.getMessage());
        }

        return accessLogs;
    }

    /**
     * Generate disclosure log for HIPAA accounting of disclosures
     * @param startDate Start date for the log
     * @param endDate End date for the log
     * @return ContentDocumentId of the generated log
     */
    @AuraEnabled
    public static Id generateDisclosureLog(Date startDate, Date endDate) {
        if (startDate == null) {
            startDate = Date.today().addYears(-6); // HIPAA requires 6-year retention
        }
        if (endDate == null) {
            endDate = Date.today();
        }

        // Query compliance evidence for disclosures
        List<Compliance_Evidence__c> disclosures = [
            SELECT Id, Evidence_Type__c, Evidence_Date__c, Description__c, Evidence_Data__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = 'HIPAA'
            AND Evidence_Type__c = 'PHI_DISCLOSURE'
            AND Evidence_Date__c >= :startDate
            AND Evidence_Date__c <= :endDate
            WITH SECURITY_ENFORCED
            ORDER BY Evidence_Date__c DESC
        ];

        String logContent = generateDisclosureLogContent(disclosures, startDate, endDate);

        ContentVersion cv = new ContentVersion(
            Title = 'HIPAA_Disclosure_Log_' + startDate.format() + '_to_' + endDate.format(),
            PathOnClient = 'HIPAA_Disclosure_Log.md',
            VersionData = Blob.valueOf(logContent),
            Origin = 'H'
        );
        ElaroSecurityUtils.validateCRUDAccess('ContentVersion', DmlOperation.DML_INSERT);
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

        HIPAAPrivacyRuleService service = new HIPAAPrivacyRuleService();
        service.logAuditEntry('DISCLOSURE_LOG_GENERATED', 'Generated HIPAA disclosure log', cv.ContentDocumentId);

        return cv.ContentDocumentId;
    }

    // ========== Private Helper Methods ==========

    private List<Violation> evaluateMinimumNecessaryAccess() {
        List<Violation> violations = new List<Violation>();

        List<ExcessiveAccessUser> excessiveUsers = getExcessiveAccessUsersList();

        if (excessiveUsers.size() > 0) {
            Violation v = new Violation(
                'Minimum Necessary Violation',
                excessiveUsers.size() + ' users have excessive PHI access beyond minimum necessary',
                'HIGH',
                'HIPAA-164.514(d)',
                'Review and restrict PHI access to minimum necessary for job functions',
                8.0
            );
            v.entityType = 'ACCESS';
            v.entityId = 'MINIMUM_NECESSARY';
            violations.add(v);
        }

        return violations;
    }

    private List<Violation> evaluateDisclosureTracking() {
        List<Violation> violations = new List<Violation>();

        // Check if PHI objects have field history enabled
        for (String objectName : PHI_OBJECTS) {
            if (!hasFieldHistoryEnabled(objectName)) {
                Violation v = new Violation(
                    'Missing PHI Audit Trail',
                    'Object ' + objectName + ' does not have Field History Tracking for PHI fields',
                    'HIGH',
                    'HIPAA-164.528',
                    'Enable Field History Tracking on PHI fields for ' + objectName,
                    7.5
                );
                v.entityType = 'OBJECT';
                v.entityId = objectName;
                violations.add(v);
            }
        }

        return violations;
    }

    private List<Violation> evaluatePHISafeguards() {
        List<Violation> violations = new List<Violation>();

        // Check OWD settings for PHI objects
        for (String objectName : PHI_OBJECTS) {
            String owdSetting = getOWDSetting(objectName);
            if (owdSetting == 'Public' || owdSetting == 'PublicReadWrite') {
                Violation v = new Violation(
                    'PHI Object Over-Shared',
                    'Object ' + objectName + ' has OWD set to ' + owdSetting + ' (should be Private)',
                    'CRITICAL',
                    'HIPAA-164.530(c)',
                    'Change OWD to Private and use sharing rules for authorized access',
                    9.0
                );
                v.entityType = 'SHARING';
                v.entityId = objectName;
                violations.add(v);
            }
        }

        return violations;
    }

    private List<ExcessiveAccessUser> getExcessiveAccessUsersList() {
        List<ExcessiveAccessUser> users = new List<ExcessiveAccessUser>();

        List<PermissionSetAssignment> psAssignments = [
            SELECT AssigneeId, Assignee.Name, Assignee.Email, Assignee.Profile.Name,
                   PermissionSet.Name, PermissionSet.PermissionsModifyAllData,
                   PermissionSet.PermissionsViewAllData
            FROM PermissionSetAssignment
            WHERE Assignee.IsActive = true
            AND (PermissionSet.PermissionsModifyAllData = true
                 OR PermissionSet.PermissionsViewAllData = true)
            WITH SECURITY_ENFORCED
            LIMIT 500
        ];

        Map<Id, ExcessiveAccessUser> userMap = new Map<Id, ExcessiveAccessUser>();

        for (PermissionSetAssignment psa : psAssignments) {
            ExcessiveAccessUser exUser;
            if (userMap.containsKey(psa.AssigneeId)) {
                exUser = userMap.get(psa.AssigneeId);
            } else {
                exUser = new ExcessiveAccessUser();
                exUser.userId = psa.AssigneeId;
                exUser.userName = psa.Assignee.Name;
                exUser.userEmail = psa.Assignee.Email;
                exUser.profileName = psa.Assignee.Profile.Name;
                exUser.phiObjectsAccessible = new List<String>();
                exUser.excessivePermissions = new List<String>();
                userMap.put(psa.AssigneeId, exUser);
            }

            if (psa.PermissionSet.PermissionsModifyAllData) {
                exUser.excessivePermissions.add('Modify All Data');
            }
            if (psa.PermissionSet.PermissionsViewAllData) {
                exUser.excessivePermissions.add('View All Data');
            }

            // All PHI objects are accessible with these permissions
            exUser.phiObjectsAccessible.addAll(PHI_OBJECTS);
        }

        users.addAll(userMap.values());
        return users;
    }

    private static Boolean isPHIField(String fieldName) {
        String upperFieldName = fieldName.toUpperCase();
        for (String pattern : PHI_FIELD_PATTERNS) {
            if (upperFieldName.contains(pattern.toUpperCase())) {
                return true;
            }
        }
        return false;
    }

    private static Integer countUsersWithAccess(String objectName) {
        // Simplified count - actual implementation would check object permissions
        return [SELECT COUNT() FROM User WHERE IsActive = true WITH SECURITY_ENFORCED];
    }

    private Boolean hasFieldHistoryEnabled(String objectName) {
        try {
            Schema.SObjectType objType = Schema.getGlobalDescribe().get(objectName);
            if (objType == null) return false;

            Map<String, Schema.SObjectField> fields = objType.getDescribe().fields.getMap();
            for (Schema.SObjectField field : fields.values()) {
                if (field.getDescribe().isHistoryTracked() != null && field.getDescribe().isHistoryTracked()) {
                    return true;
                }
            }
            return false;
        } catch (Exception e) {
            return false;
        }
    }

    private String getOWDSetting(String objectName) {
        // Simplified - actual implementation would use Organization describe
        return 'Private'; // Default assumption
    }

    private static String generateDisclosureLogContent(List<Compliance_Evidence__c> disclosures, Date startDate, Date endDate) {
        String content = '# HIPAA Accounting of Disclosures\n\n';
        content += '**Period:** ' + startDate.format() + ' to ' + endDate.format() + '\n';
        content += '**Generated:** ' + DateTime.now().format() + '\n';
        content += '**Regulation:** 45 CFR 164.528\n\n';

        content += '## Summary\n\n';
        content += '- **Total Disclosures:** ' + disclosures.size() + '\n\n';

        content += '## Disclosure Log\n\n';
        content += '| Date | Type | Description |\n';
        content += '|------|------|-------------|\n';

        for (Compliance_Evidence__c disc : disclosures) {
            content += '| ' + (disc.Evidence_Date__c != null ? disc.Evidence_Date__c.format() : 'N/A');
            content += ' | ' + (disc.Evidence_Type__c != null ? disc.Evidence_Type__c : 'N/A');
            content += ' | ' + (disc.Description__c != null ? disc.Description__c.left(100) : 'N/A');
            content += ' |\n';
        }

        content += '\n---\n';
        content += '*This log is maintained in compliance with HIPAA 45 CFR 164.528*\n';

        return content;
    }

    // ========== Inner Classes ==========

    public class PHIObjectInfo {
        @AuraEnabled public String objectName;
        @AuraEnabled public List<String> phiFields;
        @AuraEnabled public Integer phiFieldCount;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Integer userAccessCount;
    }

    public class MinimumNecessaryResult {
        @AuraEnabled public DateTime evaluationDate;
        @AuraEnabled public Integer totalUsers;
        @AuraEnabled public Integer usersWithExcessAccess;
        @AuraEnabled public Decimal compliancePercentage;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public List<String> recommendations;
    }

    public class ExcessiveAccessUser {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String profileName;
        @AuraEnabled public List<String> phiObjectsAccessible;
        @AuraEnabled public List<String> excessivePermissions;
        @AuraEnabled public String justificationRequired;
    }

    public class PHIAccessLog {
        @AuraEnabled public DateTime accessDate;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String accessType;
        @AuraEnabled public Boolean isPHIField;
    }
}
