/**
 * @description Service for publishing mobile push notifications for compliance alerts.
 * Integrates with Salesforce Custom Notifications API to send alerts to on-call users.
 *
 * Features:
 * - Critical and high-priority alert publishing
 * - On-call schedule integration
 * - Escalation scheduling
 * - Alert acknowledgment tracking
 * - Snooze functionality
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
public with sharing class MobileAlertPublisher {

    private static final String CRITICAL_NOTIFICATION_TYPE = 'Elaro_Critical_Alert';

    /**
     * @description Publishes a critical alert to on-call users
     * @param alertId The ID of the alert record
     * @param title Alert title
     * @param message Alert message body
     */
    @AuraEnabled
    public static void publishCriticalAlert(String alertId, String title, String message) {
        List<Id> recipients = getOnCallUsers();

        if (recipients.isEmpty()) {
            recipients = getAdminUsers();
        }

        if (recipients.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'No recipients found for critical alert');
            return;
        }

        publishNotification(CRITICAL_NOTIFICATION_TYPE, alertId, title, message, recipients);

        // Schedule escalation check
        scheduleEscalationCheck(alertId, getEscalationDelayMinutes(1));
    }

    /**
     * @description Publishes a high-priority alert to on-call users
     * @param alertId The ID of the alert record
     * @param title Alert title
     * @param message Alert message body
     */
    @AuraEnabled
    public static void publishHighAlert(String alertId, String title, String message) {
        List<Id> recipients = getOnCallUsers();

        if (recipients.isEmpty()) {
            recipients = getAdminUsers();
        }

        publishNotification(CRITICAL_NOTIFICATION_TYPE, alertId, title, message, recipients);
    }

    /**
     * @description Publishes alert for a compliance gap based on severity
     * @param gapId The Compliance_Gap__c record ID
     */
    @AuraEnabled
    public static void publishAlertForGap(String gapId) {
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Framework__c, Severity__c, Gap_Description__c
            FROM Compliance_Gap__c
            WHERE Id = :gapId
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            throw new MobileAlertException('Compliance gap not found');
        }

        Compliance_Gap__c gap = gaps[0];
        String title = gap.Severity__c + ' Compliance Gap: ' + gap.Name;
        String message = gap.Framework__c + ' - ' + (gap.Gap_Description__c != null ?
            gap.Gap_Description__c.abbreviate(200) : 'No description');

        if (gap.Severity__c == 'CRITICAL') {
            publishCriticalAlert(gapId, title, message);
        } else if (gap.Severity__c == 'HIGH') {
            publishHighAlert(gapId, title, message);
        }
    }

    /**
     * @description Acknowledges an alert to stop escalation
     * @param alertId The alert record ID
     */
    @AuraEnabled
    public static void acknowledgeAlert(String alertId) {
        // Find the gap and update acknowledgment fields
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Alert_Acknowledged__c, Alert_Acknowledged_By__c, Alert_Acknowledged_At__c
            FROM Compliance_Gap__c
            WHERE Id = :alertId
            WITH USER_MODE
            LIMIT 1
        ];

        if (!gaps.isEmpty()) {
            Compliance_Gap__c gap = gaps[0];
            gap.Alert_Acknowledged__c = true;
            gap.Alert_Acknowledged_By__c = UserInfo.getUserId();
            gap.Alert_Acknowledged_At__c = Datetime.now();

            if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
                update gap;
            }
        }

        // Cancel any pending escalations
        cancelEscalation(alertId);
    }

    /**
     * @description Snoozes an alert for a specified duration
     * @param alertId The alert record ID
     * @param minutes Number of minutes to snooze
     */
    @AuraEnabled
    public static void snoozeAlert(String alertId, Integer minutes) {
        if (minutes == null || minutes <= 0 || minutes > 480) {
            throw new MobileAlertException('Snooze duration must be between 1 and 480 minutes');
        }

        Datetime snoozeUntil = Datetime.now().addMinutes(minutes);

        List<Compliance_Gap__c> gaps = [
            SELECT Id, Alert_Snoozed_Until__c
            FROM Compliance_Gap__c
            WHERE Id = :alertId
            WITH USER_MODE
            LIMIT 1
        ];

        if (!gaps.isEmpty()) {
            Compliance_Gap__c gap = gaps[0];
            gap.Alert_Snoozed_Until__c = snoozeUntil;

            if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
                update gap;
            }
        }

        // Cancel current escalation and schedule delayed notification
        cancelEscalation(alertId);
        scheduleDelayedNotification(alertId, minutes);
    }

    /**
     * @description Gets current on-call users
     * @return List of on-call user IDs
     */
    @AuraEnabled(cacheable=true)
    public static List<OnCallUser> getCurrentOnCallUsers() {
        Datetime now = Datetime.now();
        List<OnCallUser> result = new List<OnCallUser>();

        List<Elaro_On_Call_Schedule__c> schedules = [
            SELECT Id, User__c, User__r.Name, User__r.Email, Rotation_Name__c,
                   Start_Time__c, End_Time__c, Notification_Methods__c
            FROM Elaro_On_Call_Schedule__c
            WHERE Start_Time__c <= :now
            AND End_Time__c >= :now
            AND Active__c = true
            WITH USER_MODE
            ORDER BY Rotation_Name__c
        ];

        for (Elaro_On_Call_Schedule__c schedule : schedules) {
            OnCallUser ocu = new OnCallUser();
            ocu.userId = schedule.User__c;
            ocu.userName = schedule.User__r.Name;
            ocu.userEmail = schedule.User__r.Email;
            ocu.rotationName = schedule.Rotation_Name__c;
            ocu.shiftEnd = schedule.End_Time__c;
            ocu.notificationMethods = schedule.Notification_Methods__c;
            result.add(ocu);
        }

        return result;
    }

    /**
     * @description Gets the escalation path configuration
     * @return List of escalation path entries
     */
    @AuraEnabled(cacheable=true)
    public static List<EscalationPathEntry> getEscalationPath() {
        List<EscalationPathEntry> result = new List<EscalationPathEntry>();

        List<Elaro_Escalation_Path__c> paths = [
            SELECT Id, User__c, User__r.Name, User__r.Email, Level__c,
                   Role__c, Notification_Method__c, Escalation_Delay_Minutes__c
            FROM Elaro_Escalation_Path__c
            WHERE Active__c = true
            WITH USER_MODE
            ORDER BY Level__c ASC
        ];

        for (Elaro_Escalation_Path__c path : paths) {
            EscalationPathEntry entry = new EscalationPathEntry();
            entry.pathId = path.Id;
            entry.userId = path.User__c;
            entry.userName = path.User__r.Name;
            entry.userEmail = path.User__r.Email;
            entry.level = Integer.valueOf(path.Level__c);
            entry.role = path.Role__c;
            entry.notificationMethod = path.Notification_Method__c;
            entry.delayMinutes = Integer.valueOf(path.Escalation_Delay_Minutes__c);
            result.add(entry);
        }

        return result;
    }

    // ============================================
    // Private Helper Methods
    // ============================================

    private static void publishNotification(String typeName, String targetId, String title, String body, List<Id> recipients) {
        try {
            List<CustomNotificationType> notifTypes = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = :typeName
                LIMIT 1
            ];

            if (notifTypes.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'Notification type not found: ' + typeName);
                return;
            }

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notifTypes[0].Id);
            notification.setTargetId(targetId);
            notification.setTitle(title);
            notification.setBody(body);

            Set<String> recipientSet = new Set<String>();
            for (Id recipientId : recipients) {
                recipientSet.add(String.valueOf(recipientId));
            }

            if (!Test.isRunningTest()) {
                notification.send(recipientSet);
            }

            logNotificationSent(targetId, title, recipients.size());

        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Mobile notification failed: ' + e.getMessage());
        }
    }

    private static List<Id> getOnCallUsers() {
        Datetime now = Datetime.now();
        List<Elaro_On_Call_Schedule__c> schedules = [
            SELECT User__c
            FROM Elaro_On_Call_Schedule__c
            WHERE Start_Time__c <= :now
            AND End_Time__c >= :now
            AND Active__c = true
            WITH USER_MODE
        ];

        List<Id> userIds = new List<Id>();
        for (Elaro_On_Call_Schedule__c schedule : schedules) {
            userIds.add(schedule.User__c);
        }
        return userIds;
    }

    private static List<Id> getAdminUsers() {
        List<PermissionSetAssignment> admins = [
            SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = 'Elaro_Admin'
            WITH USER_MODE
            LIMIT 10
        ];

        List<Id> userIds = new List<Id>();
        for (PermissionSetAssignment psa : admins) {
            userIds.add(psa.AssigneeId);
        }
        return userIds;
    }

    private static Integer getEscalationDelayMinutes(Integer level) {
        List<Elaro_Escalation_Path__c> paths = [
            SELECT Escalation_Delay_Minutes__c
            FROM Elaro_Escalation_Path__c
            WHERE Level__c = :level AND Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        if (!paths.isEmpty() && paths[0].Escalation_Delay_Minutes__c != null) {
            return Integer.valueOf(paths[0].Escalation_Delay_Minutes__c);
        }
        return 30; // Default 30 minutes
    }

    private static void scheduleEscalationCheck(String alertId, Integer minutes) {
        String jobName = 'Elaro Escalation - ' + alertId.substring(0, 15);
        String cronExp = getCronForMinutesFromNow(minutes);

        try {
            System.schedule(jobName, cronExp, new MobileAlertEscalator(alertId));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to schedule escalation: ' + e.getMessage());
        }
    }

    private static void scheduleDelayedNotification(String alertId, Integer minutes) {
        String jobName = 'Elaro Delayed Alert - ' + alertId.substring(0, 15);
        String cronExp = getCronForMinutesFromNow(minutes);

        try {
            System.schedule(jobName, cronExp, new MobileAlertResender(alertId));
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to schedule delayed notification: ' + e.getMessage());
        }
    }

    private static void cancelEscalation(String alertId) {
        String jobPrefix = 'Elaro Escalation - ' + alertId.substring(0, 15);

        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%' + jobPrefix + '%')
        ];

        for (CronTrigger job : jobs) {
            try {
                System.abortJob(job.Id);
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Failed to abort job: ' + e.getMessage());
            }
        }
    }

    private static String getCronForMinutesFromNow(Integer minutes) {
        Datetime futureTime = Datetime.now().addMinutes(minutes);
        return futureTime.second() + ' ' + futureTime.minute() + ' ' +
               futureTime.hour() + ' ' + futureTime.day() + ' ' +
               futureTime.month() + ' ? ' + futureTime.year();
    }

    private static void logNotificationSent(String targetId, String title, Integer recipientCount) {
        System.debug(LoggingLevel.INFO, 'Mobile notification sent - Target: ' + targetId +
                     ', Title: ' + title + ', Recipients: ' + recipientCount);
    }

    // ============================================
    // Inner Classes
    // ============================================

    /**
     * @description Wrapper for on-call user information
     */
    public class OnCallUser {
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public String rotationName;
        @AuraEnabled public Datetime shiftEnd;
        @AuraEnabled public String notificationMethods;
    }

    /**
     * @description Wrapper for escalation path entries
     */
    public class EscalationPathEntry {
        @AuraEnabled public Id pathId;
        @AuraEnabled public Id userId;
        @AuraEnabled public String userName;
        @AuraEnabled public String userEmail;
        @AuraEnabled public Integer level;
        @AuraEnabled public String role;
        @AuraEnabled public String notificationMethod;
        @AuraEnabled public Integer delayMinutes;
    }

    /**
     * @description Schedulable class for resending snoozed alerts
     */
    public class MobileAlertResender implements Schedulable {
        private String alertId;

        public MobileAlertResender(String alertId) {
            this.alertId = alertId;
        }

        public void execute(SchedulableContext ctx) {
            // Check if still snoozed
            List<Compliance_Gap__c> gaps = [
                SELECT Id, Name, Framework__c, Severity__c, Gap_Description__c, Alert_Snoozed_Until__c
                FROM Compliance_Gap__c
                WHERE Id = :alertId
                LIMIT 1
            ];

            if (gaps.isEmpty()) return;

            Compliance_Gap__c gap = gaps[0];

            // If snooze expired, resend alert
            if (gap.Alert_Snoozed_Until__c == null || gap.Alert_Snoozed_Until__c <= Datetime.now()) {
                MobileAlertPublisher.publishAlertForGap(alertId);
            }
        }
    }

    /**
     * @description Custom exception for mobile alert errors
     */
    public class MobileAlertException extends Exception {}
}
