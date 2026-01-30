/**
 * @description Service for generating AI-assisted remediation suggestions for compliance gaps.
 * Analyzes gap type, severity, and framework to provide actionable remediation recommendations.
 *
 * Features:
 * - Pattern-based suggestion generation
 * - Confidence scoring based on gap characteristics
 * - Priority calculation based on risk reduction and effort
 * - Auto-remediation payload generation for supported types
 *
 * @author Elaro Development Team
 * @since 2026-01
 */
public with sharing class RemediationSuggestionService {

    // Suggestion type mappings based on entity types
    private static final Map<String, String> ENTITY_TO_SUGGESTION_TYPE = new Map<String, String>{
        'PERMISSION_SET' => 'PERMISSION_CHANGE',
        'PROFILE' => 'PROFILE_UPDATE',
        'CUSTOM_FIELD' => 'FIELD_LEVEL_SECURITY',
        'SHARING_RULE' => 'SHARING_RULE',
        'FLOW' => 'FLOW_MODIFICATION',
        'VALIDATION_RULE' => 'VALIDATION_RULE',
        'TRIGGER' => 'TRIGGER_UPDATE',
        'CUSTOM_OBJECT' => 'FIELD_LEVEL_SECURITY'
    };

    // Auto-remediable suggestion types
    private static final Set<String> AUTO_REMEDIABLE_TYPES = new Set<String>{
        'PERMISSION_CHANGE',
        'FIELD_LEVEL_SECURITY',
        'PROFILE_UPDATE'
    };

    /**
     * @description Generates remediation suggestions for a compliance gap
     * @param gapId The ID of the compliance gap
     * @return List of generated suggestions
     */
    @AuraEnabled
    public static List<Remediation_Suggestion__c> generateSuggestions(String gapId) {
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Framework__c, Severity__c, Status__c,
                   Gap_Description__c, Entity_Type__c, Entity_Id__c,
                   Policy_Reference__c, Risk_Score__c
            FROM Compliance_Gap__c
            WHERE Id = :gapId
            WITH USER_MODE
            LIMIT 1
        ];

        if (gaps.isEmpty()) {
            throw new RemediationException('Compliance gap not found');
        }

        Compliance_Gap__c gap = gaps[0];
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // Generate primary suggestion based on entity type
        Remediation_Suggestion__c primarySuggestion = generatePrimarySuggestion(gap);
        if (primarySuggestion != null) {
            suggestions.add(primarySuggestion);
        }

        // Generate framework-specific suggestions
        List<Remediation_Suggestion__c> frameworkSuggestions = generateFrameworkSuggestions(gap);
        suggestions.addAll(frameworkSuggestions);

        // Generate generic compliance suggestions
        Remediation_Suggestion__c genericSuggestion = generateGenericSuggestion(gap);
        if (genericSuggestion != null) {
            suggestions.add(genericSuggestion);
        }

        // Insert suggestions
        if (!suggestions.isEmpty() && Schema.sObjectType.Remediation_Suggestion__c.isCreateable()) {
            insert suggestions;
        }

        return suggestions;
    }

    /**
     * @description Gets existing suggestions for a gap
     * @param gapId The compliance gap ID
     * @return List of suggestions
     */
    @AuraEnabled(cacheable=true)
    public static List<Remediation_Suggestion__c> getSuggestions(String gapId) {
        return [
            SELECT Id, Name, Suggestion_Type__c, Description__c, Implementation_Steps__c,
                   Auto_Remediation_Available__c, Status__c, Confidence_Score__c,
                   Risk_Reduction_Score__c, Effort_Estimate__c, Priority_Score__c,
                   Framework__c, Applied_At__c, Applied_By__r.Name,
                   Reviewed_By__r.Name, Reviewed_At__c, Rejection_Reason__c
            FROM Remediation_Suggestion__c
            WHERE Compliance_Gap__c = :gapId
            WITH USER_MODE
            ORDER BY Priority_Score__c DESC, Confidence_Score__c DESC
        ];
    }

    /**
     * @description Gets all pending suggestions across gaps
     * @return List of pending suggestions with gap details
     */
    @AuraEnabled(cacheable=true)
    public static List<SuggestionWithGap> getPendingSuggestions() {
        List<SuggestionWithGap> results = new List<SuggestionWithGap>();

        List<Remediation_Suggestion__c> suggestions = [
            SELECT Id, Name, Suggestion_Type__c, Description__c, Status__c,
                   Confidence_Score__c, Priority_Score__c, Auto_Remediation_Available__c,
                   Effort_Estimate__c, Risk_Reduction_Score__c, Framework__c,
                   Compliance_Gap__c, Compliance_Gap__r.Name, Compliance_Gap__r.Severity__c,
                   Compliance_Gap__r.Framework__c
            FROM Remediation_Suggestion__c
            WHERE Status__c = 'PENDING'
            WITH USER_MODE
            ORDER BY Priority_Score__c DESC
            LIMIT 100
        ];

        for (Remediation_Suggestion__c suggestion : suggestions) {
            SuggestionWithGap swg = new SuggestionWithGap();
            swg.suggestion = suggestion;
            swg.gapId = suggestion.Compliance_Gap__c;
            swg.gapName = suggestion.Compliance_Gap__r.Name;
            swg.gapSeverity = suggestion.Compliance_Gap__r.Severity__c;
            swg.gapFramework = suggestion.Compliance_Gap__r.Framework__c;
            results.add(swg);
        }

        return results;
    }

    /**
     * @description Approves a suggestion for implementation
     * @param suggestionId The suggestion ID
     */
    @AuraEnabled
    public static void approveSuggestion(String suggestionId) {
        updateSuggestionStatus(suggestionId, 'APPROVED', null);
    }

    /**
     * @description Rejects a suggestion
     * @param suggestionId The suggestion ID
     * @param reason The rejection reason
     */
    @AuraEnabled
    public static void rejectSuggestion(String suggestionId, String reason) {
        updateSuggestionStatus(suggestionId, 'REJECTED', reason);
    }

    /**
     * @description Bulk generates suggestions for multiple gaps
     * @param gapIds List of gap IDs
     * @return Number of suggestions generated
     */
    @AuraEnabled
    public static Integer bulkGenerateSuggestions(List<String> gapIds) {
        Integer totalGenerated = 0;

        for (String gapId : gapIds) {
            try {
                List<Remediation_Suggestion__c> suggestions = generateSuggestions(gapId);
                totalGenerated += suggestions.size();
            } catch (Exception e) {
                System.debug(LoggingLevel.WARN, 'Failed to generate suggestions for gap ' + gapId + ': ' + e.getMessage());
            }
        }

        return totalGenerated;
    }

    /**
     * @description Recalculates priority scores for all pending suggestions
     */
    @AuraEnabled
    public static void recalculatePriorities() {
        List<Remediation_Suggestion__c> suggestions = [
            SELECT Id, Risk_Reduction_Score__c, Effort_Estimate__c
            FROM Remediation_Suggestion__c
            WHERE Status__c = 'PENDING'
            WITH USER_MODE
        ];

        for (Remediation_Suggestion__c suggestion : suggestions) {
            suggestion.Priority_Score__c = calculatePriorityScore(
                suggestion.Risk_Reduction_Score__c,
                suggestion.Effort_Estimate__c
            );
        }

        if (Schema.sObjectType.Remediation_Suggestion__c.isUpdateable()) {
            update suggestions;
        }
    }

    // ============================================
    // Private Helper Methods
    // ============================================

    private static Remediation_Suggestion__c generatePrimarySuggestion(Compliance_Gap__c gap) {
        String entityType = gap.Entity_Type__c;
        String suggestionType = ENTITY_TO_SUGGESTION_TYPE.get(entityType);

        if (suggestionType == null) {
            suggestionType = 'MANUAL_REVIEW';
        }

        Remediation_Suggestion__c suggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = suggestionType,
            Framework__c = gap.Framework__c,
            Status__c = 'PENDING'
        );

        // Generate description and steps based on type
        SuggestionContent content = generateSuggestionContent(suggestionType, gap);
        suggestion.Description__c = content.description;
        suggestion.Implementation_Steps__c = content.steps;

        // Calculate scores
        suggestion.Confidence_Score__c = calculateConfidenceScore(gap, suggestionType);
        suggestion.Risk_Reduction_Score__c = calculateRiskReduction(gap);
        suggestion.Effort_Estimate__c = estimateEffort(suggestionType);
        suggestion.Priority_Score__c = calculatePriorityScore(
            suggestion.Risk_Reduction_Score__c,
            suggestion.Effort_Estimate__c
        );

        // Check auto-remediation availability
        suggestion.Auto_Remediation_Available__c = AUTO_REMEDIABLE_TYPES.contains(suggestionType);
        if (suggestion.Auto_Remediation_Available__c) {
            suggestion.Auto_Remediation_Payload__c = generateAutoRemediationPayload(suggestionType, gap);
        }

        return suggestion;
    }

    private static List<Remediation_Suggestion__c> generateFrameworkSuggestions(Compliance_Gap__c gap) {
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();
        String framework = gap.Framework__c;

        if (framework == 'SOX') {
            suggestions.addAll(generateSOXSuggestions(gap));
        } else if (framework == 'HIPAA') {
            suggestions.addAll(generateHIPAASuggestions(gap));
        } else if (framework == 'SOC2') {
            suggestions.addAll(generateSOC2Suggestions(gap));
        } else if (framework == 'GDPR' || framework == 'CCPA') {
            suggestions.addAll(generatePrivacySuggestions(gap));
        }

        return suggestions;
    }

    private static List<Remediation_Suggestion__c> generateSOXSuggestions(Compliance_Gap__c gap) {
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // SOX often requires audit trail enhancements
        if (gap.Severity__c == 'CRITICAL' || gap.Severity__c == 'HIGH') {
            Remediation_Suggestion__c auditSuggestion = new Remediation_Suggestion__c(
                Compliance_Gap__c = gap.Id,
                Suggestion_Type__c = 'AUDIT_TRAIL',
                Framework__c = 'SOX',
                Description__c = 'Implement enhanced audit trail tracking for financial data changes. SOX Section 404 requires internal controls over financial reporting.',
                Implementation_Steps__c = '1. Enable Field History Tracking on sensitive financial fields\n' +
                    '2. Configure Event Monitoring for critical transactions\n' +
                    '3. Set up automated reports for audit compliance\n' +
                    '4. Document control procedures for auditors',
                Confidence_Score__c = 0.85,
                Risk_Reduction_Score__c = 7.5,
                Effort_Estimate__c = 'MEDIUM',
                Status__c = 'PENDING',
                Auto_Remediation_Available__c = false
            );
            auditSuggestion.Priority_Score__c = calculatePriorityScore(7.5, 'MEDIUM');
            suggestions.add(auditSuggestion);
        }

        return suggestions;
    }

    private static List<Remediation_Suggestion__c> generateHIPAASuggestions(Compliance_Gap__c gap) {
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // HIPAA requires encryption and access controls
        Remediation_Suggestion__c encryptionSuggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'ENCRYPTION',
            Framework__c = 'HIPAA',
            Description__c = 'Implement encryption for Protected Health Information (PHI). HIPAA requires encryption of PHI at rest and in transit.',
            Implementation_Steps__c = '1. Enable Shield Platform Encryption for PHI fields\n' +
                '2. Configure TLS for all external integrations\n' +
                '3. Implement encryption key management procedures\n' +
                '4. Document encryption controls for compliance',
            Confidence_Score__c = 0.90,
            Risk_Reduction_Score__c = 9.0,
            Effort_Estimate__c = 'HIGH',
            Status__c = 'PENDING',
            Auto_Remediation_Available__c = false
        );
        encryptionSuggestion.Priority_Score__c = calculatePriorityScore(9.0, 'HIGH');
        suggestions.add(encryptionSuggestion);

        return suggestions;
    }

    private static List<Remediation_Suggestion__c> generateSOC2Suggestions(Compliance_Gap__c gap) {
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // SOC2 requires comprehensive access controls
        if (gap.Entity_Type__c == 'PERMISSION_SET' || gap.Entity_Type__c == 'PROFILE') {
            Remediation_Suggestion__c accessSuggestion = new Remediation_Suggestion__c(
                Compliance_Gap__c = gap.Id,
                Suggestion_Type__c = 'PERMISSION_CHANGE',
                Framework__c = 'SOC2',
                Description__c = 'Implement least-privilege access controls. SOC2 Trust Services Criteria CC6.1 requires logical access controls.',
                Implementation_Steps__c = '1. Review current permission assignments\n' +
                    '2. Remove unnecessary permissions following least privilege\n' +
                    '3. Implement permission set groups for role-based access\n' +
                    '4. Set up quarterly access reviews',
                Confidence_Score__c = 0.88,
                Risk_Reduction_Score__c = 8.0,
                Effort_Estimate__c = 'MEDIUM',
                Status__c = 'PENDING',
                Auto_Remediation_Available__c = true
            );
            accessSuggestion.Priority_Score__c = calculatePriorityScore(8.0, 'MEDIUM');
            accessSuggestion.Auto_Remediation_Payload__c = generateAutoRemediationPayload('PERMISSION_CHANGE', gap);
            suggestions.add(accessSuggestion);
        }

        return suggestions;
    }

    private static List<Remediation_Suggestion__c> generatePrivacySuggestions(Compliance_Gap__c gap) {
        List<Remediation_Suggestion__c> suggestions = new List<Remediation_Suggestion__c>();

        // Privacy frameworks require field-level security
        Remediation_Suggestion__c flsSuggestion = new Remediation_Suggestion__c(
            Compliance_Gap__c = gap.Id,
            Suggestion_Type__c = 'FIELD_LEVEL_SECURITY',
            Framework__c = gap.Framework__c,
            Description__c = 'Restrict access to personal data fields. ' + gap.Framework__c + ' requires appropriate access controls for personal data.',
            Implementation_Steps__c = '1. Identify fields containing personal data\n' +
                '2. Create dedicated permission sets for PII access\n' +
                '3. Remove FLS from profiles not requiring access\n' +
                '4. Implement data classification labels\n' +
                '5. Document data access procedures',
            Confidence_Score__c = 0.85,
            Risk_Reduction_Score__c = 7.5,
            Effort_Estimate__c = 'MEDIUM',
            Status__c = 'PENDING',
            Auto_Remediation_Available__c = true
        );
        flsSuggestion.Priority_Score__c = calculatePriorityScore(7.5, 'MEDIUM');
        flsSuggestion.Auto_Remediation_Payload__c = generateAutoRemediationPayload('FIELD_LEVEL_SECURITY', gap);
        suggestions.add(flsSuggestion);

        return suggestions;
    }

    private static Remediation_Suggestion__c generateGenericSuggestion(Compliance_Gap__c gap) {
        // Only generate generic suggestion if no other suggestions were created
        if (gap.Severity__c == 'CRITICAL' || gap.Severity__c == 'HIGH') {
            return new Remediation_Suggestion__c(
                Compliance_Gap__c = gap.Id,
                Suggestion_Type__c = 'MANUAL_REVIEW',
                Framework__c = gap.Framework__c,
                Description__c = 'This high-severity compliance gap requires manual review and remediation planning by a compliance officer.',
                Implementation_Steps__c = '1. Schedule review meeting with compliance team\n' +
                    '2. Document current state and risk assessment\n' +
                    '3. Develop remediation plan with timeline\n' +
                    '4. Assign ownership and accountability\n' +
                    '5. Implement monitoring for similar gaps',
                Confidence_Score__c = 0.70,
                Risk_Reduction_Score__c = 5.0,
                Effort_Estimate__c = 'HIGH',
                Priority_Score__c = calculatePriorityScore(5.0, 'HIGH'),
                Status__c = 'PENDING',
                Auto_Remediation_Available__c = false
            );
        }
        return null;
    }

    private static SuggestionContent generateSuggestionContent(String suggestionType, Compliance_Gap__c gap) {
        SuggestionContent content = new SuggestionContent();

        switch on suggestionType {
            when 'PERMISSION_CHANGE' {
                content.description = 'Modify permission set to remove excessive access. ' +
                    'Current configuration grants more access than required for ' + gap.Framework__c + ' compliance.';
                content.steps = '1. Review current permission set configuration\n' +
                    '2. Identify permissions exceeding job requirements\n' +
                    '3. Create restricted permission set with minimum necessary access\n' +
                    '4. Migrate users to new permission set\n' +
                    '5. Deprecate old permission set';
            }
            when 'PROFILE_UPDATE' {
                content.description = 'Update profile settings to comply with ' + gap.Framework__c + ' access control requirements.';
                content.steps = '1. Audit current profile permissions\n' +
                    '2. Document required access for role\n' +
                    '3. Remove unnecessary object and field access\n' +
                    '4. Test profile changes in sandbox\n' +
                    '5. Deploy changes with rollback plan';
            }
            when 'FIELD_LEVEL_SECURITY' {
                content.description = 'Adjust field-level security to restrict access to sensitive data per ' + gap.Framework__c + ' requirements.';
                content.steps = '1. Identify sensitive fields requiring protection\n' +
                    '2. Create field-level security matrix\n' +
                    '3. Update FLS on profiles and permission sets\n' +
                    '4. Verify access restrictions\n' +
                    '5. Document FLS configuration';
            }
            when 'SHARING_RULE' {
                content.description = 'Configure sharing rules to enforce data access boundaries for ' + gap.Framework__c + ' compliance.';
                content.steps = '1. Review current sharing model\n' +
                    '2. Design criteria-based sharing rules\n' +
                    '3. Implement sharing rules in sandbox\n' +
                    '4. Test access scenarios\n' +
                    '5. Deploy to production';
            }
            when 'FLOW_MODIFICATION' {
                content.description = 'Modify flow to include compliance controls required by ' + gap.Framework__c + '.';
                content.steps = '1. Review flow logic and data access\n' +
                    '2. Add security checks and validations\n' +
                    '3. Implement audit logging\n' +
                    '4. Test modified flow\n' +
                    '5. Activate new version';
            }
            when else {
                content.description = 'Manual review required for ' + gap.Framework__c + ' compliance gap.';
                content.steps = '1. Review gap details\n' +
                    '2. Assess remediation options\n' +
                    '3. Document remediation plan\n' +
                    '4. Implement changes\n' +
                    '5. Verify compliance';
            }
        }

        return content;
    }

    private static Decimal calculateConfidenceScore(Compliance_Gap__c gap, String suggestionType) {
        Decimal baseScore = 0.70;

        // Higher confidence for well-defined entity types
        if (gap.Entity_Type__c != null && ENTITY_TO_SUGGESTION_TYPE.containsKey(gap.Entity_Type__c)) {
            baseScore += 0.15;
        }

        // Higher confidence for auto-remediable types
        if (AUTO_REMEDIABLE_TYPES.contains(suggestionType)) {
            baseScore += 0.10;
        }

        // Slightly lower confidence for very high severity (complex issues)
        if (gap.Severity__c == 'CRITICAL') {
            baseScore -= 0.05;
        }

        return Math.min(baseScore, 0.95);
    }

    private static Decimal calculateRiskReduction(Compliance_Gap__c gap) {
        Decimal baseReduction = 5.0;

        if (gap.Severity__c == 'CRITICAL') {
            baseReduction = 9.0;
        } else if (gap.Severity__c == 'HIGH') {
            baseReduction = 7.5;
        } else if (gap.Severity__c == 'MEDIUM') {
            baseReduction = 5.0;
        } else {
            baseReduction = 3.0;
        }

        // Factor in existing risk score if available
        if (gap.Risk_Score__c != null && gap.Risk_Score__c > 0) {
            baseReduction = Math.max(baseReduction, gap.Risk_Score__c * 0.9);
        }

        return Math.min(baseReduction, 10.0);
    }

    private static String estimateEffort(String suggestionType) {
        Map<String, String> effortMap = new Map<String, String>{
            'PERMISSION_CHANGE' => 'LOW',
            'FIELD_LEVEL_SECURITY' => 'LOW',
            'PROFILE_UPDATE' => 'MEDIUM',
            'SHARING_RULE' => 'MEDIUM',
            'FLOW_MODIFICATION' => 'HIGH',
            'VALIDATION_RULE' => 'MEDIUM',
            'TRIGGER_UPDATE' => 'HIGH',
            'ENCRYPTION' => 'VERY_HIGH',
            'AUDIT_TRAIL' => 'MEDIUM',
            'MANUAL_REVIEW' => 'HIGH'
        };

        return effortMap.containsKey(suggestionType) ? effortMap.get(suggestionType) : 'MEDIUM';
    }

    private static Decimal calculatePriorityScore(Decimal riskReduction, String effort) {
        Decimal effortMultiplier = 1.0;

        switch on effort {
            when 'LOW' {
                effortMultiplier = 1.5;
            }
            when 'MEDIUM' {
                effortMultiplier = 1.0;
            }
            when 'HIGH' {
                effortMultiplier = 0.7;
            }
            when 'VERY_HIGH' {
                effortMultiplier = 0.5;
            }
        }

        return riskReduction * effortMultiplier;
    }

    private static String generateAutoRemediationPayload(String suggestionType, Compliance_Gap__c gap) {
        Map<String, Object> payload = new Map<String, Object>();
        payload.put('suggestionType', suggestionType);
        payload.put('gapId', gap.Id);
        payload.put('entityType', gap.Entity_Type__c);
        payload.put('entityId', gap.Entity_Id__c);
        payload.put('framework', gap.Framework__c);
        payload.put('generatedAt', Datetime.now().format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\''));

        // Add type-specific configuration
        if (suggestionType == 'PERMISSION_CHANGE') {
            payload.put('action', 'REMOVE_EXCESSIVE_PERMISSIONS');
            payload.put('targetPermissionSet', gap.Entity_Id__c);
        } else if (suggestionType == 'FIELD_LEVEL_SECURITY') {
            payload.put('action', 'RESTRICT_FIELD_ACCESS');
            payload.put('targetObject', gap.Entity_Id__c);
        } else if (suggestionType == 'PROFILE_UPDATE') {
            payload.put('action', 'UPDATE_PROFILE_PERMISSIONS');
            payload.put('targetProfile', gap.Entity_Id__c);
        }

        return JSON.serialize(payload);
    }

    private static void updateSuggestionStatus(String suggestionId, String status, String reason) {
        List<Remediation_Suggestion__c> suggestions = [
            SELECT Id, Status__c, Rejection_Reason__c
            FROM Remediation_Suggestion__c
            WHERE Id = :suggestionId
            WITH USER_MODE
            LIMIT 1
        ];

        if (suggestions.isEmpty()) {
            throw new RemediationException('Suggestion not found');
        }

        Remediation_Suggestion__c suggestion = suggestions[0];
        suggestion.Status__c = status;
        suggestion.Reviewed_By__c = UserInfo.getUserId();
        suggestion.Reviewed_At__c = Datetime.now();

        if (status == 'REJECTED' && String.isNotBlank(reason)) {
            suggestion.Rejection_Reason__c = reason;
        }

        if (Schema.sObjectType.Remediation_Suggestion__c.isUpdateable()) {
            update suggestion;
        }
    }

    // ============================================
    // Inner Classes
    // ============================================

    /**
     * @description Wrapper for suggestion with gap details
     */
    public class SuggestionWithGap {
        @AuraEnabled public Remediation_Suggestion__c suggestion;
        @AuraEnabled public Id gapId;
        @AuraEnabled public String gapName;
        @AuraEnabled public String gapSeverity;
        @AuraEnabled public String gapFramework;
    }

    /**
     * @description Helper class for suggestion content
     */
    private class SuggestionContent {
        public String description;
        public String steps;
    }

    /**
     * @description Custom exception for remediation errors
     */
    public class RemediationException extends Exception {}
}
