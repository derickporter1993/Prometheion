/**
 * Tests for NoOpStep: all methods are no-op and return expected values.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see NoOpStep
 */
@IsTest
private class NoOpStepTest {

    @IsTest
    static void shouldExecuteWithoutSideEffects() {
        NoOpStep step = new NoOpStep();
        StepContext ctx = new StepContext();
        ctx.put('existing', 'value');

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual('value', ctx.getString('existing'), 'Context should be unchanged');
        Assert.areEqual(0, ctx.totalRecordsProcessed, 'No records should be processed');
    }

    @IsTest
    static void shouldFinalizeWithoutSideEffects() {
        NoOpStep step = new NoOpStep();
        StepContext ctx = new StepContext();

        Test.startTest();
        step.finalize(ctx);
        Test.stopTest();

        Assert.isTrue(ctx.state.isEmpty(), 'Context state should be unchanged');
    }

    @IsTest
    static void shouldReturnNoOpName() {
        NoOpStep step = new NoOpStep();

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('NoOp', name, 'Name should be NoOp');
    }

    @IsTest
    static void shouldNotRestart() {
        NoOpStep step = new NoOpStep();

        Test.startTest();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.isFalse(restart, 'NoOpStep should never restart');
    }

    @IsTest
    static void shouldImplementStepInterface() {
        Step step = new NoOpStep();

        Test.startTest();
        StepContext ctx = new StepContext();
        step.execute(ctx);
        step.finalize(ctx);
        String name = step.getName();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.areEqual('NoOp', name, 'Should work through Step interface');
        Assert.isFalse(restart, 'Should not restart through Step interface');
    }
}
