/**
 * @description Post-install handler for Elaro package
 * Executes configuration and initialization logic after package installation/upgrade
 *
 * @group Installation
 * @author Elaro Team
 * @version 3.0
 *
 * @see ElaroInstallHandlerTest
 *
 * Security: Uses 'without sharing' because install handlers run during package
 * installation where the installing user may not have sharing access to all
 * objects that need to be initialized (Custom Settings, Audit Logs, etc.).
 */
global without sharing class ElaroInstallHandler implements InstallHandler {

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

            ElaroLogger.info( 'Elaro installation completed successfully');

        } catch (Exception e) {
            // Log error but don't throw - don't block installation
            ElaroLogger.error( 'Elaro InstallHandler error: ' + e.getMessage());
            ElaroLogger.error( 'Stack trace: ' + e.getStackTraceString());

            // Create error audit log if possible
            try {
                createErrorAuditLog(e, context);
            } catch (Exception auditError) {
                ElaroLogger.error( 'Could not create error audit log: ' + auditError.getMessage());
            }
        }
    }

    /**
     * @description Log installation details to system debug
     * @param context Installation context
     */
    private void logInstallation(InstallContext context) {
        if (context.isInstall()) {
            ElaroLogger.info( '===== ELARO INSTALLATION =====');
            ElaroLogger.info( 'Installation Type: New Installation');
        } else if (context.isUpgrade()) {
            ElaroLogger.info( '===== ELARO UPGRADE =====');
            ElaroLogger.info( 'Installation Type: Upgrade');
            ElaroLogger.info( 'Previous Version: ' + context.previousVersion());
        } else if (context.isPush()) {
            ElaroLogger.info( '===== ELARO PUSH UPGRADE =====');
            ElaroLogger.info( 'Installation Type: Push Upgrade');
            ElaroLogger.info( 'Previous Version: ' + context.previousVersion());
        }

        ElaroLogger.info( 'Organization ID: ' + context.organizationId());
        ElaroLogger.info( 'Installer ID: ' + context.installerId());
        ElaroLogger.info( 'Timestamp: ' + System.now());
        ElaroLogger.info( '=====================================');
    }

    /**
     * @description Initialize AI settings with default values if not present
     * Creates Elaro_AI_Settings__c custom settings record
     */
    private void initializeAISettings() {
        // Check if AI settings already exist
        Elaro_AI_Settings__c existingSettings = Elaro_AI_Settings__c.getOrgDefaults();

        if (existingSettings == null || existingSettings.Id == null) {
            // Create default AI settings
            Elaro_AI_Settings__c defaultSettings = new Elaro_AI_Settings__c(
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
                ElaroSecurityUtils.validateCRUDAccess('Elaro_AI_Settings__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
                insert as user defaultSettings;
                ElaroLogger.info( 'Created default AI settings: ' + defaultSettings.Id);
            } catch (DmlException e) {
                ElaroLogger.warn( 'Could not create AI settings (may already exist): ' + e.getMessage());
            }
        } else {
            ElaroLogger.info( 'AI settings already exist: ' + existingSettings.Id);
        }
    }

    /**
     * @description Create welcome audit log entry
     * @param context Installation context
     */
    private void createWelcomeAuditLog(InstallContext context) {
        // Check if Elaro_Audit_Log__c object exists and is accessible
        if (!Schema.sObjectType.Elaro_Audit_Log__c.isCreateable()) {
            ElaroLogger.warn( 'Cannot create audit log: insufficient permissions');
            return;
        }

        String installationType = context.isInstall() ? 'New Installation' :
                                  context.isUpgrade() ? 'Upgrade' : 'Push Upgrade';

        String message = context.isInstall() ?
            'Welcome to Elaro v3.0! Your AI-powered compliance platform is ready. ' +
            'Next steps: (1) Assign permission sets, (2) Configure Named Credentials for AI/integrations, ' +
            '(3) Run initial compliance scan, (4) Configure compliance frameworks.' :
            'Elaro has been upgraded successfully. Previous version: ' +
            (context.previousVersion() != null ? String.valueOf(context.previousVersion()) : 'Unknown');

        Elaro_Audit_Log__c welcomeLog = new Elaro_Audit_Log__c(
            Action__c = 'Package Installation',
            Description__c = message,
            Event_Type__c = installationType,
            User__c = context.installerId(),
            Timestamp__c = System.now(),
            Status__c = 'Completed',
            Severity__c = 'INFO'
        );

        try {
            ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
            insert as user welcomeLog;
            ElaroLogger.info( 'Created welcome audit log: ' + welcomeLog.Id);
        } catch (DmlException e) {
            ElaroLogger.warn( 'Could not create welcome audit log: ' + e.getMessage());
        }
    }

    /**
     * @description Create error audit log entry
     * @param e Exception that occurred
     * @param context Installation context
     */
    private void createErrorAuditLog(Exception e, InstallContext context) {
        Elaro_Audit_Log__c errorLog = new Elaro_Audit_Log__c(
            Action__c = 'Package Installation Error',
            Description__c = 'An error occurred during post-install processing: ' + e.getMessage(),
            Event_Type__c = 'Installation Error',
            User__c = context.installerId(),
            Timestamp__c = System.now(),
            Status__c = 'Error',
            Severity__c = 'ERROR'
        );

        ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Log__c', ElaroSecurityUtils.DmlOperation.DML_INSERT);
        insert as user errorLog;
    }

    /**
     * @description Send installation notification to administrators
     * Attempts to send Chatter notification or email to admins
     * @param context Installation context
     */
    private void notifyAdministrators(InstallContext context) {
        try {
            // Query for Elaro_Admin permission set assignments
            List<PermissionSetAssignment> adminAssignments = [
                SELECT AssigneeId, Assignee.Email, Assignee.Name
                FROM PermissionSetAssignment
                WHERE PermissionSet.Name = 'Elaro_Admin'
                AND Assignee.IsActive = true
                WITH USER_MODE
                LIMIT 10
            ];

            if (adminAssignments.isEmpty()) {
                ElaroLogger.info( 'No Elaro_Admin users found - skipping notification');
                return;
            }

            // Create Chatter post (if Chatter is enabled)
            if (Schema.sObjectType.FeedItem.isCreateable()) {
                String chatterMessage = context.isInstall() ?
                    '🚀 Elaro v3.0 has been installed! Next steps:\n\n' +
                    '1️⃣ Review installation guide: Setup → Apps → Elaro\n' +
                    '2️⃣ Configure Named Credentials for AI features\n' +
                    '3️⃣ Assign permission sets to users\n' +
                    '4️⃣ Run initial compliance scan\n\n' +
                    'Questions? Visit the Elaro documentation.' :
                    '✅ Elaro has been upgraded to v3.0. Review release notes for new features.';

                // Post to installer's feed
                FeedItem post = new FeedItem(
                    ParentId = context.installerId(),
                    Body = chatterMessage,
                    Type = 'TextPost'
                );

                ElaroSecurityUtils.validateCRUDAccess('FeedItem', ElaroSecurityUtils.DmlOperation.DML_INSERT);
                insert as user post;
                ElaroLogger.info( 'Posted installation notification to Chatter');
            }

        } catch (Exception e) {
            ElaroLogger.warn( 'Could not notify administrators: ' + e.getMessage());
        }
    }

    /**
     * @description Get installation summary for debugging
     * @param context Installation context
     * @return Summary string
     */
    global static String getInstallationSummary(InstallContext context) {
        String summary = 'Elaro Installation Summary\n';
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
