public without sharing class SentinelReasoningEngine {
    private static final Decimal MIN_CONFIDENCE = 0.85;

    public static ReasoningResult explainViolation(String nodeHash, String framework) {
        Sentinel_Compliance_Graph__b node = queryGraphNode(nodeHash);
        Sentinel_AI_Settings__c settings = Sentinel_AI_Settings__c.getInstance();

        if (!settings.Enable_AI_Reasoning__c) {
            return generateFallbackReasoning(node, framework);
        }

        PredictionResult einsteinResult = callEinsteinPrediction(node);
        Compliance_Policy__mdt policy = queryRelevantPolicy(einsteinResult.policyId, framework);
        String explanation = buildSafeExplanation(policy, node, einsteinResult, settings);
        String adjudicationId = logAdjudication(nodeHash, explanation, einsteinResult.confidence);

        return new ReasoningResult(
            einsteinResult.isViolation,
            einsteinResult.confidence,
            policy.DeveloperName,
            policy.Legal_Citation__c,
            explanation,
            adjudicationId,
            einsteinResult.confidence < settings.Confidence_Threshold__c
        );
    }

    private static Sentinel_Compliance_Graph__b queryGraphNode(String nodeHash) {
        List<Sentinel_Compliance_Graph__b> nodes = [
            SELECT Id, Entity_Type__c, Entity_Record_Id__c, Risk_Score__c, Node_Metadata__c
            FROM Sentinel_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
            LIMIT 1
        ];
        if (nodes.isEmpty()) throw new ReasoningException('Node not found');
        return nodes[0];
    }

    private static PredictionResult callEinsteinPrediction(Sentinel_Compliance_Graph__b node) {
        Map<String, Object> features = new Map<String, Object>{
            'entityType' => node.Entity_Type__c,
            'riskScore' => node.Risk_Score__c
        };

        List<einsteinai__PredictionResult> results =
            einsteinai__PredictionService.predict('Sentinel_Risk_Scoring', features);

        return results.isEmpty() ?
            new PredictionResult(false, 0.0, null) :
            new PredictionResult(true, (Decimal)results[0].get('probability'), 'DEFAULT_POLICY');
    }

    private static Compliance_Policy__mdt queryRelevantPolicy(String policyId, String framework) {
        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Policy_Description__c, Legal_Citation__c, Remediation_Steps__c
            FROM Compliance_Policy__mdt
            WHERE Framework__c = :framework
            LIMIT 1
        ];
        return policies.isEmpty() ? createDefaultPolicy() : policies[0];
    }

    private static Compliance_Policy__mdt createDefaultPolicy() {
        Compliance_Policy__mdt policy = new Compliance_Policy__mdt();
        policy.DeveloperName = 'DEFAULT_POLICY';
        policy.Policy_Description__c = 'Manual review required';
        policy.Legal_Citation__c = 'N/A';
        policy.Remediation_Steps__c = 'Contact compliance team';
        return policy;
    }

    private static String buildSafeExplanation(Compliance_Policy__mdt policy, Sentinel_Compliance_Graph__b node, PredictionResult einsteinResult, Sentinel_AI_Settings__c settings) {
        String prefix = einsteinResult.confidence < settings.Confidence_Threshold__c ? '[REVIEW REQUIRED] ' : '';
        return prefix + String.format(
            '{0} change to {1} violated {2} ({3}). Risk: {4}/10. Remediation: {5}',
            new Object[]{
                node.Entity_Type__c,
                node.Entity_Record_Id__c,
                policy.Policy_Description__c,
                policy.Legal_Citation__c,
                node.Risk_Score__c,
                policy.Remediation_Steps__c
            }
        );
    }

    private static String logAdjudication(String nodeHash, String explanation, Decimal confidence) {
        String adjudicationHash = SentinelGraphIndexer.generateDeterministicHash(nodeHash, UserInfo.getUserId(), 'ADJUDICATION');
        Sentinel_Compliance_Graph__b adjudication = new Sentinel_Compliance_Graph__b(
            Graph_Node_Id__c = adjudicationHash,
            Parent_Node_Id__c = nodeHash,
            Timestamp__c = System.now(),
            Entity_Type__c = 'AI_ADJUDICATION',
            AI_Explanation__c = explanation,
            AI_Confidence__c = confidence,
            Human_Adjudicator__c = UserInfo.getUserId(),
            Human_Adjudicated__c = true,
            Graph_Version__c = 'v3.0'
        );
        insert adjudication;
        return adjudicationHash;
    }

    private static ReasoningResult generateFallbackReasoning(Sentinel_Compliance_Graph__b node, String framework) {
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

    public class PredictionResult {
        public Boolean isViolation;
        public Decimal confidence;
        public String policyId;
        public PredictionResult(Boolean isViolation, Decimal confidence, String policyId) {
            this.isViolation = isViolation;
            this.confidence = confidence;
            this.policyId = policyId;
        }
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

    public class ReasoningException extends Exception {}
}
