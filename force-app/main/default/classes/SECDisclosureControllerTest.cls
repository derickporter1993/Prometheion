/**
 * Integration test class for {@link SECDisclosureController}. Tests the
 * AuraEnabled controller methods that delegate to service classes,
 * covering the full SEC disclosure module workflow from assessment
 * creation through filing.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see SECDisclosureController
 */
@IsTest
private class SECDisclosureControllerTest {

    @TestSetup
    static void makeData() {
        Materiality_Assessment__c ma = new Materiality_Assessment__c(
            Incident_Description__c = 'Test incident for controller integration',
            Discovery_Date__c = DateTime.now().addDays(-5),
            Status__c = 'Draft'
        );
        insert as user ma;
    }

    /**
     * Verify createAssessment returns a valid record Id.
     */
    @IsTest
    static void testCreateAssessment_returnsId() {
        String discoveryDate = String.valueOf(DateTime.now());

        Test.startTest();
        Id assessmentId = SECDisclosureController.createAssessment(
            'New incident from controller test', discoveryDate
        );
        Test.stopTest();

        Assert.isNotNull(assessmentId, 'Should return a valid assessment Id');

        Materiality_Assessment__c queried = [
            SELECT Incident_Description__c, Status__c
            FROM Materiality_Assessment__c
            WHERE Id = :assessmentId
            WITH USER_MODE
        ];
        Assert.areEqual('Draft', queried.Status__c, 'New assessment should be in Draft status');
    }

    /**
     * Verify getAssessment returns assessment with timeline events.
     */
    @IsTest
    static void testGetAssessment_withTimeline() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        // Add a timeline event
        Incident_Timeline__c evt = new Incident_Timeline__c(
            Materiality_Assessment__c = ma.Id,
            Event_Date__c = DateTime.now().addDays(-4),
            Event_Type__c = 'Detection',
            Event_Description__c = 'Threat detected',
            Performed_By__c = 'SOC'
        );
        insert as user evt;

        Test.startTest();
        Materiality_Assessment__c result = SECDisclosureController.getAssessment(String.valueOf(ma.Id));
        Test.stopTest();

