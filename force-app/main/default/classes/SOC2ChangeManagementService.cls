/**
 * SOC2ChangeManagementService
 *
 * Tracks SOC2 CC6.1-CC6.8 change management controls.
 * Monitors configuration changes, validates change control processes,
 * and generates change management evidence.
 *
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
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
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();

        // CC6.1 - Logical Access Security
        violations.addAll(evaluateLogicalAccessChanges());

        // CC6.6 - System Changes
        violations.addAll(evaluateSystemChanges());

        // CC6.8 - Change Testing
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

        // Query metadata changes without ticket references
        List<Metadata_Change__c> metadataChanges = [
            SELECT Id, Name, Entity_Type__c, Entity_Name__c, Change_Type__c,
                   Changed_By__c, Changed_Date__c, Change_Details__c,
                   Ticket_Reference__c, Risk_Score__c
            FROM Metadata_Change__c
            WHERE Changed_Date__c >= :cutoffDate
            AND (Ticket_Reference__c = null OR Ticket_Reference__c = '')
            WITH USER_MODE
            ORDER BY Changed_Date__c DESC
            LIMIT 500
        ];

        for (Metadata_Change__c mc : metadataChanges) {
            UnauthorizedChange uc = new UnauthorizedChange();
            uc.changeId = mc.Id;
            uc.entityType = mc.Entity_Type__c;
            uc.entityName = mc.Entity_Name__c;
            uc.changeType = mc.Change_Type__c;
            uc.changedBy = mc.Changed_By__c;
            uc.changedDate = mc.Changed_Date__c;
            uc.riskScore = mc.Risk_Score__c != null ? mc.Risk_Score__c : 5.0;
            uc.isHighRisk = HIGH_RISK_CHANGE_TYPES.contains(mc.Entity_Type__c);
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

        Metadata_Change__c change = [
            SELECT Id, Ticket_Reference__c
            FROM Metadata_Change__c
            WHERE Id = :changeId
            WITH USER_MODE
            LIMIT 1
        ];

        change.Ticket_Reference__c = ticketRef;
        update as user change;

        SOC2ChangeManagementService service = new SOC2ChangeManagementService();
        service.logAuditEntry('CHANGE_LINKED', 'Linked change ' + changeId + ' to ticket ' + ticketRef, changeId);
    }

    /**
     * Get high-risk changes requiring approval
     * @return List of changes requiring approval
     */
    @AuraEnabled(cacheable=false)
    public static List<Metadata_Change__c> getChangesRequiringApproval() {
        return [
            SELECT Id, Name, Entity_Type__c, Entity_Name__c, Change_Type__c,
                   Changed_By__c, Changed_Date__c, Change_Details__c,
                   Ticket_Reference__c, Risk_Score__c, Approval_Status__c
            FROM Metadata_Change__c
            WHERE Risk_Score__c >= 7.0
            AND (Approval_Status__c = null OR Approval_Status__c = 'PENDING')
            WITH USER_MODE
            ORDER BY Risk_Score__c DESC
            LIMIT 100
        ];
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

        // Query changes
        List<Metadata_Change__c> changes = [
            SELECT Id, Name, Entity_Type__c, Entity_Name__c, Change_Type__c,
                   Changed_By__c, Changed_Date__c, Change_Details__c,
                   Ticket_Reference__c, Risk_Score__c, Approval_Status__c
            FROM Metadata_Change__c
            WHERE Changed_Date__c >= :startDate
            AND Changed_Date__c <= :endDate
            WITH USER_MODE
            ORDER BY Changed_Date__c DESC
        ];

        // Generate report content
        String reportContent = generateReportContent(changes, startDate, endDate);

        // Create ContentVersion
        ContentVersion cv = new ContentVersion(
            Title = 'SOC2_Change_Report_' + startDate.format() + '_to_' + endDate.format(),
            PathOnClient = 'SOC2_Change_Report.md',
            VersionData = Blob.valueOf(reportContent),
            Origin = 'H'
        );
        ElaroSecurityUtils.validateCRUDAccess('ContentVersion', DmlOperation.DML_INSERT);
        insert as user cv;

        // Get ContentDocumentId
        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH USER_MODE];

        SOC2ChangeManagementService service = new SOC2ChangeManagementService();
        service.logAuditEntry('REPORT_GENERATED', 'Generated SOC2 change report for ' + startDate + ' to ' + endDate, cv.ContentDocumentId);

        return cv.ContentDocumentId;
    }

    // ========== Private Helper Methods ==========

    /**
     * Evaluate logical access changes
     */
    private List<Violation> evaluateLogicalAccessChanges() {
        List<Violation> violations = new List<Violation>();

        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        // Count permission-related changes without tickets
        Integer unauthorizedPermChanges = [
            SELECT COUNT()
            FROM Metadata_Change__c
            WHERE Changed_Date__c >= :cutoffDate
            AND Entity_Type__c IN ('PermissionSet', 'Profile', 'SharingRule')
            AND (Ticket_Reference__c = null OR Ticket_Reference__c = '')
            WITH USER_MODE
        ];

        if (unauthorizedPermChanges > UNAUTHORIZED_CHANGE_THRESHOLD) {
            Violation v = new Violation(
                'Unauthorized Permission Changes',
                unauthorizedPermChanges + ' permission-related changes made without change tickets in last ' + HIGH_RISK_CHANGE_LOOKBACK_DAYS + ' days',
                'HIGH',
                'SOC2-CC6.1',
                'Implement change control process requiring tickets for all permission changes',
                8.0
            );
            v.entityType = 'PROCESS';
            v.entityId = 'CHANGE_CONTROL';
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate system changes
     */
    private List<Violation> evaluateSystemChanges() {
        List<Violation> violations = new List<Violation>();

        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        // Count high-risk changes without approval
        Integer unapprovedHighRiskChanges = [
            SELECT COUNT()
            FROM Metadata_Change__c
            WHERE Changed_Date__c >= :cutoffDate
            AND Risk_Score__c >= 7.0
            AND (Approval_Status__c = null OR Approval_Status__c = 'PENDING')
            WITH USER_MODE
        ];

        if (unapprovedHighRiskChanges > 0) {
            Violation v = new Violation(
                'Unapproved High-Risk Changes',
                unapprovedHighRiskChanges + ' high-risk changes pending approval',
                'HIGH',
                'SOC2-CC6.6',
                'Review and approve or reject pending high-risk changes',
                7.5
            );
            v.entityType = 'PROCESS';
            v.entityId = 'APPROVAL_WORKFLOW';
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate change testing controls
     */
    private List<Violation> evaluateChangeTestingControls() {
        List<Violation> violations = new List<Violation>();

        // Check for direct production deployments (no sandbox testing)
        // This is a simplified check - actual implementation would check deployment history
        Date cutoffDate = Date.today().addDays(-HIGH_RISK_CHANGE_LOOKBACK_DAYS);

        Integer directProdDeployments = [
            SELECT COUNT()
            FROM Metadata_Change__c
            WHERE Changed_Date__c >= :cutoffDate
            AND Entity_Type__c IN ('ApexClass', 'ApexTrigger', 'Flow')
            AND Deployment_Source__c = 'DIRECT'
            WITH USER_MODE
        ];

        if (directProdDeployments > 0) {
            Violation v = new Violation(
                'Direct Production Deployments',
                directProdDeployments + ' code changes deployed directly to production without sandbox testing',
                'MEDIUM',
                'SOC2-CC6.8',
                'Implement sandbox testing requirement before production deployments',
                6.0
            );
            v.entityType = 'PROCESS';
            v.entityId = 'DEPLOYMENT_PROCESS';
            violations.add(v);
        }

        return violations;
    }

    /**
     * Generate report content
     */
    private static String generateReportContent(List<Metadata_Change__c> changes, Date startDate, Date endDate) {
        String content = '# SOC2 Change Management Report\n\n';
        content += '**Report Period:** ' + startDate.format() + ' to ' + endDate.format() + '\n';
        content += '**Generated:** ' + DateTime.now().format() + '\n\n';

        content += '## Summary\n\n';
        content += '- **Total Changes:** ' + changes.size() + '\n';

        Integer withTickets = 0;
        Integer highRisk = 0;
        for (Metadata_Change__c mc : changes) {
            if (String.isNotBlank(mc.Ticket_Reference__c)) {
                withTickets++;
            }
            if (mc.Risk_Score__c != null && mc.Risk_Score__c >= 7.0) {
                highRisk++;
            }
        }

        content += '- **Changes with Tickets:** ' + withTickets + ' (' +
                   (changes.size() > 0 ? (withTickets * 100 / changes.size()) : 0) + '%)\n';
        content += '- **High-Risk Changes:** ' + highRisk + '\n\n';

        content += '## Change Details\n\n';
        content += '| Date | Type | Name | Changed By | Ticket | Risk |\n';
        content += '|------|------|------|------------|--------|------|\n';

        for (Metadata_Change__c mc : changes) {
            content += '| ' + (mc.Changed_Date__c != null ? mc.Changed_Date__c.format() : 'N/A');
            content += ' | ' + (mc.Entity_Type__c != null ? mc.Entity_Type__c : 'N/A');
            content += ' | ' + (mc.Entity_Name__c != null ? mc.Entity_Name__c : 'N/A');
            content += ' | ' + (mc.Changed_By__c != null ? mc.Changed_By__c : 'N/A');
            content += ' | ' + (String.isNotBlank(mc.Ticket_Reference__c) ? mc.Ticket_Reference__c : '-');
            content += ' | ' + (mc.Risk_Score__c != null ? String.valueOf(mc.Risk_Score__c) : '5.0');
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
        @AuraEnabled public List<Violation> violations;
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
