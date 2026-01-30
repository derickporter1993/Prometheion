/**
 * @description Test class for JiraWebhookHandler
 * Provides comprehensive coverage for Jira webhook processing
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class JiraWebhookHandlerTest {

    private static final String MOCK_JIRA_KEY = 'COMPLIANCE-456';

    @TestSetup
    static void setupTestData() {
        // Create test settings with webhook secret
        Elaro_Jira_Settings__c settings = new Elaro_Jira_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Jira_Instance_URL__c = 'https://test.atlassian.net',
            Project_Key__c = 'COMPLIANCE',
            Issue_Type__c = 'Task',
            Default_Priority__c = 'High',
            Webhook_Secret__c = 'test-secret-123',
            Sync_Enabled__c = true
        );
        insert settings;

        // Create linked compliance gap
        Compliance_Gap__c gap = new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA-AC-001',
            Severity__c = 'HIGH',
            Status__c = 'OPEN',
            Gap_Description__c = 'Test gap for webhook testing',
            Detected_Date__c = Datetime.now(),
            Jira_Issue_Key__c = MOCK_JIRA_KEY,
            Jira_Issue_URL__c = 'https://test.atlassian.net/browse/' + MOCK_JIRA_KEY,
            Jira_Status__c = 'To Do',
            Notes__c = 'Initial notes'
        );
        insert gap;
    }

    // ============================================
    // Issue Updated Tests
    // ============================================

    @isTest
    static void testHandleWebhook_IssueUpdated_StatusChange() {
        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'In Progress');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');

        // Verify gap was updated
        Compliance_Gap__c updatedGap = [SELECT Jira_Status__c, Status__c FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = :MOCK_JIRA_KEY];
        System.assertEquals('In Progress', updatedGap.Jira_Status__c, 'Jira status should be updated');
        System.assertEquals('IN_PROGRESS', updatedGap.Status__c, 'Salesforce status should be mapped');
    }

    @isTest
    static void testHandleWebhook_IssueUpdated_StatusDone() {
        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'Done');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');

        Compliance_Gap__c updatedGap = [SELECT Status__c FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = :MOCK_JIRA_KEY];
        System.assertEquals('REMEDIATED', updatedGap.Status__c, 'Should map Done to REMEDIATED');
    }

    @isTest
    static void testHandleWebhook_IssueUpdated_NoLinkedGap() {
        String payload = buildIssueUpdatedPayload('NONEXISTENT-999', 'Done');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200 even if no linked gap');
    }

    @isTest
    static void testHandleWebhook_IssueUpdated_SameStatus() {
        // First update gap to have "In Progress" status
        Compliance_Gap__c gap = [SELECT Id, Jira_Status__c FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = :MOCK_JIRA_KEY];
        gap.Jira_Status__c = 'In Progress';
        update gap;

        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'In Progress');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');
        // Response should indicate status unchanged
    }

    // ============================================
    // Issue Deleted Tests
    // ============================================

    @isTest
    static void testHandleWebhook_IssueDeleted() {
        String payload = buildIssueDeletedPayload(MOCK_JIRA_KEY);

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');

        // Verify Jira link was cleared
        Compliance_Gap__c updatedGap = [SELECT Jira_Issue_Key__c, Jira_Issue_URL__c, Jira_Status__c FROM Compliance_Gap__c LIMIT 1];
        System.assertEquals(null, updatedGap.Jira_Issue_Key__c, 'Jira key should be cleared');
        System.assertEquals(null, updatedGap.Jira_Issue_URL__c, 'Jira URL should be cleared');
        System.assertEquals(null, updatedGap.Jira_Status__c, 'Jira status should be cleared');
    }

    @isTest
    static void testHandleWebhook_IssueDeleted_NoLinkedGap() {
        String payload = buildIssueDeletedPayload('NONEXISTENT-999');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');
    }

    // ============================================
    // Comment Created Tests
    // ============================================

    @isTest
    static void testHandleWebhook_CommentCreated() {
        String payload = buildCommentCreatedPayload(MOCK_JIRA_KEY, 'John Doe', 'This is a test comment');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');

        // Verify comment was added to notes
        Compliance_Gap__c updatedGap = [SELECT Notes__c FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = :MOCK_JIRA_KEY];
        System.assert(updatedGap.Notes__c.contains('This is a test comment'), 'Notes should contain comment');
        System.assert(updatedGap.Notes__c.contains('John Doe'), 'Notes should contain author');
    }

    @isTest
    static void testHandleWebhook_CommentCreated_AdfFormat() {
        String payload = buildCommentCreatedPayloadAdf(MOCK_JIRA_KEY, 'Jane Smith', 'ADF formatted comment');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200');
    }

    // ============================================
    // Security Tests
    // ============================================

    @isTest
    static void testHandleWebhook_InvalidSecret() {
        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'Done');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'wrong-secret');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(401, res.statusCode, 'Should return 401 for invalid secret');
    }

    @isTest
    static void testHandleWebhook_NoSecretConfigured() {
        // Remove webhook secret from settings
        Elaro_Jira_Settings__c settings = Elaro_Jira_Settings__c.getOrgDefaults();
        settings.Webhook_Secret__c = null;
        update settings;

        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'Done');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        // No secret header

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should allow if no secret configured');
    }

    @isTest
    static void testHandleWebhook_LowercaseSecretHeader() {
        String payload = buildIssueUpdatedPayload(MOCK_JIRA_KEY, 'Done');

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('x-atlassian-webhook-secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should accept lowercase header');
    }

    // ============================================
    // Error Handling Tests
    // ============================================

    @isTest
    static void testHandleWebhook_MissingWebhookEvent() {
        String payload = '{"issue": {"key": "TEST-123"}}';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(400, res.statusCode, 'Should return 400 for missing event');
    }

    @isTest
    static void testHandleWebhook_UnsupportedEvent() {
        String payload = '{"webhookEvent": "unsupported:event", "issue": {"key": "TEST-123"}}';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(200, res.statusCode, 'Should return 200 for unsupported events');
    }

    @isTest
    static void testHandleWebhook_MissingIssueData() {
        String payload = '{"webhookEvent": "jira:issue_updated"}';

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf(payload);
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Should return 500 for missing issue data');
    }

    @isTest
    static void testHandleWebhook_InvalidJson() {
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/jira/webhook';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('not valid json');
        req.headers.put('X-Atlassian-Webhook-Secret', 'test-secret-123');

        RestResponse res = new RestResponse();

        RestContext.request = req;
        RestContext.response = res;

        Test.startTest();
        JiraWebhookHandler.handleWebhook();
        Test.stopTest();

        System.assertEquals(500, res.statusCode, 'Should return 500 for invalid JSON');
    }

    // ============================================
    // Helper Methods
    // ============================================

    private static String buildIssueUpdatedPayload(String issueKey, String status) {
        return '{' +
            '"webhookEvent": "jira:issue_updated",' +
            '"issue": {' +
                '"key": "' + issueKey + '",' +
                '"fields": {' +
                    '"status": {' +
                        '"name": "' + status + '"' +
                    '}' +
                '}' +
            '}' +
        '}';
    }

    private static String buildIssueDeletedPayload(String issueKey) {
        return '{' +
            '"webhookEvent": "jira:issue_deleted",' +
            '"issue": {' +
                '"key": "' + issueKey + '"' +
            '}' +
        '}';
    }

    private static String buildCommentCreatedPayload(String issueKey, String authorName, String commentText) {
        return '{' +
            '"webhookEvent": "comment_created",' +
            '"issue": {' +
                '"key": "' + issueKey + '"' +
            '},' +
            '"comment": {' +
                '"author": {' +
                    '"displayName": "' + authorName + '"' +
                '},' +
                '"body": "' + commentText + '"' +
            '}' +
        '}';
    }

    private static String buildCommentCreatedPayloadAdf(String issueKey, String authorName, String commentText) {
        return '{' +
            '"webhookEvent": "comment_created",' +
            '"issue": {' +
                '"key": "' + issueKey + '"' +
            '},' +
            '"comment": {' +
                '"author": {' +
                    '"displayName": "' + authorName + '"' +
                '},' +
                '"body": {' +
                    '"type": "doc",' +
                    '"version": 1,' +
                    '"content": [' +
                        '{' +
                            '"type": "paragraph",' +
                            '"content": [' +
                                '{"type": "text", "text": "' + commentText + '"}' +
                            ']' +
                        '}' +
                    ']' +
                '}' +
            '}' +
        '}';
    }
}
