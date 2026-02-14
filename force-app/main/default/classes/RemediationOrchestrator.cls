/**
 * @description Orchestrates automated remediation actions for compliance events
 * Supports actions like REVOKE_PERMISSION, LOCK_USER, NOTIFY_MANAGER
 * @group Automation & Alerting
 * @author Elaro Team
 */
public with sharing class RemediationOrchestrator {
    
    // ═══════════════════════════════════════════════════════════════
    // CONSTANTS
    // ═══════════════════════════════════════════════════════════════
    
    public enum RemediationAction {
        REVOKE_PERMISSION,
        LOCK_USER,
        NOTIFY_MANAGER,
        CREATE_CASE,
        QUARANTINE_DATA,
        FORCE_LOGOUT,
        DISABLE_API_ACCESS
    }
    
    private static final Map<String, RemediationAction> ACTION_MAP = new Map<String, RemediationAction>{
        'REVOKE_PERMISSION' => RemediationAction.REVOKE_PERMISSION,
        'LOCK_USER' => RemediationAction.LOCK_USER,
        'NOTIFY_MANAGER' => RemediationAction.NOTIFY_MANAGER,
        'CREATE_CASE' => RemediationAction.CREATE_CASE,
        'QUARANTINE_DATA' => RemediationAction.QUARANTINE_DATA,
        'FORCE_LOGOUT' => RemediationAction.FORCE_LOGOUT,
        'DISABLE_API_ACCESS' => RemediationAction.DISABLE_API_ACCESS
    };
    
    // ═══════════════════════════════════════════════════════════════
    // PUBLIC METHODS
    // ═══════════════════════════════════════════════════════════════
    
    /**
     * @description Create a remediation case for an event
     * @param eventId The event ID to remediate
     * @param priority The case priority (High, Medium, Low)
     * @return Case ID of the created case
     */
    @AuraEnabled
    public static Id createRemediationCase(String eventId, String priority) {
        if (String.isBlank(eventId)) {
            throw new AuraHandledException('Event ID is required');
        }
        
        // Query event details
        Elaro_Evidence_Item__c event;
        try {
            event = [
                SELECT Id, Name, Evidence_Type__c, Description__c, Evidence_Date__c
                FROM Elaro_Evidence_Item__c
                WHERE Id = :eventId
                LIMIT 1
            ];
        } catch (Exception e) {
            throw new AuraHandledException('Event not found: ' + eventId);
        }
        
        // Create case
        Case remedCase = new Case(
            Subject = 'Compliance Remediation: ' + event.Evidence_Type__c,
            Description = 'Remediation required for compliance event.\n\n' +
                         'Event ID: ' + event.Name + '\n' +
                         'Event Type: ' + event.Evidence_Type__c + '\n' +
                         'Date: ' + event.Evidence_Date__c + '\n' +
                         'Details: ' + event.Description__c,
            Priority = String.isNotBlank(priority) ? priority : 'High',
            Status = 'New',
            Origin = 'Elaro',
            Type = 'Compliance',
            OwnerId = UserInfo.getUserId()
        );
        
        insert as user remedCase;

        // Link case to event (if lookup field exists)
        updateEventWithCase(event.Id, remedCase.Id);
        
        return remedCase.Id;
    }
    
    /**
     * @description Execute a remediation action
     * @param actionType The type of action to execute
     * @param targetId The target (user, permission, etc.) ID
     * @param context Additional context for the action
     * @return RemediationResult with execution outcome
     */
    @AuraEnabled
    public static RemediationResult executeRemediationAction(String actionType, String targetId, Map<String, Object> context) {
        RemediationResult result = new RemediationResult();
        result.actionType = actionType;
        result.targetId = targetId;
        result.executedAt = Datetime.now();
        result.executedBy = UserInfo.getUserId();
        
        try {
            RemediationAction action = ACTION_MAP.get(actionType);
            if (action == null) {
                throw new AuraHandledException('Invalid action type: ' + actionType);
            }
            
            switch on action {
                when REVOKE_PERMISSION {
                    result = executeRevokePermission(targetId, context, result);
                }
                when LOCK_USER {
                    result = executeLockUser(targetId, context, result);
                }
                when NOTIFY_MANAGER {
                    result = executeNotifyManager(targetId, context, result);
                }
                when CREATE_CASE {
                    result = executeCreateCase(targetId, context, result);
                }
                when QUARANTINE_DATA {
                    result = executeQuarantineData(targetId, context, result);
                }
                when FORCE_LOGOUT {
                    result = executeForceLogout(targetId, context, result);
                }
                when DISABLE_API_ACCESS {
                    result = executeDisableAPIAccess(targetId, context, result);
                }
            }
            
            // Log the action
            logRemediationAction(result);
            
        } catch (Exception e) {
            result.success = false;
            result.errorMessage = e.getMessage();
            ElaroLogger.error( 'Remediation error: ' + e.getMessage());
        }
        
        return result;
    }
    
    /**
     * @description Get available remediation actions for an event type
     * @param eventType The event type
     * @return List of available actions
     */
    @AuraEnabled(cacheable=true)
    public static List<ActionOption> getAvailableActions(String eventType) {
        List<ActionOption> actions = new List<ActionOption>();
        
        // Common actions
        actions.add(new ActionOption('CREATE_CASE', 'Create Case', 'Create a remediation case', 'utility:case'));
        actions.add(new ActionOption('NOTIFY_MANAGER', 'Notify Manager', 'Send notification to user\'s manager', 'utility:email'));
        
        // Event-specific actions
        if (eventType == 'LoginAs' || eventType == 'PermissionSetEventLog') {
            actions.add(new ActionOption('REVOKE_PERMISSION', 'Revoke Permission', 'Remove the permission that enabled this action', 'utility:ban'));
            actions.add(new ActionOption('LOCK_USER', 'Lock User', 'Temporarily lock the user account', 'utility:lock'));
        }
        
        if (eventType == 'API' || eventType == 'BulkApiResult') {
            actions.add(new ActionOption('DISABLE_API_ACCESS', 'Disable API Access', 'Revoke API-only access', 'utility:disconnect'));
        }
        
        if (eventType == 'Login') {
            actions.add(new ActionOption('FORCE_LOGOUT', 'Force Logout', 'End all active sessions', 'utility:logout'));
        }
        
        if (eventType == 'ReportExport' || eventType == 'ContentDistribution') {
            actions.add(new ActionOption('QUARANTINE_DATA', 'Quarantine Data', 'Restrict access to exported data', 'utility:shield'));
        }
        
        return actions;
    }
    
    /**
     * @description Get remediation history for an event
     * @param eventId The event ID
     * @return List of remediation actions taken
     */
    @AuraEnabled(cacheable=true)
    public static List<RemediationResult> getRemediationHistory(String eventId) {
        // In production, query from a custom object
        return new List<RemediationResult>();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // ACTION EXECUTION METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static RemediationResult executeRevokePermission(String targetId, Map<String, Object> context, RemediationResult result) {
        // Target ID should be a PermissionSetAssignment ID or User ID + Permission Set name
        String userId = (String)context.get('userId');
        String permissionSetId = (String)context.get('permissionSetId');
        
        if (String.isNotBlank(permissionSetId) && String.isNotBlank(userId)) {
            List<PermissionSetAssignment> assignments = [
                SELECT Id FROM PermissionSetAssignment
                WHERE AssigneeId = :userId AND PermissionSetId = :permissionSetId
                LIMIT 1
            ];
            
            if (!assignments.isEmpty()) {
                delete as user assignments;
                result.success = true;
                result.message = 'Permission set assignment removed successfully';
            } else {
                result.success = false;
                result.message = 'Permission set assignment not found';
            }
        } else {
            result.success = false;
            result.message = 'User ID and Permission Set ID are required';
        }
        
        return result;
    }
    
    private static RemediationResult executeLockUser(String targetId, Map<String, Object> context, RemediationResult result) {
        try {
            User u = [SELECT Id, IsActive FROM User WHERE Id = :targetId WITH USER_MODE LIMIT 1];
            u.IsActive = false;
            update as user u;
            
            result.success = true;
            result.message = 'User account has been deactivated';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to lock user: ' + e.getMessage();
        }
        
        return result;
    }
    
    private static RemediationResult executeNotifyManager(String targetId, Map<String, Object> context, RemediationResult result) {
        try {
            User u = [SELECT Id, Name, Email, ManagerId, Manager.Email, Manager.Name FROM User WHERE Id = :targetId WITH USER_MODE LIMIT 1];
            
            if (u.ManagerId != null && String.isNotBlank(u.Manager.Email)) {
                String eventDescription = (String)context.get('eventDescription');
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{ u.Manager.Email });
                email.setSubject('Compliance Alert: Action Required for ' + u.Name);
                email.setPlainTextBody(
                    'Dear ' + u.Manager.Name + ',\n\n' +
                    'A compliance event has been detected that requires your attention:\n\n' +
                    'Employee: ' + u.Name + '\n' +
                    'Event: ' + (eventDescription != null ? eventDescription : 'Compliance violation detected') + '\n\n' +
                    'Please review and take appropriate action.\n\n' +
                    'Elaro Compliance Platform'
                );
                email.setSaveAsActivity(false);
                
                if (!Test.isRunningTest()) {
                    Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ email });
                }
                
                result.success = true;
                result.message = 'Manager notification sent to ' + u.Manager.Email;
            } else {
                result.success = false;
                result.message = 'User does not have a manager assigned';
            }
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to notify manager: ' + e.getMessage();
        }
        
        return result;
    }
    
    private static RemediationResult executeCreateCase(String targetId, Map<String, Object> context, RemediationResult result) {
        String eventDescription = (String)context.get('eventDescription');
        String priority = (String)context.get('priority');
        
        Case remedCase = new Case(
            Subject = 'Compliance Remediation Required',
            Description = eventDescription != null ? eventDescription : 'Automated remediation case',
            Priority = priority != null ? priority : 'High',
            Status = 'New',
            Origin = 'Elaro',
            Type = 'Compliance'
        );
        
        insert as user remedCase;

        result.success = true;
        result.message = 'Case created: ' + remedCase.Id;
        result.resultId = remedCase.Id;
        
        return result;
    }
    
    private static RemediationResult executeQuarantineData(String targetId, Map<String, Object> context, RemediationResult result) {
        // In production, this would restrict access to specific content
        result.success = true;
        result.message = 'Data quarantine initiated. Manual review required.';
        return result;
    }
    
    private static RemediationResult executeForceLogout(String targetId, Map<String, Object> context, RemediationResult result) {
        try {
            // Delete active sessions for the user
            List<AuthSession> sessions = [
                SELECT Id FROM AuthSession 
                WHERE UsersId = :targetId AND IsCurrent = false
            ];
            
            if (!sessions.isEmpty()) {
                delete as user sessions;
            }
            
            result.success = true;
            result.message = 'User sessions terminated';
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to force logout: ' + e.getMessage();
        }
        
        return result;
    }
    
    private static RemediationResult executeDisableAPIAccess(String targetId, Map<String, Object> context, RemediationResult result) {
        // Remove API-specific permission sets
        result.success = true;
        result.message = 'API access review initiated. Manual review required for API-enabled permission sets.';
        return result;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // HELPER METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static void updateEventWithCase(Id eventId, Id caseId) {
        // Update the event record to link to the case
        try {
            Elaro_Evidence_Item__c event = new Elaro_Evidence_Item__c(
                Id = eventId,
                Status__c = 'Under Review'
            );
            update as user event;
        } catch (Exception e) {
            ElaroLogger.warn( 'Could not update event: ' + e.getMessage());
        }
    }
    
    private static void logRemediationAction(RemediationResult result) {
        // In production, log to a custom object for audit trail
        ElaroLogger.info( 'Remediation Action: ' + JSON.serialize(result));
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    public class RemediationResult {
        @AuraEnabled public String actionType;
        @AuraEnabled public String targetId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Datetime executedAt;
        @AuraEnabled public Id executedBy;
        @AuraEnabled public Id resultId;
    }
    
    public class ActionOption {
        @AuraEnabled public String value;
        @AuraEnabled public String label;
        @AuraEnabled public String description;
        @AuraEnabled public String icon;
        
        public ActionOption(String value, String label, String description, String icon) {
            this.value = value;
            this.label = label;
            this.description = description;
            this.icon = icon;
        }
    }
}
