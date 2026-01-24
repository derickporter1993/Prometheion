/**
 * BreachAssessmentService
 *
 * Handles 4-factor risk assessment for HIPAA breaches per 45 CFR 164.402.
 * Extracted from HIPAABreachNotificationService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class BreachAssessmentService {

    private static final Integer HHS_ANNUAL_THRESHOLD = 500;

    /**
     * Calculate Nature and Extent score based on exposed data types and volume
     * Factor 1 of 4-factor risk analysis
     */
    public Decimal calculateNatureExtentScore(BreachNotificationTypes.BreachAssessmentRequest request) {
        Decimal score = 1;

        // High-risk PHI types increase score
        Set<String> highRiskTypes = new Set<String>{'SSN', 'Financial', 'Mental Health', 'Substance Abuse', 'HIV/AIDS'};
        if (request.dataTypesExposed != null) {
            for (String dataType : request.dataTypesExposed) {
                if (highRiskTypes.contains(dataType)) {
                    score += 2;
                }
            }
        }

        // Volume of records affects score (use >= HHS_ANNUAL_THRESHOLD per HIPAA 45 CFR 164.408)
        if (request.recordsAffected != null && request.recordsAffected >= HHS_ANNUAL_THRESHOLD) {
            score += 2;
        } else if (request.recordsAffected != null && request.recordsAffected >= 100) {
            score += 1;
        }

        return Math.min(score, 10);
    }

    /**
     * Calculate Unauthorized Person score based on recipient type
     * Factor 2 of 4-factor risk analysis
     */
    public Decimal calculateUnauthorizedPersonScore(BreachNotificationTypes.BreachAssessmentRequest request) {
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

    /**
     * Calculate Acquisition score based on whether data was viewed/acquired
     * Factor 3 of 4-factor risk analysis
     */
    public Decimal calculateAcquisitionScore(BreachNotificationTypes.BreachAssessmentRequest request) {
        if (request.dataAcquired && request.dataViewed) {
            return 10; // Highest risk
        } else if (request.dataAcquired || request.dataViewed) {
            return 7;
        } else {
            return 3; // Lower risk if no evidence of acquisition/viewing
        }
    }

    /**
     * Calculate Mitigation score based on mitigations applied
     * Factor 4 of 4-factor risk analysis
     */
    public Decimal calculateMitigationScore(BreachNotificationTypes.BreachAssessmentRequest request) {
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

    /**
     * Get risk level label from numeric score
     */
    public String getRiskLevel(Decimal score) {
        if (score >= 8.0) return 'CRITICAL';
        if (score >= 6.0) return 'HIGH';
        if (score >= 4.0) return 'MEDIUM';
        return 'LOW';
    }

    /**
     * Perform complete 4-factor breach assessment
     */
    public BreachNotificationTypes.BreachAssessment performAssessment(
        BreachNotificationTypes.BreachAssessmentRequest request
    ) {
        BreachNotificationTypes.BreachAssessment assessment =
            new BreachNotificationTypes.BreachAssessment();
        assessment.framework = 'HIPAA';

        // Calculate risk score based on request data
        Decimal riskScore = 5.0; // Base score

        // Adjust based on records affected
        if (request.recordsAffected != null) {
            if (request.recordsAffected >= HHS_ANNUAL_THRESHOLD) {
                riskScore += 3.0;
            } else if (request.recordsAffected >= 100) {
                riskScore += 2.0;
            } else if (request.recordsAffected >= 10) {
                riskScore += 1.0;
            }
        }

        // Adjust based on encryption
        if (request.encryptionInPlace != null && !request.encryptionInPlace) {
            riskScore += 2.0;
        }

        // Adjust based on data types
        if (request.dataTypesExposed != null && !request.dataTypesExposed.isEmpty()) {
            riskScore += 1.0;
        }

        assessment.riskScore = Math.min(riskScore, 10.0);
        assessment.riskLevel = getRiskLevel(assessment.riskScore);
        assessment.notificationRequired = assessment.riskScore >= 3.0;

        // Set notification deadline if required (60 days per HIPAA)
        if (assessment.notificationRequired && request.discoveryDate != null) {
            assessment.notificationDeadline = request.discoveryDate.addDays(60);
        } else if (assessment.notificationRequired) {
            assessment.notificationDeadline = DateTime.now().addDays(60);
        }

        // Build analysis and mitigation steps
        assessment.analysis = 'Breach assessment completed. Records affected: ' +
            (request.recordsAffected != null ? request.recordsAffected : 0) +
            '. Encryption in place: ' + (request.encryptionInPlace != null ? request.encryptionInPlace : false);

        assessment.mitigationSteps = new List<String>{
            'Notify affected individuals within 60 days',
            'Document breach details and assessment',
            'Implement additional safeguards if needed'
        };

        // Determine notification types required per HIPAA 45 CFR 164.404
        assessment.notificationTypes = new List<String>();
        if (assessment.notificationRequired) {
            assessment.notificationTypes.add('INDIVIDUAL');
            if (request.recordsAffected != null && request.recordsAffected >= HHS_ANNUAL_THRESHOLD) {
                assessment.notificationTypes.add('REGULATOR');
                assessment.notificationTypes.add('MEDIA');
            }
        }

        return assessment;
    }
}
