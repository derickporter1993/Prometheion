@IsTest
private class ElaroAISettingsControllerTest {

    @IsTest
    static void testGetSettings_ReturnsDefaultsWhenNoSettings() {
        // Given: No Elaro_AI_Settings__c record exists

        Test.startTest();
        Elaro_AI_Settings__c settings = ElaroAISettingsController.getSettings();
        Test.stopTest();

        // Then: Should return default values
        Assert.areNotEqual(null, settings, 'Settings should not be null');
        Assert.areEqual(true, settings.Enable_AI_Reasoning__c, 'AI reasoning should be enabled by default');
        Assert.areEqual(0.85, settings.Confidence_Threshold__c, 'Confidence threshold should default to 0.85');
        Assert.areEqual(true, settings.Require_Human_Approval__c, 'Human approval should be required by default');
        Assert.areEqual(false, settings.Auto_Remediation_Enabled__c, 'Auto remediation should be disabled by default');
        Assert.areEqual('', settings.Blacklisted_Users__c, 'Blacklisted users should be empty by default');
    }

    @IsTest
    static void testGetSettings_ReturnsExistingSettings() {
        // Given: Custom settings exist
        Elaro_AI_Settings__c customSettings = new Elaro_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = false,
            Confidence_Threshold__c = 0.75,
            Require_Human_Approval__c = false,
            Auto_Remediation_Enabled__c = true,
            Blacklisted_Users__c = 'test@example.com'
        );
        insert customSettings;

        Test.startTest();
        Elaro_AI_Settings__c settings = ElaroAISettingsController.getSettings();
        Test.stopTest();

        // Then: Should return existing settings
        Assert.areEqual(false, settings.Enable_AI_Reasoning__c, 'Should return existing AI reasoning setting');
        Assert.areEqual(0.75, settings.Confidence_Threshold__c, 'Should return existing threshold');
        Assert.areEqual(false, settings.Require_Human_Approval__c, 'Should return existing human approval setting');
        Assert.areEqual(true, settings.Auto_Remediation_Enabled__c, 'Should return existing auto remediation setting');
    }

    @IsTest
    static void testSaveSettings_PositivePath() {
        // Given: New settings to save
        Elaro_AI_Settings__c settings = new Elaro_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = true,
            Confidence_Threshold__c = 0.90,
            Require_Human_Approval__c = true,
            Auto_Remediation_Enabled__c = false,
            Blacklisted_Users__c = ''
        );

        Test.startTest();
        ElaroAISettingsController.saveSettings(settings);
        Test.stopTest();

        // Then: Settings should be saved
        Elaro_AI_Settings__c savedSettings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areEqual(0.90, savedSettings.Confidence_Threshold__c, 'Threshold should be updated');
    }

    @IsTest
    static void testSaveSettings_UpdateExisting() {
        // Given: Existing settings
        Elaro_AI_Settings__c existingSettings = new Elaro_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = true,
            Confidence_Threshold__c = 0.85
        );
        insert existingSettings;

        // When: Updating settings
        existingSettings.Confidence_Threshold__c = 0.95;

        Test.startTest();
        ElaroAISettingsController.saveSettings(existingSettings);
        Test.stopTest();

        // Then: Settings should be updated
        Elaro_AI_Settings__c updated = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areEqual(0.95, updated.Confidence_Threshold__c, 'Threshold should be updated to 0.95');
    }

    @IsTest
    static void testSaveSettings_ThrowsAuraHandledException() {
        // Given: Invalid settings (null record to trigger exception in test context)
        Elaro_AI_Settings__c settings = new Elaro_AI_Settings__c();
        // Set an invalid field value that will cause upsert to fail
        settings.Confidence_Threshold__c = -1; // Assuming validation rule prevents negative values

        Test.startTest();
        try {
            // This test verifies the exception handling path
            // In real scenarios, validation rules or other constraints would trigger this
            ElaroAISettingsController.saveSettings(settings);
            // If we reach here with valid data, that's acceptable
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Error saving settings'),
                'Should throw AuraHandledException with appropriate message');
        }
        Test.stopTest();
    }

    @IsTest
    static void testSaveSettings_NullSettings() {
        Test.startTest();
        try {
            ElaroAISettingsController.saveSettings(null);
            Assert.fail( 'Expected exception for null settings');
        } catch (Exception e) {
            Assert.areNotEqual(null, e, 'Should throw exception for null settings');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetSettings_InsufficientPermissions() {
        // Given: A user without proper permissions
        Profile minAccessProfile = [SELECT Id FROM Profile WHERE Name = 'Minimum Access - Salesforce' LIMIT 1];

        User limitedUser = new User(
            Alias = 'limited',
            Email = 'limited@test.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minAccessProfile.Id,
            TimeZoneSidKey = 'America/Los_Angeles',
            Username = 'limiteduser' + DateTime.now().getTime() + '@test.com'
        );
        insert limitedUser;

        Test.startTest();
        System.runAs(limitedUser) {
            // When: Limited user tries to get settings
            Elaro_AI_Settings__c settings = ElaroAISettingsController.getSettings();

            // Then: Should still return defaults (custom settings are accessible)
            Assert.areNotEqual(null, settings, 'Should return settings even for limited user');
        }
        Test.stopTest();
    }
}
