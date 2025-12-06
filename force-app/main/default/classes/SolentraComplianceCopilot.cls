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
     */
    private static CopilotResponse handleScoreChangeQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();
        
        // Get recent high-risk changes
        List<Solentra_Compliance_Graph__b> recentChanges = [
            SELECT Graph_Node_Id__c, Timestamp__c, Entity_Type__c, Entity_Record_Id__c, 
                   Risk_Score__c, Compliance_Framework__c, AI_Explanation__c, Node_Metadata__c
            FROM Solentra_Compliance_Graph__b
            WHERE Risk_Score__c >= :SolentraConstants.RISK_THRESHOLD_HIGH
            AND Timestamp__c >= LAST_N_DAYS:7
            ORDER BY Risk_Score__c DESC
            LIMIT 5
        ];
        
        if (recentChanges.isEmpty()) {
            response.answer = Label.Copilot_No_Recent_Changes;
            return response;
        }
        
        // Build natural language response
        List<String> impacts = new List<String>();
        Integer changeNumber = 1;
        
        for (Solentra_Compliance_Graph__b change : recentChanges) {
            Evidence ev = new Evidence();
            ev.nodeId = change.Graph_Node_Id__c;
            ev.timestamp = change.Timestamp__c;
            ev.framework = change.Compliance_Framework__c;
            ev.riskScore = change.Risk_Score__c;
            ev.entityType = change.Entity_Type__c;
            ev.description = change.AI_Explanation__c;
            response.evidence.add(ev);
            
            impacts.add(changeNumber + '. ' + formatChangeDescription(change));
            changeNumber++;
            
            // Add suggested action (only for very high risk items)
            if (change.Risk_Score__c >= SolentraConstants.RISK_THRESHOLD_AUTO_FIX) {
                SuggestedAction action = new SuggestedAction();
                action.actionType = SolentraConstants.ACTION_AUTO_FIX;
                action.label = 'Auto-Fix';
                action.description = 'Automatically remediate this violation';
                action.canAutoFix = true;
                action.nodeId = change.Graph_Node_Id__c;
                response.actions.add(action);
            }
        }
        
        response.answer = Label.Copilot_Score_Drop_Reason.replace('{0}', String.valueOf(recentChanges.size())) + '\n\n' +
            String.join(impacts, '\n\n');
        
        return response;
    }
    
    /**
     * Handle risky flows queries
     */
    private static CopilotResponse handleRiskyFlowsQuery(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();
        
        // Query flows with high risk scores
        List<Solentra_Compliance_Graph__b> riskyFlows = [
            SELECT Graph_Node_Id__c, Timestamp__c, Entity_Record_Id__c, Risk_Score__c, 
                   Node_Metadata__c, AI_Explanation__c
            FROM Solentra_Compliance_Graph__b
            WHERE Entity_Type__c = :SolentraConstants.ENTITY_FLOW
            AND Risk_Score__c >= :SolentraConstants.RISK_THRESHOLD_MEDIUM
            ORDER BY Risk_Score__c DESC
            LIMIT 12
        ];
        
        if (riskyFlows.isEmpty()) {
            response.answer = Label.Copilot_No_Risky_Flows;
            return response;
        }
        
        List<String> flowDescriptions = new List<String>();
        
        for (Solentra_Compliance_Graph__b flow : riskyFlows) {
            Map<String, Object> metadata = String.isNotBlank(flow.Node_Metadata__c) 
                ? (Map<String, Object>)JSON.deserializeUntyped(flow.Node_Metadata__c)
                : new Map<String, Object>();
            
            String flowName = (String)metadata.get('apiName');
            if (String.isBlank(flowName)) flowName = flow.Entity_Record_Id__c;
            
            Evidence ev = new Evidence();
            ev.nodeId = flow.Graph_Node_Id__c;
            ev.description = flow.AI_Explanation__c;
            ev.riskScore = flow.Risk_Score__c;
            ev.entityType = SolentraConstants.ENTITY_FLOW;
            response.evidence.add(ev);
            
            flowDescriptions.add('• *' + flowName + '* (Risk: ' + flow.Risk_Score__c + '/10) - ' + 
                (String.isNotBlank(flow.AI_Explanation__c) ? flow.AI_Explanation__c : 'Review required'));
        }
        
        response.answer = Label.Copilot_Risky_Flows_Found.replace('{0}', String.valueOf(riskyFlows.size())) + '\n\n' +
            String.join(flowDescriptions, '\n');
        
        return response;
    }
    
    /**
     * Handle evidence request queries
     */
    private static CopilotResponse handleEvidenceRequest(String query, QueryClassification classification) {
        CopilotResponse response = new CopilotResponse();
        
        String framework = classification.framework != null ? classification.framework : SolentraConstants.FRAMEWORK_SOC2;
        String timeframe = classification.timeframe != null ? classification.timeframe : 'THIS_QUARTER';
        
        // Get compliance evidence
        Date startDate = getStartDateForTimeframe(timeframe);
        
        List<Solentra_Compliance_Graph__b> evidenceNodes = [
            SELECT Graph_Node_Id__c, Timestamp__c, Entity_Type__c, Entity_Record_Id__c,
                   Compliance_Framework__c, Risk_Score__c, Drift_Category__c, Human_Adjudicated__c
            FROM Solentra_Compliance_Graph__b
            WHERE Compliance_Framework__c = :framework
            AND Timestamp__c >= :startDate
            ORDER BY Timestamp__c DESC
            LIMIT 100
        ];
        
        // Calculate statistics
        Integer totalChanges = evidenceNodes.size();
        Integer violations = 0;
        Integer remediated = 0;
        Integer humanReviewed = 0;
        
        for (Solentra_Compliance_Graph__b node : evidenceNodes) {
            if (node.Drift_Category__c == SolentraConstants.DRIFT_POLICY_VIOLATION) violations++;
            if (node.Drift_Category__c == SolentraConstants.DRIFT_AUTO_REMEDIATED) remediated++;
            if (node.Human_Adjudicated__c) humanReviewed++;
        }
        
        response.answer = '📊 *' + Label.Copilot_Evidence_Summary.replace('{0}', framework) + '*\n\n' +
            '• Total configuration changes: ' + totalChanges + '\n' +
            '• Policy violations detected: ' + violations + '\n' +
            '• Auto-remediated: ' + remediated + '\n' +
            '• Human-reviewed: ' + humanReviewed + '\n\n' +
            '_Export audit-ready PDF available via the Reports tab._';
        
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
        
        String frameworkFilter = classification.framework;
        String soql = 'SELECT Graph_Node_Id__c, Timestamp__c, Entity_Type__c, Entity_Record_Id__c, ' +
            'Risk_Score__c, Compliance_Framework__c, AI_Explanation__c, Drift_Category__c ' +
            'FROM Solentra_Compliance_Graph__b WHERE Drift_Category__c = \'POLICY_VIOLATION\' ';
        
        if (String.isNotBlank(frameworkFilter)) {
            soql += 'AND Compliance_Framework__c = \'' + String.escapeSingleQuotes(frameworkFilter) + '\' ';
        }
        
        soql += 'ORDER BY Risk_Score__c DESC LIMIT 20';
        
        List<Solentra_Compliance_Graph__b> violations = Database.query(soql);
        
        if (violations.isEmpty()) {
            String frameworkSuffix = String.isNotBlank(frameworkFilter) ? ' for ' + frameworkFilter : '';
            response.answer = Label.Copilot_No_Violations.replace('{0}', frameworkSuffix) + ' 🎉';
            return response;
        }
        
        List<String> violationList = new List<String>();
        
        for (Solentra_Compliance_Graph__b v : violations) {
            Evidence ev = new Evidence();
            ev.nodeId = v.Graph_Node_Id__c;
            ev.timestamp = v.Timestamp__c;
            ev.framework = v.Compliance_Framework__c;
            ev.riskScore = v.Risk_Score__c;
            ev.entityType = v.Entity_Type__c;
            ev.description = v.AI_Explanation__c;
            response.evidence.add(ev);
            
            violationList.add('• ' + v.Entity_Type__c + ' (' + v.Compliance_Framework__c + ') - Risk: ' + 
                v.Risk_Score__c + '/10');
        }
        
        response.answer = Label.Copilot_Violations_Found.replace('{0}', String.valueOf(violations.size())) + '\n\n' + 
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
        
        // Get framework-specific stats
        AggregateResult[] stats = [
            SELECT COUNT(Id) total, 
                   SUM(CASE WHEN Drift_Category__c = 'POLICY_VIOLATION' THEN 1 ELSE 0 END) violations
            FROM Solentra_Compliance_Graph__b
            WHERE Compliance_Framework__c = :framework
            AND Timestamp__c >= LAST_N_DAYS:30
        ];
        
        Integer total = stats.isEmpty() ? 0 : (Integer)stats[0].get('total');
        Integer violations = stats.isEmpty() ? 0 : (Integer)stats[0].get('violations');
        
        // Calculate compliance percentage
        Decimal complianceRate = total > 0 ? ((Decimal)(total - violations) / total * 100).setScale(1) : 100.0;
        
        String emoji = complianceRate >= 95 ? '🟢' : complianceRate >= 80 ? '🟡' : '🔴';
        
        response.answer = emoji + ' *' + Label.Copilot_Framework_Status.replace('{0}', framework) + '*\n\n' +
            '• Compliance Rate: ' + complianceRate + '%\n' +
            '• Changes Monitored (30 days): ' + total + '\n' +
            '• Active Violations: ' + violations + '\n\n' +
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
     * Format a compliance change into natural language
     */
    private static String formatChangeDescription(Solentra_Compliance_Graph__b change) {
        String description = '';
        
        if (String.isNotBlank(change.AI_Explanation__c)) {
            description = change.AI_Explanation__c;
        } else {
            Map<String, Object> metadata = String.isNotBlank(change.Node_Metadata__c)
                ? (Map<String, Object>)JSON.deserializeUntyped(change.Node_Metadata__c)
                : new Map<String, Object>();
            
            String entityName = (String)metadata.get('name');
            if (String.isBlank(entityName)) entityName = change.Entity_Record_Id__c;
            
            description = 'On ' + change.Timestamp__c.format('MMM d') + ', ' +
                change.Entity_Type__c + ' "' + entityName + '" was modified';
            
            if (String.isNotBlank(change.Compliance_Framework__c)) {
                description += ', potentially violating ' + change.Compliance_Framework__c + ' requirements';
            }
            
            description += '. Risk Score: ' + change.Risk_Score__c + '/10.';
        }
        
        return description;
    }
    
    /**
     * Get start date for a timeframe
     */
    private static Date getStartDateForTimeframe(String timeframe) {
        switch on timeframe {
            when 'TODAY' {
                return Date.today();
            }
            when 'YESTERDAY' {
                return Date.today().addDays(-1);
            }
            when 'THIS_WEEK' {
                return Date.today().toStartOfWeek();
            }
            when 'THIS_MONTH' {
                return Date.today().toStartOfMonth();
            }
            when 'THIS_QUARTER', 'QUARTER' {
                Integer month = Date.today().month();
                Integer quarterStart = ((month - 1) / 3) * 3 + 1;
                return Date.newInstance(Date.today().year(), quarterStart, 1);
            }
            when else {
                return Date.today().addDays(-30);
            }
        }
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

