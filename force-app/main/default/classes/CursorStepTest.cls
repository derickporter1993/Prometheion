/**
 * Tests for CursorStep: CursorLike mock, single batch, multi batch, empty dataset,
 * position tracking, shouldRestart, setFetchSize clamping, circuit breakers.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see CursorStep
 */
@IsTest
private class CursorStepTest {

    /**
     * Concrete CursorStep implementation for testing.
     */
    private class TestCursorStep extends CursorStep {
        public List<SObject> processedRecords = new List<SObject>();

        public override String getCursorQuery() {
            return 'SELECT Id, Name FROM Account WITH USER_MODE';
        }

        public override Map<String, Object> getCursorBinds() {
            return new Map<String, Object>();
        }

        public override void innerExecute(List<SObject> records, StepContext ctx) {
            processedRecords.addAll(records);
        }

        public override void finalize(StepContext ctx) {
            ctx.put('finalized', true);
        }

        public override String getName() {
            return 'TestCursorStep';
        }
    }

    private static List<Account> createTestAccounts(Integer count) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Test Account ' + i));
        }
        return accounts;
    }

    @IsTest
    static void shouldProcessSingleBatch() {
        TestCursorStep step = new TestCursorStep();
        List<Account> testData = createTestAccounts(50);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.areEqual(50, step.processedRecords.size(), 'Should process all 50 records');
        Assert.areEqual(50, ctx.cursorPosition, 'Cursor position should advance to 50');
        Assert.areEqual(50, ctx.totalRecordsProcessed, 'Total records should be 50');
        Assert.isFalse(step.shouldRestart(), 'Should not restart after single complete batch');
    }

    @IsTest
    static void shouldProcessMultipleBatches() {
        TestCursorStep step = new TestCursorStep();
        step.setFetchSize(100);
        List<Account> testData = createTestAccounts(250);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();

        Test.startTest();

        step.execute(ctx);
        Assert.areEqual(100, step.processedRecords.size(), 'First batch should process 100 records');
        Assert.areEqual(100, ctx.cursorPosition, 'Position should be 100 after first batch');
        Assert.isTrue(step.shouldRestart(), 'Should restart — more records remain');

        step.execute(ctx);
        Assert.areEqual(200, step.processedRecords.size(), 'Second batch should process next 100');
        Assert.areEqual(200, ctx.cursorPosition, 'Position should be 200 after second batch');
        Assert.isTrue(step.shouldRestart(), 'Should still restart — 50 records remain');

        step.execute(ctx);
        Assert.areEqual(250, step.processedRecords.size(), 'Third batch should process final 50');
        Assert.areEqual(250, ctx.cursorPosition, 'Position should be 250 after final batch');
        Assert.isFalse(step.shouldRestart(), 'Should not restart — cursor exhausted');

        Test.stopTest();
    }

    @IsTest
    static void shouldHandleEmptyDataset() {
        TestCursorStep step = new TestCursorStep();
        step.cursorWrapper = new CursorStep.CursorLike(new List<Account>());
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(step.processedRecords.isEmpty(), 'Should process zero records');
        Assert.areEqual(0, ctx.cursorPosition, 'Position should remain 0');
        Assert.isFalse(step.shouldRestart(), 'Should not restart on empty dataset');
    }

    @IsTest
    static void shouldTrackPositionCorrectly() {
        TestCursorStep step = new TestCursorStep();
        step.setFetchSize(10);
        List<Account> testData = createTestAccounts(25);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Assert.areEqual(10, ctx.cursorPosition, 'Position should be 10');

        step.execute(ctx);
        Assert.areEqual(20, ctx.cursorPosition, 'Position should be 20');

        step.execute(ctx);
        Assert.areEqual(25, ctx.cursorPosition, 'Position should be 25 (end)');
        Test.stopTest();

        Assert.isFalse(step.shouldRestart(), 'All records consumed');
    }

    @IsTest
    static void shouldClampFetchSizeToMinimum() {
        TestCursorStep step = new TestCursorStep();

        Test.startTest();
        step.setFetchSize(0);
        Test.stopTest();

        List<Account> testData = createTestAccounts(5);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();
        step.execute(ctx);

        Assert.areEqual(1, step.processedRecords.size(),
            'Fetch size should be clamped to minimum of 1');
    }

    @IsTest
    static void shouldClampFetchSizeToMaximum() {
        TestCursorStep step = new TestCursorStep();

        Test.startTest();
        step.setFetchSize(5000);
        Test.stopTest();

        List<Account> testData = createTestAccounts(3000);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();
        step.execute(ctx);

        Assert.areEqual(2000, step.processedRecords.size(),
            'Fetch size should be clamped to maximum of 2000');
    }

    @IsTest
    static void shouldHandlePositionBeyondDataset() {
        TestCursorStep step = new TestCursorStep();
        List<Account> testData = createTestAccounts(10);
        step.cursorWrapper = new CursorStep.CursorLike(testData);
        StepContext ctx = new StepContext();
        ctx.cursorPosition = 100;

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(step.processedRecords.isEmpty(), 'Should process nothing when beyond range');
        Assert.isFalse(step.shouldRestart(), 'Should not restart when position is past end');
    }

    @IsTest
    static void shouldReturnCorrectName() {
        TestCursorStep step = new TestCursorStep();

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('TestCursorStep', name, 'Should return the step name');
    }

    @IsTest
    static void shouldFinalizeCorrectly() {
        TestCursorStep step = new TestCursorStep();
        StepContext ctx = new StepContext();

        Test.startTest();
        step.finalize(ctx);
        Test.stopTest();

        Assert.isTrue(ctx.getBoolean('finalized'), 'Finalize should update context');
    }

    @IsTest
    static void cursorLikeShouldReturnCorrectNumRecords() {
        List<Account> testData = createTestAccounts(42);

        Test.startTest();
        CursorStep.CursorLike cursorLike = new CursorStep.CursorLike(testData);
        Integer count = cursorLike.getNumRecords();
        Test.stopTest();

        Assert.areEqual(42, count, 'CursorLike should report correct record count');
    }

    @IsTest
    static void cursorLikeShouldHandleFetchBeyondEnd() {
        List<Account> testData = createTestAccounts(5);
        CursorStep.CursorLike cursorLike = new CursorStep.CursorLike(testData);

        Test.startTest();
        List<SObject> fetched = cursorLike.fetch(3, 10);
        Test.stopTest();

        Assert.areEqual(2, fetched.size(), 'Should only return remaining records');
    }
}
