@IsTest
private class TriggerRecursionGuardTest {

    @IsTest
    static void testIsFirstRun() {
        String triggerName = 'TestTrigger';

        Test.startTest();
        // First call should return true
        Boolean firstRun = TriggerRecursionGuard.isFirstRun(triggerName);
        // Second call should return false
        Boolean secondRun = TriggerRecursionGuard.isFirstRun(triggerName);
        Test.stopTest();

        Assert.areEqual(true, firstRun, 'First call should return true');
        Assert.areEqual(false, secondRun, 'Second call should return false');
    }

    @IsTest
    static void testReset() {
        String triggerName = 'TestTrigger';

        Test.startTest();
        // Mark as running
        TriggerRecursionGuard.isFirstRun(triggerName);
        // Reset
        TriggerRecursionGuard.reset(triggerName);
        // Should be first run again
        Boolean isFirst = TriggerRecursionGuard.isFirstRun(triggerName);
        Test.stopTest();

        Assert.areEqual(true, isFirst, 'After reset, should be first run again');
    }

    @IsTest
    static void testIsRunning() {
        String triggerName = 'TestTrigger';

        Test.startTest();
        // Not running initially
        Boolean notRunning = TriggerRecursionGuard.isRunning(triggerName);
        // Start running
        TriggerRecursionGuard.isFirstRun(triggerName);
        Boolean isRunning = TriggerRecursionGuard.isRunning(triggerName);
        // Reset
        TriggerRecursionGuard.reset(triggerName);
        Boolean notRunningAfterReset = TriggerRecursionGuard.isRunning(triggerName);
        Test.stopTest();

        Assert.areEqual(false, notRunning, 'Should not be running initially');
        Assert.areEqual(true, isRunning, 'Should be running after isFirstRun');
        Assert.areEqual(false, notRunningAfterReset, 'Should not be running after reset');
    }

    @IsTest
    static void testMultipleTriggers() {
        String trigger1 = 'Trigger1';
        String trigger2 = 'Trigger2';

        Test.startTest();
        // Start both triggers
        Boolean first1 = TriggerRecursionGuard.isFirstRun(trigger1);
        Boolean first2 = TriggerRecursionGuard.isFirstRun(trigger2);
        // Check they don't interfere
        Boolean second1 = TriggerRecursionGuard.isFirstRun(trigger1);
        Boolean second2 = TriggerRecursionGuard.isFirstRun(trigger2);
        Test.stopTest();

        Assert.areEqual(true, first1, 'First trigger should be first run');
        Assert.areEqual(true, first2, 'Second trigger should be first run');
        Assert.areEqual(false, second1, 'First trigger should not be first run');
        Assert.areEqual(false, second2, 'Second trigger should not be first run');
    }

    @IsTest
    static void testResetDoesNotAffectOthers() {
        String trigger1 = 'Trigger1';
        String trigger2 = 'Trigger2';

        Test.startTest();
        // Start both
        TriggerRecursionGuard.isFirstRun(trigger1);
        TriggerRecursionGuard.isFirstRun(trigger2);
        // Reset only first
        TriggerRecursionGuard.reset(trigger1);
        // Check states
        Boolean trigger1Running = TriggerRecursionGuard.isRunning(trigger1);
        Boolean trigger2Running = TriggerRecursionGuard.isRunning(trigger2);
        Test.stopTest();

        Assert.areEqual(false, trigger1Running, 'Trigger1 should not be running after reset');
        Assert.areEqual(true, trigger2Running, 'Trigger2 should still be running');
    }

    @IsTest
    static void testNullTriggerName() {
        Test.startTest();
        // Should handle null gracefully
        Boolean result = TriggerRecursionGuard.isFirstRun(null);
        TriggerRecursionGuard.reset(null);
        Boolean isRunning = TriggerRecursionGuard.isRunning(null);
        Test.stopTest();

        // Null is treated as a valid key in Set<String>
        Assert.areNotEqual(null, result, 'Should return a value for null');
    }
}
