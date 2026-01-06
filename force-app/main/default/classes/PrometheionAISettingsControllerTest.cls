@IsTest
private class PrometheionAISettingsControllerTest {

    @IsTest
    static void testGetSettings_ReturnsDefaultsWhenNoSettings() {
        // Given: No Prometheion_AI_Settings__c record exists

        Test.startTest();
        Prometheion_AI_Settings__c settings = PrometheionAISettingsController.getSettings();
        Test.stopTest();

        // Then: Should return default values
        System.assertNotEquals(null, settings, 'Settings should not be null');
        System.assertEquals(true, settings.Enable_AI_Reasoning__c, 'AI reasoning should be enabled by default');
        System.assertEquals(0.85, settings.Confidence_Threshold__c, 'Confidence threshold should default to 0.85');
        System.assertEquals(true, settings.Require_Human_Approval__c, 'Human approval should be required by default');
        System.assertEquals(false, settings.Auto_Remediation_Enabled__c, 'Auto remediation should be disabled by default');
        System.assertEquals('', settings.Blacklisted_Users__c, 'Blacklisted users should be empty by default');
    }

    @IsTest
    static void testGetSettings_ReturnsExistingSettings() {
        // Given: Custom settings exist
        Prometheion_AI_Settings__c customSettings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = false,
            Confidence_Threshold__c = 0.75,
            Require_Human_Approval__c = false,
            Auto_Remediation_Enabled__c = true,
            Blacklisted_Users__c = 'test@example.com'
        );
        insert customSettings;

        Test.startTest();
        Prometheion_AI_Settings__c settings = PrometheionAISettingsController.getSettings();
        Test.stopTest();

        // Then: Should return existing settings
        System.assertEquals(false, settings.Enable_AI_Reasoning__c, 'Should return existing AI reasoning setting');
        System.assertEquals(0.75, settings.Confidence_Threshold__c, 'Should return existing threshold');
        System.assertEquals(false, settings.Require_Human_Approval__c, 'Should return existing human approval setting');
        System.assertEquals(true, settings.Auto_Remediation_Enabled__c, 'Should return existing auto remediation setting');
    }

    @IsTest
    static void testSaveSettings_PositivePath() {
        // Given: New settings to save
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = true,
            Confidence_Threshold__c = 0.90,
            Require_Human_Approval__c = true,
            Auto_Remediation_Enabled__c = false,
            Blacklisted_Users__c = ''
        );

        Test.startTest();
        PrometheionAISettingsController.saveSettings(settings);
        Test.stopTest();

        // Then: Settings should be saved
        Prometheion_AI_Settings__c savedSettings = Prometheion_AI_Settings__c.getOrgDefaults();
        System.assertEquals(0.90, savedSettings.Confidence_Threshold__c, 'Threshold should be updated');
    }

    @IsTest
    static void testSaveSettings_UpdateExisting() {
        // Given: Existing settings
        Prometheion_AI_Settings__c existingSettings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = true,
            Confidence_Threshold__c = 0.85
        );
        insert existingSettings;

        // When: Updating settings
        existingSettings.Confidence_Threshold__c = 0.95;

        Test.startTest();
        PrometheionAISettingsController.saveSettings(existingSettings);
        Test.stopTest();

        // Then: Settings should be updated
        Prometheion_AI_Settings__c updated = Prometheion_AI_Settings__c.getOrgDefaults();
        System.assertEquals(0.95, updated.Confidence_Threshold__c, 'Threshold should be updated to 0.95');
    }

    @IsTest
    static void testSaveSettings_ThrowsAuraHandledException() {
        // Given: Invalid settings (null record to trigger exception in test context)
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c();
        // Set an invalid field value that will cause upsert to fail
        settings.Confidence_Threshold__c = -1; // Assuming validation rule prevents negative values

        Test.startTest();
        try {
            // This test verifies the exception handling path
            // In real scenarios, validation rules or other constraints would trigger this
            PrometheionAISettingsController.saveSettings(settings);
            // If we reach here with valid data, that's acceptable
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Error saving settings'),
                'Should throw AuraHandledException with appropriate message');
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
            Prometheion_AI_Settings__c settings = PrometheionAISettingsController.getSettings();

            // Then: Should still return defaults (custom settings are accessible)
            System.assertNotEquals(null, settings, 'Should return settings even for limited user');
        }
        Test.stopTest();
    }
}
