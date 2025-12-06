/**
 * SentinelGraphIndexerTest - Tests for the Graph Indexer Stub
 * 
 * @author Solentra
 * @version 1.0
 */
@isTest
private class SentinelGraphIndexerTest {
    
    @isTest
    static void testIndexEvent() {
        Test.startTest();
        String nodeId = SentinelGraphIndexer.indexEvent(
            SolentraConstants.ENTITY_PERMISSION_SET,
            '0PS000000000001',
            'created',
            SolentraConstants.FRAMEWORK_HIPAA,
            7.5
        );
        Test.stopTest();
        
        System.assertNotEquals(null, nodeId, 'Node ID should not be null');
        System.assert(nodeId.startsWith('node-'), 'Node ID should start with node-');
    }
    
    @isTest
    static void testGetDriftCategory() {
        Test.startTest();
        
        // High risk - policy violation
        String highRisk = SentinelGraphIndexer.getDriftCategory(8.5);
        System.assertEquals(SolentraConstants.DRIFT_POLICY_VIOLATION, highRisk);
        
        // Medium risk - pending review
        String mediumRisk = SentinelGraphIndexer.getDriftCategory(7.5);
        System.assertEquals(SolentraConstants.DRIFT_PENDING_REVIEW, mediumRisk);
        
        // Low risk - approved
        String lowRisk = SentinelGraphIndexer.getDriftCategory(5.0);
        System.assertEquals(SolentraConstants.DRIFT_HUMAN_APPROVED, lowRisk);
        
        Test.stopTest();
    }
    
    @isTest
    static void testQueryRecentNodes() {
        Test.startTest();
        List<Map<String, Object>> nodes = SentinelGraphIndexer.queryRecentNodes(30, 'HIPAA');
        Test.stopTest();
        
        System.assertNotEquals(null, nodes, 'Should return a list');
        System.assertEquals(0, nodes.size(), 'Stub should return empty list');
    }
    
    @isTest
    static void testGetNodeById() {
        Test.startTest();
        Map<String, Object> node = SentinelGraphIndexer.getNodeById('node-123');
        Test.stopTest();
        
        System.assertEquals(null, node, 'Stub should return null');
    }
    
    @isTest
    static void testMarkNodeReviewed() {
        Test.startTest();
        Boolean result = SentinelGraphIndexer.markNodeReviewed(
            'node-123', 
            UserInfo.getUserId(), 
            'Reviewed and approved'
        );
        Test.stopTest();
        
        System.assertEquals(true, result, 'Should return true');
    }
}
