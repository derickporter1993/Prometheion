public with sharing class ElaroGraphIndexer {
    private static final String GRAPH_VERSION = 'v3.0';

    public static String indexChange(String entityType, String entityId, String parentNodeId, String framework) {
        // Input validation
        if (String.isBlank(entityType)) {
            throw new ElaroException('Entity type cannot be blank');
        }
        if (String.isBlank(entityId)) {
            throw new ElaroException('Entity ID cannot be blank');
        }
        if (String.isBlank(framework)) {
            throw new ElaroException('Framework cannot be blank');
        }
        // Validate framework is supported
        if (!ElaroConstants.isValidFramework(framework)) {
            throw new ElaroException('Unsupported framework: ' + framework);
        }
        
        String nodeHash = generateDeterministicHash(entityType, entityId, framework);
        Map<String, Object> metadata = queryEntityMetadata(entityType, entityId);
        Decimal riskScore = calculateRiskScore(metadata, framework);

        Elaro_Compliance_Graph__b node = new Elaro_Compliance_Graph__b(
            Graph_Node_Id__c = nodeHash,
            Parent_Node_Id__c = parentNodeId,
            Timestamp__c = System.now(),
            Entity_Type__c = entityType,
            Entity_Record_Id__c = entityId,
            Compliance_Framework__c = framework,
            Risk_Score__c = riskScore,
            Drift_Category__c = determineDriftCategory(riskScore, metadata),
            Node_Metadata__c = serializeMetadataSafe(metadata),
            AI_Confidence__c = 0.0,
            Graph_Version__c = GRAPH_VERSION
        );

        try {
            insert node;
            return nodeHash;
        } catch (DmlException e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            System.debug(LoggingLevel.ERROR, 
                '[ElaroGraphIndexer] Graph indexing failed - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new ElaroException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + getSafeDmlMessage(e));
        } catch (Exception e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            System.debug(LoggingLevel.ERROR, 
                '[ElaroGraphIndexer] Graph indexing unexpected error - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new ElaroException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + e.getMessage());
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
                    WITH USER_MODE
                    LIMIT 1
                ];
                if (psList.isEmpty()) {
                    throw new ElaroException('PermissionSet not found: ' + entityId);
                }
                PermissionSet ps = psList[0];
                
                // FLS check: Only include Name if accessible (check is implicit with WITH USER_MODE)
                // Serialize only required, non-sensitive fields to reduce payload size and prevent data leakage
                metadata.put('name', ps.Name);
                metadata.put('objectPermissionCount', ps.ObjectPerms != null ? ps.ObjectPerms.size() : 0);
                metadata.put('fieldPermissionCount', ps.FieldPerms != null ? ps.FieldPerms.size() : 0);
                
                // Explicitly avoid serializing sensitive permission data - only counts are stored
            }
            when 'FLOW' {
                List<FlowDefinitionView> fdList = [
                    SELECT ApiName, Label, TriggerType, ProcessType
                    FROM FlowDefinitionView
                    WHERE DurableId = :entityId
                    WITH USER_MODE
                    LIMIT 1
                ];
                if (fdList.isEmpty()) {
                    throw new ElaroException('FlowDefinitionView not found: ' + entityId);
                }
                FlowDefinitionView fd = fdList[0];
                metadata.put('apiName', fd.ApiName);
                metadata.put('triggerType', fd.TriggerType);
            }
            when else {
                throw new ElaroException('Unsupported entity type: ' + entityType);
            }
        }
        return metadata;
    }

    private static Decimal calculateRiskScore(Map<String, Object> metadata, String framework) {
        Elaro_AI_Settings__c aiSettings = Elaro_AI_Settings__c.getOrgDefaults();
        if (aiSettings != null && aiSettings.Enable_AI_Reasoning__c) {
            return callEinsteinPrediction(metadata, framework);
        }
        return calculateFallbackRiskScore(metadata, framework);
    }

    private static Decimal callEinsteinPrediction(Map<String, Object> metadata, String framework) {
        // Einstein Platform integration - fallback to rule-based scoring if not available
        // In production, if Einstein is required, ensure it's installed before deployment
        try {
            // TODO: Implement Einstein Platform callout (see docs/GITHUB_ISSUE_TODO_EINSTEIN_PLATFORM.md)
            // For now, fallback to rule-based scoring
            return calculateFallbackRiskScore(metadata, framework);
        } catch (Exception e) {
            // Log Einstein prediction failure
            String correlationId = generateCorrelationId('EINSTEIN', framework);
            System.debug(LoggingLevel.ERROR, 
                '[ElaroGraphIndexer] Einstein prediction failed - CorrelationId: ' + correlationId + 
                ', Framework: ' + framework + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            
            // Log to Integration_Error__c for error tracking
            try {
                Integration_Error__c error = new Integration_Error__c(
                    Error_Type__c = 'EINSTEIN',
                    Error_Message__c = 'Einstein prediction failed: ' + e.getMessage(),
                    Stack_Trace__c = e.getStackTraceString(),
                    Correlation_Id__c = correlationId,
                    Context__c = 'Framework: ' + framework + ', Metadata: ' + JSON.serialize(metadata),
                    Status__c = 'NEW',
                    Timestamp__c = System.now()
                );
                insert error;
            } catch (Exception logError) {
                // Don't fail if error logging fails
                System.debug(LoggingLevel.WARN, 'Failed to log Einstein error: ' + logError.getMessage());
            }
            
            // Fallback to rule-based scoring
            return calculateFallbackRiskScore(metadata, framework);
        }
    }

    private static Decimal calculateFallbackRiskScore(Map<String, Object> metadata, String framework) {
        Decimal score = ElaroConstants.BASE_RISK_SCORE;
        if (metadata.containsKey('objectPermissionCount')) {
            Object permCount = metadata.get('objectPermissionCount');
            if (permCount != null) {
                score += Decimal.valueOf(String.valueOf(permCount)); // Simple heuristic
            }
        }
        return Math.min(score, ElaroConstants.RISK_SCORE_MAX);
    }

    private static String determineDriftCategory(Decimal riskScore, Map<String, Object> metadata) {
        if (riskScore >= 8.0) return 'POLICY_VIOLATION';
        if (riskScore >= 5.0) return 'UNAUTHORIZED';
        if (riskScore >= 3.0) return 'ANOMALY';
        return 'MANUAL_OVERRIDE';
    }

    /**
     * Safely serialize metadata with size limits and field validation
     * Prevents payload bloat and data leakage by enforcing size limits
     */
    private static String serializeMetadataSafe(Map<String, Object> metadata) {
        if (metadata == null || metadata.isEmpty()) {
            return '{}';
        }
        
        // Create a sanitized copy with only allowed fields
        Map<String, Object> sanitized = new Map<String, Object>();
        
        // Allowed field list - only include non-sensitive metadata
        Set<String> allowedFields = new Set<String>{
            'name', 'apiName', 'triggerType', 'objectPermissionCount', 
            'fieldPermissionCount', 'type', 'status'
        };
        
        for (String key : metadata.keySet()) {
            if (allowedFields.contains(key.toLowerCase())) {
                sanitized.put(key, metadata.get(key));
            }
        }
        
        String serialized = JSON.serialize(sanitized);
        
        // Enforce size limit (Big Object Long Text fields can be large, but we limit to 50KB)
        Integer MAX_METADATA_SIZE = 50000;
        if (serialized.length() > MAX_METADATA_SIZE) {
            System.debug(LoggingLevel.WARN, '[ElaroGraphIndexer] Metadata exceeds size limit: ' + serialized.length() + ' bytes. Truncating.');
            serialized = serialized.substring(0, MAX_METADATA_SIZE - 3) + '...';
        }
        
        return serialized;
    }

    /**
     * Generate correlation ID for structured logging
     * Uses stable inputs (no time component) for deterministic correlation tracking
     */
    private static String generateCorrelationId(String entityType, String entityId) {
        // Use only stable inputs - no time component for deterministic correlation
        String input = entityType + '|' + entityId + '|' + UserInfo.getUserId();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return EncodingUtil.base64Encode(hash).substring(0, 16);
    }

    /**
     * Bulk index multiple changes at once
     * Input structure for bulk indexing
     */
    public class IndexInput {
        public String entityType;
        public String entityId;
        public String parentNodeId;
        public String framework;
    }
    
    /**
     * Bulk index changes for better performance
     * @param inputs List of IndexInput objects to index
     * @return Map of entityId to nodeHash
     */
    public static Map<String, String> indexChangeBulk(List<IndexInput> inputs) {
        if (inputs == null || inputs.isEmpty()) {
            throw new ElaroException('Inputs cannot be null or empty');
        }
        
        Map<String, String> results = new Map<String, String>();
        List<Elaro_Compliance_Graph__b> nodesToInsert = new List<Elaro_Compliance_Graph__b>();
        
        for (IndexInput input : inputs) {
            try {
                // Validate input
                if (String.isBlank(input.entityType) || String.isBlank(input.entityId) || String.isBlank(input.framework)) {
                    System.debug(LoggingLevel.WARN, 'ElaroGraphIndexer: Skipping invalid input - EntityType: ' + input.entityType + ', EntityId: ' + input.entityId);
                    continue;
                }
                
                // Validate framework
                if (!ElaroConstants.isValidFramework(input.framework)) {
                    System.debug(LoggingLevel.WARN, 'ElaroGraphIndexer: Skipping invalid framework - ' + input.framework);
                    continue;
                }
                
                String nodeHash = generateDeterministicHash(input.entityType, input.entityId, input.framework);
                Map<String, Object> metadata = queryEntityMetadata(input.entityType, input.entityId);
                Decimal riskScore = calculateRiskScore(metadata, input.framework);
                
                Elaro_Compliance_Graph__b node = new Elaro_Compliance_Graph__b(
                    Graph_Node_Id__c = nodeHash,
                    Parent_Node_Id__c = input.parentNodeId,
                    Timestamp__c = System.now(),
                    Entity_Type__c = input.entityType,
                    Entity_Record_Id__c = input.entityId,
                    Compliance_Framework__c = input.framework,
                    Risk_Score__c = riskScore,
                    Drift_Category__c = determineDriftCategory(riskScore, metadata),
                    Node_Metadata__c = serializeMetadataSafe(metadata),
                    AI_Confidence__c = 0.0,
                    Graph_Version__c = GRAPH_VERSION
                );
                
                nodesToInsert.add(node);
                results.put(input.entityId, nodeHash);
            } catch (Exception e) {
                String correlationId = generateCorrelationId(input.entityType, input.entityId);
                System.debug(LoggingLevel.ERROR, 
                    '[ElaroGraphIndexer] Bulk indexing failed for entity - CorrelationId: ' + correlationId + 
                    ', EntityType: ' + input.entityType + 
                    ', EntityId: ' + input.entityId + 
                    ', Error: ' + e.getMessage());
                // Continue with other records
            }
        }
        
        // Bulk insert all nodes
        if (!nodesToInsert.isEmpty()) {
            try {
                insert nodesToInsert;
            } catch (DmlException e) {
                String correlationId = generateCorrelationId('BULK', String.valueOf(nodesToInsert.size()));
                System.debug(LoggingLevel.ERROR, 
                    '[ElaroGraphIndexer] Bulk insert failed - CorrelationId: ' + correlationId + 
                    ', Records: ' + nodesToInsert.size() + 
                    ', Error: ' + e.getMessage());
                throw new ElaroException('Bulk indexing failed: ' + getSafeDmlMessage(e));
            }
        }
        
        return results;
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

    public class ElaroException extends Exception {}
}
