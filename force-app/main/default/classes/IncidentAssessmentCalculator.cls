/**
 * IncidentAssessmentCalculator
 *
 * Handles incident risk calculations for SOC2 incident response.
 * Extracted from SOC2IncidentResponseService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class IncidentAssessmentCalculator {

    // Incident SLA thresholds (in hours)
    private static final Integer CRITICAL_RESPONSE_SLA = 1;
    private static final Integer HIGH_RESPONSE_SLA = 4;
    private static final Integer MEDIUM_RESPONSE_SLA = 24;
    private static final Integer LOW_RESPONSE_SLA = 72;

    /**
     * Calculate breach risk score based on request parameters
     */
    public Decimal calculateBreachRiskScore(BreachNotificationTypes.BreachAssessmentRequest request) {
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

    /**
     * Get SLA hours based on risk level
     */
    public Integer getSLAHours(String riskLevel) {
        if (riskLevel == 'Critical') return CRITICAL_RESPONSE_SLA;
        if (riskLevel == 'High') return HIGH_RESPONSE_SLA;
        if (riskLevel == 'Medium') return MEDIUM_RESPONSE_SLA;
        return LOW_RESPONSE_SLA;
    }

    /**
     * Get numeric risk score from severity string
     */
    public Decimal getSeverityRiskScore(String riskLevel) {
        if (riskLevel == 'Critical') return 9.5;
        if (riskLevel == 'High') return 7.5;
        if (riskLevel == 'Medium') return 5.5;
        return 3.5;
    }

    /**
     * Determine severity from risk score
     */
    public String getSeverityFromScore(Decimal riskScore) {
        if (riskScore >= 9.0) {
            return 'Critical';
        } else if (riskScore >= 7.0) {
            return 'High';
        } else if (riskScore >= 5.0) {
            return 'Medium';
        } else {
            return 'Low';
        }
    }

    /**
     * Get response days based on severity
     */
    public Integer getResponseDays(String severity) {
        if (severity == 'Critical') return 1;
        if (severity == 'High') return 3;
        return 7;
    }

    /**
     * Generate breach analysis text
     */
    public String generateBreachAnalysis(BreachNotificationTypes.BreachAssessmentRequest request, Decimal riskScore) {
        String analysis = 'Incident Type: ' + request.incidentType + '\n';
        analysis += 'Risk Score: ' + riskScore + '/10\n';
        analysis += 'Records Affected: ' + (request.recordsAffected != null ? String.valueOf(request.recordsAffected) : 'Unknown') + '\n';
        if (request.dataTypesExposed != null && !request.dataTypesExposed.isEmpty()) {
            analysis += 'Data Types: ' + String.join(request.dataTypesExposed, ', ') + '\n';
        }
        return analysis;
    }

    /**
     * Generate mitigation steps based on incident type
     */
    public List<String> generateMitigationSteps(String incidentType) {
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

    /**
     * Determine notification types required based on risk score
     */
    public List<String> getRequiredNotificationTypes(Decimal riskScore) {
        List<String> notificationTypes = new List<String>();

        if (riskScore >= 7.0) {
            notificationTypes.add('INTERNAL_STAKEHOLDERS');
            if (riskScore >= 9.0) {
                notificationTypes.add('MANAGEMENT');
                notificationTypes.add('AUDITOR');
            }
        }

        return notificationTypes;
    }
}
