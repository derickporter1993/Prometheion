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

        // Big Objects can only query on indexed fields - query recent records and filter in memory
        Datetime recentThreshold = Datetime.now().addDays(-1);
        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Risk_Score__c, Entity_Type__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Timestamp__c >= :recentThreshold
            LIMIT 1000
        ];

        // Filter in memory for matching nodeHash
        Prometheion_Compliance_Graph__b matchingNode = null;
        for (Prometheion_Compliance_Graph__b node : nodes) {
            if (node.Graph_Node_Id__c == nodeHash) {
                matchingNode = node;
                break;
            }
        }

        System.assertNotEquals(null, matchingNode, 'Should create one node');
        System.assertEquals('PERMISSION_SET', matchingNode.Entity_Type__c);
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
    static void testBulkIndexChange() {
        // Test bulk processing with 200+ permission sets (P1 requirement)
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 200; i++) {
            permSets.add(new PermissionSet(Name='BulkTestPS' + i, Label='Bulk Test PS ' + i));
        }
        insert permSets;

        Test.startTest();
        List<String> nodeHashes = new List<String>();
        for (PermissionSet ps : permSets) {
            try {
                String nodeHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
                nodeHashes.add(nodeHash);
            } catch (Exception e) {
                System.debug('Failed to index PS ' + ps.Name + ': ' + e.getMessage());
            }
        }
        Test.stopTest();

        System.assertEquals(200, nodeHashes.size(), 'Should have indexed 200 permission sets');
        
        // Verify all hashes are unique
        Set<String> uniqueHashes = new Set<String>(nodeHashes);
        System.assertEquals(200, uniqueHashes.size(), 'All node hashes should be unique');
    }
    
    @IsTest
    static void testInputValidation() {
        Test.startTest();
        
        // Test blank entity type
        try {
            PrometheionGraphIndexer.indexChange('', 'testid', null, 'SOC2');
            System.assert(false, 'Should have thrown exception for blank entity type');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for blank entity type');
        }
        
        // Test blank entity ID
        try {
            PrometheionGraphIndexer.indexChange('PERMISSION_SET', '', null, 'SOC2');
            System.assert(false, 'Should have thrown exception for blank entity ID');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for blank entity ID');
        }
        
        // Test blank framework
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        try {
            PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, '');
            System.assert(false, 'Should have thrown exception for blank framework');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for blank framework');
        }
        
        // Test invalid framework
        try {
            PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'INVALID_FRAMEWORK');
            System.assert(false, 'Should have thrown exception for invalid framework');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid framework');
        }
        
        Test.stopTest();
    }
    
    @IsTest
    static void testBulkIndexChangeSmallBatch() {
        // Create multiple permission sets for bulk test (smaller batch)
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 10; i++) {
            permSets.add(new PermissionSet(Name='BulkTestPS' + i, Label='Bulk Test PS ' + i));
        }
        insert permSets;
        
        Test.startTest();
        List<PrometheionGraphIndexer.IndexInput> inputs = new List<PrometheionGraphIndexer.IndexInput>();
        for (PermissionSet ps : permSets) {
            PrometheionGraphIndexer.IndexInput input = new PrometheionGraphIndexer.IndexInput();
            input.entityType = 'PERMISSION_SET';
            input.entityId = ps.Id;
            input.parentNodeId = null;
            input.framework = 'SOC2';
            inputs.add(input);
        }
        
        Map<String, String> results = PrometheionGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        System.assertEquals(10, results.size(), 'Should have indexed 10 permission sets');
        
        // Verify all hashes are unique
        Set<String> uniqueHashes = new Set<String>(results.values());
        System.assertEquals(10, uniqueHashes.size(), 'All node hashes should be unique');
    }
    
    @IsTest
    static void testBulkIndexChangeWithInvalidInputs() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        
        Test.startTest();
        List<PrometheionGraphIndexer.IndexInput> inputs = new List<PrometheionGraphIndexer.IndexInput>();
        
        // Valid input
        PrometheionGraphIndexer.IndexInput valid = new PrometheionGraphIndexer.IndexInput();
        valid.entityType = 'PERMISSION_SET';
        valid.entityId = ps.Id;
        valid.framework = 'SOC2';
        inputs.add(valid);
        
        // Invalid input (blank entity type)
        PrometheionGraphIndexer.IndexInput invalid1 = new PrometheionGraphIndexer.IndexInput();
        invalid1.entityType = '';
        invalid1.entityId = ps.Id;
        invalid1.framework = 'SOC2';
        inputs.add(invalid1);
        
        // Invalid input (invalid framework)
        PrometheionGraphIndexer.IndexInput invalid2 = new PrometheionGraphIndexer.IndexInput();
        invalid2.entityType = 'PERMISSION_SET';
        invalid2.entityId = ps.Id;
        invalid2.framework = 'INVALID';
        inputs.add(invalid2);
        
        Map<String, String> results = PrometheionGraphIndexer.indexChangeBulk(inputs);
        Test.stopTest();
        
        // Should only process the valid input
        System.assertEquals(1, results.size(), 'Should have processed only valid input');
    }
    
    @IsTest
    static void testBulkIndexChangeEmptyInput() {
        Test.startTest();
        try {
            PrometheionGraphIndexer.indexChangeBulk(null);
            System.assert(false, 'Should have thrown exception for null input');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for null input');
        }
        
        try {
            PrometheionGraphIndexer.indexChangeBulk(new List<PrometheionGraphIndexer.IndexInput>());
            System.assert(false, 'Should have thrown exception for empty input');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for empty input');
        }
        Test.stopTest();
    }
}
