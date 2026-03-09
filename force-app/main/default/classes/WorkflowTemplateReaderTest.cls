/**
 * Tests for WorkflowTemplateReader template parsing.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see WorkflowTemplateReader
 */
@IsTest
private class WorkflowTemplateReaderTest {

    @IsTest
    static void shouldReturnNullForBlankTemplateName() {
        Test.startTest();
        WorkflowTemplateReader.WorkflowTemplate result =
            WorkflowTemplateReader.loadTemplate('');
        Test.stopTest();

        Assert.isNull(result, 'Blank template name should return null');
    }

    @IsTest
    static void shouldReturnNullForNullTemplateName() {
        Test.startTest();
        WorkflowTemplateReader.WorkflowTemplate result =
            WorkflowTemplateReader.loadTemplate(null);
        Test.stopTest();

        Assert.isNull(result, 'Null template name should return null');
    }

    @IsTest
    static void shouldReturnEmptyListForBlankFramework() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowTemplate> results =
            WorkflowTemplateReader.loadTemplatesForFramework('');
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Blank framework should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyListForNullFramework() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowTemplate> results =
            WorkflowTemplateReader.loadTemplatesForFramework(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Null framework should return empty list');
    }

    @IsTest
    static void shouldParseTemplateFromRecord() {
        Compliance_Workflow_Template__mdt record = new Compliance_Workflow_Template__mdt(
            DeveloperName = 'SOC2_Full_Eval',
            Template_Name__c = 'SOC2 Full Evaluation',
            Framework__c = 'SOC2',
            Description__c = 'Full SOC2 compliance evaluation',
            Steps_JSON__c = '[{"order":1,"type":"EVALUATE","framework":"SOC2","category":"Access Control","description":"Evaluate access controls"},{"order":2,"type":"EVALUATE","framework":"SOC2","category":"Encryption","description":"Evaluate encryption"}]',
            Is_Active__c = true
        );

        Test.startTest();
        WorkflowTemplateReader.WorkflowTemplate template =
            WorkflowTemplateReader.parseTemplate(record);
        Test.stopTest();

        Assert.areEqual('SOC2_Full_Eval', template.developerName,
            'DeveloperName should match');
        Assert.areEqual('SOC2 Full Evaluation', template.templateName,
            'Template name should match');
        Assert.areEqual('SOC2', template.framework, 'Framework should match');
        Assert.areEqual('Full SOC2 compliance evaluation', template.description,
            'Description should match');
        Assert.areEqual(2, template.steps.size(), 'Should have 2 steps');
    }

    @IsTest
    static void shouldParseStepsWithCorrectOrder() {
        String stepsJson = '[{"order":3,"type":"SCORE","description":"Calculate score"},{"order":1,"type":"EVALUATE","description":"First step"},{"order":2,"type":"REMEDIATE","description":"Second step"}]';

        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps(stepsJson);
        Test.stopTest();

        Assert.areEqual(3, steps.size(), 'Should have 3 steps');
        Assert.areEqual(1, steps[0].stepOrder, 'First step should have order 1');
        Assert.areEqual(2, steps[1].stepOrder, 'Second step should have order 2');
        Assert.areEqual(3, steps[2].stepOrder, 'Third step should have order 3');
    }

    @IsTest
    static void shouldParseStepProperties() {
        String stepsJson = '[{"order":1,"type":"EVALUATE","framework":"HIPAA","category":"Technical","description":"Check encryption"}]';

        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps(stepsJson);
        Test.stopTest();

        Assert.areEqual(1, steps.size(), 'Should have 1 step');
        WorkflowTemplateReader.WorkflowStep step = steps[0];
        Assert.areEqual(1, step.stepOrder, 'Step order should be 1');
        Assert.areEqual('EVALUATE', step.stepType, 'Step type should be EVALUATE');
        Assert.areEqual('HIPAA', step.framework, 'Framework should be HIPAA');
        Assert.areEqual('Technical', step.category, 'Category should be Technical');
        Assert.areEqual('Check encryption', step.description, 'Description should match');
        Assert.isNotNull(step.config, 'Config map should not be null');
    }

    @IsTest
    static void shouldReturnEmptyStepsForBlankJson() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps('');
        Test.stopTest();

        Assert.isTrue(steps.isEmpty(), 'Blank JSON should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyStepsForNullJson() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps(null);
        Test.stopTest();

        Assert.isTrue(steps.isEmpty(), 'Null JSON should return empty list');
    }

    @IsTest
    static void shouldHandleInvalidStepsJson() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps('not valid json');
        Test.stopTest();

        Assert.isTrue(steps.isEmpty(), 'Invalid JSON should return empty list');
    }

    @IsTest
    static void shouldHandleStepWithMissingFields() {
        String stepsJson = '[{"order":1}]';

        Test.startTest();
        List<WorkflowTemplateReader.WorkflowStep> steps =
            WorkflowTemplateReader.parseSteps(stepsJson);
        Test.stopTest();

        Assert.areEqual(1, steps.size(), 'Should parse step with missing fields');
        Assert.areEqual('EVALUATE', steps[0].stepType,
            'Step type should default to EVALUATE');
        Assert.areEqual('', steps[0].description,
            'Description should default to empty string');
    }

    @IsTest
    static void shouldHandleNullDescription() {
        Compliance_Workflow_Template__mdt record = new Compliance_Workflow_Template__mdt(
            DeveloperName = 'Null_Desc',
            Template_Name__c = 'Null Description Test',
            Framework__c = 'SOC2',
            Is_Active__c = true
        );

        Test.startTest();
        WorkflowTemplateReader.WorkflowTemplate template =
            WorkflowTemplateReader.parseTemplate(record);
        Test.stopTest();

        Assert.areEqual('', template.description,
            'Null description should default to empty string');
        Assert.isTrue(template.steps.isEmpty(),
            'Null steps JSON should result in empty steps list');
    }

    @IsTest
    static void shouldLoadTemplatesForFramework() {
        Test.startTest();
        List<WorkflowTemplateReader.WorkflowTemplate> templates =
            WorkflowTemplateReader.loadTemplatesForFramework('SOC2');
        Test.stopTest();

        Assert.isNotNull(templates, 'Templates list should not be null');
    }
}
