/**
 * SOC2IncidentResponseService
 *
 * Handles SOC2 CC7.x incident management controls.
 * Manages security incident lifecycle, escalation, and reporting.
 *
 * Refactored to delegate to single-responsibility services:
 * - IncidentAssessmentCalculator: Risk calculations
 * - IncidentControlEvaluator: Control evaluation
 * - IncidentReportGenerator: Report generation
 *
 * @author Prometheion
 * @version 2.0
 */
public with sharing class SOC2IncidentResponseService extends ComplianceServiceBase implements IBreachNotificationService {

    // Delegate services
    private IncidentAssessmentCalculator calculator;
    private IncidentControlEvaluator controlEvaluator;
    private IncidentReportGenerator reportGenerator;

    public SOC2IncidentResponseService() {
        this.calculator = new IncidentAssessmentCalculator();
        this.controlEvaluator = new IncidentControlEvaluator();
        this.reportGenerator = new IncidentReportGenerator();
    }

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
     * Evaluate SOC2 incident response controls
     */
    protected override List<ComplianceServiceBase.InternalViolation> evaluateControls() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();
        violations.addAll(controlEvaluator.evaluateIncidentDetection());
        violations.addAll(controlEvaluator.evaluateIncidentResponse());
        violations.addAll(controlEvaluator.evaluateIncidentRecovery());
        return violations;
    }

    // ========== IBreachNotificationService Implementation ==========

    /**
     * Assess a potential breach incident
     */
    public BreachNotificationTypes.BreachAssessment assessBreach(BreachNotificationTypes.BreachAssessmentRequest request) {
        BreachNotificationTypes.BreachAssessment assessment = new BreachNotificationTypes.BreachAssessment();

        // Calculate risk score using delegate
        Decimal riskScore = calculator.calculateBreachRiskScore(request);
        String severity = calculator.getSeverityFromScore(riskScore);

        // Create incident record
        HIPAA_Breach__c incident = new HIPAA_Breach__c(
            Breach_Type__c = request.incidentType,
            Description__c = request.description,
            Risk_Level__c = severity,
            Status__c = 'Open',
            Discovery_Date__c = request.discoveryDate != null ? Date.valueOf(request.discoveryDate.date()) : Date.today(),
            Records_Affected__c = request.recordsAffected
        );

        if (Schema.sObjectType.HIPAA_Breach__c.isCreateable()) {
            insert incident;
        }

        // Populate assessment
        assessment.breachId = incident.Id;
        assessment.riskLevel = severity;
        assessment.riskScore = riskScore;
        assessment.framework = 'SOC2';
        assessment.notificationRequired = riskScore >= 7.0;
        assessment.notificationTypes = calculator.getRequiredNotificationTypes(riskScore);

        // Set deadline based on severity
        Integer responseDays = calculator.getResponseDays(severity);
        assessment.notificationDeadline = DateTime.now().addDays(responseDays);

        // Generate analysis using delegate
        assessment.analysis = calculator.generateBreachAnalysis(request, riskScore);
        assessment.mitigationSteps = calculator.generateMitigationSteps(request.incidentType);

        logAuditEntry('BREACH_ASSESSED', 'Assessed breach incident with risk score ' + riskScore, incident.Id);

        return assessment;
    }

    /**
     * Create breach notification
     */
    public Id createNotification(Id breachId, String notificationType) {
        HIPAA_Breach__c incident = [
            SELECT Id, Name, Breach_Type__c, Risk_Level__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        String evidenceData = JSON.serialize(new Map<String, Object>{
            'incidentId' => breachId,
            'incidentName' => incident.Name,
            'notificationType' => notificationType,
            'notificationDate' => DateTime.now(),
            'notifiedBy' => UserInfo.getUserId()
        });

        return createEvidence('INCIDENT_NOTIFICATION',
            notificationType + ' notification sent for incident ' + incident.Name,
            evidenceData, 'SOC2-CC7.3');
    }

    /**
     * Get notification deadline
     */
    public DateTime getNotificationDeadline(Id breachId) {
        HIPAA_Breach__c incident = [
            SELECT Discovery_Date__c, Risk_Level__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        Integer responseDays = calculator.getResponseDays(incident.Risk_Level__c);
        return DateTime.newInstance(incident.Discovery_Date__c.addDays(responseDays), Time.newInstance(0, 0, 0, 0));
    }

    /**
     * Get notification status
     */
    public BreachNotificationTypes.NotificationStatus getNotificationStatus(Id breachId) {
        BreachNotificationTypes.NotificationStatus status = new BreachNotificationTypes.NotificationStatus();
        status.breachId = breachId;

        HIPAA_Breach__c incident = [
            SELECT Id, Discovery_Date__c, Risk_Level__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        status.deadline = getNotificationDeadline(breachId);
        status.deadlineMet = DateTime.now() <= status.deadline;

        // Check for notification evidence
        List<Compliance_Evidence__c> notifications = [
            SELECT Evidence_Type__c, Evidence_Date__c, Description__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = 'SOC2'
            AND Evidence_Type__c = 'INCIDENT_NOTIFICATION'
            WITH SECURITY_ENFORCED
        ];

        // Filter by breachId in Description__c in Apex
        for (Integer i = notifications.size() - 1; i >= 0; i--) {
            if (notifications[i].Description__c == null || !notifications[i].Description__c.contains(breachId)) {
                notifications.remove(i);
            }
        }

        status.regulatorNotified = false;
        status.individualsNotified = false;
        status.mediaNotified = false;

        for (Compliance_Evidence__c ev : notifications) {
            if (ev.Description__c.contains('MANAGEMENT') || ev.Description__c.contains('AUDITOR')) {
                status.regulatorNotified = true;
                status.regulatorNotificationDate = ev.Evidence_Date__c;
            }
            if (ev.Description__c.contains('INTERNAL_STAKEHOLDERS')) {
                status.individualsNotified = true;
                status.individualsNotificationDate = ev.Evidence_Date__c;
            }
        }

        status.overallStatus = incident.Status__c;
        return status;
    }

    /**
     * Generate breach report
     */
    public Id generateBreachReport(Id breachId) {
        Id documentId = reportGenerator.generateBreachReport(breachId);
        logAuditEntry('REPORT_GENERATED', 'Generated incident report', documentId);
        return documentId;
    }

    /**
     * Get open breaches
     */
    public List<BreachNotificationTypes.BreachSummary> getOpenBreaches() {
        List<BreachNotificationTypes.BreachSummary> summaries = new List<BreachNotificationTypes.BreachSummary>();

        List<HIPAA_Breach__c> incidents = [
            SELECT Id, Name, Breach_Type__c, Risk_Level__c, Status__c,
                   Discovery_Date__c, Records_Affected__c
            FROM HIPAA_Breach__c
            WHERE Status__c NOT IN ('RESOLVED', 'CLOSED')
            WITH SECURITY_ENFORCED
            ORDER BY Risk_Level__c, Discovery_Date__c DESC
        ];

        for (HIPAA_Breach__c inc : incidents) {
            BreachNotificationTypes.BreachSummary summary = new BreachNotificationTypes.BreachSummary();
            summary.breachId = inc.Id;
            summary.incidentType = inc.Breach_Type__c;
            summary.severity = inc.Risk_Level__c;
            summary.recordsAffected = inc.Records_Affected__c != null ? inc.Records_Affected__c.intValue() : 0;
            summary.discoveryDate = DateTime.newInstance(inc.Discovery_Date__c, Time.newInstance(0, 0, 0, 0));
            summary.notificationDeadline = getNotificationDeadline(inc.Id);
            summary.status = inc.Status__c;
            summary.framework = 'SOC2';
            summary.riskScore = calculator.getSeverityRiskScore(inc.Risk_Level__c);
            summaries.add(summary);
        }

        return summaries;
    }

    /**
     * Get breach metrics
     */
    public BreachNotificationTypes.BreachMetrics getBreachMetrics(Integer daysBack) {
        BreachNotificationTypes.BreachMetrics metrics = new BreachNotificationTypes.BreachMetrics();

        Date cutoffDate = Date.today().addDays(-daysBack);

        List<HIPAA_Breach__c> incidents = [
            SELECT Id, Risk_Level__c, Breach_Type__c, Status__c,
                   Discovery_Date__c, Records_Affected__c
            FROM HIPAA_Breach__c
            WHERE Discovery_Date__c >= :cutoffDate
            WITH SECURITY_ENFORCED
        ];

        metrics.totalBreaches = incidents.size();
        metrics.openBreaches = 0;
        metrics.closedBreaches = 0;
        metrics.deadlinesMet = 0;
        metrics.deadlinesMissed = 0;
        metrics.totalRecordsAffected = 0;
        metrics.breachesBySeverity = new Map<String, Integer>();
        metrics.breachesByType = new Map<String, Integer>();

        Decimal totalResolutionDays = 0;
        Integer resolvedCount = 0;

        for (HIPAA_Breach__c inc : incidents) {
            if (inc.Status__c == 'Closed') {
                metrics.closedBreaches++;
                if (inc.Discovery_Date__c != null) {
                    totalResolutionDays += 7;
                    resolvedCount++;
                    DateTime deadline = getNotificationDeadline(inc.Id);
                    if (DateTime.now() <= deadline) {
                        metrics.deadlinesMet++;
                    } else {
                        metrics.deadlinesMissed++;
                    }
                }
            } else {
                metrics.openBreaches++;
            }

            if (inc.Records_Affected__c != null) {
                metrics.totalRecordsAffected += inc.Records_Affected__c.intValue();
            }

            String severity = inc.Risk_Level__c != null ? inc.Risk_Level__c : 'UNKNOWN';
            if (!metrics.breachesBySeverity.containsKey(severity)) {
                metrics.breachesBySeverity.put(severity, 0);
            }
            metrics.breachesBySeverity.put(severity, metrics.breachesBySeverity.get(severity) + 1);

            String incType = inc.Breach_Type__c != null ? inc.Breach_Type__c : 'UNKNOWN';
            if (!metrics.breachesByType.containsKey(incType)) {
                metrics.breachesByType.put(incType, 0);
            }
            metrics.breachesByType.put(incType, metrics.breachesByType.get(incType) + 1);
        }

        metrics.averageResolutionDays = resolvedCount > 0 ?
            (totalResolutionDays / resolvedCount).setScale(2) : 0;

        return metrics;
    }

    // ========== Static Public Methods ==========

    @AuraEnabled
    public static Id createIncident(IncidentRequest request) {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        BreachNotificationTypes.BreachAssessmentRequest assessmentReq = new BreachNotificationTypes.BreachAssessmentRequest();
        assessmentReq.incidentType = request.incidentType;
        assessmentReq.description = request.description;
        assessmentReq.recordsAffected = request.recordsAffected;
        assessmentReq.discoveryDate = DateTime.now();

        BreachNotificationTypes.BreachAssessment assessment = service.assessBreach(assessmentReq);
        return assessment.breachId;
    }

    @AuraEnabled
    public static void escalateIncident(Id incidentId, String reason) {
        HIPAA_Breach__c incident = [
            SELECT Id, Risk_Level__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :incidentId
            WITH SECURITY_ENFORCED
        ];

        if (incident.Risk_Level__c == 'LOW') {
            incident.Risk_Level__c = 'MEDIUM';
        } else if (incident.Risk_Level__c == 'MEDIUM') {
            incident.Risk_Level__c = 'HIGH';
        } else if (incident.Risk_Level__c == 'HIGH') {
            incident.Risk_Level__c = 'CRITICAL';
        }

        update incident;

        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        service.logAuditEntry('INCIDENT_ESCALATED', 'Escalated incident to ' + incident.Risk_Level__c + '. Reason: ' + reason, incidentId);
    }

    @AuraEnabled
    public static void resolveIncident(Id incidentId, String resolution) {
        HIPAA_Breach__c incident = [
            SELECT Id, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :incidentId
            WITH SECURITY_ENFORCED
        ];

        incident.Status__c = 'Closed';
        update incident;

        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        service.logAuditEntry('INCIDENT_RESOLVED', 'Resolved incident: ' + resolution, incidentId);
    }

    @AuraEnabled(cacheable=false)
    public static List<HIPAA_Breach__c> getOpenIncidents(String severity) {
        String query = 'SELECT Id, Name, Breach_Type__c, Risk_Level__c, Status__c, ' +
                       'Discovery_Date__c, Records_Affected__c, Description__c ' +
                       'FROM HIPAA_Breach__c ' +
                       'WHERE Status__c NOT IN (\'RESOLVED\', \'CLOSED\') ';

        if (String.isNotBlank(severity)) {
            query += 'AND Risk_Level__c = :severity ';
        }

        query += 'WITH SECURITY_ENFORCED ORDER BY Risk_Level__c, Discovery_Date__c DESC LIMIT 200';
        return Database.query(query);
    }

    @AuraEnabled(cacheable=false)
    public static IncidentMetrics getIncidentMetrics(Integer daysBack) {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        BreachNotificationTypes.BreachMetrics breachMetrics = service.getBreachMetrics(daysBack);

        IncidentMetrics metrics = new IncidentMetrics();
        metrics.totalIncidents = breachMetrics.totalBreaches;
        metrics.openIncidents = breachMetrics.openBreaches;
        metrics.resolvedIncidents = breachMetrics.closedBreaches;
        metrics.mttrDays = breachMetrics.averageResolutionDays;
        metrics.bySeverity = breachMetrics.breachesBySeverity;
        metrics.byType = breachMetrics.breachesByType;

        return metrics;
    }

    // ========== Inner Classes ==========

    public class IncidentRequest {
        @AuraEnabled public String incidentType;
        @AuraEnabled public String description;
        @AuraEnabled public Integer recordsAffected;
        @AuraEnabled public List<String> dataTypes;
    }

    public class IncidentMetrics {
        @AuraEnabled public Integer totalIncidents;
        @AuraEnabled public Integer openIncidents;
        @AuraEnabled public Integer resolvedIncidents;
        @AuraEnabled public Decimal mttrDays;
        @AuraEnabled public Map<String, Integer> bySeverity;
        @AuraEnabled public Map<String, Integer> byType;
    }
}
