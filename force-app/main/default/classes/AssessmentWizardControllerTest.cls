/**
 * Tests for AssessmentWizardController covering all @AuraEnabled endpoints
 * including wizard loading, session management, step saving, and pre-fill.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Assessment Wizards
 * @see AssessmentWizardController
 */
@IsTest
private class AssessmentWizardControllerTest {

    @IsTest
    static void shouldLoadWizard() {
        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardController.loadWizard('SOC2_Assessment');
        Test.stopTest();

        Assert.isNotNull(config, 'Config should not be null');
        Assert.areEqual('SOC2_Assessment', config.wizardName, 'Wizard name should match');
    }

    @IsTest
    static void shouldGetAvailableWizards() {
        Test.startTest();
        List<String> wizards = AssessmentWizardController.getAvailableWizards();
        Test.stopTest();

        Assert.isNotNull(wizards, 'Should return wizard list');
    }

    @IsTest
    static void shouldStartSession() {
        Test.startTest();
        Id sessionId = AssessmentWizardController.startSession(
            'HIPAA_Assessment', 'HIPAA'
        );
        Test.stopTest();

        Assert.isNotNull(sessionId, 'Session Id should not be null');
    }

    @IsTest
    static void shouldSaveStep() {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        AssessmentWizardService.WizardConfig config =
            AssessmentWizardController.saveStep(
                session.Id, 'HIPAA_Access_Control_Scan', 'passed'
            );
        Test.stopTest();

        Assert.isNotNull(config, 'Config should be returned after save');
    }

    @IsTest
    static void shouldCompleteAssessment() {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 4,
            Current_Step__c = 2,
            Status__c = 'Pending Review',
            Percent_Complete__c = 100,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        Boolean result = AssessmentWizardController.completeAssessment(session.Id);
        Test.stopTest();

        Assert.isTrue(result, 'Should complete successfully');
    }

    @IsTest
    static void shouldGetPrefillData() {
        Test.startTest();
        Map<String, String> prefill = AssessmentWizardController.getPrefillData(
            'HIPAA_Assessment', null
        );
        Test.stopTest();

        Assert.isNotNull(prefill, 'Prefill should not be null');
    }

    @IsTest
    static void shouldGetInProgressSessions() {
        // Create an in-progress session
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'SOC2_Assessment',
            Framework__c = 'SOC2',
            Current_Stage__c = 2,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 25,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        List<AssessmentWizardController.SessionSummary> sessions =
            AssessmentWizardController.getInProgressSessions();
        Test.stopTest();

        Assert.isFalse(sessions.isEmpty(), 'Should find in-progress sessions');
        Assert.areEqual('SOC2_Assessment', sessions[0].wizardName,
            'Wizard name should match');
    }

    @IsTest
    static void shouldReturnEmptySessionsWhenNone() {
        Test.startTest();
        List<AssessmentWizardController.SessionSummary> sessions =
            AssessmentWizardController.getInProgressSessions();
        Test.stopTest();

        Assert.isNotNull(sessions, 'Should not be null');
        Assert.isTrue(sessions.isEmpty(), 'Should be empty with no sessions');
    }

    @IsTest
    static void shouldConstructSessionSummary() {
        AssessmentWizardController.SessionSummary ss =
            new AssessmentWizardController.SessionSummary();

        Assert.isNotNull(ss, 'SessionSummary should construct');
    }

    @IsTest
    static void shouldRunAutoScanWithValidControls() {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'SOC2_Assessment',
            Framework__c = 'SOC2',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        Map<String, String> results = AssessmentWizardController.runAutoScan(
            session.Id, 'SOC2_Access_Control_Scan', 'SOC2-CC6.1,SOC2-CC6.2'
        );
        Test.stopTest();

        Assert.isNotNull(results, 'Should return scan results');
        Assert.areEqual(2, results.size(), 'Should scan 2 controls');
        Assert.isTrue(results.containsKey('SOC2-CC6.1'), 'Should have CC6.1 result');
        Assert.isTrue(results.containsKey('SOC2-CC6.2'), 'Should have CC6.2 result');
    }

    @IsTest
    static void shouldRunAutoScanWithSingleControl() {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'HIPAA_Assessment',
            Framework__c = 'HIPAA',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        Map<String, String> results = AssessmentWizardController.runAutoScan(
            session.Id, 'HIPAA_Access_Control_Scan', 'HIPAA-164.308'
        );
        Test.stopTest();

        Assert.isNotNull(results, 'Should return scan results');
        Assert.areEqual(1, results.size(), 'Should scan 1 control');
        Assert.isTrue(results.containsKey('HIPAA-164.308'), 'Should have HIPAA-164.308 result');
        String result = results.get('HIPAA-164.308');
        Assert.isTrue(
            result == 'PASS' || result == 'FAIL' || result == 'NOT_APPLICABLE',
            'Result should be PASS, FAIL, or NOT_APPLICABLE, got: ' + result
        );
    }

    @IsTest
    static void shouldRunAutoScanWithBlankControlReferences() {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = 'SOC2_Assessment',
            Framework__c = 'SOC2',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'In Progress',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );
        insert as user session;

        Test.startTest();
        Map<String, String> results = AssessmentWizardController.runAutoScan(
            session.Id, 'SOC2_Scan_Step', ''
        );
        Test.stopTest();

        Assert.isNotNull(results, 'Should return results map even for blank controls');
        Assert.isTrue(results.isEmpty(), 'Should be empty for blank control references');
    }

    @IsTest
    static void shouldThrowOnAutoScanWithInvalidSession() {
        Id fabricatedId = Compliance_Assessment_Session__c.SObjectType.getDescribe().getKeyPrefix() + '000000000000'; // NOPMD EagerlyLoadedDescribeSObjectResult

        Test.startTest();
        try {
            AssessmentWizardController.runAutoScan(
                fabricatedId, 'some_step', 'SOC2-CC6.1'
            );
            Assert.fail('Should throw exception for invalid session');
        } catch (AuraHandledException e) {
            Assert.isNotNull(e.getMessage(), 'Should have error message');
        }
        Test.stopTest();
    }
}
