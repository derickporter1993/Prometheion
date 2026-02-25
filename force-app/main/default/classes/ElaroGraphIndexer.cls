/**
 * ElaroGraphIndexer - Compliance Graph Indexing Service for Big Object Storage
 *
 * Indexes compliance-related entity changes into the Elaro_Compliance_Graph__b Big Object
 * for long-term audit trail retention and compliance analysis. Supports both single
 * and bulk indexing operations with comprehensive metadata extraction and risk scoring.
 *
 * Key Features:
 * - Deterministic node hashing for idempotent indexing
 * - Framework-specific risk score calculation
 * - Metadata size limits to prevent payload bloat
 * - Structured error handling with correlation IDs
 * - Bulk indexing support for high-volume operations
 * - Fallback to rule-based scoring when Einstein Platform is unavailable
 *
 * Supported Entity Types:
 * - PERMISSION_SET: Indexes permission set metadata and object/field permission counts
 * - FLOW: Indexes flow definition metadata and trigger types
 *
 * Security:
 * - Uses WITH USER_MODE for all SOQL queries
 * - Sanitizes metadata to prevent sensitive data leakage
 * - Validates framework values against allowed set
 * - Enforces field-level access through schema describe
 *
 * @author Elaro Team
 * @version 3.0
 * @see Elaro_Compliance_Graph__b
 * @see ElaroConstants
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ElaroGraphIndexer {
    private static final String GRAPH_VERSION = 'v3.0';
    private static final Integer MAX_METADATA_SIZE = 50000;
    private static final String INJECTION_PATTERN = '.*[;\'\"\\-\\-<>\\\\/%].*';

    /**
     * Indexes a single compliance entity change into the graph Big Object.
     *
     * Creates a deterministic hash-based node ID, extracts entity metadata,
     * calculates risk score, and persists to Elaro_Compliance_Graph__b.
     *
     * @param entityType The type of entity being indexed (e.g., 'PERMISSION_SET', 'FLOW')
     * @param entityId The Salesforce record ID of the entity
     * @param parentNodeId Optional parent node ID for hierarchical relationships
     * @param framework The compliance framework (e.g., 'HIPAA', 'SOC2', 'GDPR')
     * @return The generated node hash that serves as the unique identifier
     * @throws ElaroException if validation fails, entity not found, or indexing error occurs
     *
     * @example
     * String nodeHash = ElaroGraphIndexer.indexChange(
     *     'PERMISSION_SET',
     *     '0PSxxxxxxxxxxxx',
     *     null,
     *     'HIPAA'
     * );
     */
    public static String indexChange(String entityType, String entityId, String parentNodeId, String framework) {
        // Input validation - non-null, non-empty
        if (String.isBlank(entityType)) {
            throw new ElaroException('Entity type cannot be blank');
        }
        if (String.isBlank(entityId)) {
            throw new ElaroException('Entity ID cannot be blank');
        }
        if (String.isBlank(framework)) {
            throw new ElaroException('Framework cannot be blank');
        }
        // Injection character validation for entityType and entityId
        // Prevent SOQL injection, XSS, and path traversal via dangerous characters
        if (Pattern.matches(INJECTION_PATTERN, entityType)) {
            throw new ElaroException('Entity type contains invalid characters');
        }
        if (Pattern.matches(INJECTION_PATTERN, entityId)) {
            throw new ElaroException('Entity ID contains invalid characters');
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
            // Note: Elaro_Compliance_Graph__b is a Big Object and does not support standard CRUD/FLS checks
            // via ElaroSecurityUtils/Security APIs. Access to this Big Object must be controlled via
            // permission set assignments and platform Big Object permissions, not runtime CRUD checks here.
            insert as user node;
            return nodeHash;
        } catch (DmlException e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            ElaroLogger.error( 
                '[ElaroGraphIndexer] Graph indexing failed - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new ElaroException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + getSafeDmlMessage(e));
        } catch (Exception e) {
            String correlationId = generateCorrelationId(entityType, entityId);
            ElaroLogger.error( 
                '[ElaroGraphIndexer] Graph indexing unexpected error - CorrelationId: ' + correlationId + 
                ', EntityType: ' + entityType + 
                ', EntityId: ' + entityId + 
                ', Error: ' + e.getMessage() + 
                ', StackTrace: ' + e.getStackTraceString());
            throw new ElaroException('Graph indexing failed for ' + entityType + ' (' + entityId + '): ' + e.getMessage());
        }
    }

    /**
     * Generates a deterministic SHA-256 hash for consistent node identification.
     *
     * Uses stable, immutable inputs (entityType, entityId, framework) to ensure
     * the same inputs always produce the same hash. Truncated to 50 characters
     * to fit within Big Object field limits.
     *
     * @param entityType The type of entity being indexed
     * @param entityId The Salesforce record ID
     * @param framework The compliance framework
     * @return Base64-encoded SHA-256 hash (first 50 characters)
     */
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
        // Tech debt reduction: remove placeholder integration stub and use explicit, observable fallback behavior.
        // This keeps current functionality stable while making Einstein readiness visible in logs.
        if (!isEinsteinPredictionAvailable()) {
            ElaroLogger.warn(
                '[ElaroGraphIndexer] Einstein prediction requested but integration is not configured. '
                + 'Using rule-based risk scoring fallback. Framework: ' + framework
            );
            return calculateFallbackRiskScore(metadata, framework);
        }

        // Reserved extension point for actual Einstein prediction implementation.
        return calculateFallbackRiskScore(metadata, framework);
    }

    private static Boolean isEinsteinPredictionAvailable() {
        // Centralized capability check to keep scoring logic deterministic until integration is enabled.
        return false;
    }

    private static Decimal calculateFallbackRiskScore(Map<String, Object> metadata, String framework) {
        Decimal score = ElaroConstants.BASE_RISK_SCORE;

        Integer objectPermissionCount = extractIntegerMetric(metadata, 'objectPermissionCount');
        Integer fieldPermissionCount = extractIntegerMetric(metadata, 'fieldPermissionCount');

        // Weighted model tuned for deterministic behavior:
        // - Object permissions have stronger impact than field permissions
        // - Framework multiplier aligns with stricter control expectations
        Decimal permissionImpact = (Decimal.valueOf(objectPermissionCount) * 0.8)
            + (Decimal.valueOf(fieldPermissionCount) * 0.2);
        Decimal frameworkMultiplier = getFrameworkRiskMultiplier(framework);

        score += permissionImpact * frameworkMultiplier;
        return Math.max(ElaroConstants.BASE_RISK_SCORE, Math.min(score, ElaroConstants.RISK_SCORE_MAX));
    }

    private static Integer extractIntegerMetric(Map<String, Object> metadata, String key) {
        if (metadata == null || !metadata.containsKey(key) || metadata.get(key) == null) {
            return 0;
        }

        try {
            return Integer.valueOf(String.valueOf(metadata.get(key)));
        } catch (Exception e) {
            ElaroLogger.warn(
                '[ElaroGraphIndexer] Invalid metric value for key ' + key + ': ' + String.valueOf(metadata.get(key))
            );
            return 0;
        }
    }

    private static Decimal getFrameworkRiskMultiplier(String framework) {
        Map<String, Decimal> frameworkMultipliers = new Map<String, Decimal>{
            'PCI_DSS' => 1.2,
            'HIPAA' => 1.15,
            'SOC2' => 1.1,
            'NIST' => 1.05,
            'GDPR' => 1.0
        };
        return frameworkMultipliers.containsKey(framework) ? frameworkMultipliers.get(framework) : 1.0;
    }

    private static String determineDriftCategory(Decimal riskScore, Map<String, Object> metadata) {
        if (riskScore >= ElaroConstants.RISK_THRESHOLD_AUTO_FIX) {
            return ElaroConstants.DRIFT_POLICY_VIOLATION;
        }
        if (riskScore >= ElaroConstants.RISK_THRESHOLD_MEDIUM) {
            return ElaroConstants.DRIFT_UNAUTHORIZED;
        }
        if (riskScore >= ElaroConstants.RISK_THRESHOLD_LOW) {
            return ElaroConstants.DRIFT_ANOMALY;
        }
        return ElaroConstants.DRIFT_MANUAL_OVERRIDE;
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
            'name', 'apiname', 'triggertype', 'objectpermissioncount', 
            'fieldpermissioncount', 'type', 'status'
        };
        
        for (String key : metadata.keySet()) {
            if (allowedFields.contains(key.toLowerCase())) {
                sanitized.put(key, metadata.get(key));
            }
        }
        
        String serialized = JSON.serialize(sanitized);

        // Enforce size limit (Big Object Long Text fields can be large, but we limit to 50KB)
        if (serialized.length() > MAX_METADATA_SIZE) {
            ElaroLogger.warn( '[ElaroGraphIndexer] Metadata exceeds size limit: ' + serialized.length() + ' bytes. Truncating.');
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
     * Input wrapper class for bulk indexing operations.
     *
     * Encapsulates all required parameters for indexing a single entity
     * within a bulk operation. Used by indexChangeBulk() method.
     */
    public class IndexInput {
        public String entityType;
        public String entityId;
        public String parentNodeId;
        public String framework;
    }
    
    /**
     * Performs bulk indexing of multiple compliance entity changes.
     *
     * Processes a list of IndexInput objects, validates each entry,
     * generates nodes, and performs a single bulk insert operation.
     * Invalid inputs are logged and skipped rather than failing the entire batch.
     *
     * @param inputs List of IndexInput objects containing entity data to index
     * @return Map of entityId to generated nodeHash for successfully indexed records
     * @throws ElaroException if the entire bulk insert operation fails
     *
     * @example
     * List<ElaroGraphIndexer.IndexInput> inputs = new List<ElaroGraphIndexer.IndexInput>();
     * ElaroGraphIndexer.IndexInput input = new ElaroGraphIndexer.IndexInput();
     * input.entityType = 'PERMISSION_SET';
     * input.entityId = '0PSxxxxxxxxxxxx';
     * input.framework = 'HIPAA';
     * inputs.add(input);
     *
     * Map<String, String> results = ElaroGraphIndexer.indexChangeBulk(inputs);
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
                    ElaroLogger.warn( 'ElaroGraphIndexer: Skipping invalid input - EntityType: ' + input.entityType + ', EntityId: ' + input.entityId);
                    continue;
                }
                
                // Injection character validation (consistent with indexChange single-record method)
                if (Pattern.matches(INJECTION_PATTERN, input.entityType)) {
                    ElaroLogger.warn('ElaroGraphIndexer: Skipping input with invalid entityType characters - EntityType: ' + input.entityType);
                    continue;
                }
                if (Pattern.matches(INJECTION_PATTERN, input.entityId)) {
                    ElaroLogger.warn('ElaroGraphIndexer: Skipping input with invalid entityId characters - EntityId: ' + input.entityId);
                    continue;
                }

                // Validate framework
                if (!ElaroConstants.isValidFramework(input.framework)) {
                    ElaroLogger.warn( 'ElaroGraphIndexer: Skipping invalid framework - ' + input.framework);
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
                ElaroLogger.error( 
                    '[ElaroGraphIndexer] Bulk indexing failed for entity - CorrelationId: ' + correlationId + 
                    ', EntityType: ' + input.entityType + 
                    ', EntityId: ' + input.entityId + 
                    ', Error: ' + e.getMessage());
                // Continue with other records
            }
        }
        
        // Bulk insert all nodes
        if (!nodesToInsert.isEmpty()) {
            // Note: Elaro_Compliance_Graph__b is a Big Object and does not support standard CRUD/FLS checks
            // via ElaroSecurityUtils/Security APIs. Access to this Big Object must be controlled via
            // permission set assignments and platform Big Object permissions, not runtime CRUD checks here.
            try {
                insert as user nodesToInsert;
            } catch (DmlException e) {
                String correlationId = generateCorrelationId('BULK', String.valueOf(nodesToInsert.size()));
                ElaroLogger.error( 
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

    /**
     * Custom exception class for ElaroGraphIndexer errors.
     *
     * Provides standardized error handling for indexing operations with
     * support for structured error messages and correlation IDs.
     */
    public class ElaroException extends Exception {}
}
