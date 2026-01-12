/**
 * IBreachNotificationService
 *
 * Interface for breach notification operations across compliance frameworks.
 * Implementations handle breach assessment, notification tracking, and reporting.
 *
 * @author Prometheion
 * @version 1.0
 */
public interface IBreachNotificationService {

    /**
     * Assess a potential breach incident
     * @param request Breach assessment request details
     * @return Assessment result with risk level and notification requirements
     */
    BreachAssessment assessBreach(BreachAssessmentRequest request);

    /**
     * Create breach notification record
     * @param breachId The breach record Id
     * @param notificationType Type of notification (REGULATOR, INDIVIDUAL, MEDIA)
     * @return Id of the notification record
     */
    Id createNotification(Id breachId, String notificationType);

    /**
     * Get notification deadline for a breach
     * @param breachId The breach record Id
     * @return DateTime of the notification deadline
     */
    DateTime getNotificationDeadline(Id breachId);

    /**
     * Track notification status for a breach
     * @param breachId The breach record Id
     * @return Current notification status
     */
    NotificationStatus getNotificationStatus(Id breachId);

    /**
     * Generate breach report for regulators
     * @param breachId The breach record Id
     * @return ContentDocumentId of the generated report
     */
    Id generateBreachReport(Id breachId);

    /**
     * Get all open breaches requiring action
     * @return List of open breach summaries
     */
    List<BreachSummary> getOpenBreaches();

    /**
     * Get breach metrics for reporting
     * @param daysBack Number of days to analyze
     * @return Breach metrics summary
     */
    BreachMetrics getBreachMetrics(Integer daysBack);

    /**
     * Breach assessment request
     */
    class BreachAssessmentRequest {
        @AuraEnabled public String incidentType;
        @AuraEnabled public String description;
        @AuraEnabled public Integer recordsAffected;
        @AuraEnabled public List<String> dataTypesExposed;
        @AuraEnabled public DateTime discoveryDate;
        @AuraEnabled public String discoveredBy;
        @AuraEnabled public Boolean encryptionInPlace;
        @AuraEnabled public String circumstances;
    }

    /**
     * Breach assessment result
     */
    class BreachAssessment {
        @AuraEnabled public Id breachId;
        @AuraEnabled public String riskLevel;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Boolean notificationRequired;
        @AuraEnabled public List<String> notificationTypes;
        @AuraEnabled public DateTime notificationDeadline;
        @AuraEnabled public String analysis;
        @AuraEnabled public List<String> mitigationSteps;
        @AuraEnabled public String framework;
    }

    /**
     * Notification status tracking
     */
    class NotificationStatus {
        @AuraEnabled public Id breachId;
        @AuraEnabled public Boolean regulatorNotified;
        @AuraEnabled public DateTime regulatorNotificationDate;
        @AuraEnabled public Boolean individualsNotified;
        @AuraEnabled public DateTime individualsNotificationDate;
        @AuraEnabled public Integer individualsNotifiedCount;
        @AuraEnabled public Boolean mediaNotified;
        @AuraEnabled public DateTime mediaNotificationDate;
        @AuraEnabled public String overallStatus;
        @AuraEnabled public DateTime deadline;
        @AuraEnabled public Boolean deadlineMet;
    }

    /**
     * Breach summary for listing
     */
    class BreachSummary {
        @AuraEnabled public Id breachId;
        @AuraEnabled public String incidentType;
        @AuraEnabled public String severity;
        @AuraEnabled public Integer recordsAffected;
        @AuraEnabled public DateTime discoveryDate;
        @AuraEnabled public DateTime notificationDeadline;
        @AuraEnabled public String status;
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal riskScore;
    }

    /**
     * Breach metrics for reporting
     */
    class BreachMetrics {
        @AuraEnabled public Integer totalBreaches;
        @AuraEnabled public Integer openBreaches;
        @AuraEnabled public Integer closedBreaches;
        @AuraEnabled public Decimal averageResolutionDays;
        @AuraEnabled public Integer deadlinesMet;
        @AuraEnabled public Integer deadlinesMissed;
        @AuraEnabled public Map<String, Integer> breachesBySeverity;
        @AuraEnabled public Map<String, Integer> breachesByType;
        @AuraEnabled public Integer totalRecordsAffected;
    }
}
