/**
 * Controller for Escalation Path LWC component
 * Provides CRUD operations for Elaro_Escalation_Path__c records
 *
 * @author Elaro Development Team
 * @since 2026-01
 * @group System Monitoring
 */
public with sharing class EscalationPathController {

    /**
     * Gets all escalation paths ordered by level
     * @return List of path records with related user info
     */
    @AuraEnabled(cacheable=true)
    public static List<Elaro_Escalation_Path__c> getPaths() {
        try {
            List<Elaro_Escalation_Path__c> paths = [
                SELECT Id, Name, User__c, User__r.Name, User__r.Email,
                       Level__c, Role__c, Notification_Method__c,
                       Escalation_Delay_Minutes__c, Active__c
                FROM Elaro_Escalation_Path__c
                WITH USER_MODE
                ORDER BY Level__c ASC, Role__c ASC
                LIMIT 100
            ];

            // Strip inaccessible fields for FLS security
            return (List<Elaro_Escalation_Path__c>) ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.READABLE,
                paths
            );
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('EscalationPathController.getPaths', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Creates a new escalation path
     * @param path The path record to create
     * @return The created path ID
     */
    @AuraEnabled
    public static Id createPath(Elaro_Escalation_Path__c path) {
        try {
            validatePath(path);

            insert as user path;
            return path.Id;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('EscalationPathController.createPath', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Updates an existing escalation path
     * @param path The path record to update
     */
    @AuraEnabled
    public static void updatePath(Elaro_Escalation_Path__c path) {
        try {
            validatePath(path);

            update as user path;
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('EscalationPathController.updatePath', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Deletes an escalation path
     * @param pathId The ID of the path to delete
     */
    @AuraEnabled
    public static void deletePath(Id pathId) {
        try {
            delete as user [SELECT Id FROM Elaro_Escalation_Path__c WHERE Id = :pathId WITH USER_MODE];
        } catch (AuraHandledException ahe) {
            throw ahe;
        } catch (Exception e) {
            ElaroLogger.error('EscalationPathController.deletePath', e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException('Unable to complete the operation. Please verify you have the required permissions and try again.');
        }
    }

    /**
     * Validates path data before save
     * @param path The path to validate
     */
    private static void validatePath(Elaro_Escalation_Path__c path) {
        if (path.User__c == null) {
            throw new AuraHandledException('User is required');
        }
        if (path.Level__c == null || path.Level__c < 1 || path.Level__c > 3) {
            throw new AuraHandledException('Level must be between 1 and 3');
        }
        if (path.Escalation_Delay_Minutes__c == null || path.Escalation_Delay_Minutes__c < 1) {
            throw new AuraHandledException('Escalation delay must be at least 1 minute');
        }
    }
}
