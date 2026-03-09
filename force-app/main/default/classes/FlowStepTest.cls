/**
 * Tests for FlowStep: getName includes flow name, shouldRestart false.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see FlowStep
 */
@IsTest
private class FlowStepTest {

    @IsTest
    static void shouldIncludeFlowNameInGetName() {
        FlowStep step = new FlowStep('My_Test_Flow');

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('FlowStep:My_Test_Flow', name, 'Name should include flow API name');
    }

    @IsTest
    static void shouldNotRestart() {
        FlowStep step = new FlowStep('My_Test_Flow');

        Test.startTest();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.isFalse(restart, 'FlowStep should never restart');
    }

    @IsTest
    static void shouldFinalizeWithoutError() {
        FlowStep step = new FlowStep('My_Test_Flow');
        StepContext ctx = new StepContext();

        Test.startTest();
        step.finalize(ctx);
        Test.stopTest();

        Assert.isNotNull(ctx, 'Context should remain valid after finalize');
    }

    @IsTest
    static void shouldHandleDifferentFlowNames() {
        FlowStep step1 = new FlowStep('Flow_A');
        FlowStep step2 = new FlowStep('Flow_B');

        Test.startTest();
        String name1 = step1.getName();
        String name2 = step2.getName();
        Test.stopTest();

        Assert.areEqual('FlowStep:Flow_A', name1, 'First flow name should be correct');
        Assert.areEqual('FlowStep:Flow_B', name2, 'Second flow name should be correct');
        Assert.areNotEqual(name1, name2, 'Different flows should have different names');
    }
}
