/**
 * SOC2IncidentResponseService
 *
 * Handles SOC2 CC7.x incident management controls.
 * Manages security incident lifecycle, escalation, and reporting.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class SOC2IncidentResponseService extends ComplianceServiceBase implements IBreachNotificationService {

    // Incident SLA thresholds (in hours)
    private static final Integer CRITICAL_RESPONSE_SLA = 1;
    private static final Integer HIGH_RESPONSE_SLA = 4;
    private static final Integer MEDIUM_RESPONSE_SLA = 24;
    private static final Integer LOW_RESPONSE_SLA = 72;

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
    protected override List<Violation> evaluateControls() {
        List<Violation> violations = new List<Violation>();

        // CC7.2 - Incident Detection
        violations.addAll(evaluateIncidentDetection());

        // CC7.3 - Incident Response
        violations.addAll(evaluateIncidentResponse());

        // CC7.4 - Incident Recovery
        violations.addAll(evaluateIncidentRecovery());

        return violations;
    }

    // ========== IBreachNotificationService Implementation ==========

    /**
     * Assess a potential breach incident
     */
    public IBreachNotificationService.BreachAssessment assessBreach(IBreachNotificationService.BreachAssessmentRequest request) {
        IBreachNotificationService.BreachAssessment assessment = new IBreachNotificationService.BreachAssessment();

        // Calculate risk score
        Decimal riskScore = calculateBreachRiskScore(request);

        // Determine severity
        String severity;
        if (riskScore >= 9.0) {
            severity = 'CRITICAL';
        } else if (riskScore >= 7.0) {
            severity = 'HIGH';
        } else if (riskScore >= 5.0) {
            severity = 'MEDIUM';
        } else {
            severity = 'LOW';
        }

        // Create incident record
        Security_Incident__c incident = new Security_Incident__c(
            Incident_Type__c = request.incidentType,
            Description__c = request.description,
            Severity__c = severity,
            Status__c = 'OPEN',
            Detected_Date__c = request.discoveryDate != null ? request.discoveryDate : DateTime.now(),
            Affected_Records__c = request.recordsAffected,
            Framework__c = 'SOC2'
        );

        if (Schema.sObjectType.Security_Incident__c.isCreateable()) {
            insert incident;
        }

        // Populate assessment
        assessment.breachId = incident.Id;
        assessment.riskLevel = severity;
        assessment.riskScore = riskScore;
        assessment.framework = 'SOC2';

        // Determine notification requirements
        assessment.notificationRequired = riskScore >= 7.0;
        assessment.notificationTypes = new List<String>();
        if (assessment.notificationRequired) {
            assessment.notificationTypes.add('INTERNAL_STAKEHOLDERS');
            if (riskScore >= 9.0) {
                assessment.notificationTypes.add('MANAGEMENT');
                assessment.notificationTypes.add('AUDITOR');
            }
        }

        // Set deadline based on severity
        Integer responseDays = severity == 'CRITICAL' ? 1 : severity == 'HIGH' ? 3 : 7;
        assessment.notificationDeadline = DateTime.now().addDays(responseDays);

        // Generate analysis
        assessment.analysis = generateBreachAnalysis(request, riskScore);

        // Mitigation steps
        assessment.mitigationSteps = generateMitigationSteps(request.incidentType);

        logAuditEntry('BREACH_ASSESSED', 'Assessed breach incident with risk score ' + riskScore, incident.Id);

        return assessment;
    }

    /**
     * Create breach notification
     */
    public Id createNotification(Id breachId, String notificationType) {
        // For SOC2, we log the notification as evidence
        Security_Incident__c incident = [
            SELECT Id, Name, Incident_Type__c, Severity__c
            FROM Security_Incident__c
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
        Security_Incident__c incident = [
            SELECT Detected_Date__c, Severity__c
            FROM Security_Incident__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        Integer responseDays;
        if (incident.Severity__c == 'CRITICAL') {
            responseDays = 1;
        } else if (incident.Severity__c == 'HIGH') {
            responseDays = 3;
        } else {
            responseDays = 7;
        }

        return incident.Detected_Date__c.addDays(responseDays);
    }

    /**
     * Get notification status
     */
    public IBreachNotificationService.NotificationStatus getNotificationStatus(Id breachId) {
        IBreachNotificationService.NotificationStatus status = new IBreachNotificationService.NotificationStatus();
        status.breachId = breachId;

        Security_Incident__c incident = [
            SELECT Id, Detected_Date__c, Severity__c, Status__c, Resolved_Date__c
            FROM Security_Incident__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        status.deadline = getNotificationDeadline(breachId);
        status.deadlineMet = incident.Status__c == 'RESOLVED' || incident.Status__c == 'CLOSED'
            ? (incident.Resolved_Date__c <= status.deadline)
            : (DateTime.now() <= status.deadline);

        // Check for notification evidence
        List<Compliance_Evidence__c> notifications = [
            SELECT Evidence_Type__c, Evidence_Date__c, Description__c
            FROM Compliance_Evidence__c
            WHERE Framework__c = 'SOC2'
            AND Evidence_Type__c = 'INCIDENT_NOTIFICATION'
            AND Description__c LIKE :('%' + breachId + '%')
            WITH SECURITY_ENFORCED
        ];

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
        Security_Incident__c incident = [
            SELECT Id, Name, Incident_Type__c, Description__c, Severity__c, Status__c,
                   Detected_Date__c, Resolved_Date__c, Affected_Records__c,
                   Root_Cause__c, Resolution__c, Assigned_To__r.Name
            FROM Security_Incident__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
        ];

        String report = generateIncidentReportContent(incident);

        ContentVersion cv = new ContentVersion(
            Title = 'Incident_Report_' + incident.Name,
            PathOnClient = 'Incident_Report_' + incident.Name + '.md',
            VersionData = Blob.valueOf(report),
            Origin = 'H'
        );
        PrometheionSecurityUtils.validateCRUDAccess('ContentVersion', DmlOperation.DML_INSERT);
        insert cv;

        cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];

        logAuditEntry('REPORT_GENERATED', 'Generated incident report for ' + incident.Name, cv.ContentDocumentId);

        return cv.ContentDocumentId;
    }

    /**
     * Get open breaches
     */
    public List<IBreachNotificationService.BreachSummary> getOpenBreaches() {
        List<IBreachNotificationService.BreachSummary> summaries = new List<IBreachNotificationService.BreachSummary>();

        List<Security_Incident__c> incidents = [
            SELECT Id, Name, Incident_Type__c, Severity__c, Status__c,
                   Detected_Date__c, Affected_Records__c, Framework__c
            FROM Security_Incident__c
            WHERE Status__c NOT IN ('RESOLVED', 'CLOSED')
            WITH SECURITY_ENFORCED
            ORDER BY Severity__c, Detected_Date__c DESC
        ];

        for (Security_Incident__c inc : incidents) {
            IBreachNotificationService.BreachSummary summary = new IBreachNotificationService.BreachSummary();
            summary.breachId = inc.Id;
            summary.incidentType = inc.Incident_Type__c;
            summary.severity = inc.Severity__c;
            summary.recordsAffected = inc.Affected_Records__c != null ? inc.Affected_Records__c.intValue() : 0;
            summary.discoveryDate = inc.Detected_Date__c;
            summary.notificationDeadline = getNotificationDeadline(inc.Id);
            summary.status = inc.Status__c;
            summary.framework = inc.Framework__c;
            summary.riskScore = getSeverityRiskScore(inc.Severity__c);
            summaries.add(summary);
        }

        return summaries;
    }

    /**
     * Get breach metrics
     */
    public IBreachNotificationService.BreachMetrics getBreachMetrics(Integer daysBack) {
        IBreachNotificationService.BreachMetrics metrics = new IBreachNotificationService.BreachMetrics();

        Date cutoffDate = Date.today().addDays(-daysBack);

        List<Security_Incident__c> incidents = [
            SELECT Id, Severity__c, Incident_Type__c, Status__c,
                   Detected_Date__c, Resolved_Date__c, Affected_Records__c
            FROM Security_Incident__c
            WHERE Detected_Date__c >= :cutoffDate
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

        for (Security_Incident__c inc : incidents) {
            // Status counts
            if (inc.Status__c == 'RESOLVED' || inc.Status__c == 'CLOSED') {
                metrics.closedBreaches++;

                // Calculate resolution time
                if (inc.Resolved_Date__c != null && inc.Detected_Date__c != null) {
                    Long millisDiff = inc.Resolved_Date__c.getTime() - inc.Detected_Date__c.getTime();
                    totalResolutionDays += millisDiff / (1000 * 60 * 60 * 24);
                    resolvedCount++;

                    // Check deadline
                    DateTime deadline = getNotificationDeadline(inc.Id);
                    if (inc.Resolved_Date__c <= deadline) {
                        metrics.deadlinesMet++;
                    } else {
                        metrics.deadlinesMissed++;
                    }
                }
            } else {
                metrics.openBreaches++;
            }

            // Affected records
            if (inc.Affected_Records__c != null) {
                metrics.totalRecordsAffected += inc.Affected_Records__c.intValue();
            }

            // By severity
            String severity = inc.Severity__c != null ? inc.Severity__c : 'UNKNOWN';
            if (!metrics.breachesBySeverity.containsKey(severity)) {
                metrics.breachesBySeverity.put(severity, 0);
            }
            metrics.breachesBySeverity.put(severity, metrics.breachesBySeverity.get(severity) + 1);

            // By type
            String incType = inc.Incident_Type__c != null ? inc.Incident_Type__c : 'UNKNOWN';
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

    /**
     * Create a new security incident
     * @param request Incident request details
     * @return Created incident Id
     */
    @AuraEnabled
    public static Id createIncident(IncidentRequest request) {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        IBreachNotificationService.BreachAssessmentRequest assessmentReq = new IBreachNotificationService.BreachAssessmentRequest();
        assessmentReq.incidentType = request.incidentType;
        assessmentReq.description = request.description;
        assessmentReq.recordsAffected = request.recordsAffected;
        assessmentReq.discoveryDate = DateTime.now();

        IBreachNotificationService.BreachAssessment assessment = service.assessBreach(assessmentReq);
        return assessment.breachId;
    }

    /**
     * Escalate an incident
     */
    @AuraEnabled
    public static void escalateIncident(Id incidentId, String reason) {
        Security_Incident__c incident = [
            SELECT Id, Severity__c, Status__c
            FROM Security_Incident__c
            WHERE Id = :incidentId
            WITH SECURITY_ENFORCED
        ];

        // Escalate severity
        if (incident.Severity__c == 'LOW') {
            incident.Severity__c = 'MEDIUM';
        } else if (incident.Severity__c == 'MEDIUM') {
            incident.Severity__c = 'HIGH';
        } else if (incident.Severity__c == 'HIGH') {
            incident.Severity__c = 'CRITICAL';
        }

        update incident;

        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        service.logAuditEntry('INCIDENT_ESCALATED', 'Escalated incident to ' + incident.Severity__c + '. Reason: ' + reason, incidentId);
    }

    /**
     * Resolve an incident
     */
    @AuraEnabled
    public static void resolveIncident(Id incidentId, String resolution) {
        Security_Incident__c incident = [
            SELECT Id, Status__c
            FROM Security_Incident__c
            WHERE Id = :incidentId
            WITH SECURITY_ENFORCED
        ];

        incident.Status__c = 'RESOLVED';
        incident.Resolution__c = resolution;
        incident.Resolved_Date__c = DateTime.now();

        update incident;

        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        service.logAuditEntry('INCIDENT_RESOLVED', 'Resolved incident: ' + resolution, incidentId);
    }

    /**
     * Get open incidents by severity
     */
    @AuraEnabled(cacheable=false)
    public static List<Security_Incident__c> getOpenIncidents(String severity) {
        String query = 'SELECT Id, Name, Incident_Type__c, Severity__c, Status__c, ' +
                       'Detected_Date__c, Affected_Records__c, Assigned_To__r.Name, Description__c ' +
                       'FROM Security_Incident__c ' +
                       'WHERE Status__c NOT IN (\'RESOLVED\', \'CLOSED\') ';

        if (String.isNotBlank(severity)) {
            query += 'AND Severity__c = :severity ';
        }

        query += 'WITH SECURITY_ENFORCED ORDER BY Severity__c, Detected_Date__c DESC LIMIT 200';

        return Database.query(query);
    }

    /**
     * Get incident metrics
     */
    @AuraEnabled(cacheable=false)
    public static IncidentMetrics getIncidentMetrics(Integer daysBack) {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        IBreachNotificationService.BreachMetrics breachMetrics = service.getBreachMetrics(daysBack);

        IncidentMetrics metrics = new IncidentMetrics();
        metrics.totalIncidents = breachMetrics.totalBreaches;
        metrics.openIncidents = breachMetrics.openBreaches;
        metrics.resolvedIncidents = breachMetrics.closedBreaches;
        metrics.mttrDays = breachMetrics.averageResolutionDays;
        metrics.bySeverity = breachMetrics.breachesBySeverity;
        metrics.byType = breachMetrics.breachesByType;

        return metrics;
    }

    // ========== Private Helper Methods ==========

    private List<Violation> evaluateIncidentDetection() {
        List<Violation> violations = new List<Violation>();

        // Check for incidents without proper detection documentation
        Integer undocumentedIncidents = [
            SELECT COUNT()
            FROM Security_Incident__c
            WHERE (Description__c = null OR Description__c = '')
            AND Status__c NOT IN ('CLOSED')
            WITH SECURITY_ENFORCED
        ];

        if (undocumentedIncidents > 0) {
            Violation v = new Violation(
                'Undocumented Incidents',
                undocumentedIncidents + ' incidents lack proper documentation',
                'MEDIUM',
                'SOC2-CC7.2',
                'Add detailed descriptions to all security incidents',
                5.5
            );
            v.entityType = 'INCIDENT';
            v.entityId = 'DOCUMENTATION';
            violations.add(v);
        }

        return violations;
    }

    private List<Violation> evaluateIncidentResponse() {
        List<Violation> violations = new List<Violation>();

        // Check for incidents exceeding SLA
        List<Security_Incident__c> openIncidents = [
            SELECT Id, Severity__c, Detected_Date__c
            FROM Security_Incident__c
            WHERE Status__c NOT IN ('RESOLVED', 'CLOSED')
            WITH SECURITY_ENFORCED
        ];

        Integer slaBreaches = 0;
        for (Security_Incident__c inc : openIncidents) {
            Integer slaHours = getSLAHours(inc.Severity__c);
            DateTime slaDeadline = inc.Detected_Date__c.addHours(slaHours);
            if (DateTime.now() > slaDeadline) {
                slaBreaches++;
            }
        }

        if (slaBreaches > 0) {
            Violation v = new Violation(
                'SLA Breaches',
                slaBreaches + ' incidents have exceeded their response SLA',
                'HIGH',
                'SOC2-CC7.3',
                'Prioritize and resolve overdue incidents immediately',
                8.0
            );
            v.entityType = 'INCIDENT';
            v.entityId = 'SLA';
            violations.add(v);
        }

        return violations;
    }

    private List<Violation> evaluateIncidentRecovery() {
        List<Violation> violations = new List<Violation>();

        // Check for resolved incidents without root cause
        Integer noRootCause = [
            SELECT COUNT()
            FROM Security_Incident__c
            WHERE Status__c IN ('RESOLVED', 'CLOSED')
            AND (Root_Cause__c = null OR Root_Cause__c = '')
            WITH SECURITY_ENFORCED
        ];

        if (noRootCause > 0) {
            Violation v = new Violation(
                'Missing Root Cause Analysis',
                noRootCause + ' resolved incidents lack root cause analysis',
                'MEDIUM',
                'SOC2-CC7.4',
                'Complete root cause analysis for all resolved incidents',
                5.0
            );
            v.entityType = 'INCIDENT';
            v.entityId = 'ROOT_CAUSE';
            violations.add(v);
        }

        return violations;
    }

    private Decimal calculateBreachRiskScore(IBreachNotificationService.BreachAssessmentRequest request) {
        Decimal score = 5.0;

        // Records affected
        if (request.recordsAffected != null) {
            if (request.recordsAffected > 10000) {
                score += 3.0;
            } else if (request.recordsAffected > 1000) {
                score += 2.0;
            } else if (request.recordsAffected > 100) {
                score += 1.0;
            }
        }

        // Data types
        if (request.dataTypesExposed != null) {
            for (String dataType : request.dataTypesExposed) {
                if (dataType.containsIgnoreCase('PHI') || dataType.containsIgnoreCase('SSN') ||
                    dataType.containsIgnoreCase('Financial')) {
                    score += 1.5;
                }
            }
        }

        // Incident type
        if (request.incidentType == 'DATA_BREACH' || request.incidentType == 'UNAUTHORIZED_ACCESS') {
            score += 1.0;
        }

        // Encryption
        if (request.encryptionInPlace != null && request.encryptionInPlace) {
            score -= 1.0;
        }

        return Math.min(Math.max(score, 1.0), 10.0);
    }

    private Integer getSLAHours(String severity) {
        if (severity == 'CRITICAL') return CRITICAL_RESPONSE_SLA;
        if (severity == 'HIGH') return HIGH_RESPONSE_SLA;
        if (severity == 'MEDIUM') return MEDIUM_RESPONSE_SLA;
        return LOW_RESPONSE_SLA;
    }

    private Decimal getSeverityRiskScore(String severity) {
        if (severity == 'CRITICAL') return 9.5;
        if (severity == 'HIGH') return 7.5;
        if (severity == 'MEDIUM') return 5.5;
        return 3.5;
    }

    private String generateBreachAnalysis(IBreachNotificationService.BreachAssessmentRequest request, Decimal riskScore) {
        String analysis = 'Incident Type: ' + request.incidentType + '\n';
        analysis += 'Risk Score: ' + riskScore + '/10\n';
        analysis += 'Records Affected: ' + (request.recordsAffected != null ? String.valueOf(request.recordsAffected) : 'Unknown') + '\n';
        if (request.dataTypesExposed != null && !request.dataTypesExposed.isEmpty()) {
            analysis += 'Data Types: ' + String.join(request.dataTypesExposed, ', ') + '\n';
        }
        return analysis;
    }

    private List<String> generateMitigationSteps(String incidentType) {
        List<String> steps = new List<String>();
        steps.add('1. Contain the incident and prevent further damage');
        steps.add('2. Preserve evidence for investigation');
        steps.add('3. Notify relevant stakeholders per escalation matrix');
        steps.add('4. Investigate root cause');
        steps.add('5. Implement remediation measures');
        steps.add('6. Document lessons learned');
        steps.add('7. Update security controls as needed');
        return steps;
    }

    private String generateIncidentReportContent(Security_Incident__c incident) {
        String report = '# Security Incident Report\n\n';
        report += '**Incident ID:** ' + incident.Name + '\n';
        report += '**Type:** ' + incident.Incident_Type__c + '\n';
        report += '**Severity:** ' + incident.Severity__c + '\n';
        report += '**Status:** ' + incident.Status__c + '\n\n';

        report += '## Timeline\n\n';
        report += '- **Detected:** ' + (incident.Detected_Date__c != null ? incident.Detected_Date__c.format() : 'N/A') + '\n';
        report += '- **Resolved:** ' + (incident.Resolved_Date__c != null ? incident.Resolved_Date__c.format() : 'Ongoing') + '\n\n';

        report += '## Description\n\n';
        report += (incident.Description__c != null ? incident.Description__c : 'No description provided') + '\n\n';

        report += '## Impact\n\n';
        report += '- **Records Affected:** ' + (incident.Affected_Records__c != null ? String.valueOf(incident.Affected_Records__c.intValue()) : 'Unknown') + '\n\n';

        report += '## Root Cause\n\n';
        report += (incident.Root_Cause__c != null ? incident.Root_Cause__c : 'Pending analysis') + '\n\n';

        report += '## Resolution\n\n';
        report += (incident.Resolution__c != null ? incident.Resolution__c : 'Pending resolution') + '\n\n';

        report += '---\n';
        report += '*Report generated: ' + DateTime.now().format() + '*\n';

        return report;
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
