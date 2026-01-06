public with sharing class PrometheionGraphIndexer {
    private static final String GRAPH_VERSION = 'v3.0';

    public static String indexChange(String entityType, String entityId, String parentNodeId, String framework) {
        String nodeHash = generateDeterministicHash(entityType, entityId, framework);
        Map<String, Object> metadata = queryEntityMetadata(entityType, entityId);
        Decimal riskScore = calculateRiskScore(metadata, framework);

        Prometheion_Compliance_Graph__b node = new Prometheion_Compliance_Graph__b(
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
            Graph_Version__c = GRAPH_VERSION
        );

        try {
            insert node;
            return nodeHash;
        } catch (DmlException e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            System.debug(LoggingLevel.ERROR, 
                '[PrometheionGraphIndexer] Graph indexing failed - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new PrometheionException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + e.getDmlMessage(0));
        } catch (Exception e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            System.debug(LoggingLevel.ERROR, 
                '[PrometheionGraphIndexer] Graph indexing unexpected error - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new PrometheionException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + e.getMessage());
        }
    }

    public static String generateDeterministicHash(String entityType, String entityId, String framework) {
        // Use only stable, immutable inputs for deterministic hashing
        String input = entityType + '|' + entityId + '|' + framework;
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 50);
    }

    private static Map<String, Object> queryEntityMetadata(String entityType, String entityId) {
        Map<String, Object> metadata = new Map<String, Object>();
        switch on entityType {
            when 'PERMISSION_SET' {
                List<PermissionSet> psList = [
                    SELECT Id, Name,
                        (SELECT SObjectType, PermissionsRead, PermissionsEdit FROM ObjectPerms LIMIT 100),
                        (SELECT SObjectType, Field, PermissionsEdit FROM FieldPerms LIMIT 200)
                    FROM PermissionSet
                    WHERE Id = :entityId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (psList.isEmpty()) {
                    throw new PrometheionException('PermissionSet not found: ' + entityId);
                }
                PermissionSet ps = psList[0];
                metadata.put('name', ps.Name);
                // Serialize only required fields to reduce payload size
                metadata.put('objectPermissionCount', ps.ObjectPerms != null ? ps.ObjectPerms.size() : 0);
                metadata.put('fieldPermissionCount', ps.FieldPerms != null ? ps.FieldPerms.size() : 0);
            }
            when 'FLOW' {
                List<FlowDefinitionView> fdList = [
                    SELECT ApiName, Label, TriggerType, ProcessType
                    FROM FlowDefinitionView
                    WHERE DurableId = :entityId
                    WITH SECURITY_ENFORCED
                    LIMIT 1
                ];
                if (fdList.isEmpty()) {
                    throw new PrometheionException('FlowDefinitionView not found: ' + entityId);
                }
                FlowDefinitionView fd = fdList[0];
                metadata.put('apiName', fd.ApiName);
                metadata.put('triggerType', fd.TriggerType);
            }
            when else {
                throw new PrometheionException('Unsupported entity type: ' + entityType);
            }
        }
        return metadata;
    }

    private static Decimal calculateRiskScore(Map<String, Object> metadata, String framework) {
        Prometheion_AI_Settings__c aiSettings = Prometheion_AI_Settings__c.getOrgDefaults();
        if (aiSettings != null && aiSettings.Enable_AI_Reasoning__c) {
            return callEinsteinPrediction(metadata, framework);
        }
        return calculateFallbackRiskScore(metadata, framework);
    }

    private static Decimal callEinsteinPrediction(Map<String, Object> metadata, String framework) {
        // Einstein Platform integration - fallback to rule-based scoring if not available
        // In production, if Einstein is required, ensure it's installed before deployment
        return calculateFallbackRiskScore(metadata, framework);
    }

    private static Decimal calculateFallbackRiskScore(Map<String, Object> metadata, String framework) {
        Decimal score = 3.0;
        if (metadata.containsKey('objectPermissionCount')) {
            Object permCount = metadata.get('objectPermissionCount');
            if (permCount != null) {
                score += Decimal.valueOf(String.valueOf(permCount)); // Simple heuristic
            }
        }
        return Math.min(score, 10.0);
    }

    private static String determineDriftCategory(Decimal riskScore, Map<String, Object> metadata) {
        if (riskScore >= 8.0) return 'POLICY_VIOLATION';
        if (riskScore >= 5.0) return 'UNAUTHORIZED';
        if (riskScore >= 3.0) return 'ANOMALY';
        return 'MANUAL_OVERRIDE';
    }

    /**
     * Generate correlation ID for structured logging
     */
    private static String generateCorrelationId(String entityType, String entityId) {
        String input = entityType + '|' + entityId + '|' + UserInfo.getUserId() + '|' + System.now().getTime();
        Blob hash = Crypto.generateDigest('MD5', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
    }

    public class PrometheionException extends Exception {}
}
