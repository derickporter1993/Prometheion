/**
 * Tests for ComplianceOrchestrationEngine workflow execution.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see ComplianceOrchestrationEngine
 */
@IsTest
private class ComplianceOrchestrationEngineTest {

    @IsTest
    static void shouldExecuteForFrameworkAndCreateAuditRecords() {
        Test.startTest();
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            ComplianceOrchestrationEngine.executeForFramework('SOC2', 'SOC2 Test Evaluation');
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isNotNull(result.workflowExecutionId, 'Workflow execution ID should be set');
        Assert.areEqual('COMPLETED', result.status, 'Status should be COMPLETED');
        Assert.areEqual('SOC2', result.framework, 'Framework should match');
        Assert.areEqual('SOC2 Test Evaluation', result.templateName, 'Template name should match');
        Assert.isNotNull(result.ruleResults, 'Rule results should not be null');
        Assert.isNotNull(result.complianceScore, 'Compliance score should be set');
        Assert.areEqual(result.rulesPassed + result.rulesFailed, result.totalRules,
            'Passed + failed should equal total');

        // Verify Workflow_Execution__c record was created
        List<Workflow_Execution__c> executions = [
            SELECT Id, Status__c, Framework__c, Template_Name__c, Compliance_Score__c,
                   Total_Rules__c, Rules_Passed__c, Rules_Failed__c
            FROM Workflow_Execution__c
            WHERE Id = :result.workflowExecutionId
            WITH USER_MODE
        ];
        Assert.areEqual(1, executions.size(), 'Should have 1 execution record');
        Assert.areEqual('COMPLETED', executions[0].Status__c, 'Record status should be COMPLETED');
        Assert.areEqual('SOC2', executions[0].Framework__c, 'Record framework should match');
    }

    @IsTest
    static void shouldCreateStepExecutionRecords() {
        Test.startTest();
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            ComplianceOrchestrationEngine.executeForFramework('HIPAA', 'HIPAA Test');
        Test.stopTest();

        // Verify Step_Execution__c records match rule results
        List<Step_Execution__c> steps = [
            SELECT Id, Rule_Developer_Name__c, Status__c, Severity__c
            FROM Step_Execution__c
            WHERE Workflow_Execution__c = :result.workflowExecutionId
            WITH USER_MODE
        ];
        Assert.areEqual(result.totalRules, steps.size(),
            'Step count should match total rules evaluated');
    }

    @IsTest
    static void shouldThrowForNonExistentTemplate() {
        Test.startTest();
        try {
            ComplianceOrchestrationEngine.executeWorkflow('Non_Existent_Template_XYZ');
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not found'),
                'Exception message should indicate template not found');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldDefaultTemplateNameWhenNull() {
        Test.startTest();
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            ComplianceOrchestrationEngine.executeForFramework('GDPR', null);
        Test.stopTest();

        Assert.areEqual('GDPR Evaluation', result.templateName,
            'Should default template name to framework + Evaluation');
    }

    @IsTest
    static void shouldSetWorkflowExecutionResultProperties() {
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            new ComplianceOrchestrationEngine.WorkflowExecutionResult();
        result.workflowExecutionId = null;
        result.templateName = 'Test';
        result.framework = 'SOC2';
        result.status = 'PENDING';
        result.ruleResults = new List<RuleResult>();
        result.complianceScore = 85.5;
        result.totalRules = 10;
        result.rulesPassed = 8;
        result.rulesFailed = 2;

        Assert.areEqual('Test', result.templateName, 'Property getter should work');
        Assert.areEqual(85.5, result.complianceScore, 'Score property should work');
        Assert.areEqual(10, result.totalRules, 'Total rules property should work');
    }

    @IsTest
    static void shouldCalculateComplianceScore() {
        Test.startTest();
        ComplianceOrchestrationEngine.WorkflowExecutionResult result =
            ComplianceOrchestrationEngine.executeForFramework('PCI_DSS', 'PCI-DSS Test');
        Test.stopTest();

        Assert.isTrue(result.complianceScore >= 0 && result.complianceScore <= 100,
            'Score should be between 0 and 100, got: ' + result.complianceScore);
    }
}
