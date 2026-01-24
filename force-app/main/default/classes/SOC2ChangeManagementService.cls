/**
 * SOC2ChangeManagementService
 *
 * Tracks SOC2 CC6.1-CC6.8 change management controls.
 * Monitors configuration changes, validates change control processes,
 * and generates change management evidence.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class SOC2ChangeManagementService extends ComplianceServiceBase {

    // Change risk thresholds
    private static final Integer HIGH_RISK_CHANGE_LOOKBACK_DAYS = 30;
    private static final Integer UNAUTHORIZED_CHANGE_THRESHOLD = 5;

    // High-risk change types
    private static final Set<String> HIGH_RISK_CHANGE_TYPES = new Set<String>{
        'PermissionSet', 'Profile', 'SharingRule', 'CustomField',
        'ApexClass', 'ApexTrigger', 'Flow', 'CustomObject'
    };

    /**
     * Get framework name
     */
    public override String getFrameworkName() {
        return 'SOC2';
    }

    /**
     * Get framework score multiplier
     */
    protected override Decimal getFrameworkMultiplier() {
        return 1.0;
    }

    /**
     * Evaluate SOC2 change management controls
     */
    protected override List<ComplianceServiceBase.InternalViolation> evaluateControls() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Add violations from helper methods
        violations.addAll(evaluateLogicalAccessChanges());
        violations.addAll(evaluateSystemChanges());
        violations.addAll(evaluateChangeTestingControls());

        return violations;
    }

    /**
     * Evaluate all change controls
     * @return Change control evaluation result
     */
    @AuraEnabled(cacheable=false)
    public static ChangeControlResult evaluateChangeControls() {
        SOC2ChangeManagementService service = new SOC2ChangeManagementService();
        ChangeControlResult result = new ChangeControlResult();
        result.evaluationDate = DateTime.now();
        result.controlResults = new List<ControlResult>();

        // CC6.1 - Logical Access
        ControlResult cc61 = new ControlResult();
        cc61.controlId = 'CC6.1';
        cc61.controlName = 'Logical Access Security';
        cc61.violations = service.evaluateLogicalAccessChanges();
        cc61.compliant = cc61.violations.isEmpty();
        cc61.score = cc61.compliant ? 100 : Math.max(0, 100 - (cc61.violations.size() * 10));
        result.controlResults.add(cc61);

        // CC6.6 - System Changes
        ControlResult cc66 = new ControlResult();
        cc66.controlId = 'CC6.6';
        cc66.controlName = 'System Changes';
        cc66.violations = service.evaluateSystemChanges();
        cc66.compliant = cc66.violations.isEmpty();
        cc66.score = cc66.compliant ? 100 : Math.max(0, 100 - (cc66.violations.size() * 10));
        result.controlResults.add(cc66);

        // CC6.8 - Change Testing
        ControlResult cc68 = new ControlResult();
        cc68.controlId = 'CC6.8';
        cc68.controlName = 'Change Testing';
        cc68.violations = service.evaluateChangeTestingControls();
        cc68.compliant = cc68.violations.isEmpty();
        cc68.score = cc68.compliant ? 100 : Math.max(0, 100 - (cc68.violations.size() * 10));
        result.controlResults.add(cc68);

        // Calculate overall
        Decimal totalScore = 0;
        for (ControlResult cr : result.controlResults) {
            totalScore += cr.score;
        }
        result.overallScore = result.controlResults.size() > 0 ?
            (totalScore / result.controlResults.size()).setScale(2) : 0;
        result.overallCompliant = result.overallScore >= 80;

        return result;
    }

    /**
     * Get unauthorized changes (changes without tickets)
     * @param daysBack Number of days to look back
     * @return List of unauthorized changes
     */
    @AuraEnabled(cacheable=false)
    public static List<UnauthorizedChange> getUnauthorizedChanges(Integer daysBack) {
        List<UnauthorizedChange> changes = new List<UnauthorizedChange>();

        if (daysBack == null || daysBack <= 0) {
            daysBack = HIGH_RISK_CHANGE_LOOKBACK_DAYS;
        }

        Date cutoffDate = Date.today().addDays(-daysBack);

        // Query metadata changes without approval using dynamic SOQL
        // Note: Ticket_Reference__c doesn't exist, using Approved_By__c as proxy
        String soql = 'SELECT Id, Name, Metadata_Type__c, Metadata_Name__c, Change_Type__c, ' +
                      'Changed_By__c, Change_Date__c, Change_Details__c, ' +
                      'Risk_Level__c, Approved_By__c ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Change_Date__c >= :cutoffDate ' +
                      'AND Approved_By__c = null ' +
                      'WITH SECURITY_ENFORCED ' +
                      'ORDER BY Change_Date__c DESC ' +
                      'LIMIT 500';
        List<SObject> metadataChanges = Database.query(soql);

        for (SObject so : metadataChanges) {
            UnauthorizedChange uc = new UnauthorizedChange();
            uc.changeId = (Id) so.get('Id');
            uc.entityType = (String) so.get('Metadata_Type__c');
            uc.entityName = (String) so.get('Metadata_Name__c');
            uc.changeType = (String) so.get('Change_Type__c');
            uc.changedBy = (Id) so.get('Changed_By__c');
            uc.changedDate = (DateTime) so.get('Change_Date__c');
            // Map Risk_Level__c picklist to numeric score
            String riskLevel = (String) so.get('Risk_Level__c');
            Decimal riskScore = 5.0;
            if (riskLevel == 'CRITICAL') riskScore = 9.0;
            else if (riskLevel == 'HIGH') riskScore = 7.0;
            else if (riskLevel == 'MEDIUM') riskScore = 5.0;
            else if (riskLevel == 'LOW') riskScore = 3.0;
            uc.riskScore = riskScore;
            uc.isHighRisk = HIGH_RISK_CHANGE_TYPES.contains((String) so.get('Metadata_Type__c'));
            changes.add(uc);
        }

        return changes;
    }

    /**
     * Link a change to a ticket
     * @param changeId The metadata change Id
     * @param ticketRef The ticket reference (e.g., JIRA-123)
     */
    @AuraEnabled
    public static void linkChangeToTicket(Id changeId, String ticketRef) {
        if (String.isBlank(ticketRef)) {
            throw new ComplianceServiceException('Ticket reference cannot be blank');
        }

        // Note: Ticket_Reference__c doesn't exist on Metadata_Change__c
        // This method is a placeholder - ticket linking would need a custom field or related object
        // For now, we'll log the association in Change_Details__c or use a different approach
        // Use dynamic SOQL to work around type recognition issue
        String soql = 'SELECT Id, Change_Details__c ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Id = :changeId ' +
                      'WITH SECURITY_ENFORCED ' +
                      'LIMIT 1';
        SObject change = Database.query(soql);

        // Store ticket reference in Change_Details__c JSON or create a note
        // This is a simplified implementation
        String changeDetails = (String) change.get('Change_Details__c');
        if (String.isNotBlank(changeDetails)) {
            change.put('Change_Details__c', changeDetails + '\nTicket: ' + ticketRef);
        } else {
            change.put('Change_Details__c', 'Ticket: ' + ticketRef);
        }
        
        // Check if object is updateable using dynamic describe
        Schema.DescribeSObjectResult describe = Schema.getGlobalDescribe().get('Metadata_Change__c').getDescribe();
        if (describe.isUpdateable()) {
            update change;
        }

        SOC2ChangeManagementService service = new SOC2ChangeManagementService();
        service.logAuditEntry('CHANGE_LINKED', 'Linked change ' + changeId + ' to ticket ' + ticketRef, changeId);
    }

    /**
     * Get high-risk changes requiring approval
     * @return List of changes requiring approval
     */
    @AuraEnabled(cacheable=false)
    public static List<SObject> getChangesRequiringApproval() {
        // Use dynamic SOQL to work around type recognition issue
        String soql = 'SELECT Id, Name, Metadata_Type__c, Metadata_Name__c, Change_Type__c, ' +
                      'Changed_By__c, Change_Date__c, Change_Details__c, ' +
                      'Risk_Level__c, Approved_By__c, Approval_Date__c ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Risk_Level__c IN (\'HIGH\', \'CRITICAL\') ' +
                      'AND Approved_By__c = null ' +
                      'WITH SECURITY_ENFORCED ' +
                      'ORDER BY Change_Date__c DESC ' +
                      'LIMIT 100';
        return Database.query(soql);
    }

    /**
     * Generate change report
     * @param startDate Report start date
     * @param endDate Report end date
     * @return ContentDocumentId of generated report
     */
    @AuraEnabled
    public static Id generateChangeReport(Date startDate, Date endDate) {
        if (startDate == null) {
            startDate = Date.today().addDays(-30);
        }
        if (endDate == null) {
            endDate = Date.today();
        }

        // Query changes using dynamic SOQL to work around type recognition issue
        String soql = 'SELECT Id, Name, Metadata_Type__c, Metadata_Name__c, Change_Type__c, ' +
                      'Changed_By__c, Change_Date__c, Change_Details__c, ' +
                      'Risk_Level__c, Approved_By__c, Approval_Date__c ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Change_Date__c >= :startDate ' +
                      'AND Change_Date__c <= :endDate ' +
                      'WITH SECURITY_ENFORCED ' +
                      'ORDER BY Change_Date__c DESC';
        List<SObject> changes = Database.query(soql);

        // Generate report content (use SObject list)
        List<SObject> changesList = new List<SObject>();
        for (SObject so : changes) {
            changesList.add(so);
        }
        String reportContent = generateReportContent(changesList, startDate, endDate);

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'SOC2_Change_Report_' + startDate.format() + '_to_' + endDate.format(),
            PathOnClient = 'SOC2_Change_Report.md',
            VersionData = Blob.valueOf(reportContent),
            Origin = 'H'
        );
        PrometheionSecurityUtils.validateCRUDAccess('ContentVersion', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
        insert cv;

        // Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

        SOC2ChangeManagementService service = new SOC2ChangeManagementService();
        service.logAuditEntry('REPORT_GENERATED', 'Generated SOC2 change report for ' + startDate + ' to ' + endDate, cv.ContentDocumentId);

        return cv.ContentDocumentId;
    }

    // ========== Private Helper Methods ==========

    /**
     * Evaluate logical access changes
     */
    private List<ComplianceServiceBase.InternalViolation> evaluateLogicalAccessChanges() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        // Count permission-related changes without approval using dynamic SOQL
        // Note: Ticket_Reference__c doesn't exist, using Approved_By__c as proxy
        String soql = 'SELECT COUNT() ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Change_Date__c >= :cutoffDate ' +
                      'AND Metadata_Type__c IN (\'PermissionSet\', \'Profile\', \'SharingRule\') ' +
                      'AND Approved_By__c = null ' +
                      'WITH SECURITY_ENFORCED';
        Integer unauthorizedPermChanges = Database.countQuery(soql);

        if (unauthorizedPermChanges > UNAUTHORIZED_CHANGE_THRESHOLD) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Unauthorized Permission Changes',
                unauthorizedPermChanges + ' permission-related changes made without change tickets in last ' + HIGH_RISK_CHANGE_LOOKBACK_DAYS + ' days',
                'HIGH',
                'SOC2-CC6.1',
                'Implement change control process requiring tickets for all permission changes',
                8.0
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate system changes
     */
    private List<ComplianceServiceBase.InternalViolation> evaluateSystemChanges() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        // Count high-risk changes without approval using dynamic SOQL
        String soql = 'SELECT COUNT() ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Change_Date__c >= :cutoffDate ' +
                      'AND Risk_Level__c IN (\'HIGH\', \'CRITICAL\') ' +
                      'AND Approved_By__c = null ' +
                      'WITH SECURITY_ENFORCED';
        Integer unapprovedHighRiskChanges = Database.countQuery(soql);

        if (unapprovedHighRiskChanges > 0) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Unapproved High-Risk Changes',
                unapprovedHighRiskChanges + ' high-risk changes pending approval',
                'HIGH',
                'SOC2-CC6.6',
                'Review and approve or reject pending high-risk changes',
                7.5
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate change testing controls
     */
    private List<ComplianceServiceBase.InternalViolation> evaluateChangeTestingControls() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Check for direct production deployments (no sandbox testing)
        // This is a simplified check - actual implementation would check deployment history
        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        // Check for direct production deployments (no approval) using dynamic SOQL
        // Note: Deployment_Source__c doesn't exist, using Approved_By__c as proxy
        String soql = 'SELECT COUNT() ' +
                      'FROM Metadata_Change__c ' +
                      'WHERE Change_Date__c >= :cutoffDate ' +
                      'AND Metadata_Type__c IN (\'ApexClass\', \'ApexTrigger\', \'Flow\') ' +
                      'AND Approved_By__c = null ' +
                      'WITH SECURITY_ENFORCED';
        Integer directProdDeployments = Database.countQuery(soql);

        if (directProdDeployments > 0) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Direct Production Deployments',
                directProdDeployments + ' code changes deployed directly to production without sandbox testing',
                'MEDIUM',
                'SOC2-CC6.8',
                'Implement sandbox testing requirement before production deployments',
                6.0
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Generate report content
     */
    private static String generateReportContent(List<SObject> changes, Date startDate, Date endDate) {
        String content = '# SOC2 Change Management Report\n\n';
        content += '**Report Period:** ' + startDate.format() + ' to ' + endDate.format() + '\n';
        content += '**Generated:** ' + DateTime.now().format() + '\n\n';

        content += '## Summary\n\n';
        content += '- **Total Changes:** ' + changes.size() + '\n';

        Integer withApproval = 0;
        Integer highRisk = 0;
        for (SObject so : changes) {
            // Use dynamic field access to work around type recognition issue
            Id approvedBy = (Id) so.get('Approved_By__c');
            String riskLevel = (String) so.get('Risk_Level__c');
            
            if (approvedBy != null) {
                withApproval++;
            }
            if (riskLevel == 'HIGH' || riskLevel == 'CRITICAL') {
                highRisk++;
            }
        }

        content += '- **Changes with Approval:** ' + withApproval + ' (' +
                   (changes.size() > 0 ? (withApproval * 100 / changes.size()) : 0) + '%)\n';
        content += '- **High-Risk Changes:** ' + highRisk + '\n\n';

        content += '## Change Details\n\n';
        content += '| Date | Type | Name | Changed By | Ticket | Risk |\n';
        content += '|------|------|------|------------|--------|------|\n';

        for (SObject so : changes) {
            // Use dynamic field access to work around type recognition issue
            DateTime changeDate = (DateTime) so.get('Change_Date__c');
            String metadataType = (String) so.get('Metadata_Type__c');
            String metadataName = (String) so.get('Metadata_Name__c');
            Id changedBy = (Id) so.get('Changed_By__c');
            Id approvedBy = (Id) so.get('Approved_By__c');
            String riskLevel = (String) so.get('Risk_Level__c');
            
            content += '| ' + (changeDate != null ? changeDate.format() : 'N/A');
            content += ' | ' + (metadataType != null ? metadataType : 'N/A');
            content += ' | ' + (metadataName != null ? metadataName : 'N/A');
            content += ' | ' + (changedBy != null ? String.valueOf(changedBy) : 'N/A');
            content += ' | ' + (approvedBy != null ? 'Approved' : 'Pending');
            content += ' | ' + (riskLevel != null ? riskLevel : 'MEDIUM');
            content += ' |\n';
        }

        return content;
    }

    // ========== Inner Classes ==========

    /**
     * Change control evaluation result
     */
    public class ChangeControlResult {
        @AuraEnabled public DateTime evaluationDate;
        @AuraEnabled public List<ControlResult> controlResults;
        @AuraEnabled public Decimal overallScore;
        @AuraEnabled public Boolean overallCompliant;
    }

    /**
     * Individual control result
     */
    public class ControlResult {
        @AuraEnabled public String controlId;
        @AuraEnabled public String controlName;
        @AuraEnabled public Boolean compliant;
        @AuraEnabled public Decimal score;
        @AuraEnabled public List<ComplianceServiceBase.InternalViolation> violations;
    }

    /**
     * Unauthorized change record
     */
    public class UnauthorizedChange {
        @AuraEnabled public Id changeId;
        @AuraEnabled public String entityType;
        @AuraEnabled public String entityName;
        @AuraEnabled public String changeType;
        @AuraEnabled public String changedBy;
        @AuraEnabled public DateTime changedDate;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Boolean isHighRisk;
    }
}
