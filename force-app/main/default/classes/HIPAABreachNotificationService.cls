/**
 * HIPAABreachNotificationService
 *
 * Breach notification per HIPAA (45 CFR 164.400-164.414).
 * Handles breach assessment, 4-factor risk analysis, notification tracking,
 * and compliance with 60-day notification deadlines.
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class HIPAABreachNotificationService extends ComplianceServiceBase implements IBreachNotificationService {

    private static final Integer NOTIFICATION_DEADLINE_DAYS = 60;
    private static final Integer HHS_ANNUAL_THRESHOLD = 500;

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
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();

        // Check for overdue notifications
        List<HIPAA_Breach__c> overdueBreaches = getOverdueNotifications();
        for (HIPAA_Breach__c breach : overdueBreaches) {
            violations.add(new Violation(
                'Overdue Breach Notification',
                'Breach ' + breach.Name + ' has exceeded 60-day notification deadline',
                'CRITICAL',
                'HIPAA-164.404',
                'Immediately notify affected individuals and HHS',
                10.0
            ));
        }

        // Check for breaches pending assessment
        Integer pendingCount = getPendingAssessmentCount();
        if (pendingCount > 0) {
            violations.add(new Violation(
                'Pending Breach Assessments',
                pendingCount + ' breach(es) pending risk assessment',
                'HIGH',
                'HIPAA-164.402',
                'Complete 4-factor risk assessment for pending breaches',
                7.5
            ));
        }

        return violations;
    }

    // ========== IBreachNotificationService Implementation ==========

    /**
     * Assess breach risk using 4-factor analysis per §164.402
     */
    public IBreachNotificationService.BreachAssessment assessBreach(
        IBreachNotificationService.BreachAssessmentRequest request
    ) {
        IBreachNotificationService.BreachAssessment assessment =
            new IBreachNotificationService.BreachAssessment();
        assessment.assessmentDate = DateTime.now();

        // Factor 1: Nature and extent of PHI involved
        assessment.factor1Score = calculateNatureExtentScore(request);
        assessment.factor1Details = 'PHI types: ' + String.join(request.dataTypesInvolved, ', ') +
            '. Records affected: ' + request.recordsAffected;

        // Factor 2: Unauthorized person who used/received PHI
        assessment.factor2Score = calculateUnauthorizedPersonScore(request);
        assessment.factor2Details = 'Recipient type: ' + request.recipientType +
            '. Authorization status: ' + (request.recipientAuthorized ? 'Covered Entity' : 'Unauthorized');

        // Factor 3: Whether PHI was actually acquired or viewed
        assessment.factor3Score = calculateAcquisitionScore(request);
        assessment.factor3Details = 'Acquisition confirmed: ' + request.dataAcquired +
            '. Viewing confirmed: ' + request.dataViewed;

        // Factor 4: Extent to which risk has been mitigated
        assessment.factor4Score = calculateMitigationScore(request);
        assessment.factor4Details = 'Mitigations applied: ' + String.join(request.mitigationsApplied, ', ');

        // Calculate overall risk score (average of 4 factors)
        assessment.overallRiskScore = (
            assessment.factor1Score +
            assessment.factor2Score +
            assessment.factor3Score +
            assessment.factor4Score
        ) / 4;

        // Determine if notification is required (low probability = score < 3)
        assessment.notificationRequired = assessment.overallRiskScore >= 3;
        assessment.riskLevel = getRiskLevel(assessment.overallRiskScore);

        // Set notification deadline if required
        if (assessment.notificationRequired) {
            assessment.notificationDeadline = Date.today().addDays(NOTIFICATION_DEADLINE_DAYS);
        }

        return assessment;
    }

    /**
     * Get notification status for a breach
     */
    public IBreachNotificationService.NotificationStatus getNotificationStatus(Id breachId) {
        IBreachNotificationService.NotificationStatus status =
            new IBreachNotificationService.NotificationStatus();

        HIPAA_Breach__c breach = [
            SELECT Id, Name, Discovery_Date__c, Notification_Deadline__c,
                   Individuals_Notified__c, Individual_Notification_Date__c,
                   HHS_Notified__c, HHS_Notification_Date__c,
                   Media_Notified__c, Media_Notification_Date__c,
                   Records_Affected__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH USER_MODE
            LIMIT 1
        ];

        status.breachId = breach.Id;
        status.breachName = breach.Name;
        status.discoveryDate = breach.Discovery_Date__c;
        status.notificationDeadline = breach.Notification_Deadline__c;

        // Individual notification status
        status.individualsNotified = breach.Individuals_Notified__c == true;
        status.individualNotificationDate = breach.Individual_Notification_Date__c;

        // HHS notification status
        status.hhsNotified = breach.HHS_Notified__c == true;
        status.hhsNotificationDate = breach.HHS_Notification_Date__c;

        // Media notification (required if 500+ individuals in a state)
        status.mediaNotificationRequired = breach.Records_Affected__c >= HHS_ANNUAL_THRESHOLD;
        status.mediaNotified = breach.Media_Notified__c == true;
        status.mediaNotificationDate = breach.Media_Notification_Date__c;

        // Calculate days remaining
        if (breach.Notification_Deadline__c != null) {
            status.daysUntilDeadline = Date.today().daysBetween(breach.Notification_Deadline__c);
        }

        // Determine overall status
        status.overallStatus = breach.Status__c;
        status.isOverdue = status.daysUntilDeadline != null && status.daysUntilDeadline < 0;

        return status;
    }

    /**
     * Get breach summary for dashboard
     */
    public IBreachNotificationService.BreachSummary getBreachSummary() {
        IBreachNotificationService.BreachSummary summary =
            new IBreachNotificationService.BreachSummary();

        Date yearStart = Date.today().addYears(-1);

        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) cnt, SUM(Records_Affected__c) total
            FROM HIPAA_Breach__c
            WHERE Discovery_Date__c >= :yearStart
            WITH USER_MODE
            GROUP BY Status__c
        ];

        summary.totalBreaches = 0;
        summary.openBreaches = 0;
        summary.closedBreaches = 0;
        summary.totalAffectedIndividuals = 0;

        for (AggregateResult ar : results) {
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('cnt');
            Decimal affected = (Decimal) ar.get('total');

            summary.totalBreaches += count;
            summary.totalAffectedIndividuals += affected != null ? affected.intValue() : 0;

            if (status == 'Open' || status == 'Under Investigation') {
                summary.openBreaches += count;
            } else if (status == 'Closed') {
                summary.closedBreaches += count;
            }
        }

        // Get overdue count
        summary.overdueNotifications = [
            SELECT COUNT()
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c < TODAY
            AND Individuals_Notified__c = false
            WITH USER_MODE
        ];

        // Determine HHS annual report requirement
        summary.hhsAnnualReportRequired = summary.totalAffectedIndividuals >= HHS_ANNUAL_THRESHOLD;

        return summary;
    }

    /**
     * Get breach metrics for reporting
     */
    public IBreachNotificationService.BreachMetrics getBreachMetrics(Integer days) {
        IBreachNotificationService.BreachMetrics metrics =
            new IBreachNotificationService.BreachMetrics();

        Date startDate = Date.today().addDays(-days);

        List<HIPAA_Breach__c> breaches = [
            SELECT Id, Discovery_Date__c, Individual_Notification_Date__c,
                   Records_Affected__c, Risk_Level__c, Breach_Type__c
            FROM HIPAA_Breach__c
            WHERE Discovery_Date__c >= :startDate
            WITH USER_MODE
        ];

        metrics.totalBreaches = breaches.size();
        metrics.breachesByType = new Map<String, Integer>();
        metrics.breachesByRiskLevel = new Map<String, Integer>();
        metrics.averageNotificationDays = 0;

        Decimal totalNotificationDays = 0;
        Integer notifiedCount = 0;

        for (HIPAA_Breach__c breach : breaches) {
            // Count by type
            String breachType = breach.Breach_Type__c != null ? breach.Breach_Type__c : 'Unknown';
            if (!metrics.breachesByType.containsKey(breachType)) {
                metrics.breachesByType.put(breachType, 0);
            }
            metrics.breachesByType.put(breachType, metrics.breachesByType.get(breachType) + 1);

            // Count by risk level
            String riskLevel = breach.Risk_Level__c != null ? breach.Risk_Level__c : 'Unknown';
            if (!metrics.breachesByRiskLevel.containsKey(riskLevel)) {
                metrics.breachesByRiskLevel.put(riskLevel, 0);
            }
            metrics.breachesByRiskLevel.put(riskLevel, metrics.breachesByRiskLevel.get(riskLevel) + 1);

            // Calculate notification time
            if (breach.Individual_Notification_Date__c != null && breach.Discovery_Date__c != null) {
                totalNotificationDays += breach.Discovery_Date__c.daysBetween(
                    breach.Individual_Notification_Date__c
                );
                notifiedCount++;
            }
        }

        if (notifiedCount > 0) {
            metrics.averageNotificationDays = (totalNotificationDays / notifiedCount).setScale(1);
        }

        return metrics;
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

        ElaroSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', DmlOperation.DML_INSERT);
        insert as user breach;

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
            WITH USER_MODE
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
            WITH USER_MODE
            ORDER BY Notification_Deadline__c ASC
        ];
    }

    /**
     * Record individual notification
     */
    @AuraEnabled
    public static void recordIndividualNotification(Id breachId, Integer individualsNotified) {
        HIPAA_Breach__c breach = [
            SELECT Id, Individuals_Notified__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH USER_MODE
            LIMIT 1
        ];

        breach.Individuals_Notified__c = true;
        breach.Individual_Notification_Date__c = Date.today();
        breach.Individuals_Notified_Count__c = individualsNotified;

        ElaroSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', DmlOperation.DML_UPDATE);
        update as user breach;

        HIPAABreachNotificationService service = new HIPAABreachNotificationService();
        service.logAuditEntry('HIPAA_Individual_Notification', breachId,
            'Notified ' + individualsNotified + ' individuals');
    }

    /**
     * Record HHS notification
     */
    @AuraEnabled
    public static void recordHHSNotification(Id breachId, String hhsConfirmationNumber) {
        HIPAA_Breach__c breach = [
            SELECT Id, HHS_Notified__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH USER_MODE
            LIMIT 1
        ];

        breach.HHS_Notified__c = true;
        breach.HHS_Notification_Date__c = Date.today();
        breach.HHS_Confirmation_Number__c = hhsConfirmationNumber;

        ElaroSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', DmlOperation.DML_UPDATE);
        update as user breach;

        HIPAABreachNotificationService service = new HIPAABreachNotificationService();
        service.logAuditEntry('HIPAA_HHS_Notification', breachId,
            'HHS notified. Confirmation: ' + hhsConfirmationNumber);
    }

    /**
     * Get notification timeline for a breach
     */
    @AuraEnabled(cacheable=true)
    public static List<NotificationEvent> getNotificationTimeline(Id breachId) {
        List<NotificationEvent> timeline = new List<NotificationEvent>();

        HIPAA_Breach__c breach = [
            SELECT Id, Discovery_Date__c, Notification_Deadline__c,
                   Individual_Notification_Date__c, HHS_Notification_Date__c,
                   Media_Notification_Date__c, Records_Affected__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH USER_MODE
            LIMIT 1
        ];

        // Discovery event
        timeline.add(new NotificationEvent(
            'Discovery',
            breach.Discovery_Date__c,
            'Breach discovered',
            'completed'
        ));

        // Individual notification
        timeline.add(new NotificationEvent(
            'Individual Notification',
            breach.Individual_Notification_Date__c,
            'Notify affected individuals',
            breach.Individual_Notification_Date__c != null ? 'completed' : 'pending'
        ));

        // HHS notification
        timeline.add(new NotificationEvent(
            'HHS Notification',
            breach.HHS_Notification_Date__c,
            breach.Records_Affected__c >= HHS_ANNUAL_THRESHOLD ?
                'Immediate HHS notification required (500+ records)' :
                'HHS annual log entry required',
            breach.HHS_Notification_Date__c != null ? 'completed' : 'pending'
        ));

        // Media notification if applicable
        if (breach.Records_Affected__c >= HHS_ANNUAL_THRESHOLD) {
            timeline.add(new NotificationEvent(
                'Media Notification',
                breach.Media_Notification_Date__c,
                'Notify prominent media outlets (500+ in state)',
                breach.Media_Notification_Date__c != null ? 'completed' : 'pending'
            ));
        }

        // Deadline
        timeline.add(new NotificationEvent(
            'Notification Deadline',
            breach.Notification_Deadline__c,
            '60-day notification deadline',
            Date.today() > breach.Notification_Deadline__c ? 'overdue' : 'upcoming'
        ));

        return timeline;
    }

    // ========== Private Helper Methods ==========

    private List<HIPAA_Breach__c> getOverdueNotifications() {
        return [
            SELECT Id, Name, Discovery_Date__c, Notification_Deadline__c
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c < TODAY
            AND Individuals_Notified__c = false
            AND Notification_Required__c = true
            WITH USER_MODE
        ];
    }

    private Integer getPendingAssessmentCount() {
        return [
            SELECT COUNT()
            FROM HIPAA_Breach__c
            WHERE Status__c = 'Pending Assessment'
            WITH USER_MODE
        ];
    }

    private Decimal calculateNatureExtentScore(IBreachNotificationService.BreachAssessmentRequest request) {
        Decimal score = 1;

        // High-risk PHI types increase score
        Set<String> highRiskTypes = new Set<String>{'SSN', 'Financial', 'Mental Health', 'Substance Abuse', 'HIV/AIDS'};
        for (String dataType : request.dataTypesInvolved) {
            if (highRiskTypes.contains(dataType)) {
                score += 2;
            }
        }

        // Volume of records affects score
        if (request.recordsAffected > 500) {
            score += 2;
        } else if (request.recordsAffected > 100) {
            score += 1;
        }

        return Math.min(score, 10);
    }

    private Decimal calculateUnauthorizedPersonScore(IBreachNotificationService.BreachAssessmentRequest request) {
        Decimal score = 5; // Default medium risk

        if (request.recipientAuthorized) {
            score = 2; // Lower risk if recipient is covered entity
        } else if (request.recipientType == 'Unknown' || request.recipientType == 'Criminal') {
            score = 9; // High risk for unknown or criminal recipients
        } else if (request.recipientType == 'Former Employee') {
            score = 6;
        }

        return score;
    }

    private Decimal calculateAcquisitionScore(IBreachNotificationService.BreachAssessmentRequest request) {
        if (request.dataAcquired && request.dataViewed) {
            return 10; // Highest risk
        } else if (request.dataAcquired || request.dataViewed) {
            return 7;
        } else {
            return 3; // Lower risk if no evidence of acquisition/viewing
        }
    }

    private Decimal calculateMitigationScore(IBreachNotificationService.BreachAssessmentRequest request) {
        Decimal score = 10; // Start at highest risk

        // Each mitigation reduces score
        if (request.mitigationsApplied != null) {
            for (String mitigation : request.mitigationsApplied) {
                if (mitigation.contains('Encryption')) {
                    score -= 3;
                } else if (mitigation.contains('Destroyed')) {
                    score -= 4;
                } else if (mitigation.contains('Agreement')) {
                    score -= 2;
                } else {
                    score -= 1;
                }
            }
        }

        return Math.max(score, 1);
    }

    private String getRiskLevel(Decimal score) {
        if (score >= 7) {
            return 'High';
        } else if (score >= 4) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }

    // ========== Inner Classes ==========

    public class NotificationEvent {
        @AuraEnabled public String eventType;
        @AuraEnabled public Date eventDate;
        @AuraEnabled public String description;
        @AuraEnabled public String status;

        public NotificationEvent(String eventType, Date eventDate, String description, String status) {
            this.eventType = eventType;
            this.eventDate = eventDate;
            this.description = description;
            this.status = status;
        }
    }
}
