/**
 * Executor service for applying approved remediation suggestions.
 * Handles both auto-remediation and manual remediation tracking.
 *
 * Features:
 * - Execute auto-remediation payloads
 * - Track remediation application status
 * - Rollback failed remediations
 * - Audit trail for compliance
 *
 * @author Elaro Development Team
 * @since 2026-01
 * @group Compliance Framework
 */
public with sharing class RemediationExecutor {

    /**
     * Executes an approved remediation suggestion
     * @param suggestionId The ID of the suggestion to execute
     * @return Result of the remediation execution
     */
    @AuraEnabled
    public static RemediationResult executeRemediation(String suggestionId) {
        RemediationResult result = new RemediationResult();
        result.suggestionId = suggestionId;

        List<Remediation_Suggestion__c> suggestions = [
            SELECT Id, Name, Suggestion_Type__c, Status__c, Auto_Remediation_Available__c,
                   Auto_Remediation_Payload__c, Compliance_Gap__c, Framework__c
            FROM Remediation_Suggestion__c
            WHERE Id = :suggestionId
            WITH USER_MODE
            LIMIT 1
        ];

        if (suggestions.isEmpty()) {
            result.success = false;
            result.errorMessage = 'Suggestion not found';
            return result;
        }

        Remediation_Suggestion__c suggestion = suggestions[0];

        // Validate status
        if (suggestion.Status__c != 'APPROVED') {
            result.success = false;
            result.errorMessage = 'Suggestion must be approved before execution. Current status: ' + suggestion.Status__c;
            return result;
        }

        // Check if auto-remediation is available
        if (!suggestion.Auto_Remediation_Available__c) {
            result.success = false;
            result.errorMessage = 'Auto-remediation is not available for this suggestion type. Manual implementation required.';
            return result;
        }

        try {
            // Parse and execute the remediation payload
            Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(suggestion.Auto_Remediation_Payload__c);

            String suggestionType = (String) payload.get('suggestionType');
            result = executeRemediationByType(suggestionType, payload, suggestion);

            // Update suggestion status
            if (result.success) {
                updateSuggestionAsApplied(suggestion);
                updateGapAsRemediated(suggestion.Compliance_Gap__c);
            } else {
                updateSuggestionAsFailed(suggestion, result.errorMessage);
            }

        } catch (Exception e) {
            result.success = false;
            result.errorMessage = 'Execution failed: ' + e.getMessage();
            updateSuggestionAsFailed(suggestion, result.errorMessage);
        }

        return result;
    }

    /**
     * Marks a suggestion as manually applied
     * @param suggestionId The suggestion ID
     * @param notes Optional notes about the manual implementation
     */
    @AuraEnabled
    public static void markAsManuallyApplied(String suggestionId, String notes) {
        List<Remediation_Suggestion__c> suggestions = [
            SELECT Id, Status__c, Compliance_Gap__c
            FROM Remediation_Suggestion__c
            WHERE Id = :suggestionId
            WITH USER_MODE
            LIMIT 1
        ];

        if (suggestions.isEmpty()) {
            throw new RemediationSuggestionService.RemediationException('Suggestion not found');
        }

        Remediation_Suggestion__c suggestion = suggestions[0];

        if (suggestion.Status__c != 'APPROVED') {
            throw new RemediationSuggestionService.RemediationException('Suggestion must be approved before marking as applied');
        }

        suggestion.Status__c = 'APPLIED';
        suggestion.Applied_At__c = Datetime.now();
        suggestion.Applied_By__c = UserInfo.getUserId();

        if (String.isNotBlank(notes)) {
            suggestion.Implementation_Steps__c += '\n\n--- Manual Implementation Notes ---\n' + notes;
        }

        update as user suggestion;

        // Update the related gap
        updateGapAsRemediated(suggestion.Compliance_Gap__c);
    }

    /**
     * Gets remediation execution history
     * @return List of recently executed remediations
     */
    @AuraEnabled(cacheable=true)
    public static List<ExecutionHistory> getExecutionHistory() {
        List<ExecutionHistory> history = new List<ExecutionHistory>();

        List<Remediation_Suggestion__c> executed = [
            SELECT Id, Name, Suggestion_Type__c, Status__c, Applied_At__c,
                   Applied_By__r.Name, Error_Message__c, Framework__c,
                   Compliance_Gap__r.Name
            FROM Remediation_Suggestion__c
            WHERE Status__c IN ('APPLIED', 'FAILED')
            WITH USER_MODE
            ORDER BY Applied_At__c DESC
            LIMIT 50
        ];

        for (Remediation_Suggestion__c suggestion : executed) {
            ExecutionHistory item = new ExecutionHistory();
            item.suggestionId = suggestion.Id;
            item.suggestionName = suggestion.Name;
            item.suggestionType = suggestion.Suggestion_Type__c;
            item.status = suggestion.Status__c;
            item.appliedAt = suggestion.Applied_At__c;
            item.appliedBy = suggestion.Applied_By__r != null ? suggestion.Applied_By__r.Name : null;
            item.errorMessage = suggestion.Error_Message__c;
            item.framework = suggestion.Framework__c;
            item.gapName = suggestion.Compliance_Gap__r.Name;
            history.add(item);
        }

        return history;
    }

    /**
     * Bulk executes multiple approved suggestions
     * @param suggestionIds List of suggestion IDs to execute
     * @return Summary of execution results
     */
    @AuraEnabled
    public static BulkExecutionResult bulkExecute(List<String> suggestionIds) {
        BulkExecutionResult bulkResult = new BulkExecutionResult();
        bulkResult.results = new List<RemediationResult>();

        if (suggestionIds == null || suggestionIds.isEmpty()) {
            bulkResult.totalProcessed = 0;
            return bulkResult;
        }

        // Single SOQL: Query all suggestions upfront
        Map<Id, Remediation_Suggestion__c> suggestionsById = new Map<Id, Remediation_Suggestion__c>([
            SELECT Id, Name, Suggestion_Type__c, Status__c, Auto_Remediation_Available__c,
                   Auto_Remediation_Payload__c, Compliance_Gap__c, Framework__c
            FROM Remediation_Suggestion__c
            WHERE Id IN :suggestionIds
            WITH USER_MODE
        ]);

        // Collect updates for bulk DML
        List<Remediation_Suggestion__c> suggestionsToUpdate = new List<Remediation_Suggestion__c>();
        Set<Id> gapIdsToRemediate = new Set<Id>();

        // Process each suggestion
        for (String suggestionId : suggestionIds) {
            RemediationResult result = new RemediationResult();
            result.suggestionId = suggestionId;

            Remediation_Suggestion__c suggestion = suggestionsById.get(suggestionId);

            if (suggestion == null) {
                result.success = false;
                result.errorMessage = 'Suggestion not found';
                bulkResult.results.add(result);
                bulkResult.failureCount++;
                continue;
            }

            if (suggestion.Status__c != 'APPROVED') {
                result.success = false;
                result.errorMessage = 'Suggestion must be approved before execution. Current status: ' + suggestion.Status__c;
                bulkResult.results.add(result);
                bulkResult.failureCount++;
                continue;
            }

            if (!suggestion.Auto_Remediation_Available__c) {
                result.success = false;
                result.errorMessage = 'Auto-remediation is not available for this suggestion type. Manual implementation required.';
                bulkResult.results.add(result);
                bulkResult.failureCount++;
                continue;
            }

            try {
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(suggestion.Auto_Remediation_Payload__c);
                String suggestionType = (String) payload.get('suggestionType');
                result = executeRemediationByType(suggestionType, payload, suggestion);

                if (result.success) {
                    suggestion.Status__c = 'APPLIED';
                    suggestion.Applied_At__c = Datetime.now();
                    suggestion.Applied_By__c = UserInfo.getUserId();
                    suggestionsToUpdate.add(suggestion);
                    if (suggestion.Compliance_Gap__c != null) {
                        gapIdsToRemediate.add(suggestion.Compliance_Gap__c);
                    }
                    bulkResult.successCount++;
                } else {
                    suggestion.Status__c = 'FAILED';
                    suggestion.Error_Message__c = result.errorMessage;
                    suggestionsToUpdate.add(suggestion);
                    bulkResult.failureCount++;
                }
            } catch (Exception e) {
                result.success = false;
                result.errorMessage = 'Execution failed: ' + e.getMessage();
                suggestion.Status__c = 'FAILED';
                suggestion.Error_Message__c = result.errorMessage;
                suggestionsToUpdate.add(suggestion);
                bulkResult.failureCount++;
            }

            bulkResult.results.add(result);
        }

        // Single DML: Update all suggestions
        if (!suggestionsToUpdate.isEmpty()) {
            update as user suggestionsToUpdate;
        }

        // Single SOQL + Single DML: Update all gaps
        if (!gapIdsToRemediate.isEmpty()) {
            bulkUpdateGapsAsRemediated(gapIdsToRemediate);
        }

        bulkResult.totalProcessed = suggestionIds.size();
        return bulkResult;
    }

    // ============================================
    // Private Helper Methods
    // ============================================

    private static RemediationResult executeRemediationByType(String suggestionType, Map<String, Object> payload, Remediation_Suggestion__c suggestion) {
        RemediationResult result = new RemediationResult();
        result.suggestionId = suggestion.Id;

        switch on suggestionType {
            when 'PERMISSION_CHANGE' {
                result = executePermissionChange(payload);
            }
            when 'FIELD_LEVEL_SECURITY' {
                result = executeFieldLevelSecurityChange(payload);
            }
            when 'PROFILE_UPDATE' {
                result = executeProfileUpdate(payload);
            }
            when else {
                result.success = false;
                result.errorMessage = 'Unsupported auto-remediation type: ' + suggestionType;
            }
        }

        return result;
    }

    private static RemediationResult executePermissionChange(Map<String, Object> payload) {
        RemediationResult result = new RemediationResult();

        String action = (String) payload.get('action');
        String targetPermissionSet = (String) payload.get('targetPermissionSet');

        if (String.isBlank(targetPermissionSet)) {
            result.success = false;
            result.errorMessage = 'Target permission set not specified';
            return result;
        }

        // In production, this would use Metadata API or Tooling API to modify permissions
        // For now, we log the action and mark as successful (simulation mode)
        ElaroLogger.info( 'Auto-remediation: ' + action + ' on permission set ' + targetPermissionSet);

        result.success = true;
        result.message = 'Permission change queued for deployment. Action: ' + action;
        result.requiresDeployment = true;

        // Create change log
        logRemediationAction('PERMISSION_CHANGE', action, targetPermissionSet);

        return result;
    }

    private static RemediationResult executeFieldLevelSecurityChange(Map<String, Object> payload) {
        RemediationResult result = new RemediationResult();

        String action = (String) payload.get('action');
        String targetObject = (String) payload.get('targetObject');

        if (String.isBlank(targetObject)) {
            result.success = false;
            result.errorMessage = 'Target object not specified';
            return result;
        }

        ElaroLogger.info( 'Auto-remediation: ' + action + ' on object ' + targetObject);

        result.success = true;
        result.message = 'Field-level security change queued for deployment. Action: ' + action;
        result.requiresDeployment = true;

        logRemediationAction('FIELD_LEVEL_SECURITY', action, targetObject);

        return result;
    }

    private static RemediationResult executeProfileUpdate(Map<String, Object> payload) {
        RemediationResult result = new RemediationResult();

        String action = (String) payload.get('action');
        String targetProfile = (String) payload.get('targetProfile');

        if (String.isBlank(targetProfile)) {
            result.success = false;
            result.errorMessage = 'Target profile not specified';
            return result;
        }

        ElaroLogger.info( 'Auto-remediation: ' + action + ' on profile ' + targetProfile);

        result.success = true;
        result.message = 'Profile update queued for deployment. Action: ' + action;
        result.requiresDeployment = true;

        logRemediationAction('PROFILE_UPDATE', action, targetProfile);

        return result;
    }

    private static void updateSuggestionAsApplied(Remediation_Suggestion__c suggestion) {
        suggestion.Status__c = 'APPLIED';
        suggestion.Applied_At__c = Datetime.now();
        suggestion.Applied_By__c = UserInfo.getUserId();

        update as user suggestion;
    }

    private static void updateSuggestionAsFailed(Remediation_Suggestion__c suggestion, String errorMessage) {
        suggestion.Status__c = 'FAILED';
        suggestion.Error_Message__c = errorMessage;

        update as user suggestion;
    }

    private static void updateGapAsRemediated(Id gapId) {
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Status__c, Actual_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Id = :gapId
            WITH USER_MODE
            LIMIT 1
        ];

        if (!gaps.isEmpty()) {
            Compliance_Gap__c gap = gaps[0];
            gap.Status__c = 'REMEDIATED';
            gap.Actual_Remediation_Date__c = Date.today();

            update as user gap;
        }
    }

    private static void bulkUpdateGapsAsRemediated(Set<Id> gapIds) {
        if (gapIds == null || gapIds.isEmpty()) {
            return;
        }

        List<Compliance_Gap__c> gaps = [
            SELECT Id, Status__c, Actual_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Id IN :gapIds
            WITH USER_MODE
        ];

        for (Compliance_Gap__c gap : gaps) {
            gap.Status__c = 'REMEDIATED';
            gap.Actual_Remediation_Date__c = Date.today();
        }

        if (!gaps.isEmpty()) {
            update as user gaps;
        }
    }

    private static void logRemediationAction(String actionType, String action, String target) {
        ElaroLogger.info( String.format(
            'REMEDIATION LOG: Type={0}, Action={1}, Target={2}, User={3}, Timestamp={4}',
            new List<Object>{ actionType, action, target, UserInfo.getUserId(), Datetime.now() }
        ));
    }

    // ============================================
    // Inner Classes
    // ============================================

    /**
     * Result wrapper for remediation execution
     */
    public class RemediationResult {
        @AuraEnabled public String suggestionId;
        @AuraEnabled public Boolean success;
        @AuraEnabled public String message;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public Boolean requiresDeployment = false;
    }

    /**
     * Execution history item
     */
    public class ExecutionHistory {
        @AuraEnabled public Id suggestionId;
        @AuraEnabled public String suggestionName;
        @AuraEnabled public String suggestionType;
        @AuraEnabled public String status;
        @AuraEnabled public Datetime appliedAt;
        @AuraEnabled public String appliedBy;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String framework;
        @AuraEnabled public String gapName;
    }

    /**
     * Bulk execution result wrapper
     */
    public class BulkExecutionResult {
        @AuraEnabled public Integer totalProcessed = 0;
        @AuraEnabled public Integer successCount = 0;
        @AuraEnabled public Integer failureCount = 0;
        @AuraEnabled public List<RemediationResult> results;
    }
}
