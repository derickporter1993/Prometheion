/**
 * Tests for StepContext: typed getters, null coalescing, addRecordsProcessed,
 * state manipulation, and default values.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see StepContext
 */
@IsTest
private class StepContextTest {

    @IsTest
    static void shouldInitializeWithDefaults() {
        Test.startTest();
        StepContext ctx = new StepContext();
        Test.stopTest();

        Assert.isNotNull(ctx.state, 'State map should be initialized');
        Assert.isTrue(ctx.state.isEmpty(), 'State map should be empty');
        Assert.areEqual(0, ctx.cursorPosition, 'Cursor position should default to 0');
        Assert.areEqual(0, ctx.currentStepIndex, 'Current step index should default to 0');
        Assert.isNotNull(ctx.metrics, 'Metrics list should be initialized');
        Assert.isTrue(ctx.metrics.isEmpty(), 'Metrics list should be empty');
        Assert.isNotNull(ctx.errorHistory, 'Error history should be initialized');
        Assert.isTrue(ctx.errorHistory.isEmpty(), 'Error history should be empty');
        Assert.areEqual(0, ctx.retryCount, 'Retry count should default to 0');
        Assert.areEqual(0, ctx.totalRecordsProcessed, 'Total records processed should default to 0');
        Assert.isNull(ctx.workflowId, 'Workflow ID should be null by default');
    }

    @IsTest
    static void shouldPutAndGetValues() {
        StepContext ctx = new StepContext();

        Test.startTest();
        ctx.put('testKey', 'testValue');
        Object result = ctx.get('testKey');
        Test.stopTest();

        Assert.areEqual('testValue', result, 'Should retrieve stored value');
    }

    @IsTest
    static void shouldReturnNullForMissingKey() {
        StepContext ctx = new StepContext();

        Test.startTest();
        Object result = ctx.get('nonexistent');
        Test.stopTest();

        Assert.isNull(result, 'Should return null for missing key');
    }

    @IsTest
    static void shouldGetStringWithDefault() {
        StepContext ctx = new StepContext();
        ctx.put('name', 'Elaro');

        Test.startTest();
        String existing = ctx.getString('name');
        String missing = ctx.getString('nonexistent');
        Test.stopTest();

        Assert.areEqual('Elaro', existing, 'Should return stored string');
        Assert.areEqual('', missing, 'Should return empty string for missing key');
    }

    @IsTest
    static void shouldGetIntegerWithDefault() {
        StepContext ctx = new StepContext();
        ctx.put('count', 42);

        Test.startTest();
        Integer existing = ctx.getInteger('count');
        Integer missing = ctx.getInteger('nonexistent');
        Test.stopTest();

        Assert.areEqual(42, existing, 'Should return stored integer');
        Assert.areEqual(0, missing, 'Should return 0 for missing key');
    }

    @IsTest
    static void shouldGetBooleanWithDefault() {
        StepContext ctx = new StepContext();
        ctx.put('enabled', true);

        Test.startTest();
        Boolean existing = ctx.getBoolean('enabled');
        Boolean missing = ctx.getBoolean('nonexistent');
        Test.stopTest();

        Assert.isTrue(existing, 'Should return stored boolean');
        Assert.isFalse(missing, 'Should return false for missing key');
    }

    @IsTest
    static void shouldCheckHasKey() {
        StepContext ctx = new StepContext();
        ctx.put('present', 'value');

        Test.startTest();
        Boolean hasPresent = ctx.hasKey('present');
        Boolean hasMissing = ctx.hasKey('absent');
        Test.stopTest();

        Assert.isTrue(hasPresent, 'Should find existing key');
        Assert.isFalse(hasMissing, 'Should not find missing key');
    }

    @IsTest
    static void shouldRemoveKey() {
        StepContext ctx = new StepContext();
        ctx.put('temp', 'data');

        Test.startTest();
        ctx.remove('temp');
        Test.stopTest();

        Assert.isFalse(ctx.hasKey('temp'), 'Key should be removed');
    }

    @IsTest
    static void shouldAddRecordsProcessed() {
        StepContext ctx = new StepContext();

        Test.startTest();
        ctx.addRecordsProcessed(100);
        ctx.addRecordsProcessed(200);
        ctx.addRecordsProcessed(50);
        Test.stopTest();

        Assert.areEqual(350, ctx.totalRecordsProcessed, 'Should accumulate records processed');
    }

    @IsTest
    static void shouldTrackErrorHistory() {
        StepContext ctx = new StepContext();

        Test.startTest();
        ctx.errorHistory.add('Error 1');
        ctx.errorHistory.add('Error 2');
        Test.stopTest();

        Assert.areEqual(2, ctx.errorHistory.size(), 'Should track multiple errors');
        Assert.areEqual('Error 1', ctx.errorHistory[0], 'Should preserve error order');
    }

    @IsTest
    static void shouldTrackMetrics() {
        StepContext ctx = new StepContext();

        Test.startTest();
        ctx.metrics.add(new StepExecutionMetric('Step1', 100, true));
        ctx.metrics.add(new StepExecutionMetric('Step2', 200, false, 'Failed'));
        Test.stopTest();

        Assert.areEqual(2, ctx.metrics.size(), 'Should track multiple metrics');
        Assert.areEqual('Step1', ctx.metrics[0].stepName, 'Should preserve metric order');
    }
}
