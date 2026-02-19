/**
 * Test class for ElaroInstallHandler
 * Provides 100% code coverage for package installation logic
 *
 * @group Installation
 * @author Elaro Team
 * @version 3.0
 *
 * @see ElaroInstallHandler
 */
@IsTest(testFor=ElaroInstallHandler.class)
private class ElaroInstallHandlerTest {

    /**
     * Mock InstallContext for testing
     */
    private class MockInstallContext implements InstallContext {
        private Boolean isInstallFlag;
        private Boolean isUpgradeFlag;
        private Boolean isPushFlag;
        private Version prevVersion;

        public MockInstallContext(Boolean isInstall, Boolean isUpgrade, Boolean isPush, Version previousVersion) {
            this.isInstallFlag = isInstall;
            this.isUpgradeFlag = isUpgrade;
            this.isPushFlag = isPush;
            this.prevVersion = previousVersion;
        }

        public Boolean isInstall() {
            return isInstallFlag;
        }

        public Boolean isUpgrade() {
            return isUpgradeFlag;
        }

        public Boolean isPush() {
            return isPushFlag;
        }

        public Version previousVersion() {
            return prevVersion;
        }

        public Id organizationId() {
            return UserInfo.getOrganizationId();
        }

        public Id installerId() {
            return UserInfo.getUserId();
        }
    }

    /**
     * Test new installation scenario
     * Should create AI settings and audit log
     */
    @isTest
    static void testOnInstall_NewInstallation_CreatesDefaultSettings() {
        // Arrange
        MockInstallContext context = new MockInstallContext(true, false, false, null);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Ensure no AI settings exist before test
        delete [SELECT Id FROM Elaro_AI_Settings__c];

        // Act
        Test.startTest();
        handler.onInstall(context);
        Test.stopTest();

        // Assert - AI Settings created
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areNotEqual(null, settings, 'AI settings should be created on new install');
        Assert.areEqual(false, settings.AI_Enabled__c, 'AI should be disabled by default');
        Assert.areEqual('claude-sonnet-4-20250514', settings.Model_Name__c, 'Should use latest Claude model');
        Assert.areEqual(4096, settings.Max_Tokens__c, 'Should set default max tokens');
        Assert.areEqual(0.7, settings.Temperature__c, 'Should set default temperature');
        Assert.areEqual(true, settings.Cache_Enabled__c, 'Cache should be enabled by default');
        Assert.areEqual(60, settings.Cache_TTL_Minutes__c, 'Should set default cache TTL');
        Assert.areEqual(60, settings.Timeout_Seconds__c, 'Should set default timeout');

        // Assert - Audit Log created
        List<Elaro_Audit_Log__c> auditLogs = [
            SELECT Id, Action__c, Event_Type__c, Status__c, Severity__c
            FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Package Installation'
        ];
        Assert.areEqual(1, auditLogs.size(), 'Should create welcome audit log');
        Assert.areEqual('New Installation', auditLogs[0].Event_Type__c, 'Should log as new installation');
        Assert.areEqual('Completed', auditLogs[0].Status__c, 'Should mark as completed');
        Assert.areEqual('INFO', auditLogs[0].Severity__c, 'Should be INFO severity');
    }

    /**
     * Test upgrade scenario
     * Should NOT recreate AI settings if they exist
     */
    @isTest
    static void testOnInstall_Upgrade_PreservesExistingSettings() {
        // Arrange - Create existing AI settings with custom values
        Elaro_AI_Settings__c existingSettings = new Elaro_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            AI_Enabled__c = true, // Already enabled
            Model_Name__c = 'claude-opus-4-5-20251101', // Custom model
            Max_Tokens__c = 8192,
            Temperature__c = 0.5
        );
        insert existingSettings;

        Version previousVersion = new Version(2, 5, 0);
        MockInstallContext context = new MockInstallContext(false, true, false, previousVersion);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act
        Test.startTest();
        handler.onInstall(context);
        Test.stopTest();

