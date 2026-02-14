/**
 * @description REST resource for handling incoming Jira webhooks.
 * Enables bidirectional sync between Jira issues and Salesforce Compliance_Gap__c records.
 *
 * Supported webhook events:
 * - jira:issue_updated - Syncs status changes back to Salesforce
 * - jira:issue_deleted - Clears Jira link from gap
 * - comment_created - Optionally logs comments to Salesforce
 *
 * Configuration:
 * 1. Create a Site in Salesforce with this class as a guest user service
 * 2. Configure webhook in Jira pointing to: https://your-site.force.com/services/apexrest/jira/webhook
 * 3. Set webhook secret in Elaro_Jira_Settings__c.Webhook_Secret__c
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
@RestResource(urlMapping='/jira/webhook/*')
global with sharing class JiraWebhookHandler {

    private static final String LOG_SOURCE = 'JiraWebhookHandler';

    /**
     * @description Handles incoming POST requests from Jira webhooks
     */
    @HttpPost
    global static void handleWebhook() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;

        try {
            // Validate webhook secret if configured
            if (!validateWebhookSecret(req)) {
                res.statusCode = 401;
                res.responseBody = Blob.valueOf('{"error": "Invalid webhook secret"}');
                return;
            }

            String body = req.requestBody.toString();
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(body);

            String webhookEvent = (String) payload.get('webhookEvent');

            if (String.isBlank(webhookEvent)) {
                res.statusCode = 400;
                res.responseBody = Blob.valueOf('{"error": "Missing webhookEvent"}');
                return;
            }

            WebhookResult result;

            if (webhookEvent.startsWith('jira:issue_updated')) {
                result = handleIssueUpdated(payload);
            } else if (webhookEvent.startsWith('jira:issue_deleted')) {
                result = handleIssueDeleted(payload);
            } else if (webhookEvent.startsWith('comment_created')) {
                result = handleCommentCreated(payload);
            } else {
                // Acknowledge but ignore unsupported events
                result = new WebhookResult(true, 'Event ignored: ' + webhookEvent);
            }

            res.statusCode = result.success ? 200 : 500;
            res.responseBody = Blob.valueOf(JSON.serialize(result));

        } catch (Exception e) {
            ElaroLogger.error( LOG_SOURCE + ' error: ' + e.getMessage() + '\n' + e.getStackTraceString());
            res.statusCode = 500;
            res.responseBody = Blob.valueOf('{"error": "' + e.getMessage().escapeJava() + '"}');
        }
    }

    /**
     * @description Handles issue updated events - syncs status to Salesforce
     * @param payload The webhook payload
     * @return WebhookResult indicating success or failure
     */
    private static WebhookResult handleIssueUpdated(Map<String, Object> payload) {
        Map<String, Object> issue = (Map<String, Object>) payload.get('issue');
        if (issue == null) {
            return new WebhookResult(false, 'Missing issue data');
        }

        String issueKey = (String) issue.get('key');
        if (String.isBlank(issueKey)) {
            return new WebhookResult(false, 'Missing issue key');
        }

        // Find linked Compliance_Gap__c
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Status__c, Jira_Issue_Key__c, Jira_Status__c
            FROM Compliance_Gap__c
            WHERE Jira_Issue_Key__c = :issueKey
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            return new WebhookResult(true, 'No linked gap found for ' + issueKey);
        }

        Compliance_Gap__c gap = gaps[0];

        // Extract new status from issue fields
        Map<String, Object> fields = (Map<String, Object>) issue.get('fields');
        String newJiraStatus = null;

        if (fields != null) {
            Map<String, Object> status = (Map<String, Object>) fields.get('status');
            if (status != null) {
                newJiraStatus = (String) status.get('name');
            }
        }

        if (String.isBlank(newJiraStatus)) {
            return new WebhookResult(true, 'No status change detected');
        }

        // Check if status actually changed
        if (newJiraStatus.equals(gap.Jira_Status__c)) {
            return new WebhookResult(true, 'Status unchanged');
        }

        // Update Salesforce record
        gap.Jira_Status__c = newJiraStatus;
        gap.Jira_Last_Sync__c = Datetime.now();

        // Map Jira status to Salesforce status
        String newSalesforceStatus = mapJiraStatusToSalesforce(newJiraStatus);
        if (String.isNotBlank(newSalesforceStatus) && newSalesforceStatus != gap.Status__c) {
            gap.Status__c = newSalesforceStatus;
        }

        if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
            update as user gap;
        }

        return new WebhookResult(true, 'Updated gap ' + gap.Name + ' with status ' + newJiraStatus);
    }

    /**
     * @description Handles issue deleted events - clears Jira link from gap
     * @param payload The webhook payload
     * @return WebhookResult indicating success or failure
     */
    private static WebhookResult handleIssueDeleted(Map<String, Object> payload) {
        Map<String, Object> issue = (Map<String, Object>) payload.get('issue');
        if (issue == null) {
            return new WebhookResult(false, 'Missing issue data');
        }

        String issueKey = (String) issue.get('key');
        if (String.isBlank(issueKey)) {
            return new WebhookResult(false, 'Missing issue key');
        }

        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Jira_Issue_Key__c, Jira_Issue_URL__c, Jira_Status__c, Jira_Last_Sync__c
            FROM Compliance_Gap__c
            WHERE Jira_Issue_Key__c = :issueKey
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            return new WebhookResult(true, 'No linked gap found for ' + issueKey);
        }

        Compliance_Gap__c gap = gaps[0];

        // Clear Jira fields
        gap.Jira_Issue_Key__c = null;
        gap.Jira_Issue_URL__c = null;
        gap.Jira_Status__c = null;
        gap.Jira_Last_Sync__c = null;

        if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
            update as user gap;
        }

        return new WebhookResult(true, 'Cleared Jira link from gap ' + gap.Name);
    }

    /**
     * @description Handles comment created events - logs comment to Salesforce notes
     * @param payload The webhook payload
     * @return WebhookResult indicating success or failure
     */
    private static WebhookResult handleCommentCreated(Map<String, Object> payload) {
        Map<String, Object> issue = (Map<String, Object>) payload.get('issue');
        Map<String, Object> comment = (Map<String, Object>) payload.get('comment');

        if (issue == null || comment == null) {
            return new WebhookResult(false, 'Missing issue or comment data');
        }

        String issueKey = (String) issue.get('key');
        if (String.isBlank(issueKey)) {
            return new WebhookResult(false, 'Missing issue key');
        }

        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Notes__c
            FROM Compliance_Gap__c
            WHERE Jira_Issue_Key__c = :issueKey
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            return new WebhookResult(true, 'No linked gap found for ' + issueKey);
        }

        Compliance_Gap__c gap = gaps[0];

        // Extract comment author and body
        Map<String, Object> author = (Map<String, Object>) comment.get('author');
        String authorName = author != null ? (String) author.get('displayName') : 'Unknown';
        String commentBody = extractCommentBody(comment);

        if (String.isBlank(commentBody)) {
            return new WebhookResult(true, 'Empty comment body');
        }

        // Append to notes
        String timestamp = Datetime.now().format('yyyy-MM-dd HH:mm');
        String noteEntry = '\n\n--- Jira Comment (' + timestamp + ') ---\n';
        noteEntry += 'From: ' + authorName + '\n';
        noteEntry += commentBody;

        gap.Notes__c = (gap.Notes__c != null ? gap.Notes__c : '') + noteEntry;

        if (Schema.sObjectType.Compliance_Gap__c.isUpdateable()) {
            update as user gap;
        }

        return new WebhookResult(true, 'Added comment to gap ' + gap.Name);
    }

    /**
     * @description Validates the webhook secret from request headers
     * @param req The REST request
     * @return True if valid or no secret configured
     */
    private static Boolean validateWebhookSecret(RestRequest req) {
        Elaro_Jira_Settings__c settings = Elaro_Jira_Settings__c.getOrgDefaults();

        if (String.isBlank(settings.Webhook_Secret__c)) {
            // No secret configured - allow all requests (not recommended for production)
            return true;
        }

        String providedSecret = req.headers.get('X-Atlassian-Webhook-Secret');
        if (providedSecret == null) {
            providedSecret = req.headers.get('x-atlassian-webhook-secret');
        }

        return settings.Webhook_Secret__c.equals(providedSecret);
    }

    /**
     * @description Maps Jira status to Salesforce gap status
     * @param jiraStatus The Jira status name
     * @return The corresponding Salesforce status, or null if no mapping
     */
    private static String mapJiraStatusToSalesforce(String jiraStatus) {
        if (String.isBlank(jiraStatus)) {
            return null;
        }

        String normalizedStatus = jiraStatus.toLowerCase();

        Map<String, String> statusMapping = new Map<String, String>{
            'to do' => 'OPEN',
            'open' => 'OPEN',
            'backlog' => 'OPEN',
            'in progress' => 'IN_PROGRESS',
            'in review' => 'IN_PROGRESS',
            'in development' => 'IN_PROGRESS',
            'done' => 'REMEDIATED',
            'resolved' => 'REMEDIATED',
            'completed' => 'REMEDIATED',
            'closed' => 'VERIFIED',
            'verified' => 'VERIFIED'
        };

        return statusMapping.get(normalizedStatus);
    }

    /**
     * @description Extracts plain text from Jira comment body (handles ADF format)
     * @param comment The comment object from webhook
     * @return Plain text comment content
     */
    private static String extractCommentBody(Map<String, Object> comment) {
        // Try to get body directly (older format)
        Object bodyObj = comment.get('body');

        if (bodyObj instanceof String) {
            return (String) bodyObj;
        }

        // Handle Atlassian Document Format (ADF)
        if (bodyObj instanceof Map<String, Object>) {
            return extractTextFromAdf((Map<String, Object>) bodyObj);
        }

        return '';
    }

    /**
     * @description Recursively extracts text from Atlassian Document Format
     * @param adfNode The ADF node
     * @return Concatenated plain text
     */
    private static String extractTextFromAdf(Map<String, Object> adfNode) {
        String result = '';

        String nodeType = (String) adfNode.get('type');

        if (nodeType == 'text') {
            String text = (String) adfNode.get('text');
            if (String.isNotBlank(text)) {
                result += text;
            }
        }

        List<Object> content = (List<Object>) adfNode.get('content');
        if (content != null) {
            for (Object child : content) {
                if (child instanceof Map<String, Object>) {
                    result += extractTextFromAdf((Map<String, Object>) child);
                }
            }
        }

        // Add newline after paragraphs
        if (nodeType == 'paragraph') {
            result += '\n';
        }

        return result;
    }

    /**
     * @description Result wrapper for webhook processing
     */
    global class WebhookResult {
        public Boolean success;
        public String message;
        public Datetime processedAt;

        public WebhookResult(Boolean success, String message) {
            this.success = success;
            this.message = message;
            this.processedAt = Datetime.now();
        }
    }
}
