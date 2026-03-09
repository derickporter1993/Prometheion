/**
 * Tests for ElaroAsyncFeatureFlags: defaults when setting absent, custom values
 * when Custom Setting is populated.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see ElaroAsyncFeatureFlags
 */
@IsTest
private class ElaroAsyncFeatureFlagsTest {

    @IsTest
    static void shouldReturnDefaultWhenSettingAbsent() {
        Test.startTest();
        Boolean frameworkEnabled = ElaroAsyncFeatureFlags.isFrameworkEnabled();
        Integer maxRetries = ElaroAsyncFeatureFlags.getMaxRetryCount();
        Integer maxFetchSize = ElaroAsyncFeatureFlags.getMaxFetchSize();
        Boolean loggingEnabled = ElaroAsyncFeatureFlags.isStepLoggingEnabled();
        Test.stopTest();

        Assert.isTrue(frameworkEnabled, 'Framework should be enabled by default');
        Assert.areEqual(3, maxRetries, 'Max retries should default to 3');
        Assert.areEqual(200, maxFetchSize, 'Max fetch size should default to 200');
        Assert.isTrue(loggingEnabled, 'Step logging should be enabled by default');
    }

    @IsTest
    static void shouldReturnCustomValues() {
        Elaro_Async_Framework_Flags__c flags = new Elaro_Async_Framework_Flags__c(
            Use_New_Async_Framework__c = false,
            Max_Retry_Count__c = 5,
            Max_Cursor_Fetch_Size__c = 500,
            Enable_Step_Logging__c = false
        );
        insert as user flags;

        Test.startTest();
        Boolean frameworkEnabled = ElaroAsyncFeatureFlags.isFrameworkEnabled();
        Integer maxRetries = ElaroAsyncFeatureFlags.getMaxRetryCount();
        Integer maxFetchSize = ElaroAsyncFeatureFlags.getMaxFetchSize();
        Boolean loggingEnabled = ElaroAsyncFeatureFlags.isStepLoggingEnabled();
        Test.stopTest();

        Assert.isFalse(frameworkEnabled, 'Framework should be disabled per setting');
        Assert.areEqual(5, maxRetries, 'Max retries should match setting');
        Assert.areEqual(500, maxFetchSize, 'Max fetch size should match setting');
        Assert.isFalse(loggingEnabled, 'Step logging should be disabled per setting');
    }

    @IsTest
    static void shouldReturnDefaultsForPartialSetting() {
        Elaro_Async_Framework_Flags__c flags = new Elaro_Async_Framework_Flags__c(
            Use_New_Async_Framework__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean frameworkEnabled = ElaroAsyncFeatureFlags.isFrameworkEnabled();
        Integer maxRetries = ElaroAsyncFeatureFlags.getMaxRetryCount();
        Integer maxFetchSize = ElaroAsyncFeatureFlags.getMaxFetchSize();
        Test.stopTest();

        Assert.isTrue(frameworkEnabled, 'Framework should be enabled');
        Assert.isNotNull(maxRetries, 'Max retries should not be null');
        Assert.isNotNull(maxFetchSize, 'Max fetch size should not be null');
    }
}
