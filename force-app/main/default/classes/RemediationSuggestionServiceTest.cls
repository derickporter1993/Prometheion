/**
 * @description Test class for RemediationSuggestionService
 * @author Elaro Development Team
 * @since 2026-01
 */
@isTest
private class RemediationSuggestionServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create compliance gaps for different scenarios
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();

        // SOX gap with permission set entity
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_ACCESS_REVIEW',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Excessive permissions on financial objects',
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '0PS000000000001',
            Risk_Score__c = 8.5,
            Detected_Date__c = Datetime.now()
        ));

        // HIPAA gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_PHI_ACCESS',
            Severity__c = 'HIGH',
            Status__c = 'OPEN',
            Gap_Description__c = 'PHI data not encrypted',
            Entity_Type__c = 'CUSTOM_FIELD',
            Entity_Id__c = 'Account.SSN__c',
            Detected_Date__c = Datetime.now()
        ));

        // SOC2 gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_ACCESS_CONTROL',
            Severity__c = 'HIGH',
            Status__c = 'OPEN',
            Gap_Description__c = 'Missing access controls',
            Entity_Type__c = 'PROFILE',
            Entity_Id__c = '00e000000000001',
            Detected_Date__c = Datetime.now()
        ));

        // GDPR gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'GDPR',
            Policy_Reference__c = 'GDPR_DATA_ACCESS',
            Severity__c = 'MEDIUM',
            Status__c = 'OPEN',
            Gap_Description__c = 'Personal data access not restricted',
            Entity_Type__c = 'CUSTOM_OBJECT',
            Detected_Date__c = Datetime.now()
        ));

        // Gap with unknown entity type
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'NIST',
            Policy_Reference__c = 'NIST_CONTROL_AC1',
            Severity__c = 'LOW',
            Status__c = 'OPEN',
            Gap_Description__c = 'General compliance gap',
            Entity_Type__c = 'UNKNOWN_TYPE',
            Detected_Date__c = Datetime.now()
        ));

        insert gaps;
    }

    @isTest
    static void testGenerateSuggestions_SOX() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should generate at least one suggestion');

        // Verify SOX-specific suggestions
        Boolean hasAuditSuggestion = false;
        for (Remediation_Suggestion__c suggestion : suggestions) {
            System.assertEquals('SOX', suggestion.Framework__c, 'Framework should be SOX');
            System.assertEquals('PENDING', suggestion.Status__c, 'Status should be PENDING');
            System.assertNotEquals(null, suggestion.Confidence_Score__c, 'Confidence score should be set');
            System.assertNotEquals(null, suggestion.Priority_Score__c, 'Priority score should be set');

            if (suggestion.Suggestion_Type__c == 'AUDIT_TRAIL') {
                hasAuditSuggestion = true;
            }
        }
        System.assert(hasAuditSuggestion, 'Should include audit trail suggestion for SOX');
    }

    @isTest
    static void testGenerateSuggestions_HIPAA() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'HIPAA' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should generate suggestions');

        // Verify HIPAA-specific encryption suggestion
        Boolean hasEncryptionSuggestion = false;
        for (Remediation_Suggestion__c suggestion : suggestions) {
            if (suggestion.Suggestion_Type__c == 'ENCRYPTION') {
                hasEncryptionSuggestion = true;
                System.assertEquals('HIPAA', suggestion.Framework__c, 'Framework should be HIPAA');
            }
        }
        System.assert(hasEncryptionSuggestion, 'Should include encryption suggestion for HIPAA');
    }

    @isTest
    static void testGenerateSuggestions_SOC2() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOC2' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should generate suggestions');

        for (Remediation_Suggestion__c suggestion : suggestions) {
            System.assertEquals('SOC2', suggestion.Framework__c, 'Framework should be SOC2');
        }
    }

    @isTest
    static void testGenerateSuggestions_GDPR() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'GDPR' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should generate suggestions');

        // Verify privacy-specific FLS suggestion
        Boolean hasFLSSuggestion = false;
        for (Remediation_Suggestion__c suggestion : suggestions) {
            if (suggestion.Suggestion_Type__c == 'FIELD_LEVEL_SECURITY') {
                hasFLSSuggestion = true;
            }
        }
        System.assert(hasFLSSuggestion, 'Should include FLS suggestion for GDPR');
    }

    @isTest
    static void testGenerateSuggestions_InvalidGap() {
        Test.startTest();
        try {
            RemediationSuggestionService.generateSuggestions('a00000000000000AAA');
            System.assert(false, 'Expected exception for invalid gap ID');
        } catch (RemediationSuggestionService.RemediationException e) {
            System.assert(e.getMessage().contains('not found'), 'Should indicate gap not found');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetSuggestions() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];

        // First generate suggestions
        RemediationSuggestionService.generateSuggestions(gap.Id);

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.getSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should return generated suggestions');
    }

    @isTest
    static void testGetPendingSuggestions() {
        // Generate suggestions for multiple gaps
        List<Compliance_Gap__c> gaps = [SELECT Id FROM Compliance_Gap__c LIMIT 3];
        for (Compliance_Gap__c gap : gaps) {
            RemediationSuggestionService.generateSuggestions(gap.Id);
        }

        Test.startTest();
        List<RemediationSuggestionService.SuggestionWithGap> pendingSuggestions =
            RemediationSuggestionService.getPendingSuggestions();
        Test.stopTest();

        System.assert(pendingSuggestions.size() > 0, 'Should return pending suggestions');

        for (RemediationSuggestionService.SuggestionWithGap swg : pendingSuggestions) {
            System.assertNotEquals(null, swg.gapId, 'Gap ID should be set');
            System.assertNotEquals(null, swg.gapName, 'Gap name should be set');
        }
    }

    @isTest
    static void testApproveSuggestion() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        String suggestionId = suggestions[0].Id;

        Test.startTest();
        RemediationSuggestionService.approveSuggestion(suggestionId);
        Test.stopTest();

        Remediation_Suggestion__c updated = [SELECT Status__c, Reviewed_By__c, Reviewed_At__c
                                              FROM Remediation_Suggestion__c WHERE Id = :suggestionId];
        System.assertEquals('APPROVED', updated.Status__c, 'Status should be APPROVED');
        System.assertEquals(UserInfo.getUserId(), updated.Reviewed_By__c, 'Reviewed by should be current user');
        System.assertNotEquals(null, updated.Reviewed_At__c, 'Reviewed at should be set');
    }

    @isTest
    static void testRejectSuggestion() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        String suggestionId = suggestions[0].Id;

        Test.startTest();
        RemediationSuggestionService.rejectSuggestion(suggestionId, 'Not applicable to our environment');
        Test.stopTest();

        Remediation_Suggestion__c updated = [SELECT Status__c, Rejection_Reason__c
                                              FROM Remediation_Suggestion__c WHERE Id = :suggestionId];
        System.assertEquals('REJECTED', updated.Status__c, 'Status should be REJECTED');
        System.assertEquals('Not applicable to our environment', updated.Rejection_Reason__c, 'Rejection reason should be set');
    }

    @isTest
    static void testBulkGenerateSuggestions() {
        List<Compliance_Gap__c> gaps = [SELECT Id FROM Compliance_Gap__c LIMIT 3];
        List<String> gapIds = new List<String>();
        for (Compliance_Gap__c gap : gaps) {
            gapIds.add(gap.Id);
        }

        Test.startTest();
        Integer generated = RemediationSuggestionService.bulkGenerateSuggestions(gapIds);
        Test.stopTest();

        System.assert(generated > 0, 'Should generate suggestions for multiple gaps');

        List<Remediation_Suggestion__c> allSuggestions = [SELECT Id FROM Remediation_Suggestion__c];
        System.assertEquals(generated, allSuggestions.size(), 'Total suggestions should match');
    }

    @isTest
    static void testRecalculatePriorities() {
        // Generate suggestions
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];
        RemediationSuggestionService.generateSuggestions(gap.Id);

        Test.startTest();
        RemediationSuggestionService.recalculatePriorities();
        Test.stopTest();

        List<Remediation_Suggestion__c> suggestions = [SELECT Priority_Score__c FROM Remediation_Suggestion__c];
        for (Remediation_Suggestion__c suggestion : suggestions) {
            System.assertNotEquals(null, suggestion.Priority_Score__c, 'Priority should be calculated');
        }
    }

    @isTest
    static void testAutoRemediationPayloadGeneration() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        Boolean foundAutoRemediation = false;
        for (Remediation_Suggestion__c suggestion : suggestions) {
            if (suggestion.Auto_Remediation_Available__c) {
                foundAutoRemediation = true;
                System.assertNotEquals(null, suggestion.Auto_Remediation_Payload__c, 'Payload should be set');

                // Verify payload is valid JSON
                Map<String, Object> payload = (Map<String, Object>) JSON.deserializeUntyped(suggestion.Auto_Remediation_Payload__c);
                System.assertNotEquals(null, payload.get('suggestionType'), 'Payload should contain suggestionType');
                System.assertNotEquals(null, payload.get('gapId'), 'Payload should contain gapId');
            }
        }
        System.assert(foundAutoRemediation, 'Should have at least one auto-remediable suggestion');
    }

    @isTest
    static void testConfidenceScoreCalculation() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Framework__c = 'SOX' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        for (Remediation_Suggestion__c suggestion : suggestions) {
            System.assert(suggestion.Confidence_Score__c >= 0, 'Confidence should be >= 0');
            System.assert(suggestion.Confidence_Score__c <= 1, 'Confidence should be <= 1');
        }
    }

    @isTest
    static void testSuggestionWithUnknownEntityType() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c WHERE Entity_Type__c = 'UNKNOWN_TYPE' LIMIT 1];

        Test.startTest();
        List<Remediation_Suggestion__c> suggestions = RemediationSuggestionService.generateSuggestions(gap.Id);
        Test.stopTest();

        System.assert(suggestions.size() > 0, 'Should generate suggestions even for unknown entity type');

        Boolean hasManualReview = false;
        for (Remediation_Suggestion__c suggestion : suggestions) {
            if (suggestion.Suggestion_Type__c == 'MANUAL_REVIEW') {
                hasManualReview = true;
            }
        }
        System.assert(hasManualReview, 'Should include manual review for unknown entity type');
    }

    @isTest
    static void testSuggestionWithGapWrapper() {
        RemediationSuggestionService.SuggestionWithGap wrapper = new RemediationSuggestionService.SuggestionWithGap();
        wrapper.suggestion = new Remediation_Suggestion__c();
        wrapper.gapId = null;
        wrapper.gapName = 'Test Gap';
        wrapper.gapSeverity = 'HIGH';
        wrapper.gapFramework = 'SOX';

        System.assertEquals('Test Gap', wrapper.gapName, 'Gap name should match');
        System.assertEquals('HIGH', wrapper.gapSeverity, 'Severity should match');
    }
}
