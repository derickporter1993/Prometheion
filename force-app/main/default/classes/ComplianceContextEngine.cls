/**
 * Aggregates compliance context for the Command Center dashboard by querying
 * scores, gaps, evidence, and metadata-driven actions to produce a unified
 * compliance posture view.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Command Center
 * @see CommandCenterController
 * @see Compliance_Action__mdt
 */
public inherited sharing class ComplianceContextEngine {

    /**
     * DTO representing the aggregated compliance context for the Command Center.
     */
    public class ComplianceContext {
        @AuraEnabled public List<FrameworkSummary> frameworkSummaries;
        @AuraEnabled public List<ComplianceActionItem> prioritizedActions;
        @AuraEnabled public List<GapSummary> recentGaps;
        @AuraEnabled public ComplianceOverview overview;
        @AuraEnabled public Datetime contextTimestamp;

        public ComplianceContext() {
            this.frameworkSummaries = new List<FrameworkSummary>();
            this.prioritizedActions = new List<ComplianceActionItem>();
            this.recentGaps = new List<GapSummary>();
            this.overview = new ComplianceOverview();
            this.contextTimestamp = Datetime.now();
        }
    }

    /**
     * High-level compliance overview with aggregate metrics.
     */
    public class ComplianceOverview {
        @AuraEnabled public Integer overallScore;
        @AuraEnabled public Integer totalGaps;
        @AuraEnabled public Integer criticalGaps;
        @AuraEnabled public Integer highGaps;
        @AuraEnabled public Integer openGaps;
        @AuraEnabled public Integer remediatedGaps;
        @AuraEnabled public String riskRating;

        public ComplianceOverview() {
            this.overallScore = 0;
            this.totalGaps = 0;
            this.criticalGaps = 0;
            this.highGaps = 0;
            this.openGaps = 0;
            this.remediatedGaps = 0;
            this.riskRating = ElaroConstants.RATING_NEEDS_IMPROVEMENT;
        }
    }

    /**
     * Per-framework compliance summary.
     */
    public class FrameworkSummary {
        @AuraEnabled public String framework;
        @AuraEnabled public Integer score;
        @AuraEnabled public Integer gapCount;
        @AuraEnabled public Integer evidenceCount;
        @AuraEnabled public String status;

        public FrameworkSummary() {
            this.score = 0;
            this.gapCount = 0;
            this.evidenceCount = 0;
            this.status = 'Unknown';
        }
    }

    /**
     * Actionable compliance item derived from Compliance_Action__mdt
     * and enriched with current org context.
     */
    public class ComplianceActionItem {
        @AuraEnabled public String title;
        @AuraEnabled public String description;
        @AuraEnabled public String framework;
        @AuraEnabled public String severity;
        @AuraEnabled public String category;
        @AuraEnabled public String setupPath;
        @AuraEnabled public Integer priorityOrder;
        @AuraEnabled public String controlReference;
        @AuraEnabled public String remediationSteps;
        @AuraEnabled public Boolean isRelevant;

        public ComplianceActionItem() {
            this.isRelevant = true;
        }
    }

    /**
     * Summary of a compliance gap for display.
     */
    public class GapSummary {
        @AuraEnabled public Id gapId;
        @AuraEnabled public String gapName;
        @AuraEnabled public String framework;
        @AuraEnabled public String severity;
        @AuraEnabled public String status;
        @AuraEnabled public String description;
        @AuraEnabled public Datetime detectedDate;
        @AuraEnabled public String ownerName;
    }

    /**
     * Builds the full compliance context for the Command Center.
     *
     * @return ComplianceContext containing all aggregated compliance data
     */
    public ComplianceContext buildContext() {
        ComplianceContext ctx = new ComplianceContext();
        ctx.frameworkSummaries = buildFrameworkSummaries();
        ctx.overview = buildOverview(ctx.frameworkSummaries);
        ctx.prioritizedActions = loadPrioritizedActions();
        ctx.recentGaps = loadRecentGaps();
        return ctx;
    }

    /**
     * Builds per-framework compliance summaries from Compliance_Score__c
     * and Compliance_Gap__c data.
     *
     * @return List of FrameworkSummary objects
     */
    @TestVisible
    private List<FrameworkSummary> buildFrameworkSummaries() {
        List<FrameworkSummary> summaries = new List<FrameworkSummary>();

        // Get the latest scores per framework from Framework_Scores__c JSON
        List<Compliance_Score__c> scores = [
            SELECT Id, Risk_Score__c, Framework_Scores__c, Calculated_At__c
            FROM Compliance_Score__c
            WITH USER_MODE
            ORDER BY Calculated_At__c DESC
            LIMIT 1
        ];

        Map<String, Integer> frameworkScoreMap = new Map<String, Integer>();
        if (!scores.isEmpty() && scores[0].Framework_Scores__c != null) {
            try {
                Map<String, Object> parsed = (Map<String, Object>) JSON.deserializeUntyped(
                    scores[0].Framework_Scores__c
                );
                for (String fw : parsed.keySet()) {
                    Object val = parsed.get(fw);
                    if (val instanceof Integer) {
                        frameworkScoreMap.put(fw, (Integer) val);
                    } else if (val instanceof Decimal) {
                        frameworkScoreMap.put(fw, ((Decimal) val).intValue());
                    }
                }
            } catch (Exception e) {
                ElaroLogger.warn('ComplianceContextEngine.buildFrameworkSummaries',
                    'Failed to parse Framework_Scores__c: ' + e.getMessage());
            }
        }

        // Count gaps per framework
        List<AggregateResult> gapCounts = [
            SELECT Framework__c, COUNT(Id) cnt
            FROM Compliance_Gap__c
            WHERE Status__c IN ('OPEN', 'IN_PROGRESS')
            WITH USER_MODE
            GROUP BY Framework__c
        ];
        Map<String, Integer> gapCountMap = new Map<String, Integer>();
        for (AggregateResult ar : gapCounts) {
            gapCountMap.put((String) ar.get('Framework__c'), (Integer) ar.get('cnt'));
        }

        // Build summaries for known frameworks
        Set<String> frameworks = new Set<String>();
        frameworks.addAll(frameworkScoreMap.keySet());
        frameworks.addAll(gapCountMap.keySet());

        for (String fw : frameworks) {
            FrameworkSummary fs = new FrameworkSummary();
            fs.framework = fw;
            fs.score = frameworkScoreMap.get(fw) ?? 0;
            fs.gapCount = gapCountMap.get(fw) ?? 0;
            fs.status = ElaroConstants.getRatingFromScore(fs.score);
            summaries.add(fs);
        }

        return summaries;
    }

    /**
     * Builds the high-level compliance overview from framework summaries
     * and gap aggregate queries.
     *
     * @param summaries List of framework summaries
     * @return ComplianceOverview with aggregate metrics
     */
    @TestVisible
    private ComplianceOverview buildOverview(List<FrameworkSummary> summaries) {
        ComplianceOverview ov = new ComplianceOverview();

        // Calculate average score across frameworks
        if (!summaries.isEmpty()) {
            Integer totalScore = 0;
            for (FrameworkSummary fs : summaries) {
                totalScore += fs.score;
            }
            ov.overallScore = totalScore / summaries.size();
        }
        ov.riskRating = ElaroConstants.getRatingFromScore(ov.overallScore);

        // Gap severity breakdown
        List<AggregateResult> severityCounts = [
            SELECT Severity__c, Status__c, COUNT(Id) cnt
            FROM Compliance_Gap__c
            WITH USER_MODE
            GROUP BY Severity__c, Status__c
        ];

        for (AggregateResult ar : severityCounts) {
            String severity = (String) ar.get('Severity__c');
            String status = (String) ar.get('Status__c');
            Integer cnt = (Integer) ar.get('cnt');
            ov.totalGaps += cnt;

            if (severity == ElaroConstants.SEVERITY_CRITICAL) {
                ov.criticalGaps += cnt;
            }
            if (severity == ElaroConstants.SEVERITY_HIGH) {
                ov.highGaps += cnt;
            }
            if (status == 'OPEN' || status == 'IN_PROGRESS') {
                ov.openGaps += cnt;
            }
            if (status == 'REMEDIATED' || status == 'VERIFIED') {
                ov.remediatedGaps += cnt;
            }
        }

        return ov;
    }

    /**
     * Loads prioritized compliance actions from Compliance_Action__mdt,
     * sorted by priority order.
     *
     * @return List of ComplianceActionItem sorted by priority
     */
    @TestVisible
    private List<ComplianceActionItem> loadPrioritizedActions() {
        List<ComplianceActionItem> actions = new List<ComplianceActionItem>();

        for (Compliance_Action__mdt action : [
            SELECT DeveloperName, Action_Title__c, Action_Description__c, Framework__c,
                   Severity__c, Category__c, Setup_Path__c, Priority_Order__c,
                   Control_Reference__c, Remediation_Steps__c, Is_Active__c
            FROM Compliance_Action__mdt
            WHERE Is_Active__c = TRUE
            WITH USER_MODE
            ORDER BY Priority_Order__c ASC
        ]) {
            ComplianceActionItem item = new ComplianceActionItem();
            item.title = action.Action_Title__c;
            item.description = action.Action_Description__c;
            item.framework = action.Framework__c;
            item.severity = action.Severity__c;
            item.category = action.Category__c;
            item.setupPath = action.Setup_Path__c;
            item.priorityOrder = action.Priority_Order__c != null
                ? action.Priority_Order__c.intValue() : 99;
            item.controlReference = action.Control_Reference__c;
            item.remediationSteps = action.Remediation_Steps__c;
            actions.add(item);
        }

        return actions;
    }

    /**
     * Loads the most recent compliance gaps for display in the Command Center.
     *
     * @return List of GapSummary for the 20 most recent gaps
     */
    @TestVisible
    private List<GapSummary> loadRecentGaps() {
        List<GapSummary> gaps = new List<GapSummary>();

        for (Compliance_Gap__c gap : [
            SELECT Id, Name, Framework__c, Severity__c, Status__c,
                   Gap_Description__c, Detected_Date__c,
                   Remediation_Owner__r.Name
            FROM Compliance_Gap__c
            WHERE Status__c IN ('OPEN', 'IN_PROGRESS')
            WITH USER_MODE
            ORDER BY Detected_Date__c DESC
            LIMIT 20
        ]) {
            GapSummary gs = new GapSummary();
            gs.gapId = gap.Id;
            gs.gapName = gap.Name;
            gs.framework = gap.Framework__c;
            gs.severity = gap.Severity__c;
            gs.status = gap.Status__c;
            gs.description = gap.Gap_Description__c;
            gs.detectedDate = gap.Detected_Date__c;
            gs.ownerName = gap.Remediation_Owner__r?.Name;
            gaps.add(gs);
        }

        return gaps;
    }

    /**
     * Loads actions filtered by a specific framework.
     *
     * @param framework The framework code to filter by
     * @return List of ComplianceActionItem for the specified framework
     */
    public List<ComplianceActionItem> getActionsByFramework(String framework) {
        List<ComplianceActionItem> allActions = loadPrioritizedActions();
        List<ComplianceActionItem> filtered = new List<ComplianceActionItem>();
        for (ComplianceActionItem item : allActions) {
            if (item.framework == framework) {
                filtered.add(item);
            }
        }
        return filtered;
    }
}
