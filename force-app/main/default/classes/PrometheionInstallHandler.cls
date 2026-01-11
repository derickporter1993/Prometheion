/**
 * @description Post-install handler for Prometheion package
 * Executes configuration and initialization logic after package installation/upgrade
 *
 * @group Installation
 * @author Prometheion Team
 * @version 3.0
 *
 * @see PrometheionInstallHandlerTest
 */
global class PrometheionInstallHandler implements InstallHandler {

    /**
     * @description Main installation handler method
     * Called automatically by Salesforce after package install/upgrade
     *
     * @param context Installation context (version info, org ID, etc.)
     */
    global void onInstall(InstallContext context) {
        try {
            // Log installation event
            logInstallation(context);

            // Initialize AI settings if not present
            initializeAISettings();

            // Create welcome audit log entry
            createWelcomeAuditLog(context);

            // Send installation notification (if configured)
            notifyAdministrators(context);

            System.debug(LoggingLevel.INFO, 'Prometheion installation completed successfully');

        } catch (Exception e) {
            // Log error but don't throw - don't block installation
            System.debug(LoggingLevel.ERROR, 'Prometheion InstallHandler error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());

            // Create error audit log if possible
            try {
                createErrorAuditLog(e, context);
            } catch (Exception auditError) {
                System.debug(LoggingLevel.ERROR, 'Could not create error audit log: ' + auditError.getMessage());
            }
        }
    }

    /**
     * @description Log installation details to system debug
     * @param context Installation context
     */
    private void logInstallation(InstallContext context) {
        if (context.isInstall()) {
            System.debug(LoggingLevel.INFO, '===== PROMETHEION INSTALLATION =====');
            System.debug(LoggingLevel.INFO, 'Installation Type: New Installation');
        } else if (context.isUpgrade()) {
            System.debug(LoggingLevel.INFO, '===== PROMETHEION UPGRADE =====');
            System.debug(LoggingLevel.INFO, 'Installation Type: Upgrade');
            System.debug(LoggingLevel.INFO, 'Previous Version: ' + context.previousVersion());
        } else if (context.isPush()) {
            System.debug(LoggingLevel.INFO, '===== PROMETHEION PUSH UPGRADE =====');
            System.debug(LoggingLevel.INFO, 'Installation Type: Push Upgrade');
            System.debug(LoggingLevel.INFO, 'Previous Version: ' + context.previousVersion());
        }

        System.debug(LoggingLevel.INFO, 'Organization ID: ' + context.organizationId());
        System.debug(LoggingLevel.INFO, 'Installer ID: ' + context.installerId());
        System.debug(LoggingLevel.INFO, 'Timestamp: ' + System.now());
        System.debug(LoggingLevel.INFO, '=====================================');
    }

    /**
     * @description Initialize AI settings with default values if not present
     * Creates Prometheion_AI_Settings__c custom settings record
     */
    private void initializeAISettings() {
        // Check if AI settings already exist
        Prometheion_AI_Settings__c existingSettings = Prometheion_AI_Settings__c.getOrgDefaults();

        if (existingSettings == null || existingSettings.Id == null) {
            // Create default AI settings
            Prometheion_AI_Settings__c defaultSettings = new Prometheion_AI_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId(), // Organization-wide default
                AI_Enabled__c = false, // Disabled by default - admin must enable after configuring Named Credential
                Model_Name__c = 'claude-sonnet-4-20250514', // Latest Claude model
                Max_Tokens__c = 4096,
                Temperature__c = 0.7,
                Cache_Enabled__c = true,
                Cache_TTL_Minutes__c = 60,
                Timeout_Seconds__c = 60
            );

            try {
                insert defaultSettings;
                System.debug(LoggingLevel.INFO, 'Created default AI settings: ' + defaultSettings.Id);
            } catch (DmlException e) {
                System.debug(LoggingLevel.WARN, 'Could not create AI settings (may already exist): ' + e.getMessage());
            }
        } else {
            System.debug(LoggingLevel.INFO, 'AI settings already exist: ' + existingSettings.Id);
        }
    }

    /**
     * @description Create welcome audit log entry
     * @param context Installation context
     */
    private void createWelcomeAuditLog(InstallContext context) {
        // Check if Prometheion_Audit_Log__c object exists and is accessible
        if (!Schema.sObjectType.Prometheion_Audit_Log__c.isCreateable()) {
            System.debug(LoggingLevel.WARN, 'Cannot create audit log: insufficient permissions');
            return;
        }

        String installationType = context.isInstall() ? 'New Installation' :
                                  context.isUpgrade() ? 'Upgrade' : 'Push Upgrade';

        String message = context.isInstall() ?
            'Welcome to Prometheion v3.0! Your AI-powered compliance platform is ready. ' +
            'Next steps: (1) Assign permission sets, (2) Configure Named Credentials for AI/integrations, ' +
            '(3) Run initial compliance scan, (4) Configure compliance frameworks.' :
            'Prometheion has been upgraded successfully. Previous version: ' +
            (context.previousVersion() != null ? String.valueOf(context.previousVersion()) : 'Unknown');

        Prometheion_Audit_Log__c welcomeLog = new Prometheion_Audit_Log__c(
            Action__c = 'Package Installation',
            Description__c = message,
            Event_Type__c = installationType,
            User__c = context.installerId(),
            Timestamp__c = System.now(),
            Status__c = 'Completed',
            Severity__c = 'INFO'
        );

        try {
            insert welcomeLog;
            System.debug(LoggingLevel.INFO, 'Created welcome audit log: ' + welcomeLog.Id);
        } catch (DmlException e) {
            System.debug(LoggingLevel.WARN, 'Could not create welcome audit log: ' + e.getMessage());
        }
    }

    /**
     * @description Create error audit log entry
     * @param e Exception that occurred
     * @param context Installation context
     */
    private void createErrorAuditLog(Exception e, InstallContext context) {
        if (!Schema.sObjectType.Prometheion_Audit_Log__c.isCreateable()) {
            return;
        }

        Prometheion_Audit_Log__c errorLog = new Prometheion_Audit_Log__c(
            Action__c = 'Package Installation Error',
            Description__c = 'An error occurred during post-install processing: ' + e.getMessage(),
            Event_Type__c = 'Installation Error',
            User__c = context.installerId(),
            Timestamp__c = System.now(),
            Status__c = 'Error',
            Severity__c = 'ERROR'
        );

        insert errorLog;
    }

    /**
     * @description Send installation notification to administrators
     * Attempts to send Chatter notification or email to admins
     * @param context Installation context
     */
    private void notifyAdministrators(InstallContext context) {
        try {
            // Query for Prometheion_Admin permission set assignments
            List<PermissionSetAssignment> adminAssignments = [
                SELECT AssigneeId, Assignee.Email, Assignee.Name
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name = 'Prometheion_Admin'
                AND Assignee.IsActive = true
                LIMIT 10
            ];

            if (adminAssignments.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'No Prometheion_Admin users found - skipping notification');
                return;
            }

            // Create Chatter post (if Chatter is enabled)
            if (Schema.sObjectType.FeedItem.isCreateable()) {
                String chatterMessage = context.isInstall() ?
                    '🚀 Prometheion v3.0 has been installed! Next steps:\n\n' +
                    '1️⃣ Review installation guide: Setup → Apps → Prometheion\n' +
                    '2️⃣ Configure Named Credentials for AI features\n' +
                    '3️⃣ Assign permission sets to users\n' +
                    '4️⃣ Run initial compliance scan\n\n' +
                    'Questions? Visit the Prometheion documentation.' :
                    '✅ Prometheion has been upgraded to v3.0. Review release notes for new features.';

                // Post to installer's feed
                FeedItem post = new FeedItem(
                    ParentId = context.installerId(),
                    Body = chatterMessage,
                    Type = 'TextPost'
                );

                insert post;
                System.debug(LoggingLevel.INFO, 'Posted installation notification to Chatter');
            }

        } catch (Exception e) {
            System.debug(LoggingLevel.WARN, 'Could not notify administrators: ' + e.getMessage());
        }
    }

    /**
     * @description Get installation summary for debugging
     * @param context Installation context
     * @return Summary string
     */
    global static String getInstallationSummary(InstallContext context) {
        String summary = 'Prometheion Installation Summary\n';
        summary += '=================================\n';
        summary += 'Type: ' + (context.isInstall() ? 'New Installation' :
                              context.isUpgrade() ? 'Upgrade' : 'Push Upgrade') + '\n';
        summary += 'Org ID: ' + context.organizationId() + '\n';
        summary += 'Installer ID: ' + context.installerId() + '\n';
        summary += 'Timestamp: ' + System.now() + '\n';

        if (context.isUpgrade()) {
            summary += 'Previous Version: ' + context.previousVersion() + '\n';
        }

        return summary;
    }
}
