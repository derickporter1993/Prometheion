/**
 * CCPASLAMonitorScheduler - Scheduled job for CCPA SLA monitoring
 *
 * Monitors CCPA requests for SLA compliance (45-day response deadline).
 * Sends alerts for requests approaching deadline and marks overdue requests.
 *
 * Schedule Example:
 * System.schedule('CCPA SLA Monitor', '0 0 8 * * ?', new CCPASLAMonitorScheduler());
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionCCPASLAMonitorScheduler implements Schedulable {

    private static final Integer WARNING_THRESHOLD_DAYS = 7;
    private static final Integer CRITICAL_THRESHOLD_DAYS = 3;

    /**
     * Execute the scheduled job
     * @param sc - SchedulableContext
     */
    public void execute(SchedulableContext sc) {
        Savepoint sp = Database.setSavepoint();
        try {
            checkApproachingDeadlines();
            markOverdueRequests();
            generateDailyReport();
            SchedulerErrorHandler.logSuccess('PrometheionCCPASLAMonitorScheduler', 'CCPA SLA Monitor completed successfully');
        } catch (Exception e) {
            Database.rollback(sp);
            SchedulerErrorHandler.logError('PrometheionCCPASLAMonitorScheduler', e);
            SchedulerErrorHandler.notifyOnFailure('PrometheionCCPASLAMonitorScheduler', e);
        }
    }

    /**
     * Check for requests approaching their deadline
     */
    private void checkApproachingDeadlines() {
        Date warningDate = Date.today().addDays(WARNING_THRESHOLD_DAYS);
        Date criticalDate = Date.today().addDays(CRITICAL_THRESHOLD_DAYS);

        // Find requests approaching deadline
        List<CCPA_Request__c> approachingRequests = [
            SELECT Id, Name, Contact__c, Contact__r.Name, Contact__r.Email,
                   Request_Type__c, Status__c, Request_Date__c, Response_Deadline__c
            FROM CCPA_Request__c
            WHERE Status__c IN ('Pending', 'In Progress')
            AND Response_Deadline__c <= :warningDate
            AND Response_Deadline__c >= TODAY
            WITH USER_MODE
            ORDER BY Response_Deadline__c ASC
        ];

        List<CCPA_Request__c> criticalRequests = new List<CCPA_Request__c>();
        List<CCPA_Request__c> warningRequests = new List<CCPA_Request__c>();

        for (CCPA_Request__c request : approachingRequests) {
            if (request.Response_Deadline__c <= criticalDate) {
                criticalRequests.add(request);
            } else {
                warningRequests.add(request);
            }
        }

        // Send critical alerts
        if (!criticalRequests.isEmpty()) {
            sendCriticalAlerts(criticalRequests);
        }

        // Send warning alerts
        if (!warningRequests.isEmpty()) {
            sendWarningAlerts(warningRequests);
        }
    }

    /**
     * Mark overdue requests
     */
    private void markOverdueRequests() {
        List<CCPA_Request__c> overdueRequests = [
            SELECT Id, Status__c, Response_Deadline__c
            FROM CCPA_Request__c
            WHERE Status__c IN ('Pending', 'In Progress')
            AND Response_Deadline__c < TODAY
            WITH USER_MODE
        ];

        if (overdueRequests.isEmpty()) {
            return;
        }

        for (CCPA_Request__c request : overdueRequests) {
            request.Status__c = 'Overdue';
        }

        List<Database.SaveResult> results = Database.update(overdueRequests, false);
        for (Database.SaveResult sr : results) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    System.debug(LoggingLevel.ERROR, '[CCPASLAMonitorScheduler] Update failed: ' + err.getMessage());
                }
            }
        }

        System.debug(LoggingLevel.WARN,
            '[CCPASLAMonitorScheduler] Marked ' + overdueRequests.size() + ' requests as overdue');

        // Send overdue notification to compliance team
        sendOverdueNotification(overdueRequests);
    }

    /**
     * Generate daily SLA compliance report
     */
    private void generateDailyReport() {
        // Count requests by status
        Integer pending = [SELECT COUNT() FROM CCPA_Request__c WHERE Status__c = 'Pending' WITH USER_MODE];
        Integer inProgress = [SELECT COUNT() FROM CCPA_Request__c WHERE Status__c = 'In Progress' WITH USER_MODE];
        Integer completed = [SELECT COUNT() FROM CCPA_Request__c WHERE Status__c = 'Completed'
                            AND Completed_Date__c = TODAY WITH USER_MODE];
        Integer overdue = [SELECT COUNT() FROM CCPA_Request__c WHERE Status__c = 'Overdue' WITH USER_MODE];

        // Calculate average response time
        List<AggregateResult> avgResults = [
            SELECT AVG(Days_To_Complete__c) avgDays
            FROM CCPA_Request__c
            WHERE Status__c = 'Completed'
            AND Completed_Date__c >= LAST_N_DAYS:30
            WITH USER_MODE
        ];

        Decimal avgResponseDays = avgResults.isEmpty() || avgResults[0].get('avgDays') == null ?
            0 : (Decimal)avgResults[0].get('avgDays');

        System.debug(LoggingLevel.INFO,
            '[CCPASLAMonitorScheduler] Daily Report - ' +
            'Pending: ' + pending + ', ' +
            'In Progress: ' + inProgress + ', ' +
            'Completed Today: ' + completed + ', ' +
            'Overdue: ' + overdue + ', ' +
            'Avg Response: ' + avgResponseDays.setScale(1) + ' days');
    }

    /**
     * Send critical alerts for requests due within 3 days
     * @param requests - List of critical requests
     */
    private void sendCriticalAlerts(List<CCPA_Request__c> requests) {
        for (CCPA_Request__c request : requests) {
            Integer daysRemaining = Date.today().daysBetween(request.Response_Deadline__c);
            System.debug(LoggingLevel.ERROR,
                '[CCPASLAMonitorScheduler] CRITICAL: Request ' + request.Name +
                ' due in ' + daysRemaining + ' days');
        }
        // In production, would send email/Slack/Teams notification
    }

    /**
     * Send warning alerts for requests due within 7 days
     * @param requests - List of warning requests
     */
    private void sendWarningAlerts(List<CCPA_Request__c> requests) {
        for (CCPA_Request__c request : requests) {
            Integer daysRemaining = Date.today().daysBetween(request.Response_Deadline__c);
            System.debug(LoggingLevel.WARN,
                '[CCPASLAMonitorScheduler] WARNING: Request ' + request.Name +
                ' due in ' + daysRemaining + ' days');
        }
    }

    /**
     * Send notification for overdue requests
     * @param requests - List of overdue requests
     */
    private void sendOverdueNotification(List<CCPA_Request__c> requests) {
        System.debug(LoggingLevel.ERROR,
            '[CCPASLAMonitorScheduler] ALERT: ' + requests.size() +
            ' CCPA requests are now OVERDUE. Immediate action required.');
    }

    /**
     * Schedule daily SLA monitoring using CRON from Custom Metadata
     * @return Job ID
     */
    public static String scheduleDaily() {
        String cronExp = SchedulerErrorHandler.getCronExpression('CCPASLAMonitor', '0 0 8 * * ?');
        return System.schedule(
            'CCPA SLA Monitor - Daily',
            cronExp,
            new PrometheionCCPASLAMonitorScheduler()
        );
    }

    /**
     * Schedule hourly monitoring for critical periods
     * @return Job ID
     */
    public static String scheduleHourly() {
        String cronExp = '0 0 * * * ?';
        return System.schedule(
            'CCPA SLA Monitor - Hourly',
            cronExp,
            new PrometheionCCPASLAMonitorScheduler()
        );
    }
}
