/**
 * SolentraComplianceCopilot - Natural Language Compliance Query Interface
 * 
 * ChatGPT-style interface for compliance queries:
 * User: "Why did my compliance score drop 15 points?"
 * Solentra: "On Dec 2, Profile 'Sales_Manager' was given Edit access to 
 *            PHI field Patient_SSN__c, violating HIPAA Minimum Necessary rule. 
 *            [View Evidence] [Auto-Fix]"
 * 
 * @author Solentra
 * @version 1.0
 */
public with sharing class SolentraComplianceCopilot {
    
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
                response.queryType = SolentraConstants.QUERY_GENERAL;
                return response;
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
            System.debug(LoggingLevel.ERROR, SolentraConstants.LOG_PREFIX + 'askCopilot error: ' + e.getMessage() + '\n' + e.getStackTraceString());
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
            result.queryType = SolentraConstants.QUERY_SCORE_CHANGE;
        } else if (lowerQuery.contains('violation') || lowerQuery.contains('non-compliant') || lowerQuery.contains('failed')) {
            result.queryType = SolentraConstants.QUERY_VIOLATION_SEARCH;
        } else if (lowerQuery.contains('evidence') || lowerQuery.contains('audit') || lowerQuery.contains('report')) {
            result.queryType = SolentraConstants.QUERY_EVIDENCE_REQUEST;
        } else if (lowerQuery.contains('flow') && (lowerQuery.contains('risky') || lowerQuery.contains('pii') || lowerQuery.contains('phi'))) {
            result.queryType = SolentraConstants.QUERY_RISKY_FLOWS;
        } else if (lowerQuery.contains('access') || lowerQuery.contains('permission') || lowerQuery.contains('who can')) {
            result.queryType = SolentraConstants.QUERY_USER_ACCESS;
        } else if (lowerQuery.contains('hipaa') || lowerQuery.contains('soc2') || lowerQuery.contains('soc 2') || 
                   lowerQuery.contains('nist') || lowerQuery.contains('fedramp') || lowerQuery.contains('gdpr')) {
            result.queryType = SolentraConstants.QUERY_FRAMEWORK_STATUS;
        } else {
            result.queryType = SolentraConstants.QUERY_GENERAL;
        }
        
        // Detect framework
        if (lowerQuery.contains('hipaa')) result.framework = SolentraConstants.FRAMEWORK_HIPAA;
        else if (lowerQuery.contains('soc2') || lowerQuery.contains('soc 2')) result.framework = SolentraConstants.FRAMEWORK_SOC2;
        else if (lowerQuery.contains('nist')) result.framework = SolentraConstants.FRAMEWORK_NIST;
        else if (lowerQuery.contains('fedramp')) result.framework = SolentraConstants.FRAMEWORK_FEDRAMP;
        else if (lowerQuery.contains('gdpr')) result.framework = SolentraConstants.FRAMEWORK_GDPR;
        
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
            ev.entityType = SolentraConstants.ENTITY_FLOW;
            ev.riskScore = 5.0; // Default risk score
            response.evidence.add(ev);
            
            flowDescriptions.add('• *' + flow.Label + '* (' + flow.ProcessType + ')');
        }
        
        response.answer = 'Found ' + flows.size() + ' active Flows:\n\n' +
            String.join(flowDescriptions, '\n') + '\n\n_Enable Solentra Big Object for detailed risk analysis._';
        
        return response;
    }
    
    /**
     * Handle evidence request queries
     */
    private static CopilotResponse handleEvidenceRequest(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();
        
        String framework = classification.framework != null ? classification.framework : SolentraConstants.FRAMEWORK_SOC2;
        
        // Get audit trail stats
        Integer totalChanges = [SELECT COUNT() FROM SetupAuditTrail WHERE CreatedDate >= LAST_N_DAYS:30];
        
        response.answer = '📊 *' + Label.Copilot_Evidence_Summary.replace('{0}', framework) + '*\n\n' +
            '• Configuration changes (30 days): ' + totalChanges + '\n' +
            '• Audit trail retention: Active\n' +
            '• Field History Tracking: Check Setup\n\n' +
            '_Enable Solentra Big Object for comprehensive compliance tracking._';
        
        // Add export action
        SuggestedAction exportAction = new SuggestedAction();
        exportAction.actionType = SolentraConstants.ACTION_EXPORT;
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
        
        String framework = classification.framework != null ? classification.framework : SolentraConstants.FRAMEWORK_HIPAA;
        
        // Get compliance score
        Map<String, Object> scoreData = SolentraComplianceScorer.calculateComplianceScore();
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
