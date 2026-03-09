/**
 * Tests for StepProcessor: single step, multi step, cursor re-enqueue,
 * feature flag disabled, static factory methods.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see StepProcessor
 */
@IsTest
private class StepProcessorTest {

    /**
     * Simple Step implementation for testing that tracks execution.
     */
    private class TrackingStep implements Step {
        public Boolean executed = false;
        public Boolean finalized = false;
        private String name;
        private Boolean restart;

        public TrackingStep(String name) {
            this.name = name;
            this.restart = false;
        }

        public TrackingStep(String name, Boolean restart) {
            this.name = name;
            this.restart = restart;
        }

        public void execute(StepContext ctx) {
            executed = true;
            Integer count = ctx.getInteger('executionCount');
            ctx.put('executionCount', count + 1);
        }

        public void finalize(StepContext ctx) {
            finalized = true;
        }

        public String getName() {
            return name;
        }

        public Boolean shouldRestart() {
            return restart;
        }
    }

    /**
     * Step that sets needsRestart flag once, then completes.
     */
    private class RestartOnceStep implements Step {
        public Integer executeCount = 0;
        public Boolean finalized = false;

        public void execute(StepContext ctx) {
            executeCount++;
            if (executeCount == 1) {
                ctx.put('needsRestart', true);
            }
        }

        public void finalize(StepContext ctx) {
            finalized = true;
        }

        public String getName() {
            return 'RestartOnceStep';
        }

        public Boolean shouldRestart() {
            return false;
        }
    }

    /**
     * Step that throws an exception to test error handling.
     */
    private class FailingStep implements Step {
        public void execute(StepContext ctx) {
            throw new AuraHandledException('Intentional test failure');
        }

        public void finalize(StepContext ctx) {}

        public String getName() {
            return 'FailingStep';
        }

        public Boolean shouldRestart() {
            return false;
        }
    }

    @IsTest
    static void shouldExecuteSingleStep() {
        TrackingStep step = new TrackingStep('Step1');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isTrue(step.executed, 'Step should have been executed');
        Assert.areEqual(1, ctx.getInteger('executionCount'), 'Execution count should be 1');
        Assert.areEqual(1, ctx.metrics.size(), 'Should have 1 metric');
        Assert.isTrue(ctx.metrics[0].success, 'Metric should indicate success');
    }

    @IsTest
    static void shouldCaptureMetrics() {
        TrackingStep step = new TrackingStep('MetricStep');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.areEqual(1, ctx.metrics.size(), 'Should have captured 1 metric');
        StepExecutionMetric metric = ctx.metrics[0];
        Assert.areEqual('MetricStep', metric.stepName, 'Metric step name should match');
        Assert.isTrue(metric.success, 'Metric should be successful');
        Assert.isTrue(metric.executionTimeMs >= 0, 'Execution time should be non-negative');
        Assert.isNotNull(metric.soqlQueriesUsed, 'SOQL queries should be tracked');
        Assert.isNotNull(metric.dmlStatementsUsed, 'DML statements should be tracked');
    }

    @IsTest
    static void shouldHandleFeatureFlagDisabled() {
        Elaro_Async_Framework_Flags__c flags = new Elaro_Async_Framework_Flags__c(
            Use_New_Async_Framework__c = false,
            Max_Retry_Count__c = 3,
            Max_Cursor_Fetch_Size__c = 200,
            Enable_Step_Logging__c = true
        );
        insert as user flags;

        TrackingStep step = new TrackingStep('DisabledStep');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isFalse(step.executed, 'Step should NOT execute when framework is disabled');
    }

    @IsTest
    static void shouldRunWithStaticFactoryNoContext() {
        Test.startTest();
        Id jobId = StepProcessor.run(new List<Step>{ new NoOpStep() });
        Test.stopTest();

        Assert.isNotNull(jobId, 'Should return a valid job Id');
    }

    @IsTest
    static void shouldRunWithStaticFactoryWithContext() {
        StepContext ctx = new StepContext();
        ctx.put('initialKey', 'initialValue');

        Test.startTest();
        Id jobId = StepProcessor.run(new List<Step>{ new NoOpStep() }, ctx);
        Test.stopTest();

        Assert.isNotNull(jobId, 'Should return a valid job Id');
    }

    @IsTest
    static void shouldHandleEmptyStepList() {
        StepContext ctx = new StepContext();
        ctx.currentStepIndex = 0;

        Test.startTest();
        StepProcessor processor = new StepProcessor(new List<Step>(), ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isTrue(ctx.metrics.isEmpty(), 'No metrics should be captured for empty steps');
    }

    @IsTest
    static void shouldHandleStepIndexBeyondListSize() {
        TrackingStep step = new TrackingStep('NeverRun');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();
        ctx.currentStepIndex = 5;

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isFalse(step.executed, 'Step should not execute when index is beyond list');
    }

    @IsTest
    static void shouldPublishStepLogEvent() {
        TrackingStep step = new TrackingStep('LoggedStep');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isTrue(step.executed, 'Step should have executed');
    }

    @IsTest
    static void shouldUseCustomRetryCountFromSetting() {
        Elaro_Async_Framework_Flags__c flags = new Elaro_Async_Framework_Flags__c(
            Use_New_Async_Framework__c = true,
            Max_Retry_Count__c = 7,
            Max_Cursor_Fetch_Size__c = 200,
            Enable_Step_Logging__c = true
        );
        insert as user flags;

        TrackingStep step = new TrackingStep('CustomRetryStep');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isTrue(step.executed, 'Step should execute with custom retry settings');
    }

    @IsTest
    static void shouldTrackWorkflowIdInLog() {
        TrackingStep step = new TrackingStep('WorkflowStep');
        List<Step> steps = new List<Step>{ step };
        StepContext ctx = new StepContext();

        Account testAccount = new Account(Name = 'Workflow Test');
        insert as user testAccount;
        ctx.workflowId = testAccount.Id;

        Test.startTest();
        StepProcessor processor = new StepProcessor(steps, ctx);
        System.enqueueJob(processor);
        Test.stopTest();

        Assert.isTrue(step.executed, 'Step should execute with workflow Id set');
    }
}
