/**
 * Test class for ComplianceGraphService
 * @author Elaro Development Team
 * @since 2026-01
 */
@IsTest(testFor=ComplianceGraphService.class)
private class ComplianceGraphServiceTest {

    @TestSetup
    static void setupTestData() {
        // Create compliance gaps for different frameworks
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();

        // SOX gaps
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_ACCESS_REVIEW',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Critical SOX gap',
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '0PS000000000001',
            Risk_Score__c = 9.0,
            Detected_Date__c = Datetime.now()
        ));

        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOX',
            Policy_Reference__c = 'SOX_FINANCIAL_CONTROLS',
            Severity__c = 'HIGH',
            Status__c = 'IN_PROGRESS',
            Gap_Description__c = 'High SOX gap',
            Entity_Type__c = 'PROFILE',
            Entity_Id__c = '00e000000000001',
            Risk_Score__c = 7.0,
            Detected_Date__c = Datetime.now()
        ));

        // HIPAA gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_PHI_ACCESS',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Gap_Description__c = 'Critical HIPAA gap',
            Entity_Type__c = 'CUSTOM_FIELD',
            Entity_Id__c = 'Account.SSN__c',
            Risk_Score__c = 9.5,
            Detected_Date__c = Datetime.now()
        ));

        // SOC2 gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_ACCESS_CONTROL',
            Severity__c = 'MEDIUM',
            Status__c = 'OPEN',
            Gap_Description__c = 'Medium SOC2 gap',
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '0PS000000000001',
            Detected_Date__c = Datetime.now()
        ));

        // GDPR gap
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'GDPR',
            Policy_Reference__c = 'GDPR_DATA_ACCESS',
            Severity__c = 'LOW',
            Status__c = 'REMEDIATED',
            Gap_Description__c = 'Low GDPR gap',
            Detected_Date__c = Datetime.now()
        ));

        insert as user gaps;
    }

    @isTest
    static void testGetComplianceGraph() {
        Test.startTest();
        ComplianceGraphService.GraphData graph = ComplianceGraphService.getComplianceGraph();
        Test.stopTest();

        Assert.areNotEqual(null, graph, 'Graph should not be null');
        Assert.areNotEqual(null, graph.nodes, 'Nodes should not be null');
        Assert.areNotEqual(null, graph.edges, 'Edges should not be null');
        Assert.isTrue(graph.nodes.size() > 0, 'Should have nodes');
        Assert.isTrue(graph.edges.size() > 0, 'Should have edges');

        // Verify node types
        Set<String> nodeTypes = new Set<String>();
        for (ComplianceGraphService.GraphNode node : graph.nodes) {
            nodeTypes.add(node.nodeType);
            Assert.areNotEqual(null, node.id, 'Node ID should be set');
            Assert.areNotEqual(null, node.label, 'Node label should be set');
        }
        Assert.isTrue(nodeTypes.contains('framework'), 'Should have framework nodes');
        Assert.isTrue(nodeTypes.contains('gap'), 'Should have gap nodes');
    }

    @isTest
    static void testGetGraphByFramework() {
        Test.startTest();
        ComplianceGraphService.GraphData graph = ComplianceGraphService.getGraphByFramework('SOX');
        Test.stopTest();

        Assert.areNotEqual(null, graph, 'Graph should not be null');
        Assert.isTrue(graph.nodes.size() > 0, 'Should have nodes');

        // Verify all gaps are SOX
        for (ComplianceGraphService.GraphNode node : graph.nodes) {
            if (node.nodeType == 'gap' && node.metadata != null) {
                Assert.areEqual('SOX', node.metadata.get('framework'), 'All gaps should be SOX');
            }
        }
    }

    @isTest
    static void testAnalyzeImpact() {
        Test.startTest();
        ComplianceGraphService.ImpactAnalysis analysis = ComplianceGraphService.analyzeImpact('PERMISSION_SET', '0PS000000000001');
        Test.stopTest();

        Assert.areNotEqual(null, analysis, 'Analysis should not be null');
        Assert.areEqual('PERMISSION_SET', analysis.entityType, 'Entity type should match');
        Assert.areEqual('0PS000000000001', analysis.entityId, 'Entity ID should match');
        Assert.isTrue(analysis.totalGaps >= 2, 'Should have at least 2 gaps affecting this entity');
        Assert.isTrue(analysis.affectedFrameworks.size() >= 2, 'Should affect multiple frameworks');
        Assert.isTrue(analysis.riskScore > 0, 'Risk score should be positive');
    }

    @isTest
    static void testAnalyzeImpact_NoGaps() {
        Test.startTest();
        ComplianceGraphService.ImpactAnalysis analysis = ComplianceGraphService.analyzeImpact('UNKNOWN_TYPE', 'UNKNOWN_ID');
        Test.stopTest();

        Assert.areNotEqual(null, analysis, 'Analysis should not be null');
        Assert.areEqual(0, analysis.totalGaps, 'Should have no gaps');
        Assert.areEqual(0, analysis.riskScore, 'Risk score should be 0');
    }

    @isTest
    static void testGetGraphStats() {
        Test.startTest();
        ComplianceGraphService.GraphStats stats = ComplianceGraphService.getGraphStats();
        Test.stopTest();

        Assert.areNotEqual(null, stats, 'Stats should not be null');
        Assert.areEqual(5, stats.totalGaps, 'Should have 5 gaps');
        Assert.areEqual(4, stats.totalFrameworks, 'Should have 4 frameworks');
        Assert.areNotEqual(null, stats.frameworkCounts, 'Framework counts should not be null');
        Assert.areNotEqual(null, stats.severityCounts, 'Severity counts should not be null');
        Assert.areNotEqual(null, stats.statusCounts, 'Status counts should not be null');

        // Verify framework counts
        Assert.areEqual(2, stats.frameworkCounts.get('SOX'), 'SOX should have 2 gaps');
        Assert.areEqual(1, stats.frameworkCounts.get('HIPAA'), 'HIPAA should have 1 gap');

        // Verify severity counts
        Assert.areEqual(2, stats.severityCounts.get('CRITICAL'), 'Should have 2 critical gaps');
    }

    @isTest
    static void testGetNodeDetails_Framework() {
        Test.startTest();
        ComplianceGraphService.NodeDetails details = ComplianceGraphService.getNodeDetails('framework-SOX', 'framework');
        Test.stopTest();

        Assert.areNotEqual(null, details, 'Details should not be null');
        Assert.areEqual('framework-SOX', details.nodeId, 'Node ID should match');
        Assert.areEqual('framework', details.nodeType, 'Node type should match');
        Assert.areEqual('SOX', details.name, 'Name should be SOX');
    }

    @isTest
    static void testGetNodeDetails_Gap() {
        Compliance_Gap__c gap = [SELECT Id FROM Compliance_Gap__c LIMIT 1];
        String nodeId = 'gap-' + gap.Id;

        Test.startTest();
        ComplianceGraphService.NodeDetails details = ComplianceGraphService.getNodeDetails(nodeId, 'gap');
        Test.stopTest();

        Assert.areNotEqual(null, details, 'Details should not be null');
        Assert.areNotEqual(null, details.metadata, 'Metadata should be set');
        Assert.areNotEqual(null, details.metadata.get('framework'), 'Framework should be in metadata');
        Assert.areNotEqual(null, details.metadata.get('severity'), 'Severity should be in metadata');
    }

    @isTest
    static void testGraphNodeWrapper() {
        ComplianceGraphService.GraphNode node = new ComplianceGraphService.GraphNode();
        node.id = 'test-node';
        node.label = 'Test Node';
        node.nodeType = 'framework';
        node.size = 30;
        node.color = '#1E88E5';
        node.metadata = new Map<String, Object>{ 'key' => 'value' };

        Assert.areEqual('test-node', node.id, 'ID should match');
        Assert.areEqual('Test Node', node.label, 'Label should match');
        Assert.areEqual(30, node.size, 'Size should match');
    }

    @isTest
    static void testGraphEdgeWrapper() {
        ComplianceGraphService.GraphEdge edge = new ComplianceGraphService.GraphEdge('source', 'target', 'CONTAINS', 2);

        Assert.areEqual('source', edge.source, 'Source should match');
        Assert.areEqual('target', edge.target, 'Target should match');
        Assert.areEqual('CONTAINS', edge.edgeType, 'Edge type should match');
        Assert.areEqual(2, edge.weight, 'Weight should match');
    }

    @isTest
    static void testImpactAnalysisWrapper() {
        ComplianceGraphService.ImpactAnalysis analysis = new ComplianceGraphService.ImpactAnalysis();
        analysis.entityType = 'PERMISSION_SET';
        analysis.entityId = 'test123';
        analysis.affectedGaps = new List<ComplianceGraphService.AffectedGap>();
        analysis.affectedFrameworks = new Set<String>();
        analysis.riskScore = 15.5;
        analysis.totalGaps = 3;
        analysis.criticalCount = 1;
        analysis.highCount = 1;
        analysis.mediumCount = 1;
        analysis.lowCount = 0;

        Assert.areEqual('PERMISSION_SET', analysis.entityType, 'Entity type should match');
        Assert.areEqual(15.5, analysis.riskScore, 'Risk score should match');
        Assert.areEqual(3, analysis.totalGaps, 'Total gaps should match');
    }

    @isTest
    static void testAffectedGapWrapper() {
        ComplianceGraphService.AffectedGap gap = new ComplianceGraphService.AffectedGap();
        gap.gapId = null;
        gap.gapName = 'GAP-00001';
        gap.framework = 'SOX';
        gap.severity = 'CRITICAL';
        gap.status = 'OPEN';
        gap.riskScore = 9.0;

        Assert.areEqual('GAP-00001', gap.gapName, 'Gap name should match');
        Assert.areEqual('SOX', gap.framework, 'Framework should match');
        Assert.areEqual('CRITICAL', gap.severity, 'Severity should match');
    }

    @isTest
    static void testGraphStatsWrapper() {
        ComplianceGraphService.GraphStats stats = new ComplianceGraphService.GraphStats();
        stats.totalGaps = 10;
        stats.totalFrameworks = 4;
        stats.totalEntities = 5;
        stats.frameworkCounts = new Map<String, Integer>{ 'SOX' => 5, 'HIPAA' => 5 };
        stats.severityCounts = new Map<String, Integer>{ 'CRITICAL' => 2 };
        stats.statusCounts = new Map<String, Integer>{ 'OPEN' => 8 };

        Assert.areEqual(10, stats.totalGaps, 'Total gaps should match');
        Assert.areEqual(4, stats.totalFrameworks, 'Total frameworks should match');
    }

    @isTest
    static void testNodeDetailsWrapper() {
        ComplianceGraphService.NodeDetails details = new ComplianceGraphService.NodeDetails();
        details.nodeId = 'test-id';
        details.nodeType = 'gap';
        details.name = 'Test Gap';
        details.label = 'Test Gap Label';
        details.metadata = new Map<String, Object>{ 'key' => 'value' };

        Assert.areEqual('test-id', details.nodeId, 'Node ID should match');
        Assert.areEqual('gap', details.nodeType, 'Node type should match');
    }

    @isTest
    static void testGraphDataWrapper() {
        ComplianceGraphService.GraphData data = new ComplianceGraphService.GraphData();
        data.nodes = new List<ComplianceGraphService.GraphNode>();
        data.edges = new List<ComplianceGraphService.GraphEdge>();

        Assert.areNotEqual(null, data.nodes, 'Nodes should not be null');
        Assert.areNotEqual(null, data.edges, 'Edges should not be null');
    }

    @isTest
    static void testEntityNodeCreation() {
        // Verify entity nodes are created for gaps with entity info
        Test.startTest();
        ComplianceGraphService.GraphData graph = ComplianceGraphService.getComplianceGraph();
        Test.stopTest();

        Boolean hasEntityNode = false;
        for (ComplianceGraphService.GraphNode node : graph.nodes) {
            if (node.nodeType == 'entity') {
                hasEntityNode = true;
                Assert.isTrue(node.id.startsWith('entity-'), 'Entity node ID should start with entity-');
            }
        }
        Assert.isTrue(hasEntityNode, 'Should have entity nodes for gaps with entity info');
    }

    @isTest
    static void testEdgeConnections() {
        Test.startTest();
        ComplianceGraphService.GraphData graph = ComplianceGraphService.getComplianceGraph();
        Test.stopTest();

        Set<String> edgeTypes = new Set<String>();
        for (ComplianceGraphService.GraphEdge edge : graph.edges) {
            edgeTypes.add(edge.edgeType);
            Assert.areNotEqual(null, edge.source, 'Edge source should be set');
            Assert.areNotEqual(null, edge.target, 'Edge target should be set');
        }

        Assert.isTrue(edgeTypes.contains('HAS_GAP'), 'Should have HAS_GAP edges');
        Assert.isTrue(edgeTypes.contains('FRAMEWORK_GAP'), 'Should have FRAMEWORK_GAP edges');
    }
}
