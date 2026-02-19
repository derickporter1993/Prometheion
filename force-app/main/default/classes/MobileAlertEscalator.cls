/**
 * Schedulable class that handles alert escalation.
 * Checks if an alert has been acknowledged and escalates to the next level if not.
 *
 * Escalation levels:
 * - Level 1: Team Lead (after initial delay)
 * - Level 2: Manager (if Level 1 not acknowledged)
 * - Level 3: CISO/Director (final escalation)
 *
 * @author Elaro Development Team
 * @since 2026-01
 * @group System Monitoring
 */
public with sharing class MobileAlertEscalator implements Schedulable {

    private static final String CRITICAL_NOTIFICATION_TYPE = 'Elaro_Critical_Alert';
    private static final Integer MAX_ESCALATION_LEVEL = 3;

    private String alertId;

    /**
     * Constructor
     * @param alertId The ID of the alert to potentially escalate
     */
    public MobileAlertEscalator(String alertId) {
        this.alertId = alertId;
    }

    /**
     * Schedulable execute method
     * @param ctx SchedulableContext
     */
    public void execute(SchedulableContext ctx) {
        processEscalation();
    }

    /**
     * Main escalation processing logic
     */
    private void processEscalation() {
        // Get the alert/gap details
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Framework__c, Severity__c, Gap_Description__c,
                   Alert_Acknowledged__c, Alert_Escalation_Level__c, Alert_Snoozed_Until__c
            FROM Compliance_Gap__c
            WHERE Id = :alertId
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            return;
        }

        Compliance_Gap__c gap = gaps[0];

        // Check if already acknowledged
        if (gap.Alert_Acknowledged__c == true) {
            return;
        }

        // Check if snoozed
        if (gap.Alert_Snoozed_Until__c != null && gap.Alert_Snoozed_Until__c > Datetime.now()) {
            return;
        }

        // Get current escalation level
        Integer currentLevel = gap.Alert_Escalation_Level__c != null ?
                              Integer.valueOf(gap.Alert_Escalation_Level__c) : 0;

        // Check if we've hit max escalation
        if (currentLevel >= MAX_ESCALATION_LEVEL) {
            logMaxEscalationReached(gap);
            return;
        }

        // Get escalation recipients for next level
        Integer nextLevel = currentLevel + 1;
        List<Id> escalationRecipients = getEscalationRecipients(nextLevel);

        if (escalationRecipients.isEmpty()) {
            ElaroLogger.warn( 'No escalation recipients for level ' + nextLevel);
            return;
        }

        // Send escalated notification
        String title = getEscalatedTitle(gap, nextLevel);
        String message = getEscalatedMessage(gap, nextLevel);

        sendEscalatedNotification(title, message, escalationRecipients);

        // Update escalation level on gap
        gap.Alert_Escalation_Level__c = nextLevel;
        update as user gap;

        // Schedule next escalation if not at max level
        if (nextLevel < MAX_ESCALATION_LEVEL) {
            scheduleNextEscalation(alertId, nextLevel + 1);
        }
    }

    /**
     * Gets recipients for a specific escalation level
     * @param level The escalation level (1, 2, or 3)
     * @return List of user IDs for that escalation level
     */
    private List<Id> getEscalationRecipients(Integer level) {
        List<Elaro_Escalation_Path__c> paths = [
            SELECT User__c
            FROM Elaro_Escalation_Path__c
            WHERE Level__c = :level
            AND Active__c = true
            WITH USER_MODE
        ];

        List<Id> userIds = new List<Id>();
        for (Elaro_Escalation_Path__c path : paths) {
            userIds.add(path.User__c);
        }
        return userIds;
    }

    /**
     * Gets the escalation delay for a specific level
     * @param level The escalation level
     * @return Delay in minutes
     */
    private Integer getEscalationDelay(Integer level) {
        List<Elaro_Escalation_Path__c> paths = [
            SELECT Escalation_Delay_Minutes__c
            FROM Elaro_Escalation_Path__c
            WHERE Level__c = :level
            AND Active__c = true
            WITH USER_MODE
            LIMIT 1
        ];

        if (!paths.isEmpty() && paths[0].Escalation_Delay_Minutes__c != null) {
            return Integer.valueOf(paths[0].Escalation_Delay_Minutes__c);
        }
        return 15; // Default 15 minutes
    }

    /**
     * Builds the escalated alert title
     */
    private String getEscalatedTitle(Compliance_Gap__c gap, Integer level) {
        String levelLabel = getLevelLabel(level);
        return 'ESCALATED (L' + level + '): ' + gap.Severity__c + ' - ' + gap.Name;
    }

    /**
     * Builds the escalated alert message
     */
    private String getEscalatedMessage(Compliance_Gap__c gap, Integer level) {
        String levelLabel = getLevelLabel(level);
        return 'Alert not acknowledged. ' + levelLabel + ' escalation.\n' +
               gap.Framework__c + ' compliance gap requires immediate attention.\n' +
               (gap.Gap_Description__c != null ? gap.Gap_Description__c.abbreviate(150) : '');
    }

    /**
     * Gets human-readable label for escalation level
     */
    private String getLevelLabel(Integer level) {
        Map<Integer, String> labels = new Map<Integer, String>{
            1 => 'Team Lead',
            2 => 'Manager',
            3 => 'CISO/Director'
        };
        return labels.containsKey(level) ? labels.get(level) : 'Level ' + level;
    }

    /**
     * Sends the escalated notification
     */
    private void sendEscalatedNotification(String title, String body, List<Id> recipients) {
        try {
            List<CustomNotificationType> notifTypes = [
                SELECT Id FROM CustomNotificationType
                WHERE DeveloperName = :CRITICAL_NOTIFICATION_TYPE
                WITH USER_MODE
                LIMIT 1
            ];

            if (notifTypes.isEmpty()) {
                ElaroLogger.error( 'Notification type not found');
                return;
            }

            Messaging.CustomNotification notification = new Messaging.CustomNotification();
            notification.setNotificationTypeId(notifTypes[0].Id);
            notification.setTargetId(alertId);
            notification.setTitle(title);
            notification.setBody(body);

            Set<String> recipientSet = new Set<String>();
            for (Id recipientId : recipients) {
                recipientSet.add(String.valueOf(recipientId));
            }

            if (!Test.isRunningTest()) {
                notification.send(recipientSet);
            }

        } catch (Exception e) {
            ElaroLogger.error( 'Escalated notification failed: ' + e.getMessage());
        }
    }

    /**
     * Schedules the next escalation check
     */
    private void scheduleNextEscalation(String alertId, Integer nextLevel) {
        Integer delay = getEscalationDelay(nextLevel);
        String jobName = 'Elaro Escalation L' + nextLevel + ' - ' + alertId.substring(0, 15);

        Datetime futureTime = Datetime.now().addMinutes(delay);
        String cronExp = futureTime.second() + ' ' + futureTime.minute() + ' ' +
                        futureTime.hour() + ' ' + futureTime.day() + ' ' +
                        futureTime.month() + ' ? ' + futureTime.year();

        try {
            System.schedule(jobName, cronExp, new MobileAlertEscalator(alertId));
        } catch (Exception e) {
            ElaroLogger.error( 'Failed to schedule next escalation: ' + e.getMessage());
        }
    }

    /**
     * Logs when maximum escalation level is reached
     */
    private void logMaxEscalationReached(Compliance_Gap__c gap) {
        ElaroLogger.warn( 'Maximum escalation level reached for gap: ' + gap.Name +
                     '. Alert was never acknowledged.');
    }
}
