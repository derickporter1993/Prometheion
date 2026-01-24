/**
 * HIPAABreachNotificationService
 *
 * Breach notification per HIPAA (45 CFR 164.400-164.414).
 * Handles breach assessment, 4-factor risk analysis, notification tracking,
 * and compliance with 60-day notification deadlines.
 *
 * Refactored to delegate to single-responsibility services:
 * - BreachAssessmentService: 4-factor risk assessment
 * - BreachNotificationOrchestrator: Notification workflow management
 * - BreachReportingService: Reports and metrics
 *
 * @author Prometheion
 * @version 2.0
 */
public with sharing class HIPAABreachNotificationService extends ComplianceServiceBase implements IBreachNotificationService {

    private static final Integer NOTIFICATION_DEADLINE_DAYS = 60;
    private static final Integer HHS_ANNUAL_THRESHOLD = 500;

    // Delegate services
    private BreachAssessmentService assessmentService;
    private BreachNotificationOrchestrator orchestrator;
    private BreachReportingService reportingService;

    public HIPAABreachNotificationService() {
        this.assessmentService = new BreachAssessmentService();
        this.orchestrator = new BreachNotificationOrchestrator();
        this.reportingService = new BreachReportingService();
    }

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
     * Evaluate breach notification controls
     */
    protected override List<ComplianceServiceBase.InternalViolation> evaluateControls() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Check for overdue notifications
        List<HIPAA_Breach__c> overdueBreaches = reportingService.getOverdueNotifications();
        for (HIPAA_Breach__c breach : overdueBreaches) {
            ComplianceServiceBase.InternalViolation violation = new ComplianceServiceBase.InternalViolation(
                'Overdue Breach Notification',
                'Breach ' + breach.Name + ' has exceeded 60-day notification deadline',
                'CRITICAL',
                'HIPAA-164.404',
                'Immediately notify affected individuals and HHS',
                10.0
            );
            violations.add(violation);
        }

        // Check for breaches pending assessment
        Integer pendingCount = reportingService.getPendingAssessmentCount();
        if (pendingCount > 0) {
            ComplianceServiceBase.InternalViolation violation = new ComplianceServiceBase.InternalViolation(
                'Pending Breach Assessments',
                pendingCount + ' breach(es) pending risk assessment',
                'HIGH',
                'HIPAA-164.402',
                'Complete 4-factor risk assessment for pending breaches',
                7.5
            );
            violations.add(violation);
        }

        return violations;
    }

    // ========== IBreachNotificationService Implementation ==========

    /**
     * Assess breach risk using 4-factor analysis per 164.402
     */
    public BreachNotificationTypes.BreachAssessment assessBreach(
        BreachNotificationTypes.BreachAssessmentRequest request
    ) {
        BreachNotificationTypes.BreachAssessment assessment = assessmentService.performAssessment(request);

        // Create breach record if notification required
        if (assessment.notificationRequired) {
            HIPAA_Breach__c breach = new HIPAA_Breach__c(
                Description__c = request.description,
                Discovery_Date__c = request.discoveryDate != null ? request.discoveryDate.date() : Date.today(),
                Notification_Deadline__c = assessment.notificationDeadline != null ? assessment.notificationDeadline.date() : Date.today().addDays(NOTIFICATION_DEADLINE_DAYS),
                Records_Affected__c = request.recordsAffected != null ? request.recordsAffected : 0,
                Breach_Type__c = request.incidentType,
                Risk_Level__c = assessment.riskLevel,
                Status__c = 'Open',
                Notification_Required__c = true
            );

            PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
            insert breach;
            assessment.breachId = breach.Id;
        }

        return assessment;
    }

    /**
     * Get notification status for a breach
     */
    public BreachNotificationTypes.NotificationStatus getNotificationStatus(Id breachId) {
        return orchestrator.getNotificationStatus(breachId);
    }

    /**
     * Get breach summary for dashboard
     */
    public BreachNotificationTypes.BreachSummary getBreachSummary() {
        return reportingService.getBreachSummary();
    }

    /**
     * Create breach notification record
     */
    public Id createNotification(Id breachId, String notificationType) {
        Id result = orchestrator.createNotification(breachId, notificationType);
        logAuditEntry('HIPAA_Notification_Created', breachId, 'Created ' + notificationType + ' notification');
        return result;
    }

    /**
     * Get notification deadline for a breach
     */
    public DateTime getNotificationDeadline(Id breachId) {
        return orchestrator.getNotificationDeadline(breachId);
    }

    /**
     * Generate breach report for regulators
     */
    public Id generateBreachReport(Id breachId) {
        Id result = reportingService.generateBreachReport(breachId);
        logAuditEntry('HIPAA_Breach_Report_Generated', breachId, 'Breach report generated');
        return result;
    }

    /**
     * Get all open breaches requiring action
     */
    public List<BreachNotificationTypes.BreachSummary> getOpenBreaches() {
        return reportingService.getOpenBreaches();
    }

    /**
     * Get breach metrics for reporting
     */
    public BreachNotificationTypes.BreachMetrics getBreachMetrics(Integer days) {
        return reportingService.getBreachMetrics(days);
    }

    // ========== Aura-Enabled Methods ==========

    /**
     * Create new breach record
     */
    @AuraEnabled
    public static Id createBreachRecord(Map<String, Object> breachData) {
        HIPAA_Breach__c breach = new HIPAA_Breach__c();
        breach.Description__c = (String) breachData.get('description');
        breach.Discovery_Date__c = Date.today();
        breach.Notification_Deadline__c = Date.today().addDays(NOTIFICATION_DEADLINE_DAYS);
        breach.Records_Affected__c = (Decimal) breachData.get('recordsAffected');
        breach.Breach_Type__c = (String) breachData.get('breachType');
        breach.Status__c = 'Open';

        PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
        insert breach;

        // Log audit entry
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();
        service.logAuditEntry('HIPAA_Breach_Created', breach.Id, 'HIPAA Breach record created');

        return breach.Id;
    }

    /**
     * Get breaches pending assessment
     */
    @AuraEnabled(cacheable=true)
    public static List<HIPAA_Breach__c> getPendingBreaches() {
        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Records_Affected__c,
                   Breach_Type__c, Status__c, Risk_Level__c
            FROM HIPAA_Breach__c
            WHERE Status__c = 'Pending Assessment'
            WITH SECURITY_ENFORCED
            ORDER BY Discovery_Date__c ASC
        ];
    }

    /**
     * Get breaches requiring notification
     */
    @AuraEnabled(cacheable=true)
    public static List<HIPAA_Breach__c> getBreachesRequiringNotification() {
        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Notification_Deadline__c,
                   Records_Affected__c, Risk_Level__c, Status__c,
                   Individuals_Notified__c, HHS_Notified__c, Media_Notified__c
            FROM HIPAA_Breach__c
            WHERE Notification_Required__c = true
            AND (Individuals_Notified__c = false OR HHS_Notified__c = false)
            WITH SECURITY_ENFORCED
            ORDER BY Notification_Deadline__c ASC
        ];
    }

    /**
     * Record individual notification
     */
    @AuraEnabled
    public static void recordIndividualNotification(Id breachId, Integer individualsNotified) {
        BreachNotificationOrchestrator orchestrator = new BreachNotificationOrchestrator();
        orchestrator.recordIndividualNotification(breachId, individualsNotified);

        HIPAABreachNotificationService service = new HIPAABreachNotificationService();
        service.logAuditEntry('HIPAA_Individual_Notification', breachId,
            'Notified ' + individualsNotified + ' individuals');
    }

    /**
     * Record HHS notification
     */
    @AuraEnabled
    public static void recordHHSNotification(Id breachId, String hhsConfirmationNumber) {
        BreachNotificationOrchestrator orchestrator = new BreachNotificationOrchestrator();
        orchestrator.recordHHSNotification(breachId, hhsConfirmationNumber);

        HIPAABreachNotificationService service = new HIPAABreachNotificationService();
        service.logAuditEntry('HIPAA_HHS_Notification', breachId,
            'HHS notified. Confirmation: ' + hhsConfirmationNumber);
    }

    /**
     * Get notification timeline for a breach
     */
    @AuraEnabled(cacheable=true)
    public static List<BreachNotificationOrchestrator.NotificationEvent> getNotificationTimeline(Id breachId) {
        BreachNotificationOrchestrator orchestrator = new BreachNotificationOrchestrator();
        return orchestrator.getNotificationTimeline(breachId);
    }
}
