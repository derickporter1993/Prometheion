/**
 * Orchestrates guided assessment wizard flows by loading configuration from
 * Assessment_Wizard_Config__mdt, managing session state in
 * Compliance_Assessment_Session__c, and coordinating step transitions
 * including auto-scan, attestation, evidence upload, approval, and review.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Assessment Wizards
 * @see AssessmentWizardController
 * @see Assessment_Wizard_Config__mdt
 * @see Compliance_Assessment_Session__c
 */
public inherited sharing class AssessmentWizardService {

    /**
     * DTO representing a single wizard step configuration.
     */
    public class WizardStep {
        @AuraEnabled public String stepId;
        @AuraEnabled public String wizardName;
        @AuraEnabled public String framework;
        @AuraEnabled public Integer stageOrder;
        @AuraEnabled public Integer stepOrder;
        @AuraEnabled public String stepType;
        @AuraEnabled public String controlReference;
        @AuraEnabled public String helpText;
        @AuraEnabled public Boolean isRequired;
        @AuraEnabled public String status;
        @AuraEnabled public String response;
    }

    /**
     * DTO representing a wizard stage containing ordered steps.
     */
    public class WizardStage {
        @AuraEnabled public Integer stageOrder;
        @AuraEnabled public String stageName;
        @AuraEnabled public List<WizardStep> steps;
        @AuraEnabled public Boolean isComplete;

        public WizardStage() {
            this.steps = new List<WizardStep>();
            this.isComplete = false;
        }
    }

    /**
     * DTO representing the full wizard configuration with stages, steps,
     * and current session state.
     */
    public class WizardConfig {
        @AuraEnabled public String wizardName;
        @AuraEnabled public String framework;
        @AuraEnabled public List<WizardStage> stages;
        @AuraEnabled public Integer currentStage;
        @AuraEnabled public Integer currentStep;
        @AuraEnabled public Decimal percentComplete;
        @AuraEnabled public String sessionStatus;
        @AuraEnabled public Id sessionId;

        public WizardConfig() {
            this.stages = new List<WizardStage>();
            this.currentStage = 1;
            this.currentStep = 1;
            this.percentComplete = 0;
            this.sessionStatus = 'Not Started';
        }
    }

    /**
     * DTO for persisting step responses in Session_State__c JSON.
     */
    public class StepResponse {
        public String stepId;
        public String status;
        public String response;
        public Datetime completedAt;

        public StepResponse() {
            this.status = 'Pending';
        }
    }

    /**
     * Loads the wizard configuration for a given wizard name,
     * creating or resuming a session as appropriate.
     *
     * @param wizardName Developer name of the wizard (e.g., 'HIPAA_Assessment')
     * @return WizardConfig with stages, steps, and session state
     */
    public static WizardConfig loadWizard(String wizardName) {
        if (String.isBlank(wizardName)) {
            return new WizardConfig();
        }

        WizardConfig config = new WizardConfig();
        config.wizardName = wizardName;

        // Load steps from Custom Metadata
        List<Assessment_Wizard_Config__mdt> stepConfigs = [
            SELECT DeveloperName, Wizard_Name__c, Framework__c, Stage_Order__c,
                   Step_Order__c, Step_Type__c, Control_Reference__c,
                   Help_Text__c, Is_Required__c
            FROM Assessment_Wizard_Config__mdt
            WHERE Wizard_Name__c = :wizardName
            WITH USER_MODE
            ORDER BY Stage_Order__c ASC, Step_Order__c ASC
        ];

        if (stepConfigs.isEmpty()) {
            return config;
        }

        config.framework = stepConfigs[0].Framework__c;

        // Group steps into stages
        Map<Integer, WizardStage> stageMap = new Map<Integer, WizardStage>();
        for (Assessment_Wizard_Config__mdt sc : stepConfigs) {
            Integer stageNum = sc.Stage_Order__c != null ? sc.Stage_Order__c.intValue() : 1;
            WizardStage stage = stageMap.get(stageNum);
            if (stage == null) {
                stage = new WizardStage();
                stage.stageOrder = stageNum;
                stage.stageName = 'Stage ' + stageNum;
                stageMap.put(stageNum, stage);
            }

            WizardStep step = new WizardStep();
            step.stepId = sc.DeveloperName;
            step.wizardName = sc.Wizard_Name__c;
            step.framework = sc.Framework__c;
            step.stageOrder = stageNum;
            step.stepOrder = sc.Step_Order__c != null ? sc.Step_Order__c.intValue() : 1;
            step.stepType = sc.Step_Type__c;
            step.controlReference = sc.Control_Reference__c;
            step.helpText = sc.Help_Text__c;
            step.isRequired = sc.Is_Required__c ?? true;
            step.status = 'Pending';
            stage.steps.add(step);
        }

        // Sort stages by order
        List<Integer> stageOrders = new List<Integer>(stageMap.keySet());
        stageOrders.sort();
        for (Integer order : stageOrders) {
            config.stages.add(stageMap.get(order));
        }

        // Load or create session
        config = mergeSessionState(config);

        return config;
    }

    /**
     * Returns a list of available wizard names for display in a picker.
     *
     * @return List of unique wizard names from Assessment_Wizard_Config__mdt
     */
    public static List<String> getAvailableWizards() {
        Set<String> wizardNames = new Set<String>();
        for (Assessment_Wizard_Config__mdt cfg : [
            SELECT Wizard_Name__c
            FROM Assessment_Wizard_Config__mdt
            WITH USER_MODE
        ]) {
            if (String.isNotBlank(cfg.Wizard_Name__c)) {
                wizardNames.add(cfg.Wizard_Name__c);
            }
        }
        List<String> sorted = new List<String>(wizardNames);
        sorted.sort();
        return sorted;
    }

    /**
     * Creates a new assessment session for the given wizard.
     *
     * @param wizardName The wizard developer name
     * @param framework The compliance framework
     * @return Id of the new Compliance_Assessment_Session__c
     */
    public static Id createSession(String wizardName, String framework) {
        Compliance_Assessment_Session__c session = new Compliance_Assessment_Session__c(
            Wizard_Name__c = wizardName,
            Framework__c = framework ?? 'Unknown',
            Current_Stage__c = 1,
            Current_Step__c = 1,
            Status__c = 'Not Started',
            Percent_Complete__c = 0,
            Session_State__c = '{}',
            Assigned_To__c = UserInfo.getUserId()
        );

        insert as user session;
        ElaroLogger.info('AssessmentWizardService.createSession',
            new Map<String, Object>{
                'wizardName' => wizardName,
                'framework' => framework,
                'sessionId' => session.Id
            });
        return session.Id;
    }

    /**
     * Saves a step response and advances the wizard to the next step.
     *
     * @param sessionId The assessment session Id
     * @param stepId The DeveloperName of the step being completed
     * @param responseData The user's response for this step (JSON or text)
     * @return Updated WizardConfig reflecting the new state
     */
    public static WizardConfig saveStepAndAdvance(Id sessionId, String stepId, String responseData) {
        if (sessionId == null || String.isBlank(stepId)) {
            return new WizardConfig();
        }

        List<Compliance_Assessment_Session__c> sessions = [
            SELECT Id, Wizard_Name__c, Framework__c, Session_State__c,
                   Current_Stage__c, Current_Step__c, Status__c,
                   Percent_Complete__c, Started_Date__c
            FROM Compliance_Assessment_Session__c
            WHERE Id = :sessionId
            WITH USER_MODE
            LIMIT 1
        ];

        if (sessions.isEmpty()) {
            return new WizardConfig();
        }

        Compliance_Assessment_Session__c session = sessions[0];

        // Start the session if not yet started
        if (session.Status__c == 'Not Started') {
            session.Status__c = 'In Progress';
            session.Started_Date__c = Datetime.now();
        }

        // Deserialize existing state
        Map<String, Object> stateMap = deserializeState(session.Session_State__c);

        // Save this step's response
        Map<String, Object> stepState = new Map<String, Object>{
            'status' => 'Completed',
            'response' => responseData,
            'completedAt' => Datetime.now().format()
        };
        stateMap.put(stepId, stepState);

        session.Session_State__c = JSON.serialize(stateMap);

        // Calculate progress and advance
        WizardConfig config = loadWizard(session.Wizard_Name__c);
        config.sessionId = session.Id;
        applyStateToConfig(config, stateMap);

        Integer totalSteps = 0;
        Integer completedSteps = 0;
        Integer nextStage = -1;
        Integer nextStep = -1;
        Boolean foundCurrent = false;

        for (WizardStage stage : config.stages) {
            Boolean stageComplete = true;
            for (WizardStep step : stage.steps) {
                totalSteps++;
                if (step.status == 'Completed') {
                    completedSteps++;
                } else {
                    stageComplete = false;
                    if (!foundCurrent) {
                        nextStage = stage.stageOrder;
                        nextStep = step.stepOrder;
                        foundCurrent = true;
                    }
                }
            }
            stage.isComplete = stageComplete;
        }

        // Update session
        Decimal pct = totalSteps > 0 ? ((Decimal) completedSteps / totalSteps) * 100 : 0;
        session.Percent_Complete__c = pct.setScale(2);

        if (nextStage > 0) {
            session.Current_Stage__c = nextStage;
            session.Current_Step__c = nextStep;
            config.currentStage = nextStage;
            config.currentStep = nextStep;
        } else {
            // All steps completed
            session.Status__c = 'Pending Review';
            session.Current_Stage__c = config.stages.size();
            session.Current_Step__c = 1;
        }

        config.percentComplete = session.Percent_Complete__c;
        config.sessionStatus = session.Status__c;

        update as user session;

        ElaroLogger.info('AssessmentWizardService.saveStepAndAdvance',
            new Map<String, Object>{
                'sessionId' => sessionId,
                'stepId' => stepId,
                'percentComplete' => session.Percent_Complete__c,
                'status' => session.Status__c
            });

        return config;
    }

    /**
     * Marks an assessment session as completed.
     *
     * @param sessionId The assessment session Id
     * @return true if successfully completed
     */
    public static Boolean completeAssessment(Id sessionId) {
        if (sessionId == null) {
            return false;
        }

        List<Compliance_Assessment_Session__c> sessions = [
            SELECT Id, Status__c, Percent_Complete__c
            FROM Compliance_Assessment_Session__c
            WHERE Id = :sessionId
            WITH USER_MODE
            LIMIT 1
        ];

        if (sessions.isEmpty()) {
            return false;
        }

        Compliance_Assessment_Session__c session = sessions[0];
        session.Status__c = 'Completed';
        session.Completed_Date__c = Datetime.now();
        session.Percent_Complete__c = 100;

        update as user session;

        ElaroLogger.info('AssessmentWizardService.completeAssessment',
            new Map<String, Object>{ 'sessionId' => sessionId });

        return true;
    }

    /**
     * Retrieves step responses from a prior assessment session for
     * cross-framework pre-fill. Finds the most recent completed session
     * for any wizard and returns its state map.
     *
     * @param currentWizardName The current wizard to exclude from lookup
     * @param framework Optional framework filter; null returns any
     * @return Map of stepId to response data from the prior session
     */
    public static Map<String, String> getPrefillData(String currentWizardName, String framework) {
        Map<String, String> prefillMap = new Map<String, String>();

        String query = 'SELECT Id, Session_State__c, Wizard_Name__c '
            + 'FROM Compliance_Assessment_Session__c '
            + 'WHERE Status__c = \'Completed\' '
            + 'AND Wizard_Name__c != :currentWizardName ';

        Map<String, Object> binds = new Map<String, Object>{
            'currentWizardName' => currentWizardName ?? ''
        };

        if (String.isNotBlank(framework)) {
            query += 'AND Framework__c = :framework ';
            binds.put('framework', framework);
        }
        query += 'ORDER BY Completed_Date__c DESC WITH USER_MODE LIMIT 1';

        List<Compliance_Assessment_Session__c> sessions = Database.queryWithBinds(
            query, binds, AccessLevel.USER_MODE
        );

        if (sessions.isEmpty()) {
            return prefillMap;
        }

        Map<String, Object> stateMap = deserializeState(sessions[0].Session_State__c);
        for (String key : stateMap.keySet()) {
            Object stepData = stateMap.get(key);
            if (stepData instanceof Map<String, Object>) {
                Map<String, Object> stepMap = (Map<String, Object>) stepData;
                String response = (String) stepMap.get('response');
                if (String.isNotBlank(response)) {
                    prefillMap.put(key, response);
                }
            }
        }

        return prefillMap;
    }

    /**
     * Loads session state and merges it into the wizard config.
     *
     * @param config The WizardConfig to enrich with session data
     * @return Updated WizardConfig with session state applied
     */
    @TestVisible
    private static WizardConfig mergeSessionState(WizardConfig config) {
        // Find most recent active session for this wizard
        List<Compliance_Assessment_Session__c> sessions = [
            SELECT Id, Session_State__c, Current_Stage__c, Current_Step__c,
                   Status__c, Percent_Complete__c, Started_Date__c
            FROM Compliance_Assessment_Session__c
            WHERE Wizard_Name__c = :config.wizardName
            AND Status__c NOT IN ('Completed', 'Abandoned')
            AND Assigned_To__c = :UserInfo.getUserId()
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        if (!sessions.isEmpty()) {
            Compliance_Assessment_Session__c session = sessions[0];
            config.sessionId = session.Id;
            config.currentStage = session.Current_Stage__c != null
                ? session.Current_Stage__c.intValue() : 1;
            config.currentStep = session.Current_Step__c != null
                ? session.Current_Step__c.intValue() : 1;
            config.percentComplete = session.Percent_Complete__c ?? 0;
            config.sessionStatus = session.Status__c ?? 'Not Started';

            Map<String, Object> stateMap = deserializeState(session.Session_State__c);
            applyStateToConfig(config, stateMap);
        }

        return config;
    }

    /**
     * Applies persisted state map to the wizard config steps.
     *
     * @param config The WizardConfig to update
     * @param stateMap Map from Session_State__c JSON
     */
    @TestVisible
    private static void applyStateToConfig(WizardConfig config, Map<String, Object> stateMap) {
        for (WizardStage stage : config.stages) {
            Boolean allComplete = true;
            for (WizardStep step : stage.steps) {
                Object stepData = stateMap.get(step.stepId);
                if (stepData instanceof Map<String, Object>) {
                    Map<String, Object> stepMap = (Map<String, Object>) stepData;
                    step.status = (String) stepMap.get('status') ?? 'Pending';
                    step.response = (String) stepMap.get('response');
                }
                if (step.status != 'Completed') {
                    allComplete = false;
                }
            }
            stage.isComplete = allComplete;
        }
    }

    /**
     * Safely deserializes Session_State__c JSON.
     *
     * @param stateJson The JSON string
     * @return Deserialized map or empty map if invalid
     */
    @TestVisible
    private static Map<String, Object> deserializeState(String stateJson) {
        if (String.isBlank(stateJson)) {
            return new Map<String, Object>();
        }
        try {
            Object parsed = JSON.deserializeUntyped(stateJson);
            if (parsed instanceof Map<String, Object>) {
                return (Map<String, Object>) parsed;
            }
        } catch (Exception e) {
            ElaroLogger.warn('AssessmentWizardService.deserializeState',
                new Map<String, Object>{ 'error' => e.getMessage() });
        }
        return new Map<String, Object>();
    }
}
