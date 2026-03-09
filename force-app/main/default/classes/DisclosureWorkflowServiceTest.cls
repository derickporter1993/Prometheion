/**
 * Test class for {@link DisclosureWorkflowService}. Validates workflow
 * creation, status transitions, filing recording, and transition validation.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see DisclosureWorkflowService
 */
@IsTest
private class DisclosureWorkflowServiceTest {

    @TestSetup
    static void makeData() {
        Materiality_Assessment__c ma = new Materiality_Assessment__c(
            Incident_Description__c = 'Test incident for disclosure workflow',
            Discovery_Date__c = DateTime.now().addDays(-5),
            Status__c = 'Determined',
            Determination_Result__c = 'Material',
            Determination_Date__c = DateTime.now().addDays(-2)
        );
        insert as user ma;
    }

    /**
     * Verify createWorkflow produces a record with Drafting status.
     */
    @IsTest
    static void testCreateWorkflow_success() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        Test.startTest();
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');
        Test.stopTest();

        Assert.isNotNull(workflow.Id, 'Workflow should have been inserted');

        Disclosure_Workflow__c queried = [
            SELECT Materiality_Assessment__c, Form_Type__c, Status__c
            FROM Disclosure_Workflow__c
            WHERE Id = :workflow.Id
            WITH USER_MODE
        ];
        Assert.areEqual(ma.Id, queried.Materiality_Assessment__c, 'Assessment link should match');
        Assert.areEqual('8-K', queried.Form_Type__c, 'Form type should be 8-K');
        Assert.areEqual('Drafting', queried.Status__c, 'Initial status should be Drafting');
    }

    /**
     * Verify valid transition from Drafting to Legal_Review succeeds.
     */
    @IsTest
    static void testAdvanceWorkflow_validTransition() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        Test.startTest();
        DisclosureWorkflowService.advanceWorkflow(
            workflow.Id, 'Legal_Review', 'Draft reviewed and ready for legal'
        );
        Test.stopTest();

        Disclosure_Workflow__c updated = [
            SELECT Status__c, Review_Notes__c
            FROM Disclosure_Workflow__c
            WHERE Id = :workflow.Id
            WITH USER_MODE
        ];
        Assert.areEqual('Legal_Review', updated.Status__c, 'Status should transition to Legal_Review');
        Assert.areEqual(
            'Draft reviewed and ready for legal',
            updated.Review_Notes__c,
            'Review notes should be saved'
        );
    }

    /**
     * Verify invalid transition from Drafting to Filed throws exception.
     */
    @IsTest
    static void testAdvanceWorkflow_invalidTransition() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'Filed', 'Skipping to filed');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Invalid status transition'),
                'Exception should indicate invalid transition'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception for invalid transition Drafting->Filed');
    }

    /**
     * Verify recordFiling sets all filing fields correctly.
     */
    @IsTest
    static void testRecordFiling_setsFields() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        // Advance through the workflow to Ready_To_File
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'Legal_Review', 'Legal review passed');
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'CFO_Review', 'CFO approved');
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'CEO_Approval', 'CEO approved');
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'Board_Review', 'Board approved');
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'Ready_To_File', 'Ready for SEC filing');

        Test.startTest();
        DisclosureWorkflowService.recordFiling(workflow.Id, 'EDGAR-2026-001234');
        Test.stopTest();

        Disclosure_Workflow__c filed = [
            SELECT EDGAR_Filing_Number__c, Filing_Date__c, Filed_By__c, Status__c
            FROM Disclosure_Workflow__c
            WHERE Id = :workflow.Id
            WITH USER_MODE
        ];

        Assert.areEqual('EDGAR-2026-001234', filed.EDGAR_Filing_Number__c, 'EDGAR number should be set');
        Assert.isNotNull(filed.Filing_Date__c, 'Filing date should be set');
        Assert.areEqual(UserInfo.getUserId(), filed.Filed_By__c, 'Filed by should be current user');
        Assert.areEqual('Filed', filed.Status__c, 'Status should be Filed');
    }

    /**
     * Verify getValidNextStatuses from Drafting returns Legal_Review.
     */
    @IsTest
    static void testGetValidNextStatuses_fromDrafting() {
        Test.startTest();
        List<String> validStatuses = DisclosureWorkflowService.getValidNextStatuses('Drafting');
        Test.stopTest();

        Assert.isFalse(validStatuses.isEmpty(), 'Should return valid next statuses');
        Assert.isTrue(
            validStatuses.contains('Legal_Review'),
            'Drafting should allow transition to Legal_Review'
        );
    }

    /**
     * Verify getValidNextStatuses from Filed returns Amended.
     */
    @IsTest
    static void testGetValidNextStatuses_fromFiled() {
        Test.startTest();
        List<String> validStatuses = DisclosureWorkflowService.getValidNextStatuses('Filed');
        Test.stopTest();

        Assert.isFalse(validStatuses.isEmpty(), 'Filed should have valid next statuses');
        Assert.isTrue(
            validStatuses.contains('Amended'),
            'Filed should allow transition to Amended'
        );
    }

    /**
     * Verify getWorkflowsByAssessment returns workflows for a given assessment.
     */
    @IsTest
    static void testGetWorkflowsByAssessment_returnsWorkflows() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');
        DisclosureWorkflowService.createWorkflow(ma.Id, '10-K');

        Test.startTest();
        List<Disclosure_Workflow__c> workflows = DisclosureWorkflowService.getWorkflowsByAssessment(ma.Id);
        Test.stopTest();

        Assert.areEqual(2, workflows.size(), 'Should return 2 workflows for the assessment');
    }

    /**
     * Verify recordFiling fails when workflow is not in Ready_To_File status.
     */
    @IsTest
    static void testRecordFiling_wrongStatus_throwsException() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.recordFiling(workflow.Id, 'EDGAR-FAKE');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Ready_To_File'),
                'Exception should mention required Ready_To_File status'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when not in Ready_To_File status');
    }

    /**
     * Verify submitForApproval fails when approver fields are not populated.
     */
    @IsTest
    static void testSubmitForApproval_missingApprovers_throwsException() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.submitForApproval(workflow.Id, 'Test comments');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('approver fields'),
                'Exception should mention missing approver fields'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when approver fields are empty');
    }

    /**
     * Verify submitForApproval fails when workflow is not in Drafting status.
     */
    @IsTest
    static void testSubmitForApproval_wrongStatus_throwsException() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        // Advance past Drafting
        DisclosureWorkflowService.advanceWorkflow(workflow.Id, 'Legal_Review', 'Moving on');

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.submitForApproval(workflow.Id, 'Test comments');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('Drafting'),
                'Exception should mention required Drafting status'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when not in Drafting status');
    }

    /**
     * Verify submitForApproval fails with invalid workflow Id.
     */
    @IsTest
    static void testSubmitForApproval_notFound_throwsException() {
        // Use a fabricated Id that won't exist
        Id fakeId = Disclosure_Workflow__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000'; // NOPMD EagerlyLoadedDescribeSObjectResult

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.submitForApproval(fakeId, 'Test');
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('not found'),
                'Exception should indicate workflow not found'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception for nonexistent workflow');
    }

    /**
     * Verify getApprovalStatus returns status map for a workflow.
     */
    @IsTest
    static void testGetApprovalStatus_returnsMap() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        Disclosure_Workflow__c workflow = DisclosureWorkflowService.createWorkflow(ma.Id, '8-K');

        Test.startTest();
        Map<String, Object> status = DisclosureWorkflowService.getApprovalStatus(workflow.Id);
        Test.stopTest();

        Assert.isNotNull(status, 'Should return a non-null status map');
        Assert.areEqual('Drafting', status.get('workflowStatus'), 'Workflow status should be Drafting');
    }

    /**
     * Verify getApprovalStatus fails with invalid workflow Id.
     */
    @IsTest
    static void testGetApprovalStatus_notFound_throwsException() {
        Id fakeId = Disclosure_Workflow__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000'; // NOPMD EagerlyLoadedDescribeSObjectResult

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            DisclosureWorkflowService.getApprovalStatus(fakeId);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('not found'),
                'Exception should indicate workflow not found'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception for nonexistent workflow');
    }
}
