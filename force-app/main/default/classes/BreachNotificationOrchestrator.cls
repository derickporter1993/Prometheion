/**
 * BreachNotificationOrchestrator
 *
 * Orchestrates breach notification workflows including status tracking,
 * notification creation, and timeline management.
 * Extracted from HIPAABreachNotificationService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class BreachNotificationOrchestrator {

    private static final Integer NOTIFICATION_DEADLINE_DAYS = 60;
    private static final Integer HHS_ANNUAL_THRESHOLD = 500;

    /**
     * Get notification status for a breach
     */
    public BreachNotificationTypes.NotificationStatus getNotificationStatus(Id breachId) {
        BreachNotificationTypes.NotificationStatus status =
            new BreachNotificationTypes.NotificationStatus();

        HIPAA_Breach__c breach = [
            SELECT Id, Name, Discovery_Date__c, Notification_Deadline__c,
                   Individuals_Notified__c, Individual_Notification_Date__c,
                   HHS_Notified__c, HHS_Notification_Date__c,
                   Media_Notified__c, Media_Notification_Date__c,
                   Records_Affected__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        status.breachId = breach.Id;

        // Set deadline and calculate if deadline was met
        if (breach.Notification_Deadline__c != null) {
            status.deadline = DateTime.newInstance(breach.Notification_Deadline__c, Time.newInstance(0, 0, 0, 0));

            // Check if individual notification was sent on time
            Boolean individualsNotifiedOnTime = breach.Individuals_Notified__c == true &&
                breach.Individual_Notification_Date__c != null &&
                breach.Individual_Notification_Date__c <= breach.Notification_Deadline__c;

            // For breaches >= 500, also check HHS notification timing
            Boolean hhsNotificationRequired = breach.Records_Affected__c != null &&
                breach.Records_Affected__c >= HHS_ANNUAL_THRESHOLD;
            Boolean hhsNotifiedOnTime = !hhsNotificationRequired ||
                (breach.HHS_Notified__c == true &&
                 breach.HHS_Notification_Date__c != null &&
                 breach.HHS_Notification_Date__c <= breach.Notification_Deadline__c);

            status.deadlineMet = individualsNotifiedOnTime && hhsNotifiedOnTime;
        }

        // Individual notification status
        status.individualsNotified = breach.Individuals_Notified__c == true;
        if (breach.Individual_Notification_Date__c != null) {
            status.individualsNotificationDate = DateTime.newInstance(breach.Individual_Notification_Date__c, Time.newInstance(0, 0, 0, 0));
        }
        status.individualsNotifiedCount = breach.Records_Affected__c != null ? Integer.valueOf(breach.Records_Affected__c) : 0;

        // HHS notification status
        status.regulatorNotified = breach.HHS_Notified__c == true;
        if (breach.HHS_Notification_Date__c != null) {
            status.regulatorNotificationDate = DateTime.newInstance(breach.HHS_Notification_Date__c, Time.newInstance(0, 0, 0, 0));
        }

        // Media notification
        status.mediaNotified = breach.Media_Notified__c == true;
        if (breach.Media_Notification_Date__c != null) {
            status.mediaNotificationDate = DateTime.newInstance(breach.Media_Notification_Date__c, Time.newInstance(0, 0, 0, 0));
        }

        // Overall status
        if (breach.Status__c != null) {
            status.overallStatus = breach.Status__c;
        } else {
            status.overallStatus = 'OPEN';
        }

        return status;
    }

    /**
     * Create breach notification record
     */
    public Id createNotification(Id breachId, String notificationType) {
        HIPAA_Breach__c breach = [
            SELECT Id, Notification_Deadline__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        // Update breach record based on notification type
        if (notificationType == 'INDIVIDUAL') {
            breach.Individuals_Notified__c = true;
            breach.Individual_Notification_Date__c = Date.today();
        } else if (notificationType == 'REGULATOR') {
            breach.HHS_Notified__c = true;
            breach.HHS_Notification_Date__c = Date.today();
        } else if (notificationType == 'MEDIA') {
            breach.Media_Notified__c = true;
            breach.Media_Notification_Date__c = Date.today();
        }

        PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_UPDATE);
        update breach;

        return breachId;
    }

    /**
     * Get notification deadline for a breach
     */
    public DateTime getNotificationDeadline(Id breachId) {
        HIPAA_Breach__c breach = [
            SELECT Notification_Deadline__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        return breach.Notification_Deadline__c != null
            ? DateTime.newInstance(breach.Notification_Deadline__c, Time.newInstance(0, 0, 0, 0))
            : null;
    }

    /**
     * Get notification timeline for a breach
     */
    public List<NotificationEvent> getNotificationTimeline(Id breachId) {
        List<NotificationEvent> timeline = new List<NotificationEvent>();

        HIPAA_Breach__c breach = [
            SELECT Id, Discovery_Date__c, Notification_Deadline__c,
                   Individual_Notification_Date__c, HHS_Notification_Date__c,
                   Media_Notification_Date__c, Records_Affected__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
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

    /**
     * Record individual notification
     */
    public void recordIndividualNotification(Id breachId, Integer individualsNotified) {
        HIPAA_Breach__c breach = [
            SELECT Id, Individuals_Notified__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        breach.Individuals_Notified__c = true;
        breach.Individual_Notification_Date__c = Date.today();
        breach.Individuals_Notified_Count__c = individualsNotified;

        PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_UPDATE);
        update breach;
    }

    /**
     * Record HHS notification
     */
    public void recordHHSNotification(Id breachId, String hhsConfirmationNumber) {
        HIPAA_Breach__c breach = [
            SELECT Id, HHS_Notified__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        breach.HHS_Notified__c = true;
        breach.HHS_Notification_Date__c = Date.today();
        breach.HHS_Confirmation_Number__c = hhsConfirmationNumber;

        PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_UPDATE);
        update breach;
    }

    /**
     * Inner class for notification timeline events
     */
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
