/**
 * BreachReportingService
 *
 * Handles breach reporting, metrics, and summary generation.
 * Extracted from HIPAABreachNotificationService for single-responsibility.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class BreachReportingService {

    private static final Integer HHS_ANNUAL_THRESHOLD = 500;

    /**
     * Get breach summary for dashboard
     */
    public BreachNotificationTypes.BreachSummary getBreachSummary() {
        BreachNotificationTypes.BreachSummary summary =
            new BreachNotificationTypes.BreachSummary();

        Date yearStart = Date.today().addYears(-1);

        List<AggregateResult> results = [
            SELECT Status__c, COUNT(Id) cnt, SUM(Records_Affected__c) total
            FROM HIPAA_Breach__c
            WHERE Discovery_Date__c >= :yearStart
            WITH SECURITY_ENFORCED
            GROUP BY Status__c
        ];

        summary.totalBreaches = 0;
        summary.openBreaches = 0;
        summary.closedBreaches = 0;
        summary.totalAffectedIndividuals = 0;

        for (AggregateResult ar : results) {
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('cnt');
            Decimal affected = (Decimal) ar.get('total');

            summary.totalBreaches += count;
            summary.totalAffectedIndividuals += affected != null ? affected.intValue() : 0;

            if (status == 'Open' || status == 'Under Investigation') {
                summary.openBreaches += count;
            } else if (status == 'Closed') {
                summary.closedBreaches += count;
            }
        }

        // Get overdue count
        summary.overdueNotifications = [
            SELECT COUNT()
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c < TODAY
            AND Individuals_Notified__c = false
            WITH SECURITY_ENFORCED
        ];

        // Determine HHS annual report requirement
        summary.hhsAnnualReportRequired = summary.totalAffectedIndividuals >= HHS_ANNUAL_THRESHOLD;

        return summary;
    }

    /**
     * Get all open breaches requiring action
     */
    public List<BreachNotificationTypes.BreachSummary> getOpenBreaches() {
        List<BreachNotificationTypes.BreachSummary> summaries = new List<BreachNotificationTypes.BreachSummary>();

        List<HIPAA_Breach__c> breaches = [
            SELECT Id, Name, Breach_Type__c, Risk_Level__c, Records_Affected__c,
                   Discovery_Date__c, Notification_Deadline__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Status__c != 'Closed'
            WITH SECURITY_ENFORCED
            ORDER BY Notification_Deadline__c ASC NULLS LAST
        ];

        for (HIPAA_Breach__c breach : breaches) {
            BreachNotificationTypes.BreachSummary summary = new BreachNotificationTypes.BreachSummary();
            summary.breachId = breach.Id;
            summary.incidentType = breach.Breach_Type__c;
            summary.severity = breach.Risk_Level__c;
            summary.recordsAffected = breach.Records_Affected__c != null ? breach.Records_Affected__c.intValue() : 0;
            summary.discoveryDate = breach.Discovery_Date__c != null
                ? DateTime.newInstance(breach.Discovery_Date__c, Time.newInstance(0, 0, 0, 0))
                : null;
            summary.notificationDeadline = breach.Notification_Deadline__c != null
                ? DateTime.newInstance(breach.Notification_Deadline__c, Time.newInstance(0, 0, 0, 0))
                : null;
            summary.status = breach.Status__c;
            summary.framework = 'HIPAA';
            summary.riskScore = 0.0;
            summaries.add(summary);
        }

        return summaries;
    }

    /**
     * Get breach metrics for reporting
     */
    public BreachNotificationTypes.BreachMetrics getBreachMetrics(Integer days) {
        BreachNotificationTypes.BreachMetrics metrics =
            new BreachNotificationTypes.BreachMetrics();

        Date startDate = Date.today().addDays(-days);

        List<HIPAA_Breach__c> breaches = [
            SELECT Id, Discovery_Date__c, Individual_Notification_Date__c,
                   Records_Affected__c, Risk_Level__c, Breach_Type__c
            FROM HIPAA_Breach__c
            WHERE Discovery_Date__c >= :startDate
            WITH SECURITY_ENFORCED
        ];

        metrics.totalBreaches = breaches.size();
        metrics.breachesByType = new Map<String, Integer>();
        metrics.breachesBySeverity = new Map<String, Integer>();
        metrics.averageResolutionDays = 0;

        Decimal totalNotificationDays = 0;
        Integer notifiedCount = 0;

        for (HIPAA_Breach__c breach : breaches) {
            // Count by type
            String breachType = breach.Breach_Type__c != null ? breach.Breach_Type__c : 'Unknown';
            if (!metrics.breachesByType.containsKey(breachType)) {
                metrics.breachesByType.put(breachType, 0);
            }
            metrics.breachesByType.put(breachType, metrics.breachesByType.get(breachType) + 1);

            // Count by severity
            String severity = breach.Risk_Level__c != null ? breach.Risk_Level__c : 'Unknown';
            if (!metrics.breachesBySeverity.containsKey(severity)) {
                metrics.breachesBySeverity.put(severity, 0);
            }
            metrics.breachesBySeverity.put(severity, metrics.breachesBySeverity.get(severity) + 1);

            // Calculate notification time
            if (breach.Individual_Notification_Date__c != null && breach.Discovery_Date__c != null) {
                totalNotificationDays += breach.Discovery_Date__c.daysBetween(
                    breach.Individual_Notification_Date__c
                );
                notifiedCount++;
            }
        }

        if (notifiedCount > 0) {
            metrics.averageResolutionDays = (totalNotificationDays / notifiedCount).setScale(1);
        }

        return metrics;
    }

    /**
     * Generate breach report for regulators
     */
    public Id generateBreachReport(Id breachId) {
        // This would typically generate a PDF report
        // For now, return the breach ID as a placeholder
        return breachId;
    }

    /**
     * Get overdue notifications
     */
    public List<HIPAA_Breach__c> getOverdueNotifications() {
        return [
            SELECT Id, Name, Discovery_Date__c, Notification_Deadline__c
            FROM HIPAA_Breach__c
            WHERE Notification_Deadline__c < TODAY
            AND Individuals_Notified__c = false
            AND Notification_Required__c = true
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * Get pending assessment count
     */
    public Integer getPendingAssessmentCount() {
        return [
            SELECT COUNT()
            FROM HIPAA_Breach__c
            WHERE Status__c = 'Pending Assessment'
            WITH SECURITY_ENFORCED
        ];
    }
}
