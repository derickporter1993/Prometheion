/**
 * Tests for DMLStep: small batch, auto-chunking with 500 records, empty list.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see DMLStep
 */
@IsTest
private class DMLStepTest {

    private class TestDMLStep extends DMLStep {
        private List<SObject> records;
        public List<List<SObject>> processedBatches = new List<List<SObject>>();
        private Boolean finalized = false;

        public TestDMLStep(List<SObject> records) {
            this.records = records;
        }

        public override List<SObject> getRecordsToProcess(StepContext ctx) {
            return records;
        }

        public override void processBatch(List<SObject> batch, StepContext ctx) {
            processedBatches.add(batch);
        }

        public override void finalize(StepContext ctx) {
            finalized = true;
        }

        public override String getName() {
            return 'TestDMLStep';
        }
    }

    @IsTest
    static void shouldProcessSmallBatch() {
        List<Account> testRecords = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            testRecords.add(new Account(Name = 'Test ' + i));
        }
        TestDMLStep step = new TestDMLStep(testRecords);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual(1, step.processedBatches.size(), 'Should process in single batch');
        Assert.areEqual(50, step.processedBatches[0].size(), 'Batch should contain all 50 records');
        Assert.areEqual(50, ctx.totalRecordsProcessed, 'Total records should be 50');
    }

    @IsTest
    static void shouldAutoChunk500Records() {
        List<Account> testRecords = new List<Account>();
        for (Integer i = 0; i < 500; i++) {
            testRecords.add(new Account(Name = 'Test ' + i));
        }
        TestDMLStep step = new TestDMLStep(testRecords);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual(3, step.processedBatches.size(), 'Should chunk into 3 batches (200+200+100)');
        Assert.areEqual(200, step.processedBatches[0].size(), 'First batch should be 200');
        Assert.areEqual(200, step.processedBatches[1].size(), 'Second batch should be 200');
        Assert.areEqual(100, step.processedBatches[2].size(), 'Third batch should be 100');
        Assert.areEqual(500, ctx.totalRecordsProcessed, 'Total records should be 500');
    }

    @IsTest
    static void shouldHandleEmptyList() {
        TestDMLStep step = new TestDMLStep(new List<Account>());
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(step.processedBatches.isEmpty(), 'Should not process any batches');
        Assert.areEqual(0, ctx.totalRecordsProcessed, 'Total records should be 0');
    }

    @IsTest
    static void shouldHandleNullList() {
        TestDMLStep step = new TestDMLStep(null);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(step.processedBatches.isEmpty(), 'Should not process any batches for null');
        Assert.areEqual(0, ctx.totalRecordsProcessed, 'Total records should be 0');
    }

    @IsTest
    static void shouldNotRestart() {
        TestDMLStep step = new TestDMLStep(new List<Account>());

        Test.startTest();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.isFalse(restart, 'DMLStep should never restart');
    }

    @IsTest
    static void shouldReturnCorrectName() {
        TestDMLStep step = new TestDMLStep(new List<Account>());

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('TestDMLStep', name, 'Should return the step name');
    }

    @IsTest
    static void shouldFinalize() {
        TestDMLStep step = new TestDMLStep(new List<Account>());
        StepContext ctx = new StepContext();

        Test.startTest();
        step.finalize(ctx);
        Test.stopTest();

        Assert.isTrue(step.finalized, 'Finalize should be called');
    }

    @IsTest
    static void shouldProcessExactBatchSizeMultiple() {
        List<Account> testRecords = new List<Account>();
        for (Integer i = 0; i < 400; i++) {
            testRecords.add(new Account(Name = 'Test ' + i));
        }
        TestDMLStep step = new TestDMLStep(testRecords);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual(2, step.processedBatches.size(), 'Should chunk into exactly 2 batches');
        Assert.areEqual(200, step.processedBatches[0].size(), 'First batch should be 200');
        Assert.areEqual(200, step.processedBatches[1].size(), 'Second batch should be 200');
    }
}
