/**
 * Tests for RemediationService remediation coordination.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Rule Engine
 * @see RemediationService
 */
@IsTest
private class RemediationServiceTest {

    private static RuleResult createFailedResult(String devName) {
        RuleResult result = new RuleResult();
        result.ruleDeveloperName = devName;
        result.ruleName = devName + ' Rule';
        result.framework = 'SOC2';
        result.passed = false;
        result.findingDetails = 'Non-compliant configuration found';
        result.severity = 'HIGH';
        return result;
    }

    @IsTest
    static void shouldReturnEmptyOutcomesForNullInput() {
        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(null);
        Test.stopTest();

        Assert.isTrue(outcomes.isEmpty(), 'Null input should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyOutcomesForEmptyList() {
        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(new List<RuleResult>());
        Test.stopTest();

        Assert.isTrue(outcomes.isEmpty(), 'Empty input should return empty list');
    }

    @IsTest
    static void shouldProcessFailedResults() {
        List<RuleResult> failedResults = new List<RuleResult>{
            createFailedResult('Test_Rule_001'),
            createFailedResult('Test_Rule_002')
        };

        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(failedResults);
        Test.stopTest();

        Assert.areEqual(2, outcomes.size(), 'Should have 2 outcomes');
        for (RemediationService.RemediationOutcome outcome : outcomes) {
            Assert.isNotNull(outcome.ruleDeveloperName,
                'Rule developer name should be set');
            Assert.isNotNull(outcome.message, 'Message should be set');
        }
    }

    @IsTest
    static void shouldSkipPassingResults() {
        RuleResult passedResult = new RuleResult();
        passedResult.ruleDeveloperName = 'Passed_Rule';
        passedResult.passed = true;

        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(
                new List<RuleResult>{ passedResult });
        Test.stopTest();

        Assert.isTrue(outcomes.isEmpty(),
            'Passing results should be skipped');
    }

    @IsTest
    static void shouldSkipResultsWithBlankDeveloperName() {
        RuleResult result = new RuleResult();
        result.passed = false;
        result.ruleDeveloperName = '';

        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(
                new List<RuleResult>{ result });
        Test.stopTest();

        Assert.isTrue(outcomes.isEmpty(),
            'Results with blank developer name should be skipped');
    }

    @IsTest
    static void shouldLoadRemediations() {
        Test.startTest();
        Map<String, Compliance_Remediation__mdt> remMap =
            RemediationService.loadRemediations();
        Test.stopTest();

        Assert.isNotNull(remMap, 'Remediation map should not be null');
    }

    @IsTest
    static void shouldSetRemediationOutcomeProperties() {
        RemediationService.RemediationOutcome outcome =
            new RemediationService.RemediationOutcome();
        outcome.ruleDeveloperName = 'Test_Rule';
        outcome.success = true;
        outcome.actionType = 'NOTIFY';
        outcome.message = 'Notification sent';

        Assert.areEqual('Test_Rule', outcome.ruleDeveloperName,
            'Property getter should work');
        Assert.isTrue(outcome.success, 'Success should be true');
        Assert.areEqual('NOTIFY', outcome.actionType, 'Action type should match');
        Assert.areEqual('Notification sent', outcome.message, 'Message should match');
    }

    @IsTest
    static void shouldHandleNonAutoRemediateRule() {
        RuleResult failedResult = createFailedResult('Non_Auto_Rule');

        Test.startTest();
        List<RemediationService.RemediationOutcome> outcomes =
            RemediationService.processFailedResults(
                new List<RuleResult>{ failedResult });
        Test.stopTest();

        Assert.areEqual(1, outcomes.size(), 'Should have 1 outcome');
        // Since the rule likely doesn't exist in CMT, auto-remediate is not enabled
        Assert.areEqual('NONE', outcomes[0].actionType,
            'Action type should be NONE for non-auto-remediate rule');
    }
}
