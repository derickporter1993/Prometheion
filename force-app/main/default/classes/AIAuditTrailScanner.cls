/**
 * Scans SetupAuditTrail for AI-related configuration changes to detect when
 * AI systems are deployed, modified, or decommissioned. Provides change tracking
 * and compliance audit trail for AI governance.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 * @see AIDetectionEngine
 * @see AIGovernanceService
 */
public inherited sharing class AIAuditTrailScanner {

    private static final List<String> AI_ACTIONS = new List<String>{
        'MLPredictionDefinition',
        'Bot',
        'GenAiFunction',
        'GenAiPlanner',
        'Einstein',
        'ML'
    };

    private static final Integer DEFAULT_LOOKBACK_DAYS = 180;

    /**
     * Scans SetupAuditTrail for AI-related changes within a specified time period.
     *
     * @param lookbackDays Number of days to scan backwards (default 180)
     * @return List of AI-related audit trail entries
     * @throws AuraHandledException if query fails or user lacks permission
     * @example
     * List<AIAuditTrailScanner.AIAuditEntry> changes = AIAuditTrailScanner.scanAIChanges(90);
     */
    public static List<AIAuditEntry> scanAIChanges(Integer lookbackDays) {
        Integer days = lookbackDays ?? DEFAULT_LOOKBACK_DAYS;
        List<AIAuditEntry> auditEntries = new List<AIAuditEntry>();

        try {
            Datetime cutoffDate = Datetime.now().addDays(-days);

            // Query SetupAuditTrail for AI-related actions
            List<SetupAuditTrail> trails = [
                SELECT Id, Action, Section, CreatedDate, CreatedBy.Name, Display
                FROM SetupAuditTrail
                WHERE CreatedDate >= :cutoffDate
                WITH USER_MODE
                ORDER BY CreatedDate DESC
                LIMIT 2000
            ];

            for (SetupAuditTrail trail : trails) {
                if (isAIRelatedAction(trail)) {
                    AIAuditEntry entry = new AIAuditEntry();
                    entry.actionType = trail.Action;
                    entry.section = trail.Section;
                    entry.changeDate = trail.CreatedDate;
                    entry.changedBy = trail.CreatedBy.Name;
                    entry.display = trail.Display;
                    entry.severity = determineSeverity(trail.Action);
                    auditEntries.add(entry);
                }
            }
        } catch (Exception e) {
            ElaroLogger.error('AIAuditTrailScanner.scanAIChanges', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to scan the AI audit trail. Please verify you have the required permissions and try again.');
        }

        return auditEntries;
    }

    /**
     * Determines if a SetupAuditTrail entry is related to AI systems.
     *
     * @param trail The SetupAuditTrail record to evaluate
     * @return True if the action is AI-related
     */
    private static Boolean isAIRelatedAction(SetupAuditTrail trail) {
        String action = trail.Action ?? '';
        String section = trail.Section ?? '';
        String display = trail.Display ?? '';

        // Check if action, section, or display contains AI keywords
        for (String keyword : AI_ACTIONS) {
            if (action.containsIgnoreCase(keyword) ||
                section.containsIgnoreCase(keyword) ||
                display.containsIgnoreCase(keyword)) {
                return true;
            }
        }

        return false;
    }

    /**
     * Determines the severity level of an AI-related change.
     *
     * @param action The action type from SetupAuditTrail
     * @return Severity level: HIGH_RISK, MEDIUM_RISK, or LOW_RISK
     */
    private static String determineSeverity(String action) {
        String actionLower = action.toLowerCase();

        // High risk actions: deletion, deactivation, permission changes
        if (actionLower.contains('delete') || actionLower.contains('deactivate') ||
            actionLower.contains('permission')) {
            return 'HIGH_RISK';
        }

        // Medium risk actions: creation, modification
        if (actionLower.contains('create') || actionLower.contains('modify') ||
            actionLower.contains('update')) {
            return 'MEDIUM_RISK';
        }

        // Low risk: viewing, exporting
        return 'LOW_RISK';
    }

    /**
     * Gets the most recent AI-related change for a specific system type.
     *
     * @param systemType The AI system type to search for
     * @return Most recent AIAuditEntry or null if none found
     */
    public static AIAuditEntry getLatestChange(String systemType) {
        List<AIAuditEntry> allChanges = scanAIChanges(DEFAULT_LOOKBACK_DAYS);

        for (AIAuditEntry entry : allChanges) {
            if (entry.actionType.containsIgnoreCase(systemType) ||
                entry.display.containsIgnoreCase(systemType)) {
                return entry;
            }
        }

        return null;
    }

    /**
     * Wrapper class representing an AI-related audit trail entry.
     */
    public class AIAuditEntry {
        @AuraEnabled public String actionType { get; set; }
        @AuraEnabled public String section { get; set; }
        @AuraEnabled public Datetime changeDate { get; set; }
        @AuraEnabled public String changedBy { get; set; }
        @AuraEnabled public String display { get; set; }
        @AuraEnabled public String severity { get; set; }
    }
}
