/**
 * Tests for AssessmentWizardService covering wizard loading, session management,
 * step progression, pre-fill, and state serialization.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Assessment Wizards
 * @see AssessmentWizardService
 */
@IsTest
private class AssessmentWizardServiceTest {

    @TestSetup
    static void makeData() {
        List<Compliance_Assessment_Session__c> sessions = new List<Compliance_Assessment_Session__c>();

        // Not Started session for step advancement tests
        sessions.add(new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'Not Started',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        ));

        // In Progress session for blank step tests
        sessions.add(new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        ));

        // Pending Review session for completion tests
        sessions.add(new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 4,
            Current_Step__c = 2,
            Status__c = 'Pending Review',
            Percent_Complete__c = 100,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        ));

        // Completed SOC2 session for prefill tests
        sessions.add(new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'SOC2_Assessment',
            Framework__c = 'SOC2',
            Current_Stage__c = 4,
            Current_Step__c = 2,
            Status__c = 'Completed',
            Percent_Complete__c = 100,
            Completed_Date__c = Datetime.now(),
            Session_State__c = '{"SOC2_Security_Scan":{"status":"Completed","response":"passed"}}',
            Assigned_To__c = UserInfo.getUserId()
        ));

        insert as user sessions;
    }

    @IsTest
    static void shouldLoadWizardFromMetadata() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.loadWizard('HIPAA_Assessment');
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.areEqual('HIPAA_Assessment', config.wizardName, 'Wizard name should match');
        Assert.areEqual('HIPAA', config.framework, 'Framework should be HIPAA');
        Assert.isFalse(config.stages.isEmpty(), 'Should have stages');
    }

    @IsTest
    static void shouldReturnEmptyForBlankWizardName() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.loadWizard('');
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.isTrue(config.stages.isEmpty(), 'Blank wizard should have no stages');
    }

    @IsTest
    static void shouldReturnEmptyForNullWizardName() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.loadWizard(null);
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.isTrue(config.stages.isEmpty(), 'Null wizard should have no stages');
    }

    @IsTest
    static void shouldReturnEmptyForUnknownWizard() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.loadWizard('Nonexistent_Wizard');
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.isTrue(config.stages.isEmpty(), 'Unknown wizard should have no stages');
    }

    @IsTest
    static void shouldGetAvailableWizards() {
        Test.startTest();
        List<String> wizards = AssessmentWizardService.getAvailableWizards();
        Test.stopTest();

        Assert.isNotNull(wizards, 'Wizards list should not be null');
        // CMT records include HIPAA, SOC2, PCI_DSS
    }

    @IsTest
    static void shouldCreateSession() {
        Test.startTest();
        Id sessionId = AssessmentWizardService.createSession(
            'HIPAA_Assessment', 'HIPAA'
        );
        Test.stopTest();

        Assert.isNotNull(sessionId, 'Session Id should not be null');

        Compliance_Assessment_Session__c session = [
            SELECT Wizard_Name__c, Framework__c, Status__c, Percent_Complete__c
            FROM Compliance_Assessment_Session__c
            WHERE Id = :sessionId
            WITH USER_MODE
        ];
        Assert.areEqual('HIPAA_Assessment', session.Wizard_Name__c, 'Wizard name should match');
        Assert.areEqual('HIPAA', session.Framework__c, 'Framework should match');
        Assert.areEqual('Not Started', session.Status__c, 'Status should be Not Started');
        Assert.areEqual(0, session.Percent_Complete__c, 'Percent should be 0');
    }

    @IsTest
    static void shouldCreateSessionWithNullFramework() {
        Test.startTest();
        Id sessionId = AssessmentWizardService.createSession(
            'Test_Wizard', null
        );
        Test.stopTest();

        Assert.isNotNull(sessionId, 'Session should be created');

        Compliance_Assessment_Session__c session = [
            SELECT Framework__c FROM Compliance_Assessment_Session__c
            WHERE Id = :sessionId WITH USER_MODE
        ];
        Assert.areEqual('Unknown', session.Framework__c, 'Null framework should default to Unknown');
    }

    @IsTest
    static void shouldSaveStepAndAdvance() {
        Compliance_Assessment_Session__c session = [
            SELECT Id FROM Compliance_Assessment_Session__c
            WHERE Status__c = 'Not Started' AND Wizard_Name__c = 'HIPAA_Assessment'
            WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.saveStepAndAdvance(
                session.Id, 'HIPAA_Access_Control_Scan', 'scan_passed'
            );
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.isTrue(config.percentComplete > 0, 'Progress should advance');
    }

    @IsTest
    static void shouldReturnEmptyForNullSessionId() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.saveStepAndAdvance(null, 'step1', 'data');
        Test.stopTest();

        Assert.isNotNull(config, 'Should return empty config');
        Assert.isTrue(config.stages.isEmpty(), 'Null session should return empty');
    }

    @IsTest
    static void shouldReturnEmptyForBlankStepId() {
        Compliance_Assessment_Session__c session = [
            SELECT Id FROM Compliance_Assessment_Session__c
            WHERE Status__c = 'In Progress' AND Wizard_Name__c = 'HIPAA_Assessment'
            WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.saveStepAndAdvance(session.Id, '', 'data');
        Test.stopTest();

        Assert.isNotNull(config, 'Should return empty config');
    }

    @IsTest
    static void shouldCompleteAssessment() {
        Compliance_Assessment_Session__c session = [
            SELECT Id FROM Compliance_Assessment_Session__c
            WHERE Status__c = 'Pending Review' AND Wizard_Name__c = 'HIPAA_Assessment'
            WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        Boolean completed = AssessmentWizardService.completeAssessment(session.Id);
        Test.stopTest();

        Assert.isTrue(completed, 'Assessment should be completed');

        Compliance_Assessment_Session__c updated = [
            SELECT Status__c, Completed_Date__c
            FROM Compliance_Assessment_Session__c
            WHERE Id = :session.Id
            WITH USER_MODE
        ];
        Assert.areEqual('Completed', updated.Status__c, 'Status should be Completed');
        Assert.isNotNull(updated.Completed_Date__c, 'Completed date should be set');
    }

    @IsTest
    static void shouldReturnFalseForNullSessionComplete() {
        Test.startTest();
        Boolean completed = AssessmentWizardService.completeAssessment(null);
        Test.stopTest();

        Assert.isFalse(completed, 'Null session should return false');
    }

    @IsTest
    static void shouldGetPrefillDataFromPriorSession() {
        Test.startTest();
        Map<String, String> prefill = AssessmentWizardService.getPrefillData(
            'HIPAA_Assessment', null
        );
        Test.stopTest();

        Assert.isNotNull(prefill, 'Prefill should not be null');
        Assert.areEqual('passed', prefill.get('SOC2_Security_Scan'),
            'Should contain response from prior session');
    }

    @IsTest
    static void shouldReturnEmptyPrefillForNoCompletedSessions() {
        // Remove completed sessions from @TestSetup so this test has none
        delete as user [
            SELECT Id FROM Compliance_Assessment_Session__c
            WHERE Status__c = 'Completed' WITH USER_MODE
        ];

        Test.startTest();
        Map<String, String> prefill = AssessmentWizardService.getPrefillData(
            'HIPAA_Assessment', null
        );
        Test.stopTest();

        Assert.isNotNull(prefill, 'Prefill should not be null');
        Assert.isTrue(prefill.isEmpty(), 'Should be empty when no completed sessions');
    }

    @IsTest
    static void shouldDeserializeValidState() {
        String json = '{"step1":{"status":"Completed","response":"yes"}}';

        Test.startTest();
        Map<String, Object> result = AssessmentWizardService.deserializeState(json);
        Test.stopTest();

        Assert.isFalse(result.isEmpty(), 'Should parse valid JSON');
        Assert.isTrue(result.containsKey('step1'), 'Should contain step1');
    }

    @IsTest
    static void shouldReturnEmptyForInvalidState() {
        Test.startTest();
        Map<String, Object> result = AssessmentWizardService.deserializeState('not-json');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Invalid JSON should return empty map');
    }

    @IsTest
    static void shouldReturnEmptyForNullState() {
        Test.startTest();
        Map<String, Object> result = AssessmentWizardService.deserializeState(null);
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Null state should return empty map');
    }

    @IsTest
    static void shouldReturnEmptyForBlankState() {
        Test.startTest();
        Map<String, Object> result = AssessmentWizardService.deserializeState('');
        Test.stopTest();

        Assert.isTrue(result.isEmpty(), 'Blank state should return empty map');
    }

    @IsTest
    static void shouldApplyStateToConfig() {
        AssessmentWizardService.WizardConfig config = new AssessmentWizardService.WizardConfig();
        AssessmentWizardService.WizardStage stage = new AssessmentWizardService.WizardStage();
        stage.stageOrder = 1;
        AssessmentWizardService.WizardStep step = new AssessmentWizardService.WizardStep();
        step.stepId = 'test_step';
        step.status = 'Pending';
        stage.steps.add(step);
        config.stages.add(stage);

        Map<String, Object> stateMap = new Map<String, Object>{
            'test_step' => new Map<String, Object>{
                'status' => 'Completed',
                'response' => 'done'
            }
        };

        Test.startTest();
        AssessmentWizardService.applyStateToConfig(config, stateMap);
        Test.stopTest();

        Assert.areEqual('Completed', config.stages[0].steps[0].status,
            'Step status should be updated from state');
        Assert.areEqual('done', config.stages[0].steps[0].response,
            'Step response should be applied');
        Assert.isTrue(config.stages[0].isComplete,
            'Stage should be marked complete when all steps complete');
    }

    @IsTest
    static void shouldConstructDTOs() {
        AssessmentWizardService.WizardStep step = new AssessmentWizardService.WizardStep();
        Assert.isNotNull(step, 'WizardStep should construct');

        AssessmentWizardService.WizardStage stage = new AssessmentWizardService.WizardStage();
        Assert.isNotNull(stage.steps, 'Steps should be initialized');
        Assert.isFalse(stage.isComplete, 'Should default to not complete');

        AssessmentWizardService.WizardConfig config = new AssessmentWizardService.WizardConfig();
        Assert.isNotNull(config.stages, 'Stages should be initialized');
        Assert.areEqual(1, config.currentStage, 'Default stage should be 1');
        Assert.areEqual(1, config.currentStep, 'Default step should be 1');
        Assert.areEqual(0, config.percentComplete, 'Default percent should be 0');
        Assert.areEqual('Not Started', config.sessionStatus, 'Default status');

        AssessmentWizardService.StepResponse resp = new AssessmentWizardService.StepResponse();
        Assert.areEqual('Pending', resp.status, 'Default step response status');
    }

    @IsTest
    static void shouldGroupStepsIntoStages() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardService.loadWizard('HIPAA_Assessment');
        Test.stopTest();

        // HIPAA has 4 stages
        Assert.areEqual(4, config.stages.size(),
            'HIPAA should have 4 stages, got: ' + config.stages.size());

        // Verify each stage has steps
        for (AssessmentWizardService.WizardStage stage : config.stages) {
            Assert.isFalse(stage.steps.isEmpty(),
                'Stage ' + stage.stageOrder + ' should have steps');
        }
    }

    @IsTest
    static void shouldExecuteAutoScanWithValidControls() {
        Id sessionId = AssessmentWizardService.createSession('SOC2_Assessment', 'SOC2');

        Test.startTest();
        Map<String, String> results = AssessmentWizardService.executeAutoScan(
            sessionId,
            new List<String>{'SOC2-CC6.1', 'SOC2-CC6.2'}
        );
        Test.stopTest();

        Assert.isNotNull(results, 'Should return scan results');
        Assert.areEqual(2, results.size(), 'Should scan 2 controls');
        Assert.isTrue(results.containsKey('SOC2-CC6.1'), 'Should have CC6.1 result');
        Assert.isTrue(results.containsKey('SOC2-CC6.2'), 'Should have CC6.2 result');

        // Verify results are valid
        for (String controlRef : results.keySet()) {
            String result = results.get(controlRef);
            Assert.isTrue(
                result == 'PASS' || result == 'FAIL' || result == 'NOT_APPLICABLE',
                'Result should be PASS, FAIL, or NOT_APPLICABLE, got: ' + result
            );
        }

        // Verify session state was updated
        Compliance_Assessment_Session__c session = [
            SELECT Id, Session_State__c
            FROM Compliance_Assessment_Session__c
            WHERE Id = :sessionId
            WITH USER_MODE
        ];
        Assert.isTrue(
            session.Session_State__c.contains('autoScanResults'),
            'Session state should contain autoScanResults'
        );
    }

    @IsTest
    static void shouldHandleUnknownControlReferences() {
        Id sessionId = AssessmentWizardService.createSession('HIPAA_Assessment', 'HIPAA');

        Test.startTest();
        Map<String, String> results = AssessmentWizardService.executeAutoScan(
            sessionId,
            new List<String>{'UNKNOWN-001', 'INVALID-002'}
        );
        Test.stopTest();

        Assert.isNotNull(results, 'Should return results even for unknown controls');
        Assert.areEqual(2, results.size(), 'Should process all controls');
        Assert.areEqual('NOT_APPLICABLE', results.get('UNKNOWN-001'),
            'Unknown control should be NOT_APPLICABLE');
        Assert.areEqual('NOT_APPLICABLE', results.get('INVALID-002'),
            'Invalid control should be NOT_APPLICABLE');
    }

    @IsTest
    static void shouldRejectAutoScanWithInvalidSession() {
        // Use fabricated non-existent Id to test the sessions.isEmpty() validation path
        Id fabricatedId = Compliance_Assessment_Session__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000'; // NOPMD EagerlyLoadedDescribeSObjectResult

        Test.startTest();
        try {
            AssessmentWizardService.executeAutoScan(
                fabricatedId,
                new List<String>{'SOC2-CC6.1'}
            );
            Assert.fail('Should throw exception for invalid session');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Invalid session'),
                'Should indicate invalid session');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldEvaluatePermissionSetRequirements() {
        // Create test data: overly permissive permission set
        PermissionSet ps = new PermissionSet(
            Label = 'Test Admin',
            Name = 'Test_Admin',
            PermissionsModifyAllData = true
        );
        insert as user ps;

        ElaroFrameworkEngine.FrameworkRequirement req = new ElaroFrameworkEngine.FrameworkRequirement(
            'SOC2-CC6.1',
            'Logical and physical access controls',
            'PERMISSION_SET'
        );

        Test.startTest();
        String result = AssessmentWizardService.evaluateControlRequirement(req, 'SOC2');
        Test.stopTest();

        Assert.areEqual('FAIL', result,
            'Should FAIL when overly permissive permission sets exist');
    }

    @IsTest
    static void shouldEvaluateUserRequirements() {
        ElaroFrameworkEngine.FrameworkRequirement req = new ElaroFrameworkEngine.FrameworkRequirement(
            'SOC2-CC6.6',
            'Access removal for terminated users',
            'USER'
        );

        Test.startTest();
        String result = AssessmentWizardService.evaluateControlRequirement(req, 'SOC2');
        Test.stopTest();

        // Result depends on org data, verify valid response
        Assert.isTrue(
            result == 'PASS' || result == 'FAIL',
            'User requirement should return PASS or FAIL, got: ' + result
        );
    }

    @IsTest
    static void shouldHandleUnsupportedEntityTypes() {
        ElaroFrameworkEngine.FrameworkRequirement req = new ElaroFrameworkEngine.FrameworkRequirement(
            'CUSTOM-001',
            'Custom requirement',
            'UNSUPPORTED_TYPE'
        );

        Test.startTest();
        String result = AssessmentWizardService.evaluateControlRequirement(req, 'CUSTOM');
        Test.stopTest();

        Assert.areEqual('NOT_APPLICABLE', result,
            'Unsupported entity types should return NOT_APPLICABLE');
    }
}
