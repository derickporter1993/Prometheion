/**
 * SentinelRemediationEngine - Auto-Remediation Engine for Compliance Violations
 * 
 * Q1 2025 Priority 1 Feature
 * 
 * When AI detects a violation with 95%+ confidence and auto-remediation is enabled,
 * this engine can automatically revert changes while creating an approval record
 * for human review within 24 hours.
 * 
 * Customer Impact: "Sentinel prevented 47 HIPAA violations this quarter automatically"
 * 
 * @author Sentinel Enterprise
 * @version 1.0
 */
public with sharing class SentinelRemediationEngine {
    
    private static final Decimal DEFAULT_CONFIDENCE_THRESHOLD = 0.95;
    private static final Integer REVIEW_WINDOW_HOURS = 24;
    
    /**
     * Remediation Result returned after attempting auto-remediation
     */
    public class RemediationResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public String remediationId;
        @AuraEnabled public String action;
        @AuraEnabled public String originalState;
        @AuraEnabled public String newState;
        @AuraEnabled public Datetime reviewDeadline;
        @AuraEnabled public String message;
        @AuraEnabled public Boolean requiresApproval;
        
        public RemediationResult() {
            this.success = false;
            this.requiresApproval = true;
        }
    }
    
    /**
     * Evaluate a compliance violation and determine if auto-remediation should occur
     */
    @AuraEnabled
    public static RemediationResult evaluateAndRemediate(String nodeHash, String framework) {
        RemediationResult result = new RemediationResult();
        
        try {
            // Get AI settings
            Sentinel_AI_Settings__c settings = Sentinel_AI_Settings__c.getOrgDefaults();
            
            // Check if auto-remediation is enabled
            if (settings == null || !settings.Auto_Remediation_Enabled__c) {
                result.message = 'Auto-remediation is disabled. Manual review required.';
                result.requiresApproval = true;
                return result;
            }
            
            // Get the compliance graph node
            Sentinel_Compliance_Graph__b node = queryGraphNode(nodeHash);
            
            // Get AI reasoning for this violation
            SentinelReasoningEngine.ReasoningResult reasoning = 
                SentinelReasoningEngine.explainViolation(nodeHash, framework);
            
            // Check confidence threshold
            Decimal threshold = settings.Confidence_Threshold__c != null 
                ? settings.Confidence_Threshold__c 
                : DEFAULT_CONFIDENCE_THRESHOLD;
            
            if (reasoning.confidence < threshold) {
                result.message = 'Confidence ' + reasoning.confidence + ' below threshold ' + threshold + '. Manual review required.';
                result.requiresApproval = true;
                logRemediationAttempt(nodeHash, 'SKIPPED_LOW_CONFIDENCE', result.message);
                return result;
            }
            
            // Check if policy allows auto-remediation
            Compliance_Policy__mdt policy = queryPolicy(reasoning.policy, framework);
            if (policy == null || !policy.Auto_Remediation_Allowed__c) {
                result.message = 'Policy ' + reasoning.policy + ' does not allow auto-remediation.';
                result.requiresApproval = true;
                logRemediationAttempt(nodeHash, 'SKIPPED_POLICY_BLOCKED', result.message);
                return result;
            }
            
            // Perform the remediation based on entity type
            result = executeRemediation(node, reasoning, policy, settings);
            
            // Create approval record for human review
            if (result.success) {
                createApprovalRecord(nodeHash, result, reasoning, policy);
                notifyStakeholders(result, reasoning, node);
            }
            
            return result;
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Remediation failed: ' + e.getMessage();
            logRemediationAttempt(nodeHash, 'ERROR', e.getMessage() + '\n' + e.getStackTraceString());
            return result;
        }
    }
    
    /**
     * Execute the actual remediation based on entity type
     */
    private static RemediationResult executeRemediation(
        Sentinel_Compliance_Graph__b node,
        SentinelReasoningEngine.ReasoningResult reasoning,
        Compliance_Policy__mdt policy,
        Sentinel_AI_Settings__c settings
    ) {
        RemediationResult result = new RemediationResult();
        
        String entityType = node.Entity_Type__c;
        String entityId = node.Entity_Record_Id__c;
        Map<String, Object> metadata = (Map<String, Object>)JSON.deserializeUntyped(node.Node_Metadata__c);
        
        switch on entityType {
            when 'PERMISSION_SET_ASSIGNMENT' {
                result = remediatePermissionSetAssignment(entityId, metadata, policy);
            }
            when 'PERMISSION_SET' {
                result = remediatePermissionSet(entityId, metadata, policy);
            }
            when 'SHARING_RULE' {
                result = remediateSharingRule(entityId, metadata, policy);
            }
            when 'FIELD_SECURITY' {
                result = remediateFieldSecurity(entityId, metadata, policy);
            }
            when else {
                result.success = false;
                result.message = 'Entity type ' + entityType + ' does not support auto-remediation.';
                result.requiresApproval = true;
            }
        }
        
        result.reviewDeadline = Datetime.now().addHours(REVIEW_WINDOW_HOURS);
        return result;
    }
    
    /**
     * Remediate overly permissive permission set assignment
     * Action: Remove the permission set assignment from the user
     */
    private static RemediationResult remediatePermissionSetAssignment(
        String assignmentId, 
        Map<String, Object> metadata,
        Compliance_Policy__mdt policy
    ) {
        RemediationResult result = new RemediationResult();
        
        try {
            // Query the assignment
            PermissionSetAssignment psa = [
                SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name
                FROM PermissionSetAssignment
                WHERE Id = :assignmentId
                LIMIT 1
            ];
            
            // Store original state for audit
            result.originalState = JSON.serialize(new Map<String, Object>{
                'assignmentId' => psa.Id,
                'assigneeId' => psa.AssigneeId,
                'permissionSetId' => psa.PermissionSetId,
                'permissionSetName' => psa.PermissionSet.Name
            });
            
            // Delete the assignment (remediate)
            delete psa;
            
            result.success = true;
            result.action = 'REMOVED_PERMISSION_SET_ASSIGNMENT';
            result.newState = 'Permission set "' + psa.PermissionSet.Name + '" removed from user';
            result.message = 'Auto-remediated: Removed overly permissive permission set assignment';
            result.remediationId = generateRemediationId();
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to remove permission set assignment: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Remediate permission set by removing dangerous permissions
     * Action: Remove Modify All Data / View All Data permissions
     */
    private static RemediationResult remediatePermissionSet(
        String permSetId,
        Map<String, Object> metadata,
        Compliance_Policy__mdt policy
    ) {
        RemediationResult result = new RemediationResult();
        
        try {
            PermissionSet ps = [
                SELECT Id, Name, PermissionsModifyAllData, PermissionsViewAllData
                FROM PermissionSet
                WHERE Id = :permSetId
                LIMIT 1
            ];
            
            result.originalState = JSON.serialize(new Map<String, Object>{
                'permissionSetId' => ps.Id,
                'name' => ps.Name,
                'modifyAllData' => ps.PermissionsModifyAllData,
                'viewAllData' => ps.PermissionsViewAllData
            });
            
            // Remove dangerous permissions
            Boolean changed = false;
            if (ps.PermissionsModifyAllData) {
                ps.PermissionsModifyAllData = false;
                changed = true;
            }
            if (ps.PermissionsViewAllData) {
                ps.PermissionsViewAllData = false;
                changed = true;
            }
            
            if (changed) {
                update ps;
                result.success = true;
                result.action = 'REMOVED_ELEVATED_PERMISSIONS';
                result.newState = 'Removed ModifyAllData/ViewAllData from ' + ps.Name;
                result.message = 'Auto-remediated: Removed elevated permissions from permission set';
                result.remediationId = generateRemediationId();
            } else {
                result.success = false;
                result.message = 'No elevated permissions found to remove';
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Failed to modify permission set: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Remediate sharing rule by reverting to more restrictive access
     */
    private static RemediationResult remediateSharingRule(
        String ruleId,
        Map<String, Object> metadata,
        Compliance_Policy__mdt policy
    ) {
        RemediationResult result = new RemediationResult();
        result.success = false;
        result.message = 'Sharing rule remediation requires Metadata API. Creating approval for manual review.';
        result.requiresApproval = true;
        return result;
    }
    
    /**
     * Remediate field security
     */
    private static RemediationResult remediateFieldSecurity(
        String fieldId,
        Map<String, Object> metadata,
        Compliance_Policy__mdt policy
    ) {
        RemediationResult result = new RemediationResult();
        result.success = false;
        result.message = 'Field security remediation requires Metadata API. Creating approval for manual review.';
        result.requiresApproval = true;
        return result;
    }
    
    /**
     * Revert a previous remediation (rollback)
     */
    @AuraEnabled
    public static RemediationResult revertRemediation(String remediationId) {
        RemediationResult result = new RemediationResult();
        
        try {
            // Query the remediation record from the graph
            List<Sentinel_Compliance_Graph__b> remediations = [
                SELECT Id, Node_Metadata__c, Entity_Type__c, Entity_Record_Id__c
                FROM Sentinel_Compliance_Graph__b
                WHERE Graph_Node_Id__c = :remediationId
                AND Entity_Type__c = 'REMEDIATION'
                LIMIT 1
            ];
            
            if (remediations.isEmpty()) {
                result.success = false;
                result.message = 'Remediation record not found';
                return result;
            }
            
            Map<String, Object> metadata = (Map<String, Object>)JSON.deserializeUntyped(remediations[0].Node_Metadata__c);
            String originalState = (String)metadata.get('originalState');
            String action = (String)metadata.get('action');
            
            // Execute rollback based on action type
            if (action == 'REMOVED_PERMISSION_SET_ASSIGNMENT') {
                Map<String, Object> original = (Map<String, Object>)JSON.deserializeUntyped(originalState);
                PermissionSetAssignment psa = new PermissionSetAssignment(
                    AssigneeId = (Id)original.get('assigneeId'),
                    PermissionSetId = (Id)original.get('permissionSetId')
                );
                insert psa;
                result.success = true;
                result.message = 'Rolled back: Re-assigned permission set';
            } else if (action == 'REMOVED_ELEVATED_PERMISSIONS') {
                Map<String, Object> original = (Map<String, Object>)JSON.deserializeUntyped(originalState);
                PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Id = :(Id)original.get('permissionSetId')];
                ps.PermissionsModifyAllData = (Boolean)original.get('modifyAllData');
                ps.PermissionsViewAllData = (Boolean)original.get('viewAllData');
                update ps;
                result.success = true;
                result.message = 'Rolled back: Restored elevated permissions';
            } else {
                result.success = false;
                result.message = 'Unknown action type: ' + action;
            }
            
        } catch (Exception e) {
            result.success = false;
            result.message = 'Rollback failed: ' + e.getMessage();
        }
        
        return result;
    }
    
    /**
     * Create an approval record for human review
     */
    private static void createApprovalRecord(
        String nodeHash,
        RemediationResult result,
        SentinelReasoningEngine.ReasoningResult reasoning,
        Compliance_Policy__mdt policy
    ) {
        Sentinel_Compliance_Graph__b approval = new Sentinel_Compliance_Graph__b(
            Graph_Node_Id__c = result.remediationId,
            Parent_Node_Id__c = nodeHash,
            Timestamp__c = System.now(),
            Entity_Type__c = 'REMEDIATION',
            Entity_Record_Id__c = result.remediationId,
            Compliance_Framework__c = policy.Framework__c,
            Risk_Score__c = policy.Risk_Weight__c,
            Drift_Category__c = 'AUTO_REMEDIATED',
            Node_Metadata__c = JSON.serialize(new Map<String, Object>{
                'action' => result.action,
                'originalState' => result.originalState,
                'newState' => result.newState,
                'confidence' => reasoning.confidence,
                'policy' => reasoning.policy,
                'legalCitation' => reasoning.legalCitation,
                'reviewDeadline' => result.reviewDeadline
            }),
            AI_Confidence__c = reasoning.confidence,
            AI_Explanation__c = result.message + '\n\nReasoning: ' + reasoning.explanation,
            Human_Adjudicated__c = false,
            Graph_Version__c = 'v3.0'
        );
        
        insert approval;
    }
    
    /**
     * Notify stakeholders of the remediation
     */
    private static void notifyStakeholders(
        RemediationResult result,
        SentinelReasoningEngine.ReasoningResult reasoning,
        Sentinel_Compliance_Graph__b node
    ) {
        String message = '🛡️ *Sentinel Auto-Remediation Executed*\n\n' +
            '*Action:* ' + result.action + '\n' +
            '*Policy:* ' + reasoning.policy + '\n' +
            '*Legal Citation:* ' + reasoning.legalCitation + '\n' +
            '*Confidence:* ' + (reasoning.confidence * 100).setScale(1) + '%\n' +
            '*Review Deadline:* ' + result.reviewDeadline.format() + '\n\n' +
            '*Details:*\n' + result.message + '\n\n' +
            '_This action requires human review within 24 hours. Click to approve or rollback._';
        
        SlackNotifier.notifyAsync(message);
    }
    
    /**
     * Log remediation attempt to the compliance graph
     */
    private static void logRemediationAttempt(String nodeHash, String status, String details) {
        Sentinel_Compliance_Graph__b logEntry = new Sentinel_Compliance_Graph__b(
            Graph_Node_Id__c = generateRemediationId(),
            Parent_Node_Id__c = nodeHash,
            Timestamp__c = System.now(),
            Entity_Type__c = 'REMEDIATION_ATTEMPT',
            Drift_Category__c = status,
            Node_Metadata__c = JSON.serialize(new Map<String, Object>{
                'status' => status,
                'details' => details,
                'attemptedBy' => UserInfo.getUserId(),
                'attemptedAt' => System.now()
            }),
            Human_Adjudicated__c = false,
            Graph_Version__c = 'v3.0'
        );
        
        insert logEntry;
    }
    
    /**
     * Query compliance graph node by hash
     */
    private static Sentinel_Compliance_Graph__b queryGraphNode(String nodeHash) {
        List<Sentinel_Compliance_Graph__b> nodes = [
            SELECT Id, Entity_Type__c, Entity_Record_Id__c, Risk_Score__c, Node_Metadata__c, Compliance_Framework__c
            FROM Sentinel_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
            LIMIT 1
        ];
        
        if (nodes.isEmpty()) {
            throw new RemediationException('Compliance graph node not found: ' + nodeHash);
        }
        
        return nodes[0];
    }
    
    /**
     * Query compliance policy by name and framework
     */
    private static Compliance_Policy__mdt queryPolicy(String policyName, String framework) {
        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Framework__c, Policy_Description__c, Legal_Citation__c, 
                   Remediation_Steps__c, Risk_Weight__c, Auto_Remediation_Allowed__c, Severity__c
            FROM Compliance_Policy__mdt
            WHERE DeveloperName = :policyName
            AND Framework__c = :framework
            AND Is_Active__c = true
            LIMIT 1
        ];
        
        return policies.isEmpty() ? null : policies[0];
    }
    
    /**
     * Generate unique remediation ID
     */
    private static String generateRemediationId() {
        String input = 'REMEDIATION|' + UserInfo.getUserId() + '|' + System.now().getTime();
        Blob hash = Crypto.generateDigest('SHA256', Blob.valueOf(input));
        return 'REM-' + EncodingUtil.base64Encode(hash).substring(0, 20);
    }
    
    /**
     * Get pending remediations awaiting approval
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getPendingRemediations() {
        List<Map<String, Object>> pending = new List<Map<String, Object>>();
        
        for (Sentinel_Compliance_Graph__b node : [
            SELECT Graph_Node_Id__c, Timestamp__c, Node_Metadata__c, AI_Confidence__c, AI_Explanation__c
            FROM Sentinel_Compliance_Graph__b
            WHERE Entity_Type__c = 'REMEDIATION'
            AND Human_Adjudicated__c = false
            ORDER BY Timestamp__c DESC
            LIMIT 50
        ]) {
            Map<String, Object> metadata = (Map<String, Object>)JSON.deserializeUntyped(node.Node_Metadata__c);
            pending.add(new Map<String, Object>{
                'remediationId' => node.Graph_Node_Id__c,
                'timestamp' => node.Timestamp__c,
                'action' => metadata.get('action'),
                'confidence' => node.AI_Confidence__c,
                'explanation' => node.AI_Explanation__c,
                'reviewDeadline' => metadata.get('reviewDeadline')
            });
        }
        
        return pending;
    }
    
    /**
     * Approve a remediation (mark as human-reviewed)
     */
    @AuraEnabled
    public static Boolean approveRemediation(String remediationId) {
        // Big Objects are immutable, so we create a new adjudication node
        Sentinel_Compliance_Graph__b approval = new Sentinel_Compliance_Graph__b(
            Graph_Node_Id__c = generateRemediationId(),
            Parent_Node_Id__c = remediationId,
            Timestamp__c = System.now(),
            Entity_Type__c = 'REMEDIATION_APPROVAL',
            Human_Adjudicator__c = UserInfo.getUserId(),
            Human_Adjudicated__c = true,
            Graph_Version__c = 'v3.0'
        );
        
        insert approval;
        return true;
    }
    
    public class RemediationException extends Exception {}
}
