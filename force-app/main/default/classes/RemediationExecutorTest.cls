/**
 * @description Test class for RemediationExecutor
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class RemediationExecutorTest {

    @TestSetup
    static void setupTestData() {
        // Create a compliance gap
        Compliance_Gap__c gap = new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_ACCESS_REVIEW',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Excessive permissions',
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '0PS000000000001',
            Detected_Date__c = Datetime.now()
        );
        insert gap;

        // Create suggestions with different states
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // Auto-remediable approved suggestion
        suggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PERMISSION_CHANGE',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'PERMISSION_CHANGE',
                'action' => 'REMOVE_EXCESSIVE_PERMISSIONS',
                'targetPermissionSet' => '0PS000000000001',
                'gapId' => gap.Id
            }),
            Description__c = 'Test suggestion',
            Confidence_Score__c = 0.85,
            Risk_Reduction_Score__c = 8.0,
            Effort_Estimate__c = 'LOW',
            Priority_Score__c = 12.0
        ));

        // Non-auto-remediable approved suggestion
        suggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'MANUAL_REVIEW',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = false,
            Description__c = 'Manual review required',
            Confidence_Score__c = 0.70,
            Risk_Reduction_Score__c = 5.0,
            Effort_Estimate__c = 'HIGH',
            Priority_Score__c = 3.5
        ));

        // Pending suggestion
        suggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'FIELD_LEVEL_SECURITY',
            Framework__c = 'SOX',
            Status__c = 'PENDING',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'FIELD_LEVEL_SECURITY',
                'action' => 'RESTRICT_FIELD_ACCESS',
                'targetObject' => 'Account',
                'gapId' => gap.Id
            }),
            Description__c = 'FLS suggestion',
            Confidence_Score__c = 0.80
        ));

        insert suggestions;
    }

    @isTest
    static void testExecuteRemediation_Success() {
        Remediation_Suggestion__c suggestion = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'APPROVED' AND Auto_Remediation_Available__c = true
            LIMIT 1
        ];

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(suggestion.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Execution should succeed');
        System.assertNotEquals(null, result.message, 'Message should be set');
        System.assertEquals(true, result.requiresDeployment, 'Should require deployment');

        // Verify suggestion status updated
        Remediation_Suggestion__c updated = [SELECT Status__c, Applied_At__c, Applied_By__c
                                              FROM Remediation_Suggestion__c WHERE Id = :suggestion.Id];
        System.assertEquals('APPLIED', updated.Status__c, 'Status should be APPLIED');
        System.assertNotEquals(null, updated.Applied_At__c, 'Applied at should be set');
        System.assertEquals(UserInfo.getUserId(), updated.Applied_By__c, 'Applied by should be current user');
    }

    @isTest
    static void testExecuteRemediation_NotApproved() {
        Remediation_Suggestion__c suggestion = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'PENDING'
            LIMIT 1
        ];

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(suggestion.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Execution should fail');
        System.assert(result.errorMessage.contains('approved'), 'Error should mention approval');
    }

    @isTest
    static void testExecuteRemediation_NoAutoRemediation() {
        Remediation_Suggestion__c suggestion = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'APPROVED' AND Auto_Remediation_Available__c = false
            LIMIT 1
        ];

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(suggestion.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Execution should fail');
        System.assert(result.errorMessage.contains('not available'), 'Error should mention auto-remediation not available');
    }

    @isTest
    static void testExecuteRemediation_NotFound() {
        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation('a00000000000000AAA');
        Test.stopTest();

        System.assertEquals(false, result.success, 'Execution should fail');
        System.assert(result.errorMessage.contains('not found'), 'Error should mention not found');
    }

    @isTest
    static void testMarkAsManuallyApplied() {
        Remediation_Suggestion__c suggestion = [
            SELECT Id, Compliance_Gap__c FROM Remediation_Suggestion__c
            WHERE Status__c = 'APPROVED' AND Auto_Remediation_Available__c = false
            LIMIT 1
        ];

        Test.startTest();
        RemediationExecutor.markAsManuallyApplied(suggestion.Id, 'Implemented by John Doe via manual configuration.');
        Test.stopTest();

        // Verify suggestion status
        Remediation_Suggestion__c updated = [SELECT Status__c, Applied_At__c, Implementation_Steps__c
                                              FROM Remediation_Suggestion__c WHERE Id = :suggestion.Id];
        System.assertEquals('APPLIED', updated.Status__c, 'Status should be APPLIED');
        System.assert(updated.Implementation_Steps__c.contains('Manual Implementation Notes'), 'Notes should be appended');

        // Verify gap status
        Compliance_Gap__c gap = [SELECT Status__c, Actual_Remediation_Date__c
                                  FROM Compliance_Gap__c WHERE Id = :suggestion.Compliance_Gap__c];
        System.assertEquals('REMEDIATED', gap.Status__c, 'Gap should be remediated');
        System.assertEquals(Date.today(), gap.Actual_Remediation_Date__c, 'Remediation date should be today');
    }

    @isTest
    static void testMarkAsManuallyApplied_NotApproved() {
        Remediation_Suggestion__c suggestion = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'PENDING'
            LIMIT 1
        ];

        Test.startTest();
        try {
            RemediationExecutor.markAsManuallyApplied(suggestion.Id, 'Test notes');
            System.assert(false, 'Expected exception for non-approved suggestion');
        } catch (RemediationSuggestionService.RemediationException e) {
            System.assert(e.getMessage().contains('approved'), 'Error should mention approval');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarkAsManuallyApplied_NotFound() {
        Test.startTest();
        try {
            RemediationExecutor.markAsManuallyApplied('a00000000000000AAA', 'Test notes');
            System.assert(false, 'Expected exception for invalid ID');
        } catch (RemediationSuggestionService.RemediationException e) {
            System.assert(e.getMessage().contains('not found'), 'Error should mention not found');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetExecutionHistory() {
        // First execute a remediation to create history
        Remediation_Suggestion__c suggestion = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'APPROVED' AND Auto_Remediation_Available__c = true
            LIMIT 1
        ];
        RemediationExecutor.executeRemediation(suggestion.Id);

        Test.startTest();
        List<RemediationExecutor.ExecutionHistory> history = RemediationExecutor.getExecutionHistory();
        Test.stopTest();

        System.assert(history.size() > 0, 'Should have execution history');

        RemediationExecutor.ExecutionHistory item = history[0];
        System.assertNotEquals(null, item.suggestionId, 'Suggestion ID should be set');
        System.assertEquals('APPLIED', item.status, 'Status should be APPLIED');
    }

    @isTest
    static void testBulkExecute() {
        // Create additional approved auto-remediable suggestions
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Remediation_Suggestion__c suggestion2 = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PROFILE_UPDATE',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'PROFILE_UPDATE',
                'action' => 'UPDATE_PROFILE_PERMISSIONS',
                'targetProfile' => '00e000000000001',
                'gapId' => gap.Id
            }),
            Description__c = 'Profile update suggestion'
        );
        insert suggestion2;

        List<Remediation_Suggestion__c> approvedSuggestions = [
            SELECT Id FROM Remediation_Suggestion__c
            WHERE Status__c = 'APPROVED' AND Auto_Remediation_Available__c = true
        ];

        List<String> suggestionIds = new List<String>();
        for (Remediation_Suggestion__c s : approvedSuggestions) {
            suggestionIds.add(s.Id);
        }

        Test.startTest();
        RemediationExecutor.BulkExecutionResult result = RemediationExecutor.bulkExecute(suggestionIds);
        Test.stopTest();

        System.assertEquals(suggestionIds.size(), result.totalProcessed, 'Total processed should match');
        System.assert(result.successCount > 0, 'Should have successes');
        System.assertNotEquals(null, result.results, 'Results list should be set');
    }

    @isTest
    static void testRemediationResultWrapper() {
        RemediationExecutor.RemediationResult result = new RemediationExecutor.RemediationResult();
        result.suggestionId = 'test123';
        result.success = true;
        result.message = 'Test message';
        result.errorMessage = null;
        result.requiresDeployment = true;

        System.assertEquals('test123', result.suggestionId, 'Suggestion ID should match');
        System.assertEquals(true, result.success, 'Success should match');
        System.assertEquals(true, result.requiresDeployment, 'Requires deployment should match');
    }

    @isTest
    static void testExecutionHistoryWrapper() {
        RemediationExecutor.ExecutionHistory item = new RemediationExecutor.ExecutionHistory();
        item.suggestionId = null;
        item.suggestionName = 'REM-00001';
        item.suggestionType = 'PERMISSION_CHANGE';
        item.status = 'APPLIED';
        item.appliedAt = Datetime.now();
        item.appliedBy = 'Test User';
        item.errorMessage = null;
        item.framework = 'SOX';
        item.gapName = 'GAP-00001';

        System.assertEquals('REM-00001', item.suggestionName, 'Suggestion name should match');
        System.assertEquals('APPLIED', item.status, 'Status should match');
    }

    @isTest
    static void testBulkExecutionResultWrapper() {
        RemediationExecutor.BulkExecutionResult result = new RemediationExecutor.BulkExecutionResult();
        result.totalProcessed = 5;
        result.successCount = 3;
        result.failureCount = 2;
        result.results = new List<RemediationExecutor.RemediationResult>();

        System.assertEquals(5, result.totalProcessed, 'Total should match');
        System.assertEquals(3, result.successCount, 'Success count should match');
        System.assertEquals(2, result.failureCount, 'Failure count should match');
    }

    @isTest
    static void testExecuteRemediation_FLSType() {
        // Create FLS-type approved suggestion
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Remediation_Suggestion__c flsSuggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'FIELD_LEVEL_SECURITY',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'FIELD_LEVEL_SECURITY',
                'action' => 'RESTRICT_FIELD_ACCESS',
                'targetObject' => 'Account',
                'gapId' => gap.Id
            }),
            Description__c = 'FLS suggestion'
        );
        insert flsSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(flsSuggestion.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'FLS remediation should succeed');
        System.assert(result.message.contains('Field-level security'), 'Message should mention FLS');
    }

    @isTest
    static void testExecuteRemediation_ProfileType() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Remediation_Suggestion__c profileSuggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PROFILE_UPDATE',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'PROFILE_UPDATE',
                'action' => 'UPDATE_PROFILE_PERMISSIONS',
                'targetProfile' => '00e000000000001',
                'gapId' => gap.Id
            }),
            Description__c = 'Profile update'
        );
        insert profileSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(profileSuggestion.Id);
        Test.stopTest();

        System.assertEquals(true, result.success, 'Profile remediation should succeed');
        System.assert(result.message.contains('Profile update'), 'Message should mention profile');
    }

    @isTest
    static void testExecuteRemediation_InvalidPayload() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        Remediation_Suggestion__c badSuggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PERMISSION_CHANGE',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = 'invalid json',
            Description__c = 'Bad payload'
        );
        insert badSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(badSuggestion.Id);
        Test.stopTest();

        System.assertEquals(false, result.success, 'Should fail with invalid payload');
        System.assert(result.errorMessage.contains('Execution failed'), 'Error should mention execution failure');
    }
}
