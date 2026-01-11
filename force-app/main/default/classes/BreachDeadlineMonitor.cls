/**
 * BreachDeadlineMonitor
 *
 * Scheduled job to monitor HIPAA breach notification deadlines.
 * Sends alerts for approaching and overdue deadlines per 45 CFR 164.404.
 *
 * Schedule: Daily (recommended)
 * Example: System.schedule('Breach Deadline Monitor', '0 0 8 * * ?', new BreachDeadlineMonitor());
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class BreachDeadlineMonitor implements Schedulable {

    private static final String JOB_NAME = 'Prometheion Breach Deadline Monitor';
    private static final Integer ALERT_DAYS_BEFORE = 14; // Alert 2 weeks before deadline
    private static final Integer CRITICAL_DAYS_BEFORE = 7; // Critical alert 1 week before
    private static final Integer HHS_THRESHOLD = 500; // HHS immediate notification threshold

    /**
     * Schedulable execute method
     */
    public void execute(SchedulableContext ctx) {
        monitorDeadlinesAsync();
    }

    /**
     * Async method to monitor deadlines
     */
    @future
    private static void monitorDeadlinesAsync() {
        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.monitorDeadlines();
    }

    /**
     * Main method to monitor all breach deadlines
     */
    public void monitorDeadlines() {
        try {
            MonitoringResult result = new MonitoringResult();

            // Check for overdue breaches
            result.overdueBreaches = checkOverdueBreaches();

            // Check for approaching deadlines
            result.criticalBreaches = checkCriticalDeadlines();
            result.upcomingBreaches = checkUpcomingDeadlines();

            // Check for large breaches requiring immediate HHS notification
            result.hhsRequired = checkHHSNotificationRequired();

            // Create alerts and notifications
            createAlerts(result);

            // Update breach statuses
            updateBreachStatuses(result);

            // Log execution
            logExecution(result);

        } catch (Exception e) {
            logError('Breach deadline monitoring failed: ' + e.getMessage());
        }
    }

    /**
     * Check for overdue breach notifications
     */
    private List<HIPAA_Breach__c> checkOverdueBreaches() {
        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Notification_Deadline__c,
                   Records_Affected__c, Status__c, Risk_Level__c,
                   Individuals_Notified__c, HHS_Notified__c
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c < TODAY
            AND Notification_Required__c = true
            AND (Individuals_Notified__c = false OR HHS_Notified__c = false)
            AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Notification_Deadline__c ASC
        ];
    }

    /**
     * Check for breaches with deadlines within 7 days
     */
    private List<HIPAA_Breach__c> checkCriticalDeadlines() {
        Date criticalDate = Date.today().addDays(CRITICAL_DAYS_BEFORE);

        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Notification_Deadline__c,
                   Records_Affected__c, Status__c, Risk_Level__c,
                   Individuals_Notified__c, HHS_Notified__c
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c >= TODAY
            AND Notification_Deadline__c <= :criticalDate
            AND Notification_Required__c = true
            AND (Individuals_Notified__c = false OR HHS_Notified__c = false)
            AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Notification_Deadline__c ASC
        ];
    }

    /**
     * Check for breaches with deadlines within 14 days
     */
    private List<HIPAA_Breach__c> checkUpcomingDeadlines() {
        Date upcomingDate = Date.today().addDays(ALERT_DAYS_BEFORE);
        Date criticalDate = Date.today().addDays(CRITICAL_DAYS_BEFORE);

        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Notification_Deadline__c,
                   Records_Affected__c, Status__c, Risk_Level__c,
                   Individuals_Notified__c, HHS_Notified__c
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c > :criticalDate
            AND Notification_Deadline__c <= :upcomingDate
            AND Notification_Required__c = true
            AND (Individuals_Notified__c = false OR HHS_Notified__c = false)
            AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Notification_Deadline__c ASC
        ];
    }

    /**
     * Check for large breaches requiring immediate HHS notification
     */
    private List<HIPAA_Breach__c> checkHHSNotificationRequired() {
        return [
            SELECT Id, Name, Description__c, Discovery_Date__c, Notification_Deadline__c,
                   Records_Affected__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Records_Affected__c >= :HHS_THRESHOLD
            AND HHS_Notified__c = false
            AND Notification_Required__c = true
            AND Status__c != 'Closed'
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Create alerts based on monitoring results
     */
    private void createAlerts(MonitoringResult result) {
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();

        // Create critical alerts for overdue breaches
        for (HIPAA_Breach__c breach : result.overdueBreaches) {
            Integer daysOverdue = breach.Notification_Deadline__c.daysBetween(Date.today());

            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'Breach Notification';
            gap.Framework__c = 'HIPAA';
            gap.Severity__c = 'Critical';
            gap.Status__c = 'Open';
            gap.Description__c = 'OVERDUE: Breach ' + breach.Name + ' notification is ' +
                daysOverdue + ' days past deadline. ' +
                'Affected records: ' + breach.Records_Affected__c;
            gap.Remediation_Steps__c = 'IMMEDIATE ACTION REQUIRED: ' +
                'Complete all required notifications immediately. Document reason for delay.';
            gap.Due_Date__c = Date.today();
            gap.Related_Record_Id__c = breach.Id;

            gaps.add(gap);
        }

        // Create high priority alerts for critical deadlines
        for (HIPAA_Breach__c breach : result.criticalBreaches) {
            Integer daysRemaining = Date.today().daysBetween(breach.Notification_Deadline__c);

            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'Breach Notification';
            gap.Framework__c = 'HIPAA';
            gap.Severity__c = 'High';
            gap.Status__c = 'Open';
            gap.Description__c = 'CRITICAL: Breach ' + breach.Name + ' notification due in ' +
                daysRemaining + ' days. Affected records: ' + breach.Records_Affected__c;
            gap.Remediation_Steps__c = 'Prioritize notification activities. ' +
                'Ensure individual and HHS notifications are sent before deadline.';
            gap.Due_Date__c = breach.Notification_Deadline__c;
            gap.Related_Record_Id__c = breach.Id;

            gaps.add(gap);
        }

        // Create alerts for HHS notification requirement
        for (HIPAA_Breach__c breach : result.hhsRequired) {
            Compliance_Gap__c gap = new Compliance_Gap__c();
            gap.Gap_Type__c = 'HHS Notification';
            gap.Framework__c = 'HIPAA';
            gap.Severity__c = 'Critical';
            gap.Status__c = 'Open';
            gap.Description__c = 'HHS NOTIFICATION REQUIRED: Breach ' + breach.Name +
                ' affects ' + breach.Records_Affected__c +
                ' individuals. Per HIPAA, breaches of 500+ require immediate HHS notification.';
            gap.Remediation_Steps__c = 'Submit breach notification to HHS via the online portal immediately. ' +
                'Also notify prominent media outlets in affected states.';
            gap.Due_Date__c = Date.today();
            gap.Related_Record_Id__c = breach.Id;

            gaps.add(gap);
        }

        // Insert all gaps
        if (!gaps.isEmpty()) {
            // Check for existing gaps to avoid duplicates
            Set<Id> breachIds = new Set<Id>();
            for (Compliance_Gap__c gap : gaps) {
                if (gap.Related_Record_Id__c != null) {
                    breachIds.add(gap.Related_Record_Id__c);
                }
            }

            Set<Id> existingGapBreachIds = new Set<Id>();
            for (Compliance_Gap__c existing : [
                SELECT Related_Record_Id__c
                FROM Compliance_Gap__c
                WHERE Related_Record_Id__c IN :breachIds
                AND Status__c NOT IN ('Verified', 'Accepted Risk')
                AND CreatedDate >= :DateTime.now().addDays(-1)
                WITH SECURITY_ENFORCED
            ]) {
                existingGapBreachIds.add(existing.Related_Record_Id__c);
            }

            // Filter out duplicates
            List<Compliance_Gap__c> newGaps = new List<Compliance_Gap__c>();
            for (Compliance_Gap__c gap : gaps) {
                if (!existingGapBreachIds.contains(gap.Related_Record_Id__c)) {
                    newGaps.add(gap);
                }
            }

            if (!newGaps.isEmpty()) {
                PrometheionSecurityUtils.validateCRUDAccess('Compliance_Gap__c', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
                insert newGaps;
            }
        }

        // Publish platform event for real-time alerts
        publishAlertEvents(result);
    }

    /**
     * Publish platform events for real-time alerts
     */
    private void publishAlertEvents(MonitoringResult result) {
        List<Prometheion_Alert_Event__e> events = new List<Prometheion_Alert_Event__e>();

        // Overdue breach alerts
        for (HIPAA_Breach__c breach : result.overdueBreaches) {
            events.add(new Prometheion_Alert_Event__e(
                Alert_Type__c = 'HIPAA Breach Overdue',
                Severity__c = 'Critical',
                Message__c = 'Breach ' + breach.Name + ' notification is OVERDUE',
                Related_Record_Id__c = breach.Id
            ));
        }

        // Critical deadline alerts
        for (HIPAA_Breach__c breach : result.criticalBreaches) {
            Integer daysRemaining = Date.today().daysBetween(breach.Notification_Deadline__c);
            events.add(new Prometheion_Alert_Event__e(
                Alert_Type__c = 'HIPAA Breach Deadline',
                Severity__c = 'High',
                Message__c = 'Breach ' + breach.Name + ' deadline in ' + daysRemaining + ' days',
                Related_Record_Id__c = breach.Id
            ));
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    /**
     * Update breach statuses based on deadlines
     */
    private void updateBreachStatuses(MonitoringResult result) {
        List<HIPAA_Breach__c> breachesToUpdate = new List<HIPAA_Breach__c>();

        // Mark overdue breaches
        for (HIPAA_Breach__c breach : result.overdueBreaches) {
            if (breach.Status__c != 'Notification In Progress') {
                breach.Status__c = 'Notification In Progress';
                breachesToUpdate.add(breach);
            }
        }

        if (!breachesToUpdate.isEmpty()) {
            PrometheionSecurityUtils.validateCRUDAccess('HIPAA_Breach__c', PrometheionSecurityUtils.DmlOperation.DML_UPDATE);
            update breachesToUpdate;
        }
    }

    /**
     * Log successful execution
     */
    private void logExecution(MonitoringResult result) {
        try {
            String details = 'Breach Deadline Monitoring Results:\n';
            details += '- Overdue breaches: ' + result.overdueBreaches.size() + '\n';
            details += '- Critical (< 7 days): ' + result.criticalBreaches.size() + '\n';
            details += '- Upcoming (< 14 days): ' + result.upcomingBreaches.size() + '\n';
            details += '- HHS notification required: ' + result.hhsRequired.size();

            Prometheion_Audit_Log__c log = new Prometheion_Audit_Log__c();
            log.Action__c = 'Breach Deadline Monitor';
            log.Status__c = result.overdueBreaches.isEmpty() ? 'Success' : 'Warning';
            log.Details__c = details;
            log.User__c = UserInfo.getUserId();
            PrometheionSecurityUtils.validateCRUDAccess('Prometheion_Audit_Log__c', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log execution: ' + e.getMessage());
        }
    }

    /**
     * Log error
     */
    private void logError(String message) {
        try {
            Prometheion_Audit_Log__c log = new Prometheion_Audit_Log__c();
            log.Action__c = 'Breach Deadline Monitor';
            log.Status__c = 'Error';
            log.Details__c = message;
            log.User__c = UserInfo.getUserId();
            PrometheionSecurityUtils.validateCRUDAccess('Prometheion_Audit_Log__c', PrometheionSecurityUtils.DmlOperation.DML_INSERT);
            insert log;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to log error: ' + e.getMessage());
        }
    }

    // ========== Static Utility Methods ==========

    /**
     * Schedule daily at 8 AM
     */
    public static String scheduleDaily() {
        String cronExp = '0 0 8 * * ?';
        return System.schedule(JOB_NAME + ' - Daily', cronExp, new BreachDeadlineMonitor());
    }

    /**
     * Schedule with custom cron
     */
    public static String scheduleCustom(String cronExpression, String jobSuffix) {
        return System.schedule(JOB_NAME + ' - ' + jobSuffix, cronExpression, new BreachDeadlineMonitor());
    }

    /**
     * Abort all scheduled jobs
     */
    public static void abortAllJobs() {
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE :('%' + JOB_NAME + '%')
        ];

        for (CronTrigger job : jobs) {
            System.abortJob(job.Id);
        }
    }

    /**
     * Run immediately
     */
    @AuraEnabled
    public static void runNow() {
        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.monitorDeadlines();
    }

    /**
     * Get deadline summary
     */
    @AuraEnabled(cacheable=true)
    public static DeadlineSummary getDeadlineSummary() {
        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();

        DeadlineSummary summary = new DeadlineSummary();
        summary.overdueCount = monitor.checkOverdueBreaches().size();
        summary.criticalCount = monitor.checkCriticalDeadlines().size();
        summary.upcomingCount = monitor.checkUpcomingDeadlines().size();
        summary.hhsRequiredCount = monitor.checkHHSNotificationRequired().size();
        summary.totalActiveBreaches = summary.overdueCount + summary.criticalCount + summary.upcomingCount;

        return summary;
    }

    // ========== Inner Classes ==========

    private class MonitoringResult {
        public List<HIPAA_Breach__c> overdueBreaches = new List<HIPAA_Breach__c>();
        public List<HIPAA_Breach__c> criticalBreaches = new List<HIPAA_Breach__c>();
        public List<HIPAA_Breach__c> upcomingBreaches = new List<HIPAA_Breach__c>();
        public List<HIPAA_Breach__c> hhsRequired = new List<HIPAA_Breach__c>();
    }

    public class DeadlineSummary {
        @AuraEnabled public Integer overdueCount;
        @AuraEnabled public Integer criticalCount;
        @AuraEnabled public Integer upcomingCount;
        @AuraEnabled public Integer hhsRequiredCount;
        @AuraEnabled public Integer totalActiveBreaches;
    }
}
