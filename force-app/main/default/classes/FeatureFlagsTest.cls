/**
 * Tests for the {@link FeatureFlags} utility class. Validates that all feature flags
 * default to enabled when no custom setting record exists and that flags correctly
 * reflect disabled state when explicitly set to {@code false}.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Utilities
 * @see FeatureFlags
 * @see Elaro_Feature_Flags__c
 */
@IsTest
private class FeatureFlagsTest {

    /**
     * Verifies all feature flags default to {@code true} when no custom setting record
     * has been created. This ensures that features are enabled out-of-the-box.
     */
    @IsTest
    static void shouldDefaultToEnabledWhenNoSettingExists() {
        Test.startTest();
        Boolean commandCenter = FeatureFlags.isCommandCenterEnabled();
        Boolean eventMonitoring = FeatureFlags.isEventMonitoringEnabled();
        Boolean aiGovernance = FeatureFlags.isAIGovernanceEnabled();
        Boolean secModule = FeatureFlags.isSECModuleEnabled();
        Boolean trustCenter = FeatureFlags.isTrustCenterEnabled();
        Boolean assessmentWizard = FeatureFlags.isAssessmentWizardEnabled();
        Test.stopTest();

        Assert.isTrue(commandCenter, 'Command Center should default to enabled');
        Assert.isTrue(eventMonitoring, 'Event Monitoring should default to enabled');
        Assert.isTrue(aiGovernance, 'AI Governance should default to enabled');
        Assert.isTrue(secModule, 'SEC Module should default to enabled');
        Assert.isTrue(trustCenter, 'Trust Center should default to enabled');
        Assert.isTrue(assessmentWizard, 'Assessment Wizard should default to enabled');
    }

    /**
     * Verifies that Command Center flag returns {@code false} when explicitly disabled
     * via a custom setting record.
     */
    @IsTest
    static void shouldReturnFalseWhenCommandCenterDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = false,
            Event_Monitoring_Enabled__c = true,
            AI_Governance_Enabled__c = true,
            SEC_Module_Enabled__c = true,
            Trust_Center_Enabled__c = true,
            Assessment_Wizard_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isCommandCenterEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'Command Center should be disabled when flag is false');
    }

    /**
     * Verifies that Event Monitoring flag returns {@code false} when explicitly disabled.
     */
    @IsTest
    static void shouldReturnFalseWhenEventMonitoringDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = true,
            Event_Monitoring_Enabled__c = false,
            AI_Governance_Enabled__c = true,
            SEC_Module_Enabled__c = true,
            Trust_Center_Enabled__c = true,
            Assessment_Wizard_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isEventMonitoringEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'Event Monitoring should be disabled when flag is false');
    }

    /**
     * Verifies that AI Governance flag returns {@code false} when explicitly disabled.
     */
    @IsTest
    static void shouldReturnFalseWhenAIGovernanceDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = true,
            Event_Monitoring_Enabled__c = true,
            AI_Governance_Enabled__c = false,
            SEC_Module_Enabled__c = true,
            Trust_Center_Enabled__c = true,
            Assessment_Wizard_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isAIGovernanceEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'AI Governance should be disabled when flag is false');
    }

    /**
     * Verifies that SEC Module flag returns {@code false} when explicitly disabled.
     */
    @IsTest
    static void shouldReturnFalseWhenSECModuleDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = true,
            Event_Monitoring_Enabled__c = true,
            AI_Governance_Enabled__c = true,
            SEC_Module_Enabled__c = false,
            Trust_Center_Enabled__c = true,
            Assessment_Wizard_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isSECModuleEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'SEC Module should be disabled when flag is false');
    }

    /**
     * Verifies that Trust Center flag returns {@code false} when explicitly disabled.
     */
    @IsTest
    static void shouldReturnFalseWhenTrustCenterDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = true,
            Event_Monitoring_Enabled__c = true,
            AI_Governance_Enabled__c = true,
            SEC_Module_Enabled__c = true,
            Trust_Center_Enabled__c = false,
            Assessment_Wizard_Enabled__c = true
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isTrustCenterEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'Trust Center should be disabled when flag is false');
    }

    /**
     * Verifies that Assessment Wizard flag returns {@code false} when explicitly disabled.
     */
    @IsTest
    static void shouldReturnFalseWhenAssessmentWizardDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = true,
            Event_Monitoring_Enabled__c = true,
            AI_Governance_Enabled__c = true,
            SEC_Module_Enabled__c = true,
            Trust_Center_Enabled__c = true,
            Assessment_Wizard_Enabled__c = false
        );
        insert as user flags;

        Test.startTest();
        Boolean result = FeatureFlags.isAssessmentWizardEnabled();
        Test.stopTest();

        Assert.isFalse(result, 'Assessment Wizard should be disabled when flag is false');
    }

    /**
     * Verifies that all flags correctly return {@code false} when every feature is disabled.
     */
    @IsTest
    static void shouldReturnAllFalseWhenAllFeaturesDisabled() {
        Elaro_Feature_Flags__c flags = new Elaro_Feature_Flags__c(
            Command_Center_Enabled__c = false,
            Event_Monitoring_Enabled__c = false,
            AI_Governance_Enabled__c = false,
            SEC_Module_Enabled__c = false,
            Trust_Center_Enabled__c = false,
            Assessment_Wizard_Enabled__c = false
        );
        insert as user flags;

        Test.startTest();
        Boolean commandCenter = FeatureFlags.isCommandCenterEnabled();
        Boolean eventMonitoring = FeatureFlags.isEventMonitoringEnabled();
        Boolean aiGovernance = FeatureFlags.isAIGovernanceEnabled();
        Boolean secModule = FeatureFlags.isSECModuleEnabled();
        Boolean trustCenter = FeatureFlags.isTrustCenterEnabled();
        Boolean assessmentWizard = FeatureFlags.isAssessmentWizardEnabled();
        Test.stopTest();

        Assert.isFalse(commandCenter, 'Command Center should be disabled');
        Assert.isFalse(eventMonitoring, 'Event Monitoring should be disabled');
        Assert.isFalse(aiGovernance, 'AI Governance should be disabled');
        Assert.isFalse(secModule, 'SEC Module should be disabled');
        Assert.isFalse(trustCenter, 'Trust Center should be disabled');
        Assert.isFalse(assessmentWizard, 'Assessment Wizard should be disabled');
    }
}
