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
    BreachNotificationTypes.BreachAssessment assessBreach(BreachNotificationTypes.BreachAssessmentRequest request);

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
    BreachNotificationTypes.NotificationStatus getNotificationStatus(Id breachId);

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
    List<BreachNotificationTypes.BreachSummary> getOpenBreaches();

    /**
     * Get breach metrics for reporting
     * @param daysBack Number of days to analyze
     * @return Breach metrics summary
     */
    BreachNotificationTypes.BreachMetrics getBreachMetrics(Integer daysBack);
}
