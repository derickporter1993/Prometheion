public without sharing class PrometheionReasoningEngine {
    private static final Decimal MIN_CONFIDENCE = 0.85;

    private static Decimal getConfidenceThreshold(Prometheion_AI_Settings__c settings) {
        if (settings == null || settings.Confidence_Threshold__c == null) {
            return MIN_CONFIDENCE;
        }
        return settings.Confidence_Threshold__c;
    }

    public static ReasoningResult explainViolation(String nodeHash, String framework) {
        Prometheion_Compliance_Graph__b node = queryGraphNode(nodeHash);
        Prometheion_AI_Settings__c settings = Prometheion_AI_Settings__c.getInstance();

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
            WITH SECURITY_ENFORCED
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

    private static String buildSimpleExplanation(Prometheion_Compliance_Graph__b node, Decimal riskScore, String framework) {
        String entityType = String.isNotBlank(node.Entity_Type__c) ? node.Entity_Type__c : 'UNKNOWN';
        String entityId = String.isNotBlank(node.Entity_Record_Id__c) ? node.Entity_Record_Id__c : 'UNKNOWN';

        String severity = riskScore >= 8.0 ? 'HIGH RISK' : riskScore >= 5.0 ? 'MEDIUM RISK' : 'LOW RISK';
        String remediation = riskScore >= 8.0 ? 'Immediate review required' : riskScore >= 5.0 ? 'Review recommended' : 'Monitor';

        return String.format(
            '{0} change to {1} flagged as {2}. Risk Score: {3}/10. Framework: {4}. Remediation: {5}',
            new Object[]{
                entityType,
                entityId,
                severity,
                riskScore,
                framework,
                remediation
            }
        );
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
            System.debug(LoggingLevel.ERROR, 
                '[PrometheionReasoningEngine] Failed to log adjudication - ' +
                'CorrelationId: ' + correlationId + ', ' +
                'NodeHash: ' + nodeHash + ', ' +
                'Error: ' + e.getMessage() + ', ' +
                'DmlMessage: ' + e.getDmlMessage(0) + ', ' +
                'StackTrace: ' + e.getStackTraceString());
            throw new ReasoningException('Failed to log adjudication for node ' + nodeHash + ': ' + e.getDmlMessage(0));
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
     */
    private static String generateCorrelationId(String nodeHash) {
        String input = nodeHash + '|' + UserInfo.getUserId() + '|' + System.now().getTime();
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
    }

    public class ReasoningException extends Exception {}
}
