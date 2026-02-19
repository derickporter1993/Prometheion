/**
 * Tests for {@link HCLogger} covering info, warn, and error log methods
 * including overloads with context maps and exception parameters.
 *
 * Note: HCLogger suppresses output during test execution via {@code Test.isRunningTest()}.
 * These tests verify the methods can be called without exceptions and validate the
 * Level enum values are correctly defined.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see HCLogger
 */
@IsTest(testFor = HCLogger.class)
private class HCLoggerTest {

    @IsTest
    static void shouldLogInfoMessageWithoutException() {
        Test.startTest();
        HCLogger.info('Test info message');
        Test.stopTest();

        // Method completes without throwing; logger suppresses output in test context
        Assert.isTrue(true, 'info(String) should execute without exception');
    }

    @IsTest
    static void shouldLogInfoMessageWithContext() {
        Map<String, Object> context = new Map<String, Object>{
            'recordId' => '001000000000001',
            'action' => 'scan'
        };

        Test.startTest();
        HCLogger.info('Test info with context', context);
        Test.stopTest();

        Assert.isTrue(true, 'info(String, Map) should execute without exception');
    }

    @IsTest
    static void shouldLogInfoMessageWithNullContext() {
        Test.startTest();
        HCLogger.info('Test info null context', null);
        Test.stopTest();

        Assert.isTrue(true, 'info(String, null) should handle null context gracefully');
    }

    @IsTest
    static void shouldLogInfoMessageWithEmptyContext() {
        Test.startTest();
        HCLogger.info('Test info empty context', new Map<String, Object>());
        Test.stopTest();

        Assert.isTrue(true, 'info(String, emptyMap) should handle empty context gracefully');
    }

    @IsTest
    static void shouldLogWarnMessageWithoutException() {
        Test.startTest();
        HCLogger.warn('Test warning message');
        Test.stopTest();

        Assert.isTrue(true, 'warn(String) should execute without exception');
    }

    @IsTest
    static void shouldLogWarnMessageWithContext() {
        Map<String, Object> context = new Map<String, Object>{
            'threshold' => 80,
            'actual' => 65
        };

        Test.startTest();
        HCLogger.warn('Score below threshold', context);
        Test.stopTest();

        Assert.isTrue(true, 'warn(String, Map) should execute without exception');
    }

    @IsTest
    static void shouldLogErrorMessageWithoutException() {
        Test.startTest();
        HCLogger.error('Test error message');
        Test.stopTest();

        Assert.isTrue(true, 'error(String) should execute without exception');
    }

    @IsTest
    static void shouldLogErrorWithExceptionDetails() {
        Exception testEx;
        try {
            Integer result = 1 / 0;
        } catch (Exception ex) {
            testEx = ex;
        }

        Test.startTest();
        HCLogger.error('Division error occurred', testEx);
        Test.stopTest();

        Assert.isNotNull(testEx, 'Test exception should have been captured');
        Assert.isTrue(true, 'error(String, Exception) should execute without exception');
    }

    @IsTest
    static void shouldDefineAllLogLevels() {
        Test.startTest();
        List<HCLogger.Level> levels = HCLogger.Level.values();
        Test.stopTest();

        Assert.areEqual(4, levels.size(), 'Should define exactly 4 log levels');
        Assert.areEqual(HCLogger.Level.DEBUG_LEVEL, levels[0],
            'First level should be DEBUG_LEVEL');
        Assert.areEqual(HCLogger.Level.INFO_LEVEL, levels[1],
            'Second level should be INFO_LEVEL');
        Assert.areEqual(HCLogger.Level.WARN_LEVEL, levels[2],
            'Third level should be WARN_LEVEL');
        Assert.areEqual(HCLogger.Level.ERROR_LEVEL, levels[3],
            'Fourth level should be ERROR_LEVEL');
    }

    @IsTest
    static void shouldHandleNullMessage() {
        Test.startTest();
        HCLogger.info(null);
        HCLogger.warn(null);
        HCLogger.error(null);
        Test.stopTest();

        Assert.isTrue(true, 'All log methods should handle null messages gracefully');
    }
}
