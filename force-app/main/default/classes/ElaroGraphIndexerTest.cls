@IsTest
private class ElaroGraphIndexerTest {
    @TestSetup
    static void setup() {
        PermissionSet ps = new PermissionSet(Name='TestPS', Label='Test PS');
        insert ps;
    }

    @IsTest
    static void testIndexChange_CreatesImmutableNode() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        Test.startTest();
        String nodeHash = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        Test.stopTest();

        System.assertNotEquals(null, nodeHash, 'Should return node hash');

        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Risk_Score__c, Entity_Type__c
            FROM Elaro_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];
        System.assertEquals(1, nodes.size(), 'Should create one node');
        System.assertEquals('PERMISSION_SET', nodes[0].Entity_Type__c);
    }

    @IsTest
    static void testGenerateDeterministicHash_IsUnique() {
        String hash1 = ElaroGraphIndexer.generateDeterministicHash('FLOW', '123', 'SOC2');
        String hash2 = ElaroGraphIndexer.generateDeterministicHash('FLOW', '456', 'SOC2');
        System.assertNotEquals(hash1, hash2, 'Hash should be unique for different entities');
    }

    @IsTest
    static void testIndexChange_InvalidEntity() {
        Test.startTest();
        try {
            ElaroGraphIndexer.indexChange('INVALID', 'badid', null, 'SOC2');
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid entity');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIndexChange_InvalidFramework() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        Test.startTest();
        try {
            ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'INVALID_FRAMEWORK');
            System.assert(false, 'Should have thrown exception for invalid framework');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Unsupported framework'), 'Expected framework validation error');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testIndexChangeBulk_MultiplePermissionSets() {
        // Create 200+ permission sets for bulk testing
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 200; i++) {
            permSets.add(new PermissionSet(
                Name = 'BulkPS' + i,
                Label = 'Bulk Test PS ' + i
            ));
        }
        insert permSets;
        
        // Create bulk input
        List<ElaroGraphIndexer.IndexInput> inputs = new List<ElaroGraphIndexer.IndexInput>();
        for (PermissionSet ps : permSets) {
            ElaroGraphIndexer.IndexInput input = new ElaroGraphIndexer.IndexInput();
            input.entityType = 'PERMISSION_SET';
            input.entityId = ps.Id;
            input.framework = 'SOC2';
            inputs.add(input);
        }
        
        Test.startTest();
        Map<String, String> results = ElaroGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        System.assertEquals(200, results.size(), 'Should process all 200 records');
        
        // Verify nodes were created
        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c FROM Elaro_Compliance_Graph__b
            WHERE Entity_Type__c = 'PERMISSION_SET'
        ];
        System.assertEquals(200, nodes.size(), 'Should create 200 graph nodes');
    }
    
    @IsTest
    static void testIndexChangeBulk_MixedFrameworks() {
        // Create test permission sets
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 30; i++) {
            permSets.add(new PermissionSet(
                Name = 'MixedPS' + i,
                Label = 'Mixed Test PS ' + i
            ));
        }
        insert permSets;
        
        // Create inputs with different frameworks
        List<String> frameworks = new List<String>{'SOC2', 'HIPAA', 'GDPR', 'NIST', 'PCI_DSS'};
        List<ElaroGraphIndexer.IndexInput> inputs = new List<ElaroGraphIndexer.IndexInput>();
        Integer fwIndex = 0;
        for (PermissionSet ps : permSets) {
            ElaroGraphIndexer.IndexInput input = new ElaroGraphIndexer.IndexInput();
            input.entityType = 'PERMISSION_SET';
            input.entityId = ps.Id;
            input.framework = frameworks[Math.mod(fwIndex++, frameworks.size())];
            inputs.add(input);
        }
        
        Test.startTest();
        Map<String, String> results = ElaroGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        System.assertEquals(30, results.size(), 'Should process all 30 records with mixed frameworks');
    }
    
    @IsTest
    static void testIndexChange_FlowEntity() {
        // Query for an existing Flow to test FLOW entity type
        // Note: FlowDefinitionView is read-only metadata, so we use existing flows
        List<FlowDefinitionView> flows = [
            SELECT DurableId, ApiName
            FROM FlowDefinitionView
            WHERE IsActive = true
            LIMIT 1
        ];
        
        if (flows.isEmpty()) {
            // If no flows exist, test that the method throws appropriate error
            Test.startTest();
            try {
                ElaroGraphIndexer.indexChange('FLOW', 'NonExistentFlowId', null, 'SOC2');
                System.assert(false, 'Should have thrown exception for non-existent flow');
            } catch (Exception e) {
                System.assert(e.getMessage().contains('FlowDefinitionView not found') || 
                             e.getMessage().contains('failed'), 
                             'Expected flow not found error: ' + e.getMessage());
            }
            Test.stopTest();
        } else {
            // Test with real flow
            FlowDefinitionView testFlow = flows[0];
            Test.startTest();
            String nodeHash = ElaroGraphIndexer.indexChange('FLOW', testFlow.DurableId, null, 'SOC2');
            Test.stopTest();
            
            System.assertNotEquals(null, nodeHash, 'Should return node hash for FLOW entity');
            
            List<Elaro_Compliance_Graph__b> nodes = [
                SELECT Graph_Node_Id__c, Entity_Type__c, Risk_Score__c
                FROM Elaro_Compliance_Graph__b
                WHERE Graph_Node_Id__c = :nodeHash
            ];
            System.assertEquals(1, nodes.size(), 'Should create one node for FLOW');
            System.assertEquals('FLOW', nodes[0].Entity_Type__c, 'Entity type should be FLOW');
        }
    }
    
    @IsTest
    static void testDetermineDriftCategory_AllCategories() {
        // Test drift categories by creating permission sets and verifying categories
        // Drift categories are determined by risk score:
        // >= 8.0: POLICY_VIOLATION
        // >= 5.0: UNAUTHORIZED
        // >= 3.0: ANOMALY
        // < 3.0: MANUAL_OVERRIDE
        
        // Create permission sets to test different risk score scenarios
        // Since risk scores are calculated internally, we verify the categories indirectly
        PermissionSet ps1 = new PermissionSet(Name='TestPS_Drift1', Label='Test PS Drift 1');
        PermissionSet ps2 = new PermissionSet(Name='TestPS_Drift2', Label='Test PS Drift 2');
        PermissionSet ps3 = new PermissionSet(Name='TestPS_Drift3', Label='Test PS Drift 3');
        insert new List<PermissionSet>{ps1, ps2, ps3};
        
        Test.startTest();
        String nodeHash1 = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps1.Id, null, 'SOC2');
        String nodeHash2 = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps2.Id, null, 'HIPAA');
        String nodeHash3 = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps3.Id, null, 'GDPR');
        Test.stopTest();
        
        // Verify nodes were created with drift categories
        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Drift_Category__c, Risk_Score__c
            FROM Elaro_Compliance_Graph__b
            WHERE Graph_Node_Id__c IN :new Set<String>{nodeHash1, nodeHash2, nodeHash3}
        ];
        
        System.assertEquals(3, nodes.size(), 'Should create 3 nodes');
        
        // Verify all nodes have valid drift categories
        Set<String> validCategories = new Set<String>{
            'POLICY_VIOLATION', 'UNAUTHORIZED', 'ANOMALY', 'MANUAL_OVERRIDE'
        };
        for (Elaro_Compliance_Graph__b node : nodes) {
            System.assert(validCategories.contains(node.Drift_Category__c), 
                         'Node should have valid drift category: ' + node.Drift_Category__c);
            System.assertNotEquals(null, node.Risk_Score__c, 'Risk score should not be null');
        }
    }
    
    @IsTest
    static void testCalculateFallbackRiskScore() {
        // Ensure AI is disabled to test fallback risk score calculation
        // Fallback uses BASE_RISK_SCORE (3.0) + objectPermissionCount
        Elaro_AI_Settings__c aiSettings = Elaro_AI_Settings__c.getOrgDefaults();
        if (aiSettings != null && aiSettings.Enable_AI_Reasoning__c) {
            aiSettings.Enable_AI_Reasoning__c = false;
            upsert aiSettings;
        }
        
        // Create permission set with object permissions to test fallback calculation
        PermissionSet ps = new PermissionSet(Name='TestPS_Fallback', Label='Test PS Fallback');
        insert ps;
        
        Test.startTest();
        String nodeHash = ElaroGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        Test.stopTest();
        
        List<Elaro_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Risk_Score__c
            FROM Elaro_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];
        
        System.assertEquals(1, nodes.size(), 'Should create one node');
        
        // Fallback risk score should be BASE_RISK_SCORE (3.0) or higher
        // Since objectPermissionCount is added, score should be at least 3.0
        System.assert(nodes[0].Risk_Score__c >= 3.0, 
                     'Fallback risk score should be at least BASE_RISK_SCORE (3.0), got: ' + nodes[0].Risk_Score__c);
        System.assert(nodes[0].Risk_Score__c <= 10.0, 
                     'Risk score should not exceed RISK_SCORE_MAX (10.0), got: ' + nodes[0].Risk_Score__c);
    }
}
