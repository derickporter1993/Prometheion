/**
 * Test class for RemediationExecutor
 * @author Elaro Development Team
 * @since 2026-01
 */
@IsTest(testFor=RemediationExecutor.class)
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
        insert as user gap;

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

        insert as user suggestions;
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

        Assert.areEqual(true, result.success, 'Execution should succeed');
        Assert.areNotEqual(null, result.message, 'Message should be set');
        Assert.areEqual(true, result.requiresDeployment, 'Should require deployment');

        // Verify suggestion status updated
        Remediation_Suggestion__c updated = [SELECT Status__c, Applied_At__c, Applied_By__c
                                              FROM Remediation_Suggestion__c WHERE Id = :suggestion.Id];
        Assert.areEqual('APPLIED', updated.Status__c, 'Status should be APPLIED');
        Assert.areNotEqual(null, updated.Applied_At__c, 'Applied at should be set');
        Assert.areEqual(UserInfo.getUserId(), updated.Applied_By__c, 'Applied by should be current user');
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

        Assert.areEqual(false, result.success, 'Execution should fail');
        Assert.isTrue(result.errorMessage.contains('approved'), 'Error should mention approval');
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

        Assert.areEqual(false, result.success, 'Execution should fail');
        Assert.isTrue(result.errorMessage.contains('not available'), 'Error should mention auto-remediation not available');
    }

    @isTest
    static void testExecuteRemediation_NotFound() {
        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation('a00000000000000AAA');
        Test.stopTest();

        Assert.areEqual(false, result.success, 'Execution should fail');
        Assert.isTrue(result.errorMessage.contains('not found'), 'Error should mention not found');
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
        Assert.areEqual('APPLIED', updated.Status__c, 'Status should be APPLIED');
        Assert.isTrue(updated.Implementation_Steps__c.contains('Manual Implementation Notes'), 'Notes should be appended');

        // Verify gap status
        Compliance_Gap__c gap = [SELECT Status__c, Actual_Remediation_Date__c
                                  FROM Compliance_Gap__c WHERE Id = :suggestion.Compliance_Gap__c];
        Assert.areEqual('REMEDIATED', gap.Status__c, 'Gap should be remediated');
        Assert.areEqual(Date.today(), gap.Actual_Remediation_Date__c, 'Remediation date should be today');
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
            Assert.fail( 'Expected exception for non-approved suggestion');
        } catch (RemediationSuggestionService.RemediationException e) {
            Assert.isTrue(e.getMessage().contains('approved'), 'Error should mention approval');
        }
        Test.stopTest();
    }

    @isTest
    static void testMarkAsManuallyApplied_NotFound() {
        Test.startTest();
        try {
            RemediationExecutor.markAsManuallyApplied('a00000000000000AAA', 'Test notes');
            Assert.fail( 'Expected exception for invalid ID');
        } catch (RemediationSuggestionService.RemediationException e) {
            Assert.isTrue(e.getMessage().contains('not found'), 'Error should mention not found');
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

        Assert.isTrue(history.size() > 0, 'Should have execution history');

        RemediationExecutor.ExecutionHistory item = history[0];
        Assert.areNotEqual(null, item.suggestionId, 'Suggestion ID should be set');
        Assert.areEqual('APPLIED', item.status, 'Status should be APPLIED');
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
        insert as user suggestion2;

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

        Assert.areEqual(suggestionIds.size(), result.totalProcessed, 'Total processed should match');
        Assert.isTrue(result.successCount > 0, 'Should have successes');
        Assert.areNotEqual(null, result.results, 'Results list should be set');
    }

    @isTest
    static void testRemediationResultWrapper() {
        RemediationExecutor.RemediationResult result = new RemediationExecutor.RemediationResult();
        result.suggestionId = 'test123';
        result.success = true;
        result.message = 'Test message';
        result.errorMessage = null;
        result.requiresDeployment = true;

        Assert.areEqual('test123', result.suggestionId, 'Suggestion ID should match');
        Assert.areEqual(true, result.success, 'Success should match');
        Assert.areEqual(true, result.requiresDeployment, 'Requires deployment should match');
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

        Assert.areEqual('REM-00001', item.suggestionName, 'Suggestion name should match');
        Assert.areEqual('APPLIED', item.status, 'Status should match');
    }

    @isTest
    static void testBulkExecutionResultWrapper() {
        RemediationExecutor.BulkExecutionResult result = new RemediationExecutor.BulkExecutionResult();
        result.totalProcessed = 5;
        result.successCount = 3;
        result.failureCount = 2;
        result.results = new List<RemediationExecutor.RemediationResult>();

        Assert.areEqual(5, result.totalProcessed, 'Total should match');
        Assert.areEqual(3, result.successCount, 'Success count should match');
        Assert.areEqual(2, result.failureCount, 'Failure count should match');
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
        insert as user flsSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(flsSuggestion.Id);
        Test.stopTest();

        Assert.areEqual(true, result.success, 'FLS remediation should succeed');
        Assert.isTrue(result.message.contains('Field-level security'), 'Message should mention FLS');
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
        insert as user profileSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(profileSuggestion.Id);
        Test.stopTest();

        Assert.areEqual(true, result.success, 'Profile remediation should succeed');
        Assert.isTrue(result.message.contains('Profile update'), 'Message should mention profile');
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
        insert as user badSuggestion;

        Test.startTest();
        RemediationExecutor.RemediationResult result = RemediationExecutor.executeRemediation(badSuggestion.Id);
        Test.stopTest();

        Assert.areEqual(false, result.success, 'Should fail with invalid payload');
        Assert.isTrue(result.errorMessage.contains('Execution failed'), 'Error should mention execution failure');
    }

    @isTest
    static void testBulkExecute_LargeVolume() {
        // Create 55 gaps and suggestions to test bulk operations
        Integer recordCount = 55;
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();

        for (Integer i = 0; i < recordCount; i++) {
            gaps.add(new Compliance_Gap__c(
                Framework__c = 'SOX',
                Policy_Reference__c = 'SOX_BULK_TEST_' + i,
                Severity__c = 'HIGH',
                Status__c = 'OPEN',
                Gap_Description__c = 'Bulk test gap ' + i,
                Entity_Type__c = 'PERMISSION_SET',
                Entity_Id__c = '0PS00000000000' + String.valueOf(i).leftPad(1, '0'),
                Detected_Date__c = Datetime.now()
            ));
        }
        insert as user gaps;

        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();
        String[] suggestionTypes = new String[]{ 'PERMISSION_CHANGE', 'FIELD_LEVEL_SECURITY', 'PROFILE_UPDATE' };

        for (Integer i = 0; i < recordCount; i++) {
            String suggestionType = suggestionTypes[Math.mod(i, 3)];
            Map<String, Object> payload = new Map<String, Object>{
                'suggestionType' => suggestionType,
                'action' => 'BULK_TEST_ACTION_' + i
            };

            if (suggestionType == 'PERMISSION_CHANGE') {
                payload.put('targetPermissionSet', '0PS00000000000' + i);
            } else if (suggestionType == 'FIELD_LEVEL_SECURITY') {
                payload.put('targetObject', 'Account');
            } else {
                payload.put('targetProfile', '00e00000000000' + i);
            }

            suggestions.add(new Remediation_Suggestion__c(
                Compliance_Gap__c = gaps[i].Id,
                Suggestion_Type__c = suggestionType,
                Framework__c = 'SOX',
                Status__c = 'APPROVED',
                Auto_Remediation_Available__c = true,
                Auto_Remediation_Payload__c = JSON.serialize(payload),
                Description__c = 'Bulk test suggestion ' + i,
                Confidence_Score__c = 0.85,
                Risk_Reduction_Score__c = 7.0,
                Effort_Estimate__c = 'LOW',
                Priority_Score__c = 10.0
            ));
        }
        insert as user suggestions;

        List<String> suggestionIds = new List<String>();
        for (Remediation_Suggestion__c s : suggestions) {
            suggestionIds.add(s.Id);
        }

        Test.startTest();
        // This should NOT hit governor limits with bulkified code
        RemediationExecutor.BulkExecutionResult result = RemediationExecutor.bulkExecute(suggestionIds);
        Test.stopTest();

        Assert.areEqual(recordCount, result.totalProcessed, 'Should process all records');
        Assert.areEqual(recordCount, result.successCount, 'All should succeed');
        Assert.areEqual(0, result.failureCount, 'None should fail');
        Assert.areEqual(recordCount, result.results.size(), 'Should have result for each');

        // Verify suggestions were updated
        List<Remediation_Suggestion__c> updatedSuggestions = [
            SELECT Id, Status__c FROM Remediation_Suggestion__c
            WHERE Id IN :suggestionIds AND Status__c = 'APPLIED'
        ];
        Assert.areEqual(recordCount, updatedSuggestions.size(), 'All suggestions should be APPLIED');

        // Verify gaps were updated
        Set<Id> gapIds = new Set<Id>();
        for (Compliance_Gap__c g : gaps) {
            gapIds.add(g.Id);
        }
        List<Compliance_Gap__c> updatedGaps = [
            SELECT Id, Status__c FROM Compliance_Gap__c
            WHERE Id IN :gapIds AND Status__c = 'REMEDIATED'
        ];
        Assert.areEqual(recordCount, updatedGaps.size(), 'All gaps should be REMEDIATED');
    }

    @isTest
    static void testBulkExecute_EmptyList() {
        Test.startTest();
        RemediationExecutor.BulkExecutionResult result = RemediationExecutor.bulkExecute(new List<String>());
        Test.stopTest();

        Assert.areEqual(0, result.totalProcessed, 'Should process zero records');
        Assert.areEqual(0, result.successCount, 'No successes');
        Assert.areEqual(0, result.failureCount, 'No failures');
    }

    @isTest
    static void testBulkExecute_NullList() {
        Test.startTest();
        RemediationExecutor.BulkExecutionResult result = RemediationExecutor.bulkExecute(null);
        Test.stopTest();

        Assert.areEqual(0, result.totalProcessed, 'Should process zero records');
    }

    @isTest
    static void testBulkExecute_MixedResults() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];

        // Create one valid, one not approved, one without auto-remediation
        List<Remediation_Suggestion__c> testSuggestions = new List<Remediation_Suggestion__c>();

        // Valid - will succeed
        testSuggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PERMISSION_CHANGE',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'PERMISSION_CHANGE',
                'action' => 'TEST_ACTION',
                'targetPermissionSet' => '0PS000000000099'
            }),
            Description__c = 'Valid suggestion'
        ));

        // Not approved - will fail
        testSuggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'PERMISSION_CHANGE',
            Framework__c = 'SOX',
            Status__c = 'PENDING',
            Auto_Remediation_Available__c = true,
            Auto_Remediation_Payload__c = JSON.serialize(new Map<String, Object>{
                'suggestionType' => 'PERMISSION_CHANGE',
                'action' => 'TEST_ACTION',
                'targetPermissionSet' => '0PS000000000098'
            }),
            Description__c = 'Not approved suggestion'
        ));

        // No auto-remediation - will fail
        testSuggestions.add(new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'MANUAL_REVIEW',
            Framework__c = 'SOX',
            Status__c = 'APPROVED',
            Auto_Remediation_Available__c = false,
            Description__c = 'Manual only suggestion'
        ));

        insert as user testSuggestions;

        List<String> suggestionIds = new List<String>();
        for (Remediation_Suggestion__c s : testSuggestions) {
            suggestionIds.add(s.Id);
        }

        // Add a non-existent ID
        suggestionIds.add('a00000000000000AAA');

        Test.startTest();
        RemediationExecutor.BulkExecutionResult result = RemediationExecutor.bulkExecute(suggestionIds);
        Test.stopTest();

        Assert.areEqual(4, result.totalProcessed, 'Should process all 4');
        Assert.areEqual(1, result.successCount, 'One should succeed');
        Assert.areEqual(3, result.failureCount, 'Three should fail');
    }
}
