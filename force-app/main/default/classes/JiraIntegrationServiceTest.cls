/**
 * @description Test class for JiraIntegrationService
 * Provides comprehensive coverage for Jira integration functionality
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class JiraIntegrationServiceTest {

    private static final String MOCK_JIRA_KEY = 'COMPLIANCE-123';
    private static final String MOCK_JIRA_ID = '10001';

    @TestSetup
    static void setupTestData() {
        // Create test settings
        Elaro_Jira_Settings__c settings = new Elaro_Jira_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Jira_Instance_URL__c = 'https://test.atlassian.net',
            Project_Key__c = 'COMPLIANCE',
            Issue_Type__c = 'Task',
            Default_Priority__c = 'High',
            Auto_Create_Enabled__c = false,
            Risk_Threshold__c = 8.0,
            Sync_Enabled__c = true
        );
        insert settings;

        // Create test compliance gap
        Compliance_Gap__c gap = new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA-AC-001',
            Severity__c = 'HIGH',
            Status__c = 'OPEN',
            Gap_Description__c = 'Test gap for Jira integration',
            Remediation_Plan__c = 'Fix the issue',
            Risk_Score__c = 8.5,
            Detected_Date__c = Datetime.now()
        );
        insert gap;

        // Create linked gap for sync tests
        Compliance_Gap__c linkedGap = new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2-CC6.1',
            Severity__c = 'CRITICAL',
            Status__c = 'IN_PROGRESS',
            Gap_Description__c = 'Linked gap for sync testing',
            Risk_Score__c = 9.0,
            Detected_Date__c = Datetime.now(),
            Jira_Issue_Key__c = MOCK_JIRA_KEY,
            Jira_Issue_URL__c = 'https://test.atlassian.net/browse/' + MOCK_JIRA_KEY,
            Jira_Status__c = 'In Progress'
        );
        insert linkedGap;
    }

    // ============================================
    // Create Issue Tests
    // ============================================

    @isTest
    static void testCreateIssue_Success() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = NULL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new JiraCreateIssueMock(true));

        Test.startTest();
        JiraIntegrationService.JiraIssue result = JiraIntegrationService.createIssue(gap.Id, null);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return issue');
        System.assertEquals(MOCK_JIRA_KEY, result.key, 'Should have correct key');

        // Verify gap was updated
        Compliance_Gap__c updatedGap = [SELECT Jira_Issue_Key__c, Jira_Issue_URL__c FROM Compliance_Gap__c WHERE Id = :gap.Id];
        System.assertEquals(MOCK_JIRA_KEY, updatedGap.Jira_Issue_Key__c, 'Gap should be linked to Jira');
        System.assertNotEquals(null, updatedGap.Jira_Issue_URL__c, 'Gap should have Jira URL');
    }

    @isTest
    static void testCreateIssue_WithPriorityOverride() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = NULL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new JiraCreateIssueMock(true));

        Test.startTest();
        JiraIntegrationService.JiraIssue result = JiraIntegrationService.createIssue(gap.Id, 'Highest');
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return issue');
    }

    @isTest
    static void testCreateIssue_AlreadyLinked() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c != NULL LIMIT 1];

        Test.startTest();
        try {
            JiraIntegrationService.createIssue(gap.Id, null);
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('already exists'), 'Should mention existing issue');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateIssue_ApiFailure() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = NULL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new JiraCreateIssueMock(false));

        Test.startTest();
        try {
            JiraIntegrationService.createIssue(gap.Id, null);
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('Failed'), 'Should indicate failure');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateIssue_InvalidGapId() {
        Test.startTest();
        try {
            JiraIntegrationService.createIssue('001000000000000AAA', null);
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('not found'), 'Should indicate not found');
        }
        Test.stopTest();
    }

    @isTest
    static void testCreateIssueAsync() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = NULL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new JiraCreateIssueMock(true));

        Test.startTest();
        JiraIntegrationService.createIssueAsync(gap.Id, 'High');
        Test.stopTest();

        // Future method execution - verify no exception thrown
        System.assert(true, 'Async method should complete');
    }

    // ============================================
    // Get Issue Tests
    // ============================================

    @isTest
    static void testGetIssueStatus_Success() {
        Test.setMock(HttpCalloutMock.class, new JiraGetIssueMock(true));

        Test.startTest();
        JiraIntegrationService.JiraIssue result = JiraIntegrationService.getIssueStatus(MOCK_JIRA_KEY);
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should return issue');
        System.assertEquals(MOCK_JIRA_KEY, result.key, 'Should have correct key');
        System.assertEquals('In Progress', result.status, 'Should have status');
    }

    @isTest
    static void testGetIssueStatus_NotFound() {
        Test.setMock(HttpCalloutMock.class, new JiraGetIssueMock(false));

        Test.startTest();
        try {
            JiraIntegrationService.getIssueStatus('INVALID-999');
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('not found'), 'Should indicate not found');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetIssueStatus_BlankKey() {
        Test.startTest();
        try {
            JiraIntegrationService.getIssueStatus('');
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('required'), 'Should indicate key required');
        }
        Test.stopTest();
    }

    // ============================================
    // Sync Tests
    // ============================================

    @isTest
    static void testSyncIssueStatus() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c != NULL LIMIT 1];

        Test.setMock(HttpCalloutMock.class, new JiraGetIssueMock(true));

        Test.startTest();
        JiraIntegrationService.syncIssueStatus(gap.Id);
        Test.stopTest();

        Compliance_Gap__c updatedGap = [SELECT Jira_Status__c, Jira_Last_Sync__c FROM Compliance_Gap__c WHERE Id = :gap.Id];
        System.assertEquals('In Progress', updatedGap.Jira_Status__c, 'Status should be synced');
        System.assertNotEquals(null, updatedGap.Jira_Last_Sync__c, 'Sync timestamp should be set');
    }

    @isTest
    static void testSyncIssueStatus_NoJiraLink() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Jira_Issue_Key__c = NULL LIMIT 1];

        Test.startTest();
        try {
            JiraIntegrationService.syncIssueStatus(gap.Id);
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('No Jira issue'), 'Should indicate no link');
        }
        Test.stopTest();
    }

    // ============================================
    // Bulk Operations Tests
    // ============================================

    @isTest
    static void testCreateBulkIssues() {
        List<Compliance_Gap__c> newGaps = new List<Compliance_Gap__c>();
        for (Integer i = 0; i < 3; i++) {
            newGaps.add(new Compliance_Gap__c(
                Framework__c = 'NIST',
                Policy_Reference__c = 'NIST-AC-' + i,
                Severity__c = 'MEDIUM',
                Status__c = 'OPEN',
                Gap_Description__c = 'Bulk test gap ' + i,
                Detected_Date__c = Datetime.now()
            ));
        }
        insert newGaps;

        List<String> gapIds = new List<String>();
        for (Compliance_Gap__c g : newGaps) {
            gapIds.add(g.Id);
        }

        Test.setMock(HttpCalloutMock.class, new JiraCreateIssueMock(true));

        Test.startTest();
        List<JiraIntegrationService.JiraIssue> results = JiraIntegrationService.createBulkIssues(gapIds);
        Test.stopTest();

        System.assertEquals(3, results.size(), 'Should create issues for all gaps');
    }

    // ============================================
    // Comment Tests
    // ============================================

    @isTest
    static void testAddComment_Success() {
        Test.setMock(HttpCalloutMock.class, new JiraCommentMock(true));

        Test.startTest();
        JiraIntegrationService.addComment(MOCK_JIRA_KEY, 'Test comment from Salesforce');
        Test.stopTest();

        // No exception = success
        System.assert(true, 'Comment should be added');
    }

    @isTest
    static void testAddComment_BlankParams() {
        Test.startTest();
        try {
            JiraIntegrationService.addComment('', '');
            System.assert(false, 'Should have thrown exception');
        } catch (JiraIntegrationService.JiraIntegrationException e) {
            System.assert(e.getMessage().contains('required'), 'Should indicate required params');
        }
        Test.stopTest();
    }

    // ============================================
    // Transition Tests
    // ============================================

    @isTest
    static void testGetAvailableTransitions() {
        Test.setMock(HttpCalloutMock.class, new JiraTransitionsMock());

        Test.startTest();
        List<JiraIntegrationService.JiraTransition> transitions = JiraIntegrationService.getAvailableTransitions(MOCK_JIRA_KEY);
        Test.stopTest();

        System.assertNotEquals(null, transitions, 'Should return transitions');
        System.assert(transitions.size() > 0, 'Should have at least one transition');
    }

    @isTest
    static void testTransitionIssue() {
        Test.setMock(HttpCalloutMock.class, new JiraTransitionMock(true));

        Test.startTest();
        JiraIntegrationService.transitionIssue(MOCK_JIRA_KEY, '21');
        Test.stopTest();

        System.assert(true, 'Transition should complete');
    }

    // ============================================
    // Configuration Tests
    // ============================================

    @isTest
    static void testIsConfigured_True() {
        Test.setMock(HttpCalloutMock.class, new JiraProjectMock(true));

        Test.startTest();
        Boolean configured = JiraIntegrationService.isConfigured();
        Test.stopTest();

        System.assertEquals(true, configured, 'Should be configured');
    }

    @isTest
    static void testIsConfigured_False() {
        // Clear settings
        delete [SELECT Id FROM Elaro_Jira_Settings__c];

        Test.startTest();
        Boolean configured = JiraIntegrationService.isConfigured();
        Test.stopTest();

        System.assertEquals(false, configured, 'Should not be configured');
    }

    @isTest
    static void testGetLinkedGaps() {
        Test.startTest();
        List<Compliance_Gap__c> linkedGaps = JiraIntegrationService.getLinkedGaps();
        Test.stopTest();

        System.assertEquals(1, linkedGaps.size(), 'Should find one linked gap');
        System.assertEquals(MOCK_JIRA_KEY, linkedGaps[0].Jira_Issue_Key__c, 'Should have correct Jira key');
    }

    // ============================================
    // Mock Classes
    // ============================================

    private class JiraCreateIssueMock implements HttpCalloutMock {
        private Boolean success;

        public JiraCreateIssueMock(Boolean success) {
            this.success = success;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (success) {
                res.setStatusCode(201);
                res.setBody('{"id": "' + MOCK_JIRA_ID + '", "key": "' + MOCK_JIRA_KEY + '", "self": "https://test.atlassian.net/rest/api/3/issue/' + MOCK_JIRA_ID + '"}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"errorMessages": ["Project does not exist"]}');
            }

            return res;
        }
    }

    private class JiraGetIssueMock implements HttpCalloutMock {
        private Boolean found;

        public JiraGetIssueMock(Boolean found) {
            this.found = found;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (found) {
                res.setStatusCode(200);
                res.setBody('{' +
                    '"id": "' + MOCK_JIRA_ID + '",' +
                    '"key": "' + MOCK_JIRA_KEY + '",' +
                    '"fields": {' +
                        '"summary": "Test Issue",' +
                        '"status": {"name": "In Progress"},' +
                        '"priority": {"name": "High"},' +
                        '"assignee": {"displayName": "John Doe"},' +
                        '"created": "2024-01-15T10:30:00.000+0000",' +
                        '"updated": "2024-01-16T14:00:00.000+0000"' +
                    '}' +
                '}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"errorMessages": ["Issue does not exist"]}');
            }

            return res;
        }
    }

    private class JiraCommentMock implements HttpCalloutMock {
        private Boolean success;

        public JiraCommentMock(Boolean success) {
            this.success = success;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (success) {
                res.setStatusCode(201);
                res.setBody('{"id": "10000", "body": {"type": "doc", "version": 1, "content": []}}');
            } else {
                res.setStatusCode(400);
                res.setBody('{"errorMessages": ["Comment failed"]}');
            }

            return res;
        }
    }

    private class JiraTransitionsMock implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"transitions": [{"id": "21", "name": "Done"}, {"id": "31", "name": "In Progress"}]}');
            return res;
        }
    }

    private class JiraTransitionMock implements HttpCalloutMock {
        private Boolean success;

        public JiraTransitionMock(Boolean success) {
            this.success = success;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();

            if (success) {
                res.setStatusCode(204);
            } else {
                res.setStatusCode(400);
                res.setBody('{"errorMessages": ["Invalid transition"]}');
            }

            return res;
        }
    }

    private class JiraProjectMock implements HttpCalloutMock {
        private Boolean exists;

        public JiraProjectMock(Boolean exists) {
            this.exists = exists;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');

            if (exists) {
                res.setStatusCode(200);
                res.setBody('{"id": "10000", "key": "COMPLIANCE", "name": "Compliance Project"}');
            } else {
                res.setStatusCode(404);
                res.setBody('{"errorMessages": ["Project not found"]}');
            }

            return res;
        }
    }
}
