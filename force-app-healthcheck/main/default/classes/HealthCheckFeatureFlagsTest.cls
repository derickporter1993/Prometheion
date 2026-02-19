/**
 * Tests for {@link HealthCheckFeatureFlags} covering default-on behavior,
 * custom setting overrides, and null handling for the kill-switch pattern.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see HealthCheckFeatureFlags
 */
@IsTest(testFor = HealthCheckFeatureFlags.class)
private class HealthCheckFeatureFlagsTest {

    @IsTest
    static void shouldDefaultToEnabledWhenNoCustomSetting() {
        // No custom setting record inserted — getInstance() returns null
        Test.startTest();
        Boolean enabled = HealthCheckFeatureFlags.isEnabled();
        Test.stopTest();

        Assert.isTrue(enabled,
            'isEnabled should default to true when no custom setting exists');
    }

    @IsTest
    static void shouldDefaultTo90DaysWhenNoCustomSetting() {
        // No custom setting record inserted — getInstance() returns null
        Test.startTest();
        Integer maxDays = HealthCheckFeatureFlags.getMaxDays();
        Test.stopTest();

        Assert.areEqual(90, maxDays,
            'getMaxDays should default to 90 when no custom setting exists');
    }

    @IsTest
    static void shouldReturnEnabledWhenCustomSettingIsTrue() {
        Health_Check_Feature_Flags__c flags = new Health_Check_Feature_Flags__c(
            Health_Check_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean enabled = HealthCheckFeatureFlags.isEnabled();
        Test.stopTest();

        Assert.isTrue(enabled,
            'isEnabled should return true when custom setting is explicitly true');
    }

    @IsTest
    static void shouldReturnDisabledWhenCustomSettingIsFalse() {
        Health_Check_Feature_Flags__c flags = new Health_Check_Feature_Flags__c(
            Health_Check_Enabled__c = false
        );
        insert as user flags;

        Test.startTest();
        Boolean enabled = HealthCheckFeatureFlags.isEnabled();
        Test.stopTest();

        Assert.isFalse(enabled,
            'isEnabled should return false when custom setting is explicitly false');
    }

    @IsTest
    static void shouldReturnCustomMaxDaysWhenSet() {
        Health_Check_Feature_Flags__c flags = new Health_Check_Feature_Flags__c(
            Max_LoginHistory_Days__c = 30
        );
        insert as user flags;

        Test.startTest();
        Integer maxDays = HealthCheckFeatureFlags.getMaxDays();
        Test.stopTest();

        Assert.areEqual(30, maxDays,
            'getMaxDays should return the configured value');
    }

    @IsTest
    static void shouldReturnDefaultMaxDaysWhenFieldIsNull() {
        Health_Check_Feature_Flags__c flags = new Health_Check_Feature_Flags__c(
            Health_Check_Enabled__c = true,
            Max_LoginHistory_Days__c = null
        );
        insert as user flags;

        Test.startTest();
        Integer maxDays = HealthCheckFeatureFlags.getMaxDays();
        Test.stopTest();

        Assert.areEqual(90, maxDays,
            'getMaxDays should default to 90 when Max_LoginHistory_Days__c is null');
    }
}
