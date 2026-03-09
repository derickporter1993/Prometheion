/**
 * Tests for StepExecutionMetric: both constructors, field defaults.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see StepExecutionMetric
 */
@IsTest
private class StepExecutionMetricTest {

    @IsTest
    static void shouldConstructWithThreeArgs() {
        Test.startTest();
        StepExecutionMetric metric = new StepExecutionMetric('TestStep', 150, true);
        Test.stopTest();

        Assert.areEqual('TestStep', metric.stepName, 'Step name should match');
        Assert.areEqual(150, metric.executionTimeMs, 'Execution time should match');
        Assert.isTrue(metric.success, 'Success should be true');
        Assert.isNull(metric.errorMessage, 'Error message should be null for success');
        Assert.areEqual(0, metric.recordsProcessed, 'Records processed should default to 0');
    }

    @IsTest
    static void shouldConstructWithFourArgs() {
        Test.startTest();
        StepExecutionMetric metric = new StepExecutionMetric('FailStep', 500, false, 'Something broke');
        Test.stopTest();

        Assert.areEqual('FailStep', metric.stepName, 'Step name should match');
        Assert.areEqual(500, metric.executionTimeMs, 'Execution time should match');
        Assert.isFalse(metric.success, 'Success should be false');
        Assert.areEqual('Something broke', metric.errorMessage, 'Error message should match');
        Assert.areEqual(0, metric.recordsProcessed, 'Records processed should default to 0');
    }

    @IsTest
    static void shouldAllowSettingOptionalFields() {
        StepExecutionMetric metric = new StepExecutionMetric('Step', 100, true);

        Test.startTest();
        metric.recordsProcessed = 500;
        metric.soqlQueriesUsed = 10;
        metric.dmlStatementsUsed = 5;
        Test.stopTest();

        Assert.areEqual(500, metric.recordsProcessed, 'Records processed should be set');
        Assert.areEqual(10, metric.soqlQueriesUsed, 'SOQL queries used should be set');
        Assert.areEqual(5, metric.dmlStatementsUsed, 'DML statements used should be set');
    }
}