        Assert.isNotNull(result, 'Should return the assessment');
        Assert.areEqual(ma.Id, result.Id, 'Should return the correct assessment');
        Assert.areEqual(1, result.Incident_Timelines__r.size(), 'Should include timeline events');
    }

    /**
     * Verify submitDetermination sets filing deadline through the controller.
     */
    @IsTest
    static void testSubmitDetermination_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        String determinationDate = String.valueOf(DateTime.newInstance(2026, 1, 5, 10, 0, 0));

        Test.startTest();
        SECDisclosureController.submitDetermination(
            String.valueOf(ma.Id), 'Material', determinationDate
        );
        Test.stopTest();

        Materiality_Assessment__c updated = [
            SELECT Status__c, Filing_Deadline__c, Determination_Result__c
            FROM Materiality_Assessment__c
            WHERE Id = :ma.Id
            WITH USER_MODE
        ];
        Assert.areEqual('Determined', updated.Status__c, 'Status should be Determined');
        Assert.isNotNull(updated.Filing_Deadline__c, 'Filing deadline should be calculated');
    }

    /**
     * Verify createWorkflow returns a valid workflow Id.
     */
    @IsTest
    static void testCreateWorkflow_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        Test.startTest();
        Id workflowId = SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');
        Test.stopTest();

        Assert.isNotNull(workflowId, 'Should return a valid workflow Id');

        Disclosure_Workflow__c queried = [
            SELECT Form_Type__c, Status__c
            FROM Disclosure_Workflow__c
            WHERE Id = :workflowId
            WITH USER_MODE
        ];
        Assert.areEqual('8-K', queried.Form_Type__c, 'Form type should be 8-K');
        Assert.areEqual('Drafting', queried.Status__c, 'Initial status should be Drafting');
    }

    /**
     * Verify advanceWorkflow transitions status correctly.
     */
    @IsTest
    static void testAdvanceWorkflow_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Id workflowId = SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');

        Test.startTest();
        SECDisclosureController.advanceWorkflow(
            String.valueOf(workflowId), 'Legal_Review', 'Advancing to legal review'
        );
        Test.stopTest();

        Disclosure_Workflow__c updated = [
            SELECT Status__c FROM Disclosure_Workflow__c WHERE Id = :workflowId WITH USER_MODE
        ];
        Assert.areEqual('Legal_Review', updated.Status__c, 'Status should be Legal_Review');
    }

    /**
     * Verify recordFiling sets EDGAR number and filing metadata.
     */
    @IsTest
    static void testRecordFiling_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Id workflowId = SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');

        // Walk through the approval chain
        SECDisclosureController.advanceWorkflow(String.valueOf(workflowId), 'Legal_Review', 'ok');
        SECDisclosureController.advanceWorkflow(String.valueOf(workflowId), 'CFO_Review', 'ok');
        SECDisclosureController.advanceWorkflow(String.valueOf(workflowId), 'CEO_Approval', 'ok');
        SECDisclosureController.advanceWorkflow(String.valueOf(workflowId), 'Board_Review', 'ok');
        SECDisclosureController.advanceWorkflow(String.valueOf(workflowId), 'Ready_To_File', 'ok');

        Test.startTest();
        SECDisclosureController.recordFiling(String.valueOf(workflowId), 'EDGAR-2026-TEST');
        Test.stopTest();

        Disclosure_Workflow__c filed = [
            SELECT EDGAR_Filing_Number__c, Status__c, Filed_By__c
            FROM Disclosure_Workflow__c
            WHERE Id = :workflowId
            WITH USER_MODE
        ];
        Assert.areEqual('EDGAR-2026-TEST', filed.EDGAR_Filing_Number__c, 'EDGAR number should be set');
        Assert.areEqual('Filed', filed.Status__c, 'Status should be Filed');
    }

    /**
     * Verify getOpenAssessments returns a list from the controller.
     */
    @IsTest
    static void testGetOpenAssessments_returnsList() {
        Test.startTest();
        List<Materiality_Assessment__c> results = SECDisclosureController.getOpenAssessments();
        Test.stopTest();

        Assert.isFalse(results.isEmpty(), 'Should return at least 1 open assessment');
    }

    /**
     * Verify createGovernanceReport returns a valid report Id.
     */
    @IsTest
    static void testCreateGovernanceReport_success() {
        Test.startTest();
        Id reportId = SECDisclosureController.createGovernanceReport('FY2025', '10-K');
        Test.stopTest();

        Assert.isNotNull(reportId, 'Should return a valid governance report Id');

        Board_Governance_Report__c queried = [
            SELECT Report_Period__c, Report_Type__c, Status__c
            FROM Board_Governance_Report__c
            WHERE Id = :reportId
            WITH USER_MODE
        ];
        Assert.areEqual('FY2025', queried.Report_Period__c, 'Period should match');
        Assert.areEqual('Draft', queried.Status__c, 'Initial status should be Draft');
    }

    /**
     * Verify getGovernanceReports returns reports for the given period.
     */
    @IsTest
    static void testGetGovernanceReports_returnsList() {
        SECDisclosureController.createGovernanceReport('FY2025', '10-K');

        Test.startTest();
        List<Board_Governance_Report__c> reports = SECDisclosureController.getGovernanceReports('FY2025');
        Test.stopTest();

        Assert.areEqual(1, reports.size(), 'Should return 1 report for FY2025');
    }

    /**
     * Verify invalid Id string throws user-friendly exception.
     */
    @IsTest
    static void testInvalidId_throwsException() {
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            SECDisclosureController.getAssessment('INVALID_ID_STRING');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException for invalid Id');
    }

    /**
     * Verify addTimelineEvent creates and returns an event through the controller.
     */
    @IsTest
    static void testAddTimelineEvent_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        String eventDate = String.valueOf(DateTime.now());

        Test.startTest();
        Id eventId = SECDisclosureController.addTimelineEvent(
            String.valueOf(ma.Id), eventDate, 'Detection', 'Anomaly flagged by monitoring'
        );
        Test.stopTest();

        Assert.isNotNull(eventId, 'Should return a valid timeline event Id');

        Incident_Timeline__c queried = [
            SELECT Event_Type__c, Event_Description__c
            FROM Incident_Timeline__c
            WHERE Id = :eventId
            WITH USER_MODE
        ];
        Assert.areEqual('Detection', queried.Event_Type__c, 'Event type should match');
    }

    /**
     * Verify getTimeline returns events through the controller.
     */
    @IsTest
    static void testGetTimeline_returnsList() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        Incident_Timeline__c evt = new Incident_Timeline__c(
            Materiality_Assessment__c = ma.Id,
            Event_Date__c = DateTime.now(),
            Event_Type__c = 'Detection',
            Event_Description__c = 'Test event',
            Performed_By__c = 'SOC'
        );
        insert as user evt;

        Test.startTest();
        List<Incident_Timeline__c> timeline = SECDisclosureController.getTimeline(String.valueOf(ma.Id));
        Test.stopTest();

        Assert.areEqual(1, timeline.size(), 'Should return 1 timeline event');
    }

    /**
     * Verify getWorkflows returns workflows through the controller.
     */
    @IsTest
    static void testGetWorkflows_returnsList() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');

        Test.startTest();
        List<Disclosure_Workflow__c> workflows = SECDisclosureController.getWorkflows(String.valueOf(ma.Id));
        Test.stopTest();

        Assert.areEqual(1, workflows.size(), 'Should return 1 workflow');
    }

    /**
     * Verify requestAGDelay works through the controller.
     */
    @IsTest
    static void testRequestAGDelay_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        // First submit determination
        String determinationDate = String.valueOf(DateTime.newInstance(2026, 1, 5, 10, 0, 0));
        SECDisclosureController.submitDetermination(String.valueOf(ma.Id), 'Material', determinationDate);

        Test.startTest();
        SECDisclosureController.requestAGDelay(String.valueOf(ma.Id), 5);
        Test.stopTest();

        Materiality_Assessment__c updated = [
            SELECT AG_Delay_Requested__c, AG_Delay_Duration_Days__c
            FROM Materiality_Assessment__c
            WHERE Id = :ma.Id
            WITH USER_MODE
        ];
        Assert.isTrue(updated.AG_Delay_Requested__c, 'AG delay should be flagged');
        Assert.areEqual(5, updated.AG_Delay_Duration_Days__c, 'Delay duration should be 5');
    }

    /**
     * Verify submitForApproval rejects when approver fields are missing.
     */
    @IsTest
    static void testSubmitForApproval_missingApprovers() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Id workflowId = SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            SECDisclosureController.submitForApproval(String.valueOf(workflowId), 'CISO submitting');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('approver'),
                'Exception should mention approver fields: ' + e.getMessage()
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when approver fields are not populated');
    }

    /**
     * Verify getApprovalStatus returns status map through the controller.
     */
    @IsTest
    static void testGetApprovalStatus_returnsMap() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Id workflowId = SECDisclosureController.createWorkflow(String.valueOf(ma.Id), '8-K');

        Test.startTest();
        Map<String, Object> status = SECDisclosureController.getApprovalStatus(String.valueOf(workflowId));
        Test.stopTest();

        Assert.isNotNull(status, 'Should return a non-null status map');
        Assert.areEqual('Drafting', status.get('workflowStatus'), 'Workflow status should be Drafting');
    }
}
