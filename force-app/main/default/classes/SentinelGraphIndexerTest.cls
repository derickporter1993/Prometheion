@IsTest
private class SentinelGraphIndexerTest {
    @TestSetup
    static void setup() {
        PermissionSet ps = new PermissionSet(Name='TestPS', Label='Test PS');
        insert ps;
    }

    @IsTest
    static void testIndexChange_CreatesImmutableNode() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];
        Test.startTest();
        String nodeHash = SentinelGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        Test.stopTest();

        System.assertNotEquals(null, nodeHash, 'Should return node hash');

        List<Sentinel_Compliance_Graph__b> nodes = [
            SELECT Graph_Node_Id__c, Risk_Score__c, Entity_Type__c
            FROM Sentinel_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];
        System.assertEquals(1, nodes.size(), 'Should create one node');
        System.assertEquals('PERMISSION_SET', nodes[0].Entity_Type__c);
    }

    @IsTest
    static void testGenerateDeterministicHash_IsUnique() {
        String hash1 = SentinelGraphIndexer.generateDeterministicHash('FLOW', '123', 'SOC2');
        String hash2 = SentinelGraphIndexer.generateDeterministicHash('FLOW', '456', 'SOC2');
        System.assertNotEquals(hash1, hash2, 'Hash should be unique for different entities');
    }

    @IsTest
    static void testIndexChange_InvalidEntity() {
        Test.startTest();
        try {
            SentinelGraphIndexer.indexChange('INVALID', 'badid', null, 'SOC2');
            System.assert(false, 'Should have thrown exception');
        } catch (Exception e) {
            System.assert(true, 'Expected exception for invalid entity');
        }
        Test.stopTest();
    }
}
