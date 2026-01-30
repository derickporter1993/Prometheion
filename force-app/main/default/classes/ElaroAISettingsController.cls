/**
 * AI Settings Controller with proper default persistence
 * Best Practice: Persists org defaults instead of in-memory objects
 * Security: Enforces CRUD/FLS with Security.stripInaccessible
 */
public with sharing class ElaroAISettingsController {
    private static final Boolean DEFAULT_ENABLE_AI_REASONING = true;
    private static final Decimal DEFAULT_CONFIDENCE_THRESHOLD = 0.85;
    private static final Boolean DEFAULT_REQUIRE_HUMAN_APPROVAL = true;
    private static final Boolean DEFAULT_AUTO_REMEDIATION_ENABLED = false;
    private static final String DEFAULT_BLACKLISTED_USERS = '';

    @AuraEnabled(cacheable=true)
    public static Elaro_AI_Settings__c getSettings() {
        Elaro_AI_Settings__c settings = Elaro_AI_Settings__c.getInstance();

        // If no org default exists, create and persist one
        if (settings == null) {
            settings = createAndPersistDefaults();
        }

        return settings;
    }

    /**
     * Create and persist org default settings
     * This ensures settings are always persisted, not just in-memory
     */
    private static Elaro_AI_Settings__c createAndPersistDefaults() {
        try {
            Elaro_AI_Settings__c settings = new Elaro_AI_Settings__c(
                SetupOwnerId = UserInfo.getOrganizationId(),
                Enable_AI_Reasoning__c = DEFAULT_ENABLE_AI_REASONING,
                Confidence_Threshold__c = DEFAULT_CONFIDENCE_THRESHOLD,
                Require_Human_Approval__c = DEFAULT_REQUIRE_HUMAN_APPROVAL,
                Auto_Remediation_Enabled__c = DEFAULT_AUTO_REMEDIATION_ENABLED,
                Blacklisted_Users__c = DEFAULT_BLACKLISTED_USERS
            );

            // Check if we have permission to insert
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Elaro_AI_Settings__c>{ settings }
            );

            List<Elaro_AI_Settings__c> sanitizedSettings = decision.getRecords();
            if (!sanitizedSettings.isEmpty()) {
                Database.SaveResult result = Database.insert(sanitizedSettings[0], AccessLevel.USER_MODE);
                if (!result.isSuccess()) {
                    throw new DmlException('Failed to create default settings');
                }
                System.debug(LoggingLevel.INFO, 'ElaroAISettingsController: Created org default settings');
                return sanitizedSettings[0];
            } else {
                System.debug(LoggingLevel.WARN, 'ElaroAISettingsController: No accessible fields to create settings');
                // Return in-memory object as fallback (should not happen in normal operation)
                return settings;
            }
        } catch (DmlException e) {
            System.debug(LoggingLevel.ERROR, 'ElaroAISettingsController: Failed to create default settings: ' + e.getMessage());
            // Return in-memory object as fallback
            return new Elaro_AI_Settings__c(
                Enable_AI_Reasoning__c = DEFAULT_ENABLE_AI_REASONING,
                Confidence_Threshold__c = DEFAULT_CONFIDENCE_THRESHOLD,
                Require_Human_Approval__c = DEFAULT_REQUIRE_HUMAN_APPROVAL,
                Auto_Remediation_Enabled__c = DEFAULT_AUTO_REMEDIATION_ENABLED,
                Blacklisted_Users__c = DEFAULT_BLACKLISTED_USERS
            );
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'ElaroAISettingsController: Unexpected error creating default settings: ' + e.getMessage());
            // Return in-memory object as fallback
            return new Elaro_AI_Settings__c(
                Enable_AI_Reasoning__c = DEFAULT_ENABLE_AI_REASONING,
                Confidence_Threshold__c = DEFAULT_CONFIDENCE_THRESHOLD,
                Require_Human_Approval__c = DEFAULT_REQUIRE_HUMAN_APPROVAL,
                Auto_Remediation_Enabled__c = DEFAULT_AUTO_REMEDIATION_ENABLED,
                Blacklisted_Users__c = DEFAULT_BLACKLISTED_USERS
            );
        }
    }

    @AuraEnabled
    public static void saveSettings(Elaro_AI_Settings__c settings) {
        if (settings == null) {
            throw new AuraHandledException('Settings cannot be null');
        }

        try {
            // Ensure SetupOwnerId is set to org level
            if (settings.SetupOwnerId == null) {
                settings.SetupOwnerId = UserInfo.getOrganizationId();
            }

            // Strip inaccessible fields for security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                new List<Elaro_AI_Settings__c>{ settings }
            );
            List<Elaro_AI_Settings__c> sanitizedSettings = decision.getRecords();

            if (sanitizedSettings.isEmpty()) {
                throw new AuraHandledException('No accessible fields to update');
            }

            Elaro_AI_Settings__c oldSettings = Elaro_AI_Settings__c.getInstance();
            
            Database.UpsertResult result = Database.upsert(sanitizedSettings[0], AccessLevel.USER_MODE);
            if (!result.isSuccess()) {
                throw new DmlException('Failed to save settings');
            }
            
            // Audit log for settings changes
            logAuditEvent('AI_SETTINGS_CHANGED', 'Elaro_AI_Settings__c', sanitizedSettings[0].Id, 
                'AI Settings updated by ' + UserInfo.getUserName());
        } catch (DmlException e) {
            // Log detailed error server-side with correlation ID
            String correlationId = 'AI_SETTINGS-' + System.now().getTime() + '-' + Crypto.getRandomInteger();
            System.debug(LoggingLevel.ERROR, 
                'DML error saving settings [CorrelationId: ' + correlationId + ']: ' + 
                e.getMessage() + ' | DML: ' + getSafeDmlMessage(e));
            
            // Return user-safe generic message (no internal details)
            throw new AuraHandledException('Unable to save settings. Please try again or contact your administrator.');
        } catch (Exception e) {
            // Log detailed error server-side with correlation ID
            String correlationId = 'AI_SETTINGS-' + System.now().getTime() + '-' + Crypto.getRandomInteger();
            String errorCategory = categorizeError(e);
            System.debug(LoggingLevel.ERROR, 
                'Error saving settings [CorrelationId: ' + correlationId + ', Category: ' + errorCategory + ']: ' + 
                e.getMessage());
            
            // Return user-safe generic message (no internal details)
            throw new AuraHandledException('Unable to save settings. Please try again or contact your administrator.');
        }
    }
    
    /**
     * Log audit event for AI settings changes
     * Implements proper audit logging with CRUD/FLS enforcement
     */
    private static void logAuditEvent(String action, String entityType, String entityId, String details) {
        try {
            Elaro_Audit_Log__c auditLog = new Elaro_Audit_Log__c(
                Action__c = action,
                Entity_Type__c = entityType,
                Entity_Id__c = entityId,
                Details__c = details,
                User__c = UserInfo.getUserId(),
                Timestamp__c = System.now()
            );
            
            // Strip inaccessible fields for security (CRUD/FLS enforcement)
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                new List<Elaro_Audit_Log__c>{ auditLog }
            );
            
            List<Elaro_Audit_Log__c> sanitizedLogs = decision.getRecords();
            if (!sanitizedLogs.isEmpty()) {
                Database.SaveResult logResult = Database.insert(sanitizedLogs[0], AccessLevel.USER_MODE);
                if (logResult.isSuccess()) {
                    System.debug(LoggingLevel.INFO, '[Audit] Logged: ' + action + ' - ' + entityType + ' (' + entityId + ')');
                }
            } else {
                System.debug(LoggingLevel.WARN, '[Audit] No accessible fields to create audit log for: ' + action);
            }
        } catch (Exception e) {
            // Don't fail the main operation if audit logging fails
            System.debug(LoggingLevel.WARN, 'ElaroAISettingsController: Failed to log audit event: ' + e.getMessage());
        }
    }

    /**
     * Safely extract DML error message with bounds checking
     */
    private static String getSafeDmlMessage(DmlException e) {
        if (e == null || e.getNumDml() == 0) {
            return e != null ? e.getMessage() : 'Unknown DML error';
        }
        return e.getDmlMessage(0);
    }
    
    /**
     * Categorize error for logging (without exposing details)
     */
    private static String categorizeError(Exception e) {
        if (e instanceof DmlException) {
            return 'DML_ERROR';
        } else if (e instanceof NullPointerException) {
            return 'NULL_POINTER_ERROR';
        } else if (e instanceof IllegalArgumentException) {
            return 'VALIDATION_ERROR';
        } else {
            return 'GENERIC_ERROR';
        }
    }
}