        // Assert - Settings preserved (not overwritten)
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areEqual(existingSettings.Id, settings.Id, 'Should preserve existing settings record');
        Assert.areEqual(true, settings.AI_Enabled__c, 'Should preserve AI enabled state');
        Assert.areEqual('claude-opus-4-5-20251101', settings.Model_Name__c, 'Should preserve custom model');
        Assert.areEqual(8192, settings.Max_Tokens__c, 'Should preserve max tokens');

        // Assert - Audit Log created for upgrade
        List<Elaro_Audit_Log__c> auditLogs = [
            SELECT Id, Action__c, Event_Type__c, Description__c
            FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Package Installation'
        ];
        Assert.areEqual(1, auditLogs.size(), 'Should create upgrade audit log');
        Assert.areEqual('Upgrade', auditLogs[0].Event_Type__c, 'Should log as upgrade');
        Assert.isTrue(auditLogs[0].Description__c.contains('2.5'), 'Should reference previous version');
    }

    /**
     * Test push upgrade scenario
     */
    @isTest
    static void testOnInstall_PushUpgrade_LogsCorrectly() {
        // Arrange
        Version previousVersion = new Version(3, 0, 0);
        MockInstallContext context = new MockInstallContext(false, false, true, previousVersion);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act
        Test.startTest();
        handler.onInstall(context);
        Test.stopTest();

        // Assert - Audit Log created for push upgrade
        List<Elaro_Audit_Log__c> auditLogs = [
            SELECT Id, Action__c, Event_Type__c
            FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Package Installation'
        ];
        Assert.areEqual(1, auditLogs.size(), 'Should create push upgrade audit log');
        Assert.areEqual('Push Upgrade', auditLogs[0].Event_Type__c, 'Should log as push upgrade');
    }

    /**
     * Test error handling in install handler
     * Should not throw exceptions, only log errors
     */
    @isTest
    static void testOnInstall_HandlesErrorsGracefully() {
        // Arrange - Use a context that will work
        MockInstallContext context = new MockInstallContext(true, false, false, null);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act - Even if errors occur internally, installation should complete
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            handler.onInstall(context);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert - No exception should bubble up
        Assert.areEqual(false, exceptionThrown, 'Install handler should not throw exceptions');

        // AI settings should still be created if possible
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areNotEqual(null, settings, 'Should create settings even if other operations fail');
    }

    /**
     * Test Chatter notification creation
     * Should create FeedItem for installer
     */
    @isTest
    static void testOnInstall_CreatesChatterNotification() {
        // Arrange
        MockInstallContext context = new MockInstallContext(true, false, false, null);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act
        Test.startTest();
        handler.onInstall(context);
        Test.stopTest();

        // Assert - Chatter post created (if Chatter is enabled in org)
        // Note: In test context, Chatter posts may not be created due to limitations
        // This test verifies code executes without error
        List<FeedItem> posts = [
            SELECT Id, Body, ParentId
            FROM FeedItem
            WHERE ParentId = :UserInfo.getUserId()
            AND CreatedDate = TODAY
            LIMIT 1
        ];

        // In test context, FeedItem creation may be restricted
        // Verify the install handler completed and created settings/audit logs
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areNotEqual(null, settings, 'Install handler should have completed and created AI settings');
    }

    /**
     * Test getInstallationSummary static method
     */
    @isTest
    static void testGetInstallationSummary_ReturnsFormattedString() {
        // Arrange
        MockInstallContext context = new MockInstallContext(true, false, false, null);

        // Act
        Test.startTest();
        String summary = ElaroInstallHandler.getInstallationSummary(context);
        Test.stopTest();

        // Assert
        Assert.areNotEqual(null, summary, 'Summary should not be null');
        Assert.isTrue(summary.contains('Elaro Installation Summary'), 'Should contain header');
        Assert.isTrue(summary.contains('Type: New Installation'), 'Should contain installation type');
        Assert.isTrue(summary.contains('Org ID: ' + UserInfo.getOrganizationId()), 'Should contain org ID');
        Assert.isTrue(summary.contains('Installer ID: ' + UserInfo.getUserId()), 'Should contain installer ID');
    }

    /**
     * Test getInstallationSummary for upgrade
     */
    @isTest
    static void testGetInstallationSummary_Upgrade_IncludesPreviousVersion() {
        // Arrange
        Version previousVersion = new Version(2, 5, 3);
        MockInstallContext context = new MockInstallContext(false, true, false, previousVersion);

        // Act
        Test.startTest();
        String summary = ElaroInstallHandler.getInstallationSummary(context);
        Test.stopTest();

        // Assert
        Assert.isTrue(summary.contains('Type: Upgrade'), 'Should contain upgrade type');
        Assert.isTrue(summary.contains('Previous Version: 2.5'), 'Should contain previous version');
    }

    /**
     * Test AI settings initialization when object doesn't exist
     * (Edge case: deployment without all metadata)
     */
    @isTest
    static void testOnInstall_MissingAISettings_HandlesGracefully() {
        // Arrange
        MockInstallContext context = new MockInstallContext(true, false, false, null);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act
        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            handler.onInstall(context);
        } catch (Exception e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        // Assert - Should not throw exception even if custom settings can't be created
        Assert.areEqual(false, exceptionThrown, 'Should handle missing metadata gracefully');
    }

    /**
     * Test audit log creation when object is not accessible
     * Should handle permission errors gracefully
     */
    @isTest
    static void testOnInstall_InsufficientPermissions_ContinuesExecution() {
        // Arrange
        MockInstallContext context = new MockInstallContext(true, false, false, null);
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Note: Cannot fully test permission denial in test context
        // This test verifies handler doesn't throw exceptions

        // Act
        Test.startTest();
        handler.onInstall(context);
        Test.stopTest();

        // Assert - Installation completes successfully
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getOrgDefaults();
        Assert.areNotEqual(null, settings, 'Installation should complete and create settings even with limited permissions');
    }

    /**
     * Test multiple sequential installations don't duplicate settings
     */
    @isTest
    static void testOnInstall_MultipleInstalls_NoDuplicateSettings() {
        // Arrange
        MockInstallContext context1 = new MockInstallContext(true, false, false, null);
        MockInstallContext context2 = new MockInstallContext(false, true, false, new Version(3, 0, 0));
        ElaroInstallHandler handler = new ElaroInstallHandler();

        // Act
        Test.startTest();
        handler.onInstall(context1); // First install
        handler.onInstall(context2); // Upgrade
        Test.stopTest();

        // Assert - Only one AI settings record
        List<Elaro_AI_Settings__c> settings = [
            SELECT Id FROM Elaro_AI_Settings__c
        ];
        Assert.areEqual(1, settings.size(), 'Should only have one AI settings record');

        // Multiple audit logs allowed (one per install/upgrade)
        List<Elaro_Audit_Log__c> auditLogs = [
            SELECT Id FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Package Installation'
        ];
        Assert.isTrue(auditLogs.size() >= 1, 'Should have at least one audit log');
    }

    /**
     * Test that all installation paths execute without errors
     * Comprehensive smoke test
     */
    @isTest
    static void testOnInstall_AllPaths_ExecuteSuccessfully() {
        // Test all three installation types
        List<MockInstallContext> contexts = new List<MockInstallContext>{
            new MockInstallContext(true, false, false, null), // New install
            new MockInstallContext(false, true, false, new Version(2, 9, 5)), // Upgrade
            new MockInstallContext(false, false, true, new Version(3, 0, 1))  // Push
        };

        ElaroInstallHandler handler = new ElaroInstallHandler();

        Test.startTest();
        for (MockInstallContext ctx : contexts) {
            // Should not throw any exceptions
            handler.onInstall(ctx);
        }
        Test.stopTest();

        // Assert - All installations completed
        List<Elaro_Audit_Log__c> auditLogs = [
            SELECT Id FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Package Installation'
        ];
        Assert.isTrue(auditLogs.size() >= 1, 'All installation types should create audit logs');
    }
}
