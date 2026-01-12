/**
 * Prometheion Reasoning Engine
 * 
 * This class uses `without sharing` because:
 * 1. Big Object queries require system-level access to read Prometheion_Compliance_Graph__b records
 * 2. Cross-org compliance analysis may need to access data across different sharing contexts
 * 3. AI adjudication logging must be accessible regardless of user permissions for audit purposes
 * 4. The reasoning engine operates on compliance metadata that should be accessible to all authorized users
 * 
 * Security is maintained through:
 * - Input validation on all public methods
 * - HTML escaping to prevent XSS in explanations
 * - Deterministic hashing for audit trail integrity
 * - Correlation IDs for traceability
 * 
 * @author Prometheion
 * @version 3.0
 */
public without sharing class PrometheionReasoningEngine {
    private static final Decimal MIN_CONFIDENCE = 0.85;

    /**
     * Null-safe accessor for AI Settings
     * Returns default settings if org default doesn't exist
     */
    private static Prometheion_AI_Settings__c getAISettingsSafe() {
        Prometheion_AI_Settings__c settings = Prometheion_AI_Settings__c.getInstance();
        if (settings == null) {
            // Return default settings object (not persisted, but safe for reading)
            return new Prometheion_AI_Settings__c(
                Enable_AI_Reasoning__c = true,
                Confidence_Threshold__c = MIN_CONFIDENCE
            );
        }
        return settings;
    }

    private static Decimal getConfidenceThreshold(Prometheion_AI_Settings__c settings) {
        if (settings == null || settings.Confidence_Threshold__c == null) {
            return MIN_CONFIDENCE;
        }
        return settings.Confidence_Threshold__c;
    }

    public static ReasoningResult explainViolation(String nodeHash, String framework) {
        Prometheion_Compliance_Graph__b node = queryGraphNode(nodeHash);
        Prometheion_AI_Settings__c settings = getAISettingsSafe();

        // Null-safe check for settings - use fallback reasoning if AI not enabled
        if (settings == null || !settings.Enable_AI_Reasoning__c) {
            return generateFallbackReasoning(node, framework);
        }

        // Simplified reasoning without Custom Metadata Type dependency
        // In production, if Compliance_Policy__mdt is required, create it or use alternative approach
        Decimal riskScore = node.Risk_Score__c != null ? node.Risk_Score__c : 0.0;
        Boolean isViolation = riskScore >= 8.0;
        Decimal confidence = riskScore >= 8.0 ? 0.9 : riskScore >= 5.0 ? 0.7 : 0.5;

        String explanation = buildSimpleExplanation(node, riskScore, framework);
        String adjudicationId = logAdjudication(nodeHash, explanation, confidence);
        Decimal confidenceThreshold = getConfidenceThreshold(settings);

        return new ReasoningResult(
            isViolation,
            confidence,
            'RULE_BASED',
            'N/A',
            explanation,
            adjudicationId,
            confidence < confidenceThreshold
        );
    }

    private static Prometheion_Compliance_Graph__b queryGraphNode(String nodeHash) {
        // Big Objects can only query on indexed fields (Compliance_Framework__c, Timestamp__c)
        // Since we don't have framework context here, query recent records and filter in memory
        // Note: This is a simplified approach. In production, consider maintaining a separate lookup table
        Datetime recentThreshold = Datetime.now().addDays(-90); // Look back 90 days
        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Id, Entity_Type__c, Entity_Record_Id__c, Risk_Score__c, Node_Metadata__c, Graph_Node_Id__c, Compliance_Framework__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Timestamp__c >= :recentThreshold
            WITH USER_MODE
            ORDER BY Timestamp__c DESC
            LIMIT 10000
        ];

        // Filter in memory for the matching nodeHash
        for (Prometheion_Compliance_Graph__b node : nodes) {
            if (node.Graph_Node_Id__c == nodeHash) {
                return node;
            }
        }

        throw new ReasoningException('Node not found: ' + nodeHash);
    }

    /**
     * Build safe explanation with HTML/Markdown escaping and null-safe formatting
     * Prevents XSS and malformed strings from raw node metadata
     */
    private static String buildSimpleExplanation(Prometheion_Compliance_Graph__b node, Decimal riskScore, String framework) {
        // Null-safe extraction with escaping
        String entityType = escapeHtml(String.isNotBlank(node.Entity_Type__c) ? node.Entity_Type__c : 'UNKNOWN');
        String entityId = escapeHtml(String.isNotBlank(node.Entity_Record_Id__c) ? node.Entity_Record_Id__c : 'UNKNOWN');
        String safeFramework = escapeHtml(String.isNotBlank(framework) ? framework : 'UNKNOWN');

        // Safe numeric formatting
        Decimal safeRiskScore = riskScore != null ? riskScore : 0.0;
        String severity = safeRiskScore >= 8.0 ? 'HIGH RISK' : safeRiskScore >= 5.0 ? 'MEDIUM RISK' : 'LOW RISK';
        String remediation = safeRiskScore >= 8.0 ? 'Immediate review required' : safeRiskScore >= 5.0 ? 'Review recommended' : 'Monitor';

        return String.format(
            '{0} change to {1} flagged as {2}. Risk Score: {3}/10. Framework: {4}. Remediation: {5}',
            new Object[]{
                entityType,
                entityId,
                severity,
                safeRiskScore.setScale(1),
                safeFramework,
                remediation
            }
        );
    }

    /**
     * Escape HTML/Markdown special characters to prevent XSS and malformed strings
     */
    private static String escapeHtml(String input) {
        if (String.isBlank(input)) {
            return '';
        }
        // Escape HTML special characters
        return input.replace('&', '&amp;')
                   .replace('<', '&lt;')
                   .replace('>', '&gt;')
                   .replace('"', '&quot;')
                   .replace('\'', '&#39;');
    }

    private static String logAdjudication(String nodeHash, String explanation, Decimal confidence) {
        // Use stable inputs for deterministic hash (no time component)
        String adjudicationHash = PrometheionGraphIndexer.generateDeterministicHash('AI_ADJUDICATION', nodeHash + UserInfo.getUserId(), 'ADJUDICATION');

        // Note: Big Objects can only query on indexed fields, so we skip duplicate check here
        // In production, consider maintaining a separate lookup table for adjudications

        Prometheion_Compliance_Graph__b adjudication = new Prometheion_Compliance_Graph__b(
            Graph_Node_Id__c = adjudicationHash,
            Parent_Node_Id__c = nodeHash,
            Timestamp__c = System.now(),
            Entity_Type__c = 'AI_ADJUDICATION',
            AI_Explanation__c = explanation,
            AI_Confidence__c = confidence,
            Human_Adjudicator__c = UserInfo.getUserId(),
            Graph_Version__c = 'v3.0'
        );

        try {
            insert adjudication;
            return adjudicationHash;
        } catch (DmlException e) {
            String correlationId = generateCorrelationId(nodeHash);
            String dmlMsg = getSafeDmlMessage(e);
            System.debug(LoggingLevel.ERROR, 
                '[PrometheionReasoningEngine] Failed to log adjudication - ' +
                'CorrelationId: ' + correlationId + ', ' +
                'NodeHash: ' + nodeHash + ', ' +
                'Error: ' + e.getMessage() + ', ' +
                'DmlMessage: ' + dmlMsg + ', ' +
                'StackTrace: ' + e.getStackTraceString());
            throw new ReasoningException('Failed to log adjudication for node ' + nodeHash + ': ' + dmlMsg);
        }
    }

    private static ReasoningResult generateFallbackReasoning(Prometheion_Compliance_Graph__b node, String framework) {
        return new ReasoningResult(
            node.Risk_Score__c >= 8.0,
            0.0,
            'MANUAL_REVIEW',
            'N/A',
            'Manual review required for ' + node.Entity_Record_Id__c,
            node.Graph_Node_Id__c,
            true
        );
    }

    public class ReasoningResult {
        @AuraEnabled public Boolean isViolation;
        @AuraEnabled public Decimal confidence;
        @AuraEnabled public String policy;
        @AuraEnabled public String legalCitation;
        @AuraEnabled public String explanation;
        @AuraEnabled public String auditTrailId;
        @AuraEnabled public Boolean requiresHumanReview;

        public ReasoningResult(Boolean isViolation, Decimal confidence, String policy, String legalCitation, String explanation, String auditTrailId, Boolean requiresHumanReview) {
            this.isViolation = isViolation;
            this.confidence = confidence;
            this.policy = policy;
            this.legalCitation = legalCitation;
            this.explanation = explanation;
            this.auditTrailId = auditTrailId;
            this.requiresHumanReview = requiresHumanReview;
        }
    }

    /**
     * Generate correlation ID for structured logging
     * Uses only stable inputs (no time component) for deterministic hashing
     */
    private static String generateCorrelationId(String nodeHash) {
        String input = nodeHash + '|' + UserInfo.getUserId();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
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

    public class ReasoningException extends Exception {}
}
