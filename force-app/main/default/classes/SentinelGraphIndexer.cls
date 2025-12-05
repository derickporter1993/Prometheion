public with sharing class SentinelGraphIndexer {
    private static final String GRAPH_VERSION = 'v3.0';

    public static String indexChange(String entityType, String entityId, String parentNodeId, String framework) {
        String nodeHash = generateDeterministicHash(entityType, entityId, framework);
        Map<String, Object> metadata = queryEntityMetadata(entityType, entityId);
        Decimal riskScore = calculateRiskScore(metadata, framework);

        Sentinel_Compliance_Graph__b node = new Sentinel_Compliance_Graph__b(
            Graph_Node_Id__c = nodeHash,
            Parent_Node_Id__c = parentNodeId,
            Timestamp__c = System.now(),
            Entity_Type__c = entityType,
            Entity_Record_Id__c = entityId,
            Compliance_Framework__c = framework,
            Risk_Score__c = riskScore,
            Drift_Category__c = determineDriftCategory(riskScore, metadata),
            Node_Metadata__c = JSON.serialize(metadata),
            AI_Confidence__c = 0.0,
            Human_Adjudicated__c = false,
            Graph_Version__c = GRAPH_VERSION
        );

        try {
            insert node;
            return nodeHash;
        } catch (Exception e) {
            throw new SentinelException('Graph indexing failed: ' + e.getMessage());
        }
    }

    public static String generateDeterministicHash(String entityType, String entityId, String framework) {
        String input = entityType + '|' + entityId + '|' + framework + '|' + System.now().getTime();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 50);
    }

    private static Map<String, Object> queryEntityMetadata(String entityType, String entityId) {
        Map<String, Object> metadata = new Map<String, Object>();
        switch on entityType {
            when 'PERMISSION_SET' {
                PermissionSet ps = [
                    SELECT Id, Name,
                        (SELECT SObjectType, PermissionsRead, PermissionsEdit FROM ObjectPerms),
                        (SELECT SObjectType, Field, PermissionsEdit FROM FieldPerms)
                    FROM PermissionSet WHERE Id = :entityId
                ];
                metadata.put('name', ps.Name);
                metadata.put('objectPermissions', ps.ObjectPerms);
                metadata.put('fieldPermissions', ps.FieldPerms);
            }
            when 'FLOW' {
                FlowDefinitionView fd = [
                    SELECT ApiName, Label, TriggerType, ProcessType
                    FROM FlowDefinitionView WHERE DurableId = :entityId
                ];
                metadata.put('apiName', fd.ApiName);
                metadata.put('triggerType', fd.TriggerType);
            }
        }
        return metadata;
    }

    private static Decimal calculateRiskScore(Map<String, Object> metadata, String framework) {
        Sentinel_AI_Settings__c aiSettings = Sentinel_AI_Settings__c.getOrgDefaults();
        if (aiSettings != null && aiSettings.Enable_AI_Reasoning__c) {
            return callEinsteinPrediction(metadata, framework);
        }
        return calculateFallbackRiskScore(metadata, framework);
    }

    private static Decimal callEinsteinPrediction(Map<String, Object> metadata, String framework) {
        try {
            List<einsteinai__PredictionResult> results =
                einsteinai__PredictionService.predict('Sentinel_Risk_Scoring', metadata);
            return results.isEmpty() ? 5.0 : (Decimal)results[0].get('probability') * 10;
        } catch (Exception e) {
            return calculateFallbackRiskScore(metadata, framework);
        }
    }

    private static Decimal calculateFallbackRiskScore(Map<String, Object> metadata, String framework) {
        Decimal score = 3.0;
        if (metadata.containsKey('objectPermissions')) {
            List<Object> perms = (List<Object>)metadata.get('objectPermissions');
            score += perms.size(); // Simple heuristic
        }
        return Math.min(score, 10.0);
    }

    private static String determineDriftCategory(Decimal riskScore, Map<String, Object> metadata) {
        if (riskScore >= 8.0) return 'POLICY_VIOLATION';
        if (riskScore >= 5.0) return 'UNAUTHORIZED';
        if (riskScore >= 3.0) return 'ANOMALY';
        return 'MANUAL_OVERRIDE';
    }

    public class SentinelException extends Exception {}
}
