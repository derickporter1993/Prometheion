/**
 * ElaroComplianceCopilot - Natural Language Compliance Query Interface
 *
 * ChatGPT-style interface for compliance queries:
 * User: "Why did my compliance score drop 15 points?"
 * Elaro: "On Dec 2, Profile 'Sales_Manager' was given Edit access to
 *            PHI field Patient_SSN__c, violating HIPAA Minimum Necessary rule.
 *            [View Evidence] [Auto-Fix]"
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroComplianceCopilot {

    /**
     * Response structure for copilot queries
     */
    public class CopilotResponse {
        @AuraEnabled public String answer;
        @AuraEnabled public List<Evidence> evidence;
        @AuraEnabled public List<SuggestedAction> actions;
        @AuraEnabled public String queryType;
        @AuraEnabled public Decimal confidence;

        public CopilotResponse() {
            this.evidence = new List<Evidence>();
            this.actions = new List<SuggestedAction>();
            this.confidence = 1.0;
        }
    }

    public class Evidence {
        @AuraEnabled public String nodeId;
        @AuraEnabled public String description;
        @AuraEnabled public Datetime timestamp;
        @AuraEnabled public String framework;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public String entityType;
        @AuraEnabled public String url;
    }

    public class SuggestedAction {
        @AuraEnabled public String actionType;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public Boolean canAutoFix;
        @AuraEnabled public String nodeId;
    }

    /**
     * Main entry point - process natural language query
     */
    @AuraEnabled
    public static CopilotResponse askCopilot(String query) {
        CopilotResponse response = new CopilotResponse();

        try {
            // Validate input - handle null/blank queries gracefully
            if (String.isBlank(query)) {
                response.answer = Label.Copilot_General_Help;
                response.queryType = ElaroConstants.QUERY_GENERAL;
                return response;
            }

            // Validate input length (prevent abuse)
            if (query.length() > 5000) {
                throw new AuraHandledException('Query exceeds maximum length of 5000 characters');
            }

            // Rate limiting check using Platform Cache
            String cacheKey = 'copilot_query_' + UserInfo.getUserId();
            try {
                Cache.OrgPartition orgCache = Cache.Org.getPartition('local.ElaroCompliance');
                Integer queryCount = (Integer) orgCache.get(cacheKey);

                if (queryCount != null && queryCount > 10) {
                    throw new AuraHandledException('Rate limit exceeded. Please wait before submitting another query.');
                }

                // Increment counter with 5-minute TTL
                orgCache.put(cacheKey, (queryCount == null ? 1 : queryCount + 1), 300);
            } catch (Cache.Org.OrgCacheException e) {
                // Cache not configured, continue without rate limiting
                System.debug(LoggingLevel.WARN, 'ElaroComplianceCopilot: Cache not available for rate limiting');
            }

            // Classify the query type
            QueryClassification classification = classifyQuery(query);
            response.queryType = classification.queryType;

            // Route to appropriate handler
            switch on classification.queryType {
                when 'SCORE_CHANGE' {
                    response = handleScoreChangeQuery(query, classification);
                }
                when 'VIOLATION_SEARCH' {
                    response = handleViolationSearch(query, classification);
                }
                when 'EVIDENCE_REQUEST' {
                    response = handleEvidenceRequest(query, classification);
                }
                when 'RISKY_FLOWS' {
                    response = handleRiskyFlowsQuery(query, classification);
                }
                when 'USER_ACCESS' {
                    response = handleUserAccessQuery(query, classification);
                }
                when 'FRAMEWORK_STATUS' {
                    response = handleFrameworkStatus(query, classification);
                }
                when else {
                    response = handleGeneralQuery(query, classification);
                }
            }

        } catch (Exception e) {
            String errorMsg = String.isNotBlank(e.getMessage()) ? e.getMessage() : 'Unknown error';
            response.answer = Label.Copilot_Error_General.replace('{0}', errorMsg);
            response.confidence = 0.0;
            // Structured logging without stack traces in production
            String correlationId = 'COPILOT-' + System.now().getTime();
            String errorMessage = ElaroConstants.LOG_PREFIX + 'askCopilot error: ' + e.getTypeName() + ' - ' + e.getMessage() + ' [CorrelationId: ' + correlationId + ']';

            // Only include stack trace in test mode
            if (Test.isRunningTest()) {
                System.debug(LoggingLevel.ERROR, errorMessage + '\n' + e.getStackTraceString());
            } else {
                System.debug(LoggingLevel.ERROR, errorMessage);
            }
        }

        return response;
    }

    /**
     * Query classification result
     */
    private class QueryClassification {
        public String queryType;
        public String framework;
        public String timeframe;
        public List<String> entities;
        public List<String> keywords;
    }

    /**
     * Classify the incoming query to determine intent
     */
    private static QueryClassification classifyQuery(String query) {
        QueryClassification result = new QueryClassification();
        String lowerQuery = query.toLowerCase();

        // Detect query type based on keywords
        if (lowerQuery.contains('score') && (lowerQuery.contains('drop') || lowerQuery.contains('change') || lowerQuery.contains('went down'))) {
            result.queryType = ElaroConstants.QUERY_SCORE_CHANGE;
        } else if (lowerQuery.contains('violation') || lowerQuery.contains('non-compliant') || lowerQuery.contains('failed')) {
            result.queryType = ElaroConstants.QUERY_VIOLATION_SEARCH;
        } else if (lowerQuery.contains('evidence') || lowerQuery.contains('audit') || lowerQuery.contains('report')) {
            result.queryType = ElaroConstants.QUERY_EVIDENCE_REQUEST;
        } else if (lowerQuery.contains('flow') && (lowerQuery.contains('risky') || lowerQuery.contains('pii') || lowerQuery.contains('phi'))) {
            result.queryType = ElaroConstants.QUERY_RISKY_FLOWS;
        } else if (lowerQuery.contains('access') || lowerQuery.contains('permission') || lowerQuery.contains('who can')) {
            result.queryType = ElaroConstants.QUERY_USER_ACCESS;
        } else if (lowerQuery.contains('hipaa') || lowerQuery.contains('soc2') || lowerQuery.contains('soc 2') ||
                   lowerQuery.contains('nist') || lowerQuery.contains('fedramp') || lowerQuery.contains('gdpr')) {
            result.queryType = ElaroConstants.QUERY_FRAMEWORK_STATUS;
        } else {
            result.queryType = ElaroConstants.QUERY_GENERAL;
        }

        // Detect framework
        if (lowerQuery.contains('hipaa')) result.framework = ElaroConstants.FRAMEWORK_HIPAA;
        else if (lowerQuery.contains('soc2') || lowerQuery.contains('soc 2')) result.framework = ElaroConstants.FRAMEWORK_SOC2;
        else if (lowerQuery.contains('nist')) result.framework = ElaroConstants.FRAMEWORK_NIST;
        else if (lowerQuery.contains('fedramp')) result.framework = ElaroConstants.FRAMEWORK_FEDRAMP;
        else if (lowerQuery.contains('gdpr')) result.framework = ElaroConstants.FRAMEWORK_GDPR;

        // Detect timeframe
        if (lowerQuery.contains('today')) result.timeframe = 'TODAY';
        else if (lowerQuery.contains('yesterday')) result.timeframe = 'YESTERDAY';
        else if (lowerQuery.contains('this week')) result.timeframe = 'THIS_WEEK';
        else if (lowerQuery.contains('this month')) result.timeframe = 'THIS_MONTH';
        else if (lowerQuery.contains('q1') || lowerQuery.contains('q2') || lowerQuery.contains('q3') || lowerQuery.contains('q4')) {
            result.timeframe = 'QUARTER';
        }

        return result;
    }

    /**
     * Handle "Why did my score drop?" queries
     * Uses SetupAuditTrail for compliance data since Big Object may not be deployed
     */
    private static CopilotResponse handleScoreChangeQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        // Get recent setup changes from SetupAuditTrail
        List<SetupAuditTrail> recentChanges = [
            SELECT CreatedDate, CreatedById, CreatedBy.Name, Action, Section, Display
            FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:7
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 10
        ];

        if (recentChanges.isEmpty()) {
            response.answer = Label.Copilot_No_Recent_Changes;
            return response;
        }

        // Build natural language response
        List<String> impacts = new List<String>();
        Integer changeNumber = 1;

        for (SetupAuditTrail change : recentChanges) {
            Evidence ev = new Evidence();
            ev.nodeId = String.valueOf(change.Id);
            ev.timestamp = change.CreatedDate;
            ev.description = change.Display;
            ev.entityType = change.Section;
            ev.riskScore = calculateRiskFromAction(change.Action);
            response.evidence.add(ev);

            impacts.add(changeNumber + '. ' + change.Display + ' (' + change.CreatedBy.Name + ')');
            changeNumber++;
        }

        response.answer = Label.Copilot_Score_Drop_Reason.replace('{0}', String.valueOf(recentChanges.size())) + '\n\n' +
            String.join(impacts, '\n');

        return response;
    }

    /**
     * Calculate risk score from setup action
     */
    private static Decimal calculateRiskFromAction(String action) {
        if (String.isBlank(action)) return 3.0;
        String lowerAction = action.toLowerCase();

        if (lowerAction.contains('delete') || lowerAction.contains('removed')) return 8.0;
        if (lowerAction.contains('permission') || lowerAction.contains('profile')) return 7.0;
        if (lowerAction.contains('field') || lowerAction.contains('object')) return 6.0;
        if (lowerAction.contains('user') || lowerAction.contains('role')) return 5.0;
        return 4.0;
    }

    /**
     * Handle risky flows queries
     */
    private static CopilotResponse handleRiskyFlowsQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        // Query Flow metadata
        List<FlowDefinitionView> flows = [
            SELECT DurableId, ApiName, Label, ProcessType, IsActive, Description
            FROM FlowDefinitionView
            WHERE IsActive = true
            LIMIT 20
        ];

        if (flows.isEmpty()) {
            response.answer = Label.Copilot_No_Risky_Flows;
            return response;
        }

        List<String> flowDescriptions = new List<String>();

        for (FlowDefinitionView flow : flows) {
            Evidence ev = new Evidence();
            ev.nodeId = flow.DurableId;
            ev.description = flow.Description;
            ev.entityType = ElaroConstants.ENTITY_FLOW;
            ev.riskScore = 5.0; // Default risk score
            response.evidence.add(ev);

            flowDescriptions.add('• *' + flow.Label + '* (' + flow.ProcessType + ')');
        }

        response.answer = 'Found ' + flows.size() + ' active Flows:\n\n' +
            String.join(flowDescriptions, '\n') + '\n\n_Enable Elaro Big Object for detailed risk analysis._';

        return response;
    }

    /**
     * Handle evidence request queries
     */
    private static CopilotResponse handleEvidenceRequest(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        String framework = classification.framework != null ? classification.framework : ElaroConstants.FRAMEWORK_SOC2;

        // Get audit trail stats
        Integer totalChanges = [SELECT COUNT() FROM SetupAuditTrail WHERE CreatedDate >= LAST_N_DAYS:30 WITH SECURITY_ENFORCED];

        response.answer = '📊 *' + Label.Copilot_Evidence_Summary.replace('{0}', framework) + '*\n\n' +
            '• Configuration changes (30 days): ' + totalChanges + '\n' +
            '• Audit trail retention: Active\n' +
            '• Field History Tracking: Check Setup\n\n' +
            '_Enable Elaro Big Object for comprehensive compliance tracking._';

        // Add export action
        SuggestedAction exportAction = new SuggestedAction();
        exportAction.actionType = ElaroConstants.ACTION_EXPORT;
        exportAction.label = 'Export PDF';
        exportAction.description = 'Generate audit-ready compliance report';
        exportAction.canAutoFix = false;
        response.actions.add(exportAction);

        return response;
    }

    /**
     * Handle violation search queries
     */
    private static CopilotResponse handleViolationSearch(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        // Check for potential violations using SetupAuditTrail
        List<SetupAuditTrail> potentialViolations = [
            SELECT CreatedDate, CreatedById, CreatedBy.Name, Action, Section, Display
            FROM SetupAuditTrail
            WHERE CreatedDate >= LAST_N_DAYS:30
            AND (Action LIKE '%permission%' OR Action LIKE '%delete%' OR Action LIKE '%removed%')
            WITH SECURITY_ENFORCED
            ORDER BY CreatedDate DESC
            LIMIT 20
        ];

        if (potentialViolations.isEmpty()) {
            String frameworkSuffix = classification.framework != null ? ' for ' + classification.framework : '';
            response.answer = Label.Copilot_No_Violations.replace('{0}', frameworkSuffix) + ' 🎉';
            return response;
        }

        List<String> violationList = new List<String>();

        for (SetupAuditTrail v : potentialViolations) {
            Evidence ev = new Evidence();
            ev.nodeId = String.valueOf(v.Id);
            ev.timestamp = v.CreatedDate;
            ev.description = v.Display;
            ev.entityType = v.Section;
            ev.riskScore = calculateRiskFromAction(v.Action);
            response.evidence.add(ev);

            violationList.add('• ' + v.Section + ' - ' + v.Display);
        }

        response.answer = Label.Copilot_Violations_Found.replace('{0}', String.valueOf(potentialViolations.size())) + '\n\n' +
            String.join(violationList, '\n');

        return response;
    }

    /**
     * Handle user access queries
     */
    private static CopilotResponse handleUserAccessQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        // Get users with elevated permissions
        List<PermissionSetAssignment> elevatedUsers = [
            SELECT AssigneeId, Assignee.Name, PermissionSet.Name,
                   PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
            FROM PermissionSetAssignment
            WHERE PermissionSet.PermissionsModifyAllData = true
            OR PermissionSet.PermissionsViewAllData = true
            LIMIT 50
        ];

        if (elevatedUsers.isEmpty()) {
            response.answer = Label.Copilot_No_Elevated_Users;
            return response;
        }

        Map<Id, Set<String>> userPermissions = new Map<Id, Set<String>>();
        Map<Id, String> userNames = new Map<Id, String>();

        for (PermissionSetAssignment psa : elevatedUsers) {
            if (!userPermissions.containsKey(psa.AssigneeId)) {
                userPermissions.put(psa.AssigneeId, new Set<String>());
                userNames.put(psa.AssigneeId, psa.Assignee.Name);
            }
            userPermissions.get(psa.AssigneeId).add(psa.PermissionSet.Name);
        }

        List<String> userList = new List<String>();
        for (Id userId : userPermissions.keySet()) {
            userList.add('• *' + userNames.get(userId) + '*: ' + String.join(new List<String>(userPermissions.get(userId)), ', '));
        }

        response.answer = '⚠️ ' + Label.Copilot_Elevated_Users_Found.replace('{0}', String.valueOf(userPermissions.size())) + '\n\n' +
            String.join(userList, '\n') + '\n\n' +
            '_Review these assignments for HIPAA Minimum Necessary compliance._';

        return response;
    }

    /**
     * Handle framework status queries
     */
    private static CopilotResponse handleFrameworkStatus(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        String framework = classification.framework != null ? classification.framework : ElaroConstants.FRAMEWORK_HIPAA;

        // Get compliance score
        Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
        Decimal overallScore = (Decimal)scoreData.get('overallScore');

        String emoji = overallScore >= 90 ? '🟢' : overallScore >= 70 ? '🟡' : '🔴';

        response.answer = emoji + ' *' + Label.Copilot_Framework_Status.replace('{0}', framework) + '*\n\n' +
            '• Overall Compliance Score: ' + overallScore.setScale(1) + '%\n' +
            '• Risk Level: ' + scoreData.get('riskLevel') + '\n\n' +
            '_Run "Generate ' + framework + ' evidence for Q' + getQuarter() + '" for audit-ready documentation._';

        return response;
    }

    /**
     * Handle general queries
     */
    private static CopilotResponse handleGeneralQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();

        response.answer = Label.Copilot_General_Help + '\n\n' +
            '• "Why did my compliance score drop?"\n' +
            '• "Show me all risky Flows touching PII"\n' +
            '• "Generate SOC2 evidence for Q4"\n' +
            '• "Who has Modify All Data permission?"\n' +
            '• "What\'s our HIPAA compliance status?"\n' +
            '• "Show me recent violations"';

        return response;
    }

    /**
     * Get current quarter number
     */
    private static Integer getQuarter() {
        return ((Date.today().month() - 1) / 3) + 1;
    }

    /**
     * Deep analysis of a specific compliance topic
     * Performs comprehensive analysis including violations, risks, and recommendations
     */
    @AuraEnabled
    public static CopilotResponse deepAnalysis(String topic) {
        CopilotResponse response = new CopilotResponse();

        try {
            // Validate input
            if (String.isBlank(topic)) {
                response.answer = 'Please provide a topic for deep analysis (e.g., "HIPAA compliance", "permission sprawl")';
                response.confidence = 0.0;
                return response;
            }

            // Validate input length
            if (topic.length() > 500) {
                throw new AuraHandledException('Topic exceeds maximum length of 500 characters');
            }

            String lowerTopic = topic.toLowerCase();
            response.queryType = 'DEEP_ANALYSIS';

            // Detect framework from topic
            String framework = null;
            if (lowerTopic.contains('hipaa')) framework = ElaroConstants.FRAMEWORK_HIPAA;
            else if (lowerTopic.contains('soc2') || lowerTopic.contains('soc 2')) framework = ElaroConstants.FRAMEWORK_SOC2;
            else if (lowerTopic.contains('nist')) framework = ElaroConstants.FRAMEWORK_NIST;
            else if (lowerTopic.contains('fedramp')) framework = ElaroConstants.FRAMEWORK_FEDRAMP;
            else if (lowerTopic.contains('gdpr')) framework = ElaroConstants.FRAMEWORK_GDPR;
            else if (lowerTopic.contains('sox')) framework = ElaroConstants.FRAMEWORK_SOX;
            else if (lowerTopic.contains('pci') || lowerTopic.contains('pci-dss')) framework = ElaroConstants.FRAMEWORK_PCI_DSS;
            else if (lowerTopic.contains('ccpa')) framework = ElaroConstants.FRAMEWORK_CCPA;
            else if (lowerTopic.contains('glba')) framework = ElaroConstants.FRAMEWORK_GLBA;
            else if (lowerTopic.contains('iso') || lowerTopic.contains('27001')) framework = ElaroConstants.FRAMEWORK_ISO27001;

            // Get comprehensive compliance score
            Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
            Decimal overallScore = (Decimal)scoreData.get('overallScore');
            Map<String, Decimal> frameworkScores = (Map<String, Decimal>)scoreData.get('frameworkScores');

            // Build comprehensive analysis
            List<String> analysisPoints = new List<String>();
            analysisPoints.add('📊 *Compliance Overview*');
            analysisPoints.add('• Overall Score: ' + overallScore.setScale(1) + '%');
            
            if (framework != null && frameworkScores.containsKey(framework)) {
                Decimal frameworkScore = frameworkScores.get(framework);
                analysisPoints.add('• ' + framework + ' Score: ' + frameworkScore.setScale(1) + '%');
            }

            // Analyze violations
            List<SetupAuditTrail> violations = [
                SELECT CreatedDate, CreatedById, CreatedBy.Name, Action, Section, Display
                FROM SetupAuditTrail
                WHERE CreatedDate >= LAST_N_DAYS:30
                AND (Action LIKE '%permission%' OR Action LIKE '%delete%' OR Action LIKE '%removed%' OR Action LIKE '%field%')
                WITH SECURITY_ENFORCED
                ORDER BY CreatedDate DESC
                LIMIT 20
            ];

            if (!violations.isEmpty()) {
                analysisPoints.add('');
                analysisPoints.add('⚠️ *Recent Violations* (' + violations.size() + ' found)');
                Integer count = 1;
                for (SetupAuditTrail v : violations) {
                    Evidence ev = new Evidence();
                    ev.nodeId = String.valueOf(v.Id);
                    ev.timestamp = v.CreatedDate;
                    ev.description = v.Display;
                    ev.entityType = v.Section;
                    ev.riskScore = calculateRiskFromAction(v.Action);
                    ev.framework = framework != null ? framework : ElaroConstants.FRAMEWORK_SOC2;
                    response.evidence.add(ev);

                    if (count <= 5) {
                        analysisPoints.add(count + '. ' + v.Section + ' - ' + v.Display);
                        count++;
                    }
                }
                if (violations.size() > 5) {
                    analysisPoints.add('... and ' + (violations.size() - 5) + ' more');
                }
            }

            // Analyze user access
            List<PermissionSetAssignment> elevatedUsers = [
                SELECT AssigneeId, Assignee.Name, PermissionSet.Name,
                       PermissionSet.PermissionsModifyAllData, PermissionSet.PermissionsViewAllData
                FROM PermissionSetAssignment
                WHERE PermissionSet.PermissionsModifyAllData = true
                OR PermissionSet.PermissionsViewAllData = true
                LIMIT 20
            ];

            if (!elevatedUsers.isEmpty()) {
                analysisPoints.add('');
                analysisPoints.add('🔐 *Elevated Access Users* (' + elevatedUsers.size() + ' found)');
                Set<Id> userIds = new Set<Id>();
                for (PermissionSetAssignment psa : elevatedUsers) {
                    userIds.add(psa.AssigneeId);
                }
                analysisPoints.add('• Users with Modify All Data or View All Data: ' + userIds.size());
            }

            // Add recommendations
            analysisPoints.add('');
            analysisPoints.add('💡 *Recommendations*');
            if (overallScore < 70) {
                analysisPoints.add('• Review and remediate recent violations');
                analysisPoints.add('• Conduct access review for elevated permissions');
                analysisPoints.add('• Enable field history tracking for critical objects');
            } else if (overallScore < 85) {
                analysisPoints.add('• Monitor for new violations');
                analysisPoints.add('• Review permission assignments quarterly');
            } else {
                analysisPoints.add('• Maintain current compliance posture');
                analysisPoints.add('• Continue regular monitoring');
            }

            response.answer = String.join(analysisPoints, '\n');
            response.confidence = 0.85;

            // Add export action
            SuggestedAction exportAction = new SuggestedAction();
            exportAction.actionType = ElaroConstants.ACTION_EXPORT;
            exportAction.label = 'Export Analysis Report';
            exportAction.description = 'Generate detailed compliance analysis report';
            exportAction.canAutoFix = false;
            response.actions.add(exportAction);

        } catch (Exception e) {
            String errorMsg = String.isNotBlank(e.getMessage()) ? e.getMessage() : 'Unknown error';
            response.answer = 'Error performing deep analysis: ' + errorMsg;
            response.confidence = 0.0;
            String correlationId = 'DEEP-ANALYSIS-' + System.now().getTime();
            System.debug(LoggingLevel.ERROR, ElaroConstants.LOG_PREFIX + 'deepAnalysis error: ' + e.getTypeName() + ' - ' + e.getMessage() + ' [CorrelationId: ' + correlationId + ']');
        }

        return response;
    }

    /**
     * Quick commands for common queries
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getQuickCommands() {
        return new List<Map<String, String>>{
            new Map<String, String>{'command' => 'Why did my score drop?', 'icon' => 'utility:trending_down'},
            new Map<String, String>{'command' => 'Show me risky Flows', 'icon' => 'utility:flow'},
            new Map<String, String>{'command' => 'Generate HIPAA evidence', 'icon' => 'utility:file'},
            new Map<String, String>{'command' => 'Who has elevated access?', 'icon' => 'utility:user'},
            new Map<String, String>{'command' => 'SOC2 compliance status', 'icon' => 'utility:shield'},
            new Map<String, String>{'command' => 'Show recent violations', 'icon' => 'utility:warning'}
        };
    }
}
