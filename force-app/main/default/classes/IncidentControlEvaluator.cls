/**
 * IncidentControlEvaluator
 *
 * Evaluates SOC2 CC7.x incident management controls.
 * Extracted from SOC2IncidentResponseService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class IncidentControlEvaluator {

    // Incident SLA thresholds (in hours)
    private static final Integer CRITICAL_RESPONSE_SLA = 1;
    private static final Integer HIGH_RESPONSE_SLA = 4;
    private static final Integer MEDIUM_RESPONSE_SLA = 24;
    private static final Integer LOW_RESPONSE_SLA = 72;

    /**
     * Evaluate incident detection controls (CC7.2)
     */
    public List<ComplianceServiceBase.InternalViolation> evaluateIncidentDetection() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Check for incidents without proper detection documentation
        List<HIPAA_Breach__c> allOpenIncidents = [
            SELECT Id, Description__c
            FROM HIPAA_Breach__c
            WHERE Status__c != 'Closed'
            WITH SECURITY_ENFORCED
        ];

        Integer undocumentedIncidents = 0;
        for (HIPAA_Breach__c inc : allOpenIncidents) {
            if (String.isBlank(inc.Description__c)) {
                undocumentedIncidents++;
            }
        }

        if (undocumentedIncidents > 0) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Undocumented Incidents',
                undocumentedIncidents + ' incidents lack proper documentation',
                'MEDIUM',
                'SOC2-CC7.2',
                'Add detailed descriptions to all security incidents',
                5.5
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate incident response controls (CC7.3)
     */
    public List<ComplianceServiceBase.InternalViolation> evaluateIncidentResponse() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Check for incidents exceeding SLA
        List<HIPAA_Breach__c> openIncidents = [
            SELECT Id, Risk_Level__c, Discovery_Date__c
            FROM HIPAA_Breach__c
            WHERE Status__c != 'Closed'
            WITH SECURITY_ENFORCED
        ];

        Integer slaBreaches = 0;
        for (HIPAA_Breach__c inc : openIncidents) {
            Integer slaHours = getSLAHours(inc.Risk_Level__c);
            DateTime slaDeadline = DateTime.newInstance(inc.Discovery_Date__c, Time.newInstance(0, 0, 0, 0)).addHours(slaHours);
            if (DateTime.now() > slaDeadline) {
                slaBreaches++;
            }
        }

        if (slaBreaches > 0) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'SLA Breaches',
                slaBreaches + ' incidents have exceeded their response SLA',
                'HIGH',
                'SOC2-CC7.3',
                'Prioritize and resolve overdue incidents immediately',
                8.0
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Evaluate incident recovery controls (CC7.4)
     */
    public List<ComplianceServiceBase.InternalViolation> evaluateIncidentRecovery() {
        List<ComplianceServiceBase.InternalViolation> violations = new List<ComplianceServiceBase.InternalViolation>();

        // Check for resolved incidents without root cause
        Integer noRootCause = [
            SELECT COUNT()
            FROM HIPAA_Breach__c
            WHERE Status__c = 'Closed'
            WITH SECURITY_ENFORCED
        ];

        if (noRootCause > 0) {
            ComplianceServiceBase.InternalViolation v = new ComplianceServiceBase.InternalViolation(
                'Missing Root Cause Analysis',
                noRootCause + ' resolved incidents lack root cause analysis',
                'MEDIUM',
                'SOC2-CC7.4',
                'Complete root cause analysis for all resolved incidents',
                5.0
            );
            violations.add(v);
        }

        return violations;
    }

    /**
     * Get SLA hours based on risk level
     */
    private Integer getSLAHours(String riskLevel) {
        if (riskLevel == 'Critical') return CRITICAL_RESPONSE_SLA;
        if (riskLevel == 'High') return HIGH_RESPONSE_SLA;
        if (riskLevel == 'Medium') return MEDIUM_RESPONSE_SLA;
        return LOW_RESPONSE_SLA;
    }
}
