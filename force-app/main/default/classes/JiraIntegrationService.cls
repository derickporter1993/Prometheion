/**
 * @description Service class for Jira integration with Elaro compliance gaps.
 * Provides bidirectional sync between Salesforce Compliance_Gap__c and Jira issues.
 *
 * Features:
 * - Create Jira issues from compliance gaps
 * - Sync issue status between platforms
 * - Add comments and attachments
 * - Bulk operations support
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
public with sharing class JiraIntegrationService {

    private static final String NAMED_CREDENTIAL = 'callout:Jira_API';
    private static final String API_VERSION = '/rest/api/3';

    /**
     * @description Creates a Jira issue from a compliance gap
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     * @param priority Optional priority override (Highest, High, Medium, Low, Lowest)
     * @return JiraIssue wrapper containing the created issue details
     */
    @AuraEnabled
    public static JiraIssue createIssue(String gapId, String priority) {
        Compliance_Gap__c gap = getGapWithFields(gapId);

        if (String.isNotBlank(gap.Jira_Issue_Key__c)) {
            throw new JiraIntegrationException('A Jira issue already exists for this gap: ' + gap.Jira_Issue_Key__c);
        }

        JiraSettings settings = getSettings();
        String effectivePriority = String.isNotBlank(priority) ? priority : settings.defaultPriority;

        Map<String, Object> issuePayload = buildIssuePayload(gap, settings, effectivePriority);
        HttpResponse response = makeCallout('POST', API_VERSION + '/issue', JSON.serialize(issuePayload));

        if (response.getStatusCode() != 201) {
            throw new JiraIntegrationException('Failed to create Jira issue: ' + response.getBody());
        }

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        String issueKey = (String) responseBody.get('key');
        String issueId = (String) responseBody.get('id');

        // Update the gap with Jira information
        gap.Jira_Issue_Key__c = issueKey;
        gap.Jira_Issue_URL__c = settings.jiraInstanceUrl + '/browse/' + issueKey;
        gap.Jira_Status__c = 'To Do';
        gap.Jira_Last_Sync__c = Datetime.now();

        if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
            update as user gap;
        }

        return buildJiraIssueFromResponse(responseBody, settings.jiraInstanceUrl);
    }

    /**
     * @description Asynchronously creates a Jira issue (for trigger/batch contexts)
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     * @param priority Optional priority override
     */
    @future(callout=true)
    public static void createIssueAsync(String gapId, String priority) {
        try {
            createIssue(gapId, priority);
        } catch (Exception e) {
            ElaroLogger.error('Async Jira issue creation failed: ' + e.getMessage(), e);
            // Log to custom object for monitoring
            logError('createIssueAsync', gapId, e.getMessage());
        }
    }

    /**
     * @description Gets the current status of a Jira issue
     * @param jiraKey The Jira issue key (e.g., COMPLIANCE-123)
     * @return JiraIssue wrapper with current issue details
     */
    @AuraEnabled(cacheable=true)
    public static JiraIssue getIssueStatus(String jiraKey) {
        if (String.isBlank(jiraKey)) {
            throw new JiraIntegrationException('Jira issue key is required');
        }

        JiraSettings settings = getSettings();
        HttpResponse response = makeCallout('GET', API_VERSION + '/issue/' + jiraKey, null);

        if (response.getStatusCode() != 200) {
            if (response.getStatusCode() == 404) {
                throw new JiraIntegrationException('Jira issue not found: ' + jiraKey);
            }
            throw new JiraIntegrationException('Failed to get Jira issue: ' + response.getBody());
        }

        Map<String, Object> issueData = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        return buildJiraIssueFromFullResponse(issueData, settings.jiraInstanceUrl);
    }

    /**
     * @description Syncs the Jira issue status back to the Salesforce gap
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     */
    @AuraEnabled
    public static void syncIssueStatus(String gapId) {
        Compliance_Gap__c gap = getGapWithFields(gapId);

        if (String.isBlank(gap.Jira_Issue_Key__c)) {
            throw new JiraIntegrationException('No Jira issue linked to this gap');
        }

        JiraIssue issue = getIssueStatus(gap.Jira_Issue_Key__c);

        // Update gap with synced data
        gap.Jira_Status__c = issue.status;
        gap.Jira_Last_Sync__c = Datetime.now();

        // Optionally update Salesforce status based on Jira status
        String newStatus = mapJiraStatusToSalesforce(issue.status);
        if (String.isNotBlank(newStatus) && newStatus != gap.Status__c) {
            gap.Status__c = newStatus;
        }

        if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
            update as user gap;
        }
    }

    /**
     * @description Creates Jira issues for multiple gaps
     * @param gapIds List of Compliance_Gap__c IDs
     * @return List of created JiraIssue wrappers
     */
    @AuraEnabled
    public static List<JiraIssue> createBulkIssues(List<String> gapIds) {
        List<JiraIssue> createdIssues = new List<JiraIssue>();

        for (String gapId : gapIds) {
            try {
                JiraIssue issue = createIssue(gapId, null);
                createdIssues.add(issue);
            } catch (Exception e) {
                ElaroLogger.warn('Failed to create issue for gap ' + gapId + ': ' + e.getMessage());
            }
        }

        return createdIssues;
    }

    /**
     * @description Adds a comment to a Jira issue
     * @param jiraKey The Jira issue key
     * @param comment The comment text to add
     */
    @AuraEnabled
    public static void addComment(String jiraKey, String comment) {
        if (String.isBlank(jiraKey) || String.isBlank(comment)) {
            throw new JiraIntegrationException('Jira key and comment are required');
        }

        Map<String, Object> commentPayload = new Map<String, Object>{
            'body' => buildAtlassianDocumentFormat(comment)
        };

        HttpResponse response = makeCallout(
            'POST',
            API_VERSION + '/issue/' + jiraKey + '/comment',
            JSON.serialize(commentPayload)
        );

        if (response.getStatusCode() != 201) {
            throw new JiraIntegrationException('Failed to add comment: ' + response.getBody());
        }
    }

    /**
     * @description Updates a Jira issue status
     * @param jiraKey The Jira issue key
     * @param transitionId The Jira transition ID to execute
     */
    @AuraEnabled
    public static void transitionIssue(String jiraKey, String transitionId) {
        if (String.isBlank(jiraKey) || String.isBlank(transitionId)) {
            throw new JiraIntegrationException('Jira key and transition ID are required');
        }

        Map<String, Object> transitionPayload = new Map<String, Object>{
            'transition' => new Map<String, Object>{
                'id' => transitionId
            }
        };

        HttpResponse response = makeCallout(
            'POST',
            API_VERSION + '/issue/' + jiraKey + '/transitions',
            JSON.serialize(transitionPayload)
        );

        if (response.getStatusCode() != 204) {
            throw new JiraIntegrationException('Failed to transition issue: ' + response.getBody());
        }
    }

    /**
     * @description Gets available transitions for a Jira issue
     * @param jiraKey The Jira issue key
     * @return List of available transitions
     */
    @AuraEnabled(cacheable=true)
    public static List<JiraTransition> getAvailableTransitions(String jiraKey) {
        if (String.isBlank(jiraKey)) {
            throw new JiraIntegrationException('Jira issue key is required');
        }

        HttpResponse response = makeCallout('GET', API_VERSION + '/issue/' + jiraKey + '/transitions', null);

        if (response.getStatusCode() != 200) {
            throw new JiraIntegrationException('Failed to get transitions: ' + response.getBody());
        }

        Map<String, Object> responseBody = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
        List<Object> transitions = (List<Object>) responseBody.get('transitions');

        List<JiraTransition> result = new List<JiraTransition>();
        for (Object t : transitions) {
            Map<String, Object> transition = (Map<String, Object>) t;
            JiraTransition jt = new JiraTransition();
            jt.id = (String) transition.get('id');
            jt.name = (String) transition.get('name');
            result.add(jt);
        }

        return result;
    }

    /**
     * @description Checks if Jira integration is properly configured
     * @return True if configured and accessible
     */
    @AuraEnabled(cacheable=true)
    public static Boolean isConfigured() {
        try {
            JiraSettings settings = getSettings();
            if (String.isBlank(settings.jiraInstanceUrl) || String.isBlank(settings.projectKey)) {
                return false;
            }

            // Try to access the project to verify credentials
            HttpResponse response = makeCallout('GET', API_VERSION + '/project/' + settings.projectKey, null);
            return response.getStatusCode() == 200;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * @description Gets all gaps linked to Jira issues
     * @return List of gaps with Jira links
     */
    @AuraEnabled(cacheable=true)
    public static List<Compliance_Gap__c> getLinkedGaps() {
        return [
            SELECT Id, Name, Framework__c, Severity__c, Status__c, Gap_Description__c,
                   Jira_Issue_Key__c, Jira_Issue_URL__c, Jira_Status__c, Jira_Last_Sync__c
            FROM Compliance_Gap__c
            WHERE Jira_Issue_Key__c != NULL
            WITH USER_MODE
            ORDER BY Jira_Last_Sync__c DESC
            LIMIT 100
        ];
    }

    // ============================================
    // Private Helper Methods
    // ============================================

    private static Compliance_Gap__c getGapWithFields(String gapId) {
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Framework__c, Severity__c, Status__c, Gap_Description__c,
                   Policy_Reference__c, Remediation_Plan__c, Risk_Score__c,
                   Jira_Issue_Key__c, Jira_Issue_URL__c, Jira_Status__c, Jira_Last_Sync__c
            FROM Compliance_Gap__c
            WHERE Id = :gapId
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            throw new JiraIntegrationException('Compliance gap not found: ' + gapId);
        }

        return gaps[0];
    }

    private static JiraSettings getSettings() {
        Elaro_Jira_Settings__c settings = Elaro_Jira_Settings__c.getOrgDefaults();

        JiraSettings js = new JiraSettings();
        js.jiraInstanceUrl = settings.Jira_Instance_URL__c;
        js.projectKey = settings.Project_Key__c;
        js.issueType = settings.Issue_Type__c;
        js.defaultPriority = settings.Default_Priority__c;
        js.autoCreate = settings.Auto_Create_Enabled__c;
        js.riskThreshold = settings.Risk_Threshold__c;
        js.syncEnabled = settings.Sync_Enabled__c;

        return js;
    }

    private static Map<String, Object> buildIssuePayload(Compliance_Gap__c gap, JiraSettings settings, String priority) {
        String description = buildIssueDescription(gap);

        Map<String, Object> payload = new Map<String, Object>{
            'fields' => new Map<String, Object>{
                'project' => new Map<String, Object>{
                    'key' => settings.projectKey
                },
                'summary' => '[' + gap.Framework__c + '] ' + gap.Name + ' - ' + gap.Severity__c + ' Compliance Gap',
                'description' => buildAtlassianDocumentFormat(description),
                'issuetype' => new Map<String, Object>{
                    'name' => settings.issueType
                },
                'priority' => new Map<String, Object>{
                    'name' => mapSeverityToJiraPriority(gap.Severity__c, priority)
                },
                'labels' => new List<String>{
                    'elaro',
                    'compliance',
                    gap.Framework__c.toLowerCase()
                }
            }
        };

        return payload;
    }

    private static String buildIssueDescription(Compliance_Gap__c gap) {
        String description = '*Compliance Gap Details*\n\n';
        description += '| Field | Value |\n';
        description += '|-------|-------|\n';
        description += '| Framework | ' + gap.Framework__c + ' |\n';
        description += '| Severity | ' + gap.Severity__c + ' |\n';
        description += '| Status | ' + gap.Status__c + ' |\n';
        description += '| Risk Score | ' + (gap.Risk_Score__c != null ? String.valueOf(gap.Risk_Score__c) : 'N/A') + ' |\n';
        description += '| Policy Reference | ' + (gap.Policy_Reference__c != null ? gap.Policy_Reference__c : 'N/A') + ' |\n\n';

        if (String.isNotBlank(gap.Gap_Description__c)) {
            description += '*Gap Description*\n' + gap.Gap_Description__c + '\n\n';
        }

        if (String.isNotBlank(gap.Remediation_Plan__c)) {
            description += '*Remediation Plan*\n' + gap.Remediation_Plan__c + '\n\n';
        }

        description += '_Created by Elaro Compliance Platform_\n';
        description += 'Salesforce Record: ' + URL.getOrgDomainUrl().toExternalForm() + '/' + gap.Id;

        return description;
    }

    private static Map<String, Object> buildAtlassianDocumentFormat(String text) {
        // Jira Cloud API v3 requires Atlassian Document Format (ADF) for description/comments
        List<Object> contentParagraphs = new List<Object>();

        for (String line : text.split('\n')) {
            contentParagraphs.add(new Map<String, Object>{
                'type' => 'paragraph',
                'content' => new List<Object>{
                    new Map<String, Object>{
                        'type' => 'text',
                        'text' => line
                    }
                }
            });
        }

        return new Map<String, Object>{
            'type' => 'doc',
            'version' => 1,
            'content' => contentParagraphs
        };
    }

    private static String mapSeverityToJiraPriority(String severity, String override) {
        if (String.isNotBlank(override)) {
            return override;
        }

        Map<String, String> severityToPriority = new Map<String, String>{
            'CRITICAL' => 'Highest',
            'HIGH' => 'High',
            'MEDIUM' => 'Medium',
            'LOW' => 'Low'
        };

        return severityToPriority.containsKey(severity) ? severityToPriority.get(severity) : 'Medium';
    }

    private static String mapJiraStatusToSalesforce(String jiraStatus) {
        if (String.isBlank(jiraStatus)) {
            return null;
        }

        String normalizedStatus = jiraStatus.toLowerCase();

        Map<String, String> statusMapping = new Map<String, String>{
            'to do' => 'OPEN',
            'open' => 'OPEN',
            'in progress' => 'IN_PROGRESS',
            'in review' => 'IN_PROGRESS',
            'done' => 'REMEDIATED',
            'resolved' => 'REMEDIATED',
            'closed' => 'VERIFIED'
        };

        return statusMapping.get(normalizedStatus);
    }

    private static JiraIssue buildJiraIssueFromResponse(Map<String, Object> response, String baseUrl) {
        JiraIssue issue = new JiraIssue();
        issue.key = (String) response.get('key');
        issue.id = (String) response.get('id');
        issue.url = baseUrl + '/browse/' + issue.key;
        issue.status = 'To Do';
        issue.createdAt = Datetime.now();
        return issue;
    }

    private static JiraIssue buildJiraIssueFromFullResponse(Map<String, Object> issueData, String baseUrl) {
        JiraIssue issue = new JiraIssue();
        issue.key = (String) issueData.get('key');
        issue.id = (String) issueData.get('id');
        issue.url = baseUrl + '/browse/' + issue.key;

        Map<String, Object> fields = (Map<String, Object>) issueData.get('fields');
        if (fields != null) {
            issue.summary = (String) fields.get('summary');

            Map<String, Object> statusObj = (Map<String, Object>) fields.get('status');
            if (statusObj != null) {
                issue.status = (String) statusObj.get('name');
            }

            Map<String, Object> priorityObj = (Map<String, Object>) fields.get('priority');
            if (priorityObj != null) {
                issue.priority = (String) priorityObj.get('name');
            }

            Map<String, Object> assigneeObj = (Map<String, Object>) fields.get('assignee');
            if (assigneeObj != null) {
                issue.assignee = (String) assigneeObj.get('displayName');
            }

            String createdStr = (String) fields.get('created');
            if (String.isNotBlank(createdStr)) {
                issue.createdAt = parseJiraDatetime(createdStr);
            }

            String updatedStr = (String) fields.get('updated');
            if (String.isNotBlank(updatedStr)) {
                issue.updatedAt = parseJiraDatetime(updatedStr);
            }
        }

        return issue;
    }

    private static Datetime parseJiraDatetime(String jiraDatetime) {
        // Jira datetime format: 2024-01-15T10:30:00.000+0000
        if (String.isBlank(jiraDatetime)) {
            return null;
        }
        try {
            // Remove timezone offset for parsing
            String dateStr = jiraDatetime.substringBefore('+');
            if (dateStr.contains('-') && dateStr.length() > 10) {
                dateStr = dateStr.substringBefore('.');
            }
            return Datetime.valueOf(dateStr.replace('T', ' '));
        } catch (Exception e) {
            return null;
        }
    }

    private static HttpResponse makeCallout(String method, String endpoint, String body) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL + endpoint);
        req.setMethod(method);
        req.setHeader('Content-Type', 'application/json');
        req.setHeader('Accept', 'application/json');
        req.setTimeout(30000);

        if (String.isNotBlank(body)) {
            req.setBody(body);
        }

        Http http = new Http();
        return http.send(req);
    }

    private static void logError(String operation, String recordId, String errorMessage) {
        // Could log to a custom object for monitoring
        ElaroLogger.error('Jira Integration Error - Operation: ' + operation +
                     ', Record: ' + recordId + ', Error: ' + errorMessage);
    }

    // ============================================
    // Inner Classes
    // ============================================

    /**
     * @description Wrapper class for Jira issue data
     */
    public class JiraIssue {
        @AuraEnabled public String id;
        @AuraEnabled public String key;
        @AuraEnabled public String summary;
        @AuraEnabled public String description;
        @AuraEnabled public String status;
        @AuraEnabled public String priority;
        @AuraEnabled public String assignee;
        @AuraEnabled public String url;
        @AuraEnabled public Datetime createdAt;
        @AuraEnabled public Datetime updatedAt;
    }

    /**
     * @description Wrapper class for Jira transition data
     */
    public class JiraTransition {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
    }

    /**
     * @description Internal settings wrapper
     */
    public class JiraSettings {
        public String jiraInstanceUrl;
        public String projectKey;
        public String issueType;
        public String defaultPriority;
        public Boolean autoCreate;
        public Decimal riskThreshold;
        public Boolean syncEnabled;
    }

    /**
     * @description Custom exception for Jira integration errors
     */
    public class JiraIntegrationException extends Exception {}
}
