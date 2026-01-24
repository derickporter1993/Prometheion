/**
 * BreachNotificationTypes
 *
 * Data types for breach notification operations.
 * Used by IBreachNotificationService implementations.
 *
 * @author Prometheion
 * @version 1.0
 */
public class BreachNotificationTypes {
    
    /**
     * Breach assessment request
     */
    public class BreachAssessmentRequest {
        @AuraEnabled public String incidentType;
        @AuraEnabled public String description;
        @AuraEnabled public Integer recordsAffected;
        @AuraEnabled public List<String> dataTypesExposed;
        @AuraEnabled public DateTime discoveryDate;
        @AuraEnabled public String discoveredBy;
        @AuraEnabled public Boolean encryptionInPlace;
        @AuraEnabled public String circumstances;
        // Additional properties for risk assessment
        @AuraEnabled public Boolean recipientAuthorized;
        @AuraEnabled public String recipientType;
        @AuraEnabled public Boolean dataAcquired;
        @AuraEnabled public Boolean dataViewed;
        @AuraEnabled public List<String> mitigationsApplied;
    }

    /**
     * Breach assessment result
     */
    public class BreachAssessment {
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
    public class NotificationStatus {
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
     * Breach summary for listing and dashboard
     */
    public class BreachSummary {
        @AuraEnabled public Id breachId;
        @AuraEnabled public String incidentType;
        @AuraEnabled public String severity;
        @AuraEnabled public Integer recordsAffected;
        @AuraEnabled public DateTime discoveryDate;
        @AuraEnabled public DateTime notificationDeadline;
        @AuraEnabled public String status;
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal riskScore;
        // Dashboard summary properties
        @AuraEnabled public Integer totalBreaches;
        @AuraEnabled public Integer openBreaches;
        @AuraEnabled public Integer closedBreaches;
        @AuraEnabled public Integer totalAffectedIndividuals;
        @AuraEnabled public Integer overdueNotifications;
        @AuraEnabled public Boolean hhsAnnualReportRequired;
    }

    /**
     * Breach metrics for reporting
     */
    public class BreachMetrics {
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
