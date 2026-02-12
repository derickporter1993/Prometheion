/**
 * Lightning controller for the Assessment Wizard LWC components.
 * Provides @AuraEnabled endpoints for loading wizard configuration,
 * saving step responses, managing sessions, and cross-framework pre-fill.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Assessment Wizards
 * @see AssessmentWizardService
 */
public with sharing class AssessmentWizardController {

    /**
     * Loads the wizard configuration for a given wizard name,
     * including any in-progress session state for the current user.
     *
     * @param wizardName Developer name of the wizard (e.g., 'HIPAA_Assessment')
     * @return WizardConfig with stages, steps, and session state
     * @throws AuraHandledException if loading fails
     */
    @AuraEnabled
    public static AssessmentWizardService.WizardConfig loadWizard(String wizardName) {
        try {
            ElaroLogger.info('AssessmentWizardController.loadWizard',
                new Map<String, Object>{ 'wizardName' => wizardName });
            return AssessmentWizardService.loadWizard(wizardName);
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.loadWizard',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load the assessment wizard. Please verify your permissions and try again.');
        }
    }

    /**
     * Returns the list of available wizard names for the wizard picker.
     *
     * @return List of wizard names
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<String> getAvailableWizards() {
        try {
            return AssessmentWizardService.getAvailableWizards();
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.getAvailableWizards',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load available wizards. Please try again.');
        }
    }

    /**
     * Creates a new assessment session for the specified wizard.
     *
     * @param wizardName Developer name of the wizard
     * @param framework Compliance framework (e.g., 'HIPAA')
     * @return Id of the newly created session
     * @throws AuraHandledException if session creation fails
     */
    @AuraEnabled
    public static Id startSession(String wizardName, String framework) {
        try {
            ElaroLogger.info('AssessmentWizardController.startSession',
                new Map<String, Object>{
                    'wizardName' => wizardName,
                    'framework' => framework
                });
            return AssessmentWizardService.createSession(wizardName, framework);
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.startSession',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to start the assessment session. Please verify your permissions and try again.');
        }
    }

    /**
     * Saves the response for a step and advances the wizard.
     *
     * @param sessionId The assessment session Id
     * @param stepId The DeveloperName of the step being completed
     * @param responseData The user's response (JSON or text)
     * @return Updated WizardConfig with new position and progress
     * @throws AuraHandledException if save fails
     */
    @AuraEnabled
    public static AssessmentWizardService.WizardConfig saveStep(
        Id sessionId, String stepId, String responseData
    ) {
        try {
            ElaroLogger.info('AssessmentWizardController.saveStep',
                new Map<String, Object>{
                    'sessionId' => sessionId,
                    'stepId' => stepId
                });
            return AssessmentWizardService.saveStepAndAdvance(sessionId, stepId, responseData);
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.saveStep',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to save the step response. Please try again.');
        }
    }

    /**
     * Marks the assessment as completed.
     *
     * @param sessionId The assessment session Id
     * @return true if successfully completed
     * @throws AuraHandledException if completion fails
     */
    @AuraEnabled
    public static Boolean completeAssessment(Id sessionId) {
        try {
            ElaroLogger.info('AssessmentWizardController.completeAssessment',
                new Map<String, Object>{ 'sessionId' => sessionId });
            return AssessmentWizardService.completeAssessment(sessionId);
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.completeAssessment',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to complete the assessment. Please try again.');
        }
    }

    /**
     * Retrieves pre-fill data from a prior completed assessment session
     * for cross-framework re-use.
     *
     * @param currentWizardName Current wizard name to exclude
     * @param framework Optional framework filter
     * @return Map of stepId to response data
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, String> getPrefillData(
        String currentWizardName, String framework
    ) {
        try {
            return AssessmentWizardService.getPrefillData(currentWizardName, framework);
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.getPrefillData',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load pre-fill data. Please try again.');
        }
    }

    /**
     * Returns in-progress assessment sessions for the current user.
     *
     * @return List of session summaries
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<SessionSummary> getInProgressSessions() {
        try {
            List<SessionSummary> summaries = new List<SessionSummary>();

            for (Compliance_Assessment_Session__c session : [
                SELECT Id, Name, Wizard_Name__c, Framework__c, Status__c,
                       Percent_Complete__c, Current_Stage__c, Current_Step__c,
                       Started_Date__c, CreatedDate
                FROM Compliance_Assessment_Session__c
                WHERE Status__c NOT IN ('Completed', 'Abandoned')
                AND Assigned_To__c = :UserInfo.getUserId()
                WITH USER_MODE
                ORDER BY LastModifiedDate DESC
                LIMIT 10
            ]) {
                SessionSummary ss = new SessionSummary();
                ss.sessionId = session.Id;
                ss.sessionName = session.Name;
                ss.wizardName = session.Wizard_Name__c;
                ss.framework = session.Framework__c;
                ss.status = session.Status__c;
                ss.percentComplete = session.Percent_Complete__c ?? 0;
                ss.startedDate = session.Started_Date__c ?? session.CreatedDate;
                summaries.add(ss);
            }

            return summaries;
        } catch (Exception e) {
            ElaroLogger.error('AssessmentWizardController.getInProgressSessions',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to load assessment sessions. Please try again.');
        }
    }

    /**
     * Summary DTO for displaying in-progress sessions.
     */
    public class SessionSummary {
        @AuraEnabled public Id sessionId;
        @AuraEnabled public String sessionName;
        @AuraEnabled public String wizardName;
        @AuraEnabled public String framework;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal percentComplete;
        @AuraEnabled public Datetime startedDate;
    }
}
