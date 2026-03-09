/**
 * Tests for ComputeStep: result stored in context, null result key handling.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see ComputeStep
 */
@IsTest
private class ComputeStepTest {

    private class TestComputeStep extends ComputeStep {
        private Object resultValue;
        private String resultKey;
        private Boolean finalized = false;

        public TestComputeStep(String resultKey, Object resultValue) {
            this.resultKey = resultKey;
            this.resultValue = resultValue;
        }

        public override Object compute(StepContext ctx) {
            return resultValue;
        }

        public override String getResultKey() {
            return resultKey;
        }

        public override void finalize(StepContext ctx) {
            finalized = true;
        }

        public override String getName() {
            return 'TestComputeStep';
        }
    }

    @IsTest
    static void shouldStoreResultInContext() {
        TestComputeStep step = new TestComputeStep('score', 95);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual(95, ctx.get('score'), 'Result should be stored under the result key');
    }

    @IsTest
    static void shouldHandleNullResultKey() {
        TestComputeStep step = new TestComputeStep(null, 'discarded');
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(ctx.state.isEmpty(), 'Nothing should be stored when result key is null');
    }

    @IsTest
    static void shouldHandleNullResultValue() {
        TestComputeStep step = new TestComputeStep('result', null);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(ctx.hasKey('result'), 'Key should exist even with null value');
        Assert.isNull(ctx.get('result'), 'Value should be null');
    }

    @IsTest
    static void shouldNotRestart() {
        TestComputeStep step = new TestComputeStep('key', 'value');

        Test.startTest();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.isFalse(restart, 'ComputeStep should never restart');
    }

    @IsTest
    static void shouldReturnCorrectName() {
        TestComputeStep step = new TestComputeStep('key', 'value');

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('TestComputeStep', name, 'Should return the step name');
    }

    @IsTest
    static void shouldFinalize() {
        TestComputeStep step = new TestComputeStep('key', 'value');
        StepContext ctx = new StepContext();

        Test.startTest();
        step.finalize(ctx);
        Test.stopTest();

        Assert.isTrue(step.finalized, 'Finalize should be called');
    }

    @IsTest
    static void shouldStoreStringResult() {
        TestComputeStep step = new TestComputeStep('message', 'Hello');
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual('Hello', ctx.getString('message'), 'Should store string result');
    }
}
