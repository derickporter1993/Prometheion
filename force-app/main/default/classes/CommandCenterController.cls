/**
 * Lightning controller for the Compliance Command Center. Provides
 * @AuraEnabled endpoints for the complianceCommandCenter LWC and its
 * child components.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Command Center
 * @see ComplianceContextEngine
 */
public with sharing class CommandCenterController {

    /**
     * Loads the full compliance context for the Command Center dashboard.
     * Returns framework summaries, prioritized actions, recent gaps,
     * and an overall compliance overview.
     *
     * @return ComplianceContextEngine.ComplianceContext with all dashboard data
     * @throws AuraHandledException if context assembly fails
     */
    @AuraEnabled(cacheable=true)
    public static ComplianceContextEngine.ComplianceContext getComplianceContext() {
        try {
            ElaroLogger.info('CommandCenterController.getComplianceContext', 'Loading compliance context');
            ComplianceContextEngine engine = new ComplianceContextEngine();
            ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
            ElaroLogger.info('CommandCenterController.getComplianceContext',
                'Context loaded: ' + ctx.frameworkSummaries.size() + ' frameworks, '
                + ctx.prioritizedActions.size() + ' actions');
            return ctx;
        } catch (Exception e) {
            ElaroLogger.error('CommandCenterController.getComplianceContext',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load compliance context. Please verify your permissions and try again.');
        }
    }

    /**
     * Returns compliance actions filtered by framework.
     *
     * @param framework The framework code (e.g., 'SOC2', 'HIPAA')
     * @return List of ComplianceActionItem for the specified framework
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<ComplianceContextEngine.ComplianceActionItem> getActionsByFramework(
        String framework
    ) {
        try {
            ComplianceContextEngine engine = new ComplianceContextEngine();
            return engine.getActionsByFramework(framework);
        } catch (Exception e) {
            ElaroLogger.error('CommandCenterController.getActionsByFramework',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load actions for ' + framework + '. Please try again.');
        }
    }

    /**
     * Updates the status of a compliance gap.
     *
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     * @param newStatus The new status value (OPEN, IN_PROGRESS, REMEDIATED, VERIFIED, ACCEPTED_RISK)
     * @throws AuraHandledException if update fails
     */
    @AuraEnabled
    public static void updateGapStatus(Id gapId, String newStatus) {
        try {
            ElaroLogger.info('CommandCenterController.updateGapStatus',
                'Updating gap ' + gapId + ' to ' + newStatus);

            Compliance_Gap__c gap = new Compliance_Gap__c(
                Id = gapId,
                Status__c = newStatus
            );

            if (newStatus == 'REMEDIATED' || newStatus == 'VERIFIED') {
                gap.Actual_Remediation_Date__c = Date.today();
            }

            update as user gap;
        } catch (Exception e) {
            ElaroLogger.error('CommandCenterController.updateGapStatus',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to update gap status. Please verify you have edit permissions.');
        }
    }

    /**
     * Returns the count of open gaps grouped by severity for the
     * notification feed badge counts.
     *
     * @return Map of severity to count
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Integer> getGapCountsBySeverity() {
        try {
            Map<String, Integer> counts = new Map<String, Integer>();
            for (AggregateResult ar : [
                SELECT Severity__c, COUNT(Id) cnt
                FROM Compliance_Gap__c
                WHERE Status__c IN ('OPEN', 'IN_PROGRESS')
                WITH USER_MODE
                GROUP BY Severity__c
            ]) {
                counts.put((String) ar.get('Severity__c'), (Integer) ar.get('cnt'));
            }
            return counts;
        } catch (Exception e) {
            ElaroLogger.error('CommandCenterController.getGapCountsBySeverity',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to load gap counts.');
        }
    }

    /**
     * Returns recent compliance-related activity for the notification feed.
     * Combines gap status changes and score updates into a timeline.
     *
     * @param recordLimit Maximum number of activity items to return
     * @return List of ActivityItem ordered by most recent first
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<ActivityItem> getRecentActivity(Integer recordLimit) {
        try {
            Integer safeLimit = Math.min(recordLimit ?? 10, 50);
            List<ActivityItem> items = new List<ActivityItem>();

            // Recent gap changes
            for (Compliance_Gap__c gap : [
                SELECT Id, Name, Framework__c, Severity__c, Status__c,
                       Detected_Date__c, LastModifiedDate, LastModifiedBy.Name
                FROM Compliance_Gap__c
                WITH USER_MODE
                ORDER BY LastModifiedDate DESC
                LIMIT :safeLimit
            ]) {
                ActivityItem item = new ActivityItem();
                item.activityId = gap.Id;
                item.activityType = 'GAP_UPDATE';
                item.title = gap.Name + ' — ' + gap.Framework__c;
                item.detail = gap.Severity__c + ' gap is ' + gap.Status__c;
                item.timestamp = gap.LastModifiedDate;
                item.modifiedBy = gap.LastModifiedBy?.Name ?? 'System';
                item.severity = gap.Severity__c;
                items.add(item);
            }

            // Sort by timestamp descending (already sorted from query, but ensure after merge)
            items.sort();
            if (items.size() > safeLimit) {
                List<ActivityItem> trimmed = new List<ActivityItem>();
                for (Integer i = 0; i < safeLimit; i++) {
                    trimmed.add(items[i]);
                }
                return trimmed;
            }
            return items;
        } catch (Exception e) {
            ElaroLogger.error('CommandCenterController.getRecentActivity',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to load recent activity.');
        }
    }

    /**
     * Activity feed item for the notification feed component.
     */
    public class ActivityItem implements Comparable {
        @AuraEnabled public Id activityId;
        @AuraEnabled public String activityType;
        @AuraEnabled public String title;
        @AuraEnabled public String detail;
        @AuraEnabled public Datetime timestamp;
        @AuraEnabled public String modifiedBy;
        @AuraEnabled public String severity;

        /**
         * Sorts by timestamp descending (most recent first).
         *
         * @param compareTo The other ActivityItem
         * @return Negative if this is more recent, positive if older
         */
        public Integer compareTo(Object compareTo) {
            ActivityItem other = (ActivityItem) compareTo;
            Datetime thisTime = this.timestamp ?? Datetime.newInstance(2000, 1, 1);
            Datetime otherTime = other.timestamp ?? Datetime.newInstance(2000, 1, 1);
            // Descending: more recent first
            if (otherTime > thisTime) return 1;
            if (otherTime < thisTime) return -1;
            return 0;
        }
    }
}
