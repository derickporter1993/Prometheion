/**
 * Tests for AssessmentWizardController covering all @AuraEnabled endpoints
 * including wizard loading, session management, step saving, and pre-fill.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Assessment Wizards
 * @see AssessmentWizardController
 */
@IsTest(testFor=AssessmentWizardController.class)
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
}
