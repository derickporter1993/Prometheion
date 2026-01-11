@IsTest
private class PrometheionGraphIndexerTest {
    @TestSetup
    static void setup() {
        PermissionSet ps = new PermissionSet(Name='TestPS', Label='Test PS');
        insert ps;
    }

    @IsTest
    static void testIndexChange_CreatesImmutableNode() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        Test.startTest();
        String nodeHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        Test.stopTest();

        System.assertNotEquals(null, nodeHash, 'Should return node hash');

        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Risk_Score__c, Entity_Type__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];
        System.assertEquals(1, nodes.size(), 'Should create one node');
        System.assertEquals('PERMISSION_SET', nodes[0].Entity_Type__c);
    }

    @IsTest
    static void testGenerateDeterministicHash_IsUnique() {
        String hash1 = PrometheionGraphIndexer.generateDeterministicHash('FLOW', '123', 'SOC2');
        String hash2 = PrometheionGraphIndexer.generateDeterministicHash('FLOW', '456', 'SOC2');
        System.assertNotEquals(hash1, hash2, 'Hash should be unique for different entities');
    }

    @IsTest
    static void testIndexChange_InvalidEntity() {
        Test.startTest();
        try {
            PrometheionGraphIndexer.indexChange('INVALID', 'badid', null, 'SOC2');
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
            PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'INVALID_FRAMEWORK');
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
        List<PrometheionGraphIndexer.IndexInput> inputs = new List<PrometheionGraphIndexer.IndexInput>();
        for (PermissionSet ps : permSets) {
            PrometheionGraphIndexer.IndexInput input = new PrometheionGraphIndexer.IndexInput();
            input.entityType = 'PERMISSION_SET';
            input.entityId = ps.Id;
            input.framework = 'SOC2';
            inputs.add(input);
        }
        
        Test.startTest();
        Map<String, String> results = PrometheionGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        System.assertEquals(200, results.size(), 'Should process all 200 records');
        
        // Verify nodes were created
        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c FROM Prometheion_Compliance_Graph__b
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
        List<PrometheionGraphIndexer.IndexInput> inputs = new List<PrometheionGraphIndexer.IndexInput>();
        Integer fwIndex = 0;
        for (PermissionSet ps : permSets) {
            PrometheionGraphIndexer.IndexInput input = new PrometheionGraphIndexer.IndexInput();
            input.entityType = 'PERMISSION_SET';
            input.entityId = ps.Id;
            input.framework = frameworks[Math.mod(fwIndex++, frameworks.size())];
            inputs.add(input);
        }
        
        Test.startTest();
        Map<String, String> results = PrometheionGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        System.assertEquals(30, results.size(), 'Should process all 30 records with mixed frameworks');
    }
}
