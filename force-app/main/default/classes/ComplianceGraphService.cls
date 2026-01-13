/**
 * @description Service for generating compliance graph data for visualization.
 * Creates node and edge data for D3.js-based graph visualization.
 *
 * Features:
 * - Framework-to-policy relationships
 * - Policy-to-gap linkages
 * - Entity dependency mapping
 * - Impact analysis
 *
 * @author Prometheion Development Team
 * @since 2026-01
 */
public with sharing class ComplianceGraphService {

    private static final Map<String, String> FRAMEWORK_COLORS = new Map<String, String>{
        'SOX' => '#1E88E5',
        'SOC2' => '#43A047',
        'HIPAA' => '#E53935',
        'GDPR' => '#8E24AA',
        'CCPA' => '#FB8C00',
        'PCI_DSS' => '#00ACC1',
        'NIST' => '#5E35B1',
        'ISO27001' => '#00897B',
        'GLBA' => '#D81B60'
    };

    private static final Map<String, String> SEVERITY_COLORS = new Map<String, String>{
        'CRITICAL' => '#D32F2F',
        'HIGH' => '#F57C00',
        'MEDIUM' => '#FBC02D',
        'LOW' => '#388E3C'
    };

    /**
     * @description Gets the complete compliance graph for the organization
     * @return GraphData object containing nodes and edges
     */
    @AuraEnabled(cacheable=true)
    public static GraphData getComplianceGraph() {
        GraphData graph = new GraphData();
        graph.nodes = new List<GraphNode>();
        graph.edges = new List<GraphEdge>();

        // Add framework nodes
        Set<String> frameworks = new Set<String>();
        for (Compliance_Gap__c gap : getGapsForGraph()) {
            frameworks.add(gap.Framework__c);
        }

        for (String framework : frameworks) {
            graph.nodes.add(createFrameworkNode(framework));
        }

        // Add policy nodes and connect to frameworks
        Map<String, List<Compliance_Policy__mdt>> policiesByFramework = getPoliciesByFramework();
        for (String framework : policiesByFramework.keySet()) {
            for (Compliance_Policy__mdt policy : policiesByFramework.get(framework)) {
                graph.nodes.add(createPolicyNode(policy));
                graph.edges.add(new GraphEdge(
                    'framework-' + framework,
                    'policy-' + policy.DeveloperName,
                    'CONTAINS',
                    1
                ));
            }
        }

        // Add gap nodes and connect to policies and frameworks
        for (Compliance_Gap__c gap : getGapsForGraph()) {
            graph.nodes.add(createGapNode(gap));

            // Connect to policy
            graph.edges.add(new GraphEdge(
                'policy-' + gap.Policy_Reference__c,
                'gap-' + gap.Id,
                'HAS_GAP',
                getSeverityWeight(gap.Severity__c)
            ));

            // Connect to framework directly
            graph.edges.add(new GraphEdge(
                'framework-' + gap.Framework__c,
                'gap-' + gap.Id,
                'FRAMEWORK_GAP',
                1
            ));

            // Add entity connection if present
            if (String.isNotBlank(gap.Entity_Type__c) && String.isNotBlank(gap.Entity_Id__c)) {
                String entityNodeId = 'entity-' + gap.Entity_Type__c + '-' + gap.Entity_Id__c;

                // Check if entity node already exists
                Boolean entityExists = false;
                for (GraphNode node : graph.nodes) {
                    if (node.id == entityNodeId) {
                        entityExists = true;
                        break;
                    }
                }

                if (!entityExists) {
                    graph.nodes.add(createEntityNode(gap.Entity_Type__c, gap.Entity_Id__c));
                }

                graph.edges.add(new GraphEdge(
                    'gap-' + gap.Id,
                    entityNodeId,
                    'AFFECTS',
                    getSeverityWeight(gap.Severity__c)
                ));
            }
        }

        return graph;
    }

    /**
     * @description Gets graph data filtered by framework
     * @param framework The framework to filter by
     * @return GraphData filtered to the specified framework
     */
    @AuraEnabled(cacheable=true)
    public static GraphData getGraphByFramework(String framework) {
        GraphData graph = new GraphData();
        graph.nodes = new List<GraphNode>();
        graph.edges = new List<GraphEdge>();

        // Add framework node
        graph.nodes.add(createFrameworkNode(framework));

        // Add policies for this framework
        List<Compliance_Policy__mdt> policies = getPoliciesForFramework(framework);
        for (Compliance_Policy__mdt policy : policies) {
            graph.nodes.add(createPolicyNode(policy));
            graph.edges.add(new GraphEdge(
                'framework-' + framework,
                'policy-' + policy.DeveloperName,
                'CONTAINS',
                1
            ));
        }

        // Add gaps for this framework
        for (Compliance_Gap__c gap : getGapsForFramework(framework)) {
            graph.nodes.add(createGapNode(gap));
            graph.edges.add(new GraphEdge(
                'policy-' + gap.Policy_Reference__c,
                'gap-' + gap.Id,
                'HAS_GAP',
                getSeverityWeight(gap.Severity__c)
            ));
        }

        return graph;
    }

    /**
     * @description Performs impact analysis for a specific entity
     * @param entityType The type of entity
     * @param entityId The ID of the entity
     * @return ImpactAnalysis containing affected items
     */
    @AuraEnabled(cacheable=true)
    public static ImpactAnalysis analyzeImpact(String entityType, String entityId) {
        ImpactAnalysis analysis = new ImpactAnalysis();
        analysis.entityType = entityType;
        analysis.entityId = entityId;
        analysis.affectedGaps = new List<AffectedGap>();
        analysis.affectedFrameworks = new Set<String>();
        analysis.riskScore = 0;

        // Find all gaps affecting this entity
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Name, Framework__c, Severity__c, Status__c, Risk_Score__c,
                   Gap_Description__c, Policy_Reference__c
            FROM Compliance_Gap__c
            WHERE Entity_Type__c = :entityType
            AND Entity_Id__c = :entityId
            WITH USER_MODE
        ];

        for (Compliance_Gap__c gap : gaps) {
            AffectedGap ag = new AffectedGap();
            ag.gapId = gap.Id;
            ag.gapName = gap.Name;
            ag.framework = gap.Framework__c;
            ag.severity = gap.Severity__c;
            ag.status = gap.Status__c;
            ag.riskScore = gap.Risk_Score__c;
            analysis.affectedGaps.add(ag);

            analysis.affectedFrameworks.add(gap.Framework__c);

            if (gap.Risk_Score__c != null) {
                analysis.riskScore += gap.Risk_Score__c;
            } else {
                analysis.riskScore += getSeverityRiskScore(gap.Severity__c);
            }
        }

        analysis.totalGaps = gaps.size();
        analysis.criticalCount = 0;
        analysis.highCount = 0;
        analysis.mediumCount = 0;
        analysis.lowCount = 0;

        for (AffectedGap ag : analysis.affectedGaps) {
            if (ag.severity == 'CRITICAL') analysis.criticalCount++;
            else if (ag.severity == 'HIGH') analysis.highCount++;
            else if (ag.severity == 'MEDIUM') analysis.mediumCount++;
            else if (ag.severity == 'LOW') analysis.lowCount++;
        }

        return analysis;
    }

    /**
     * @description Gets graph statistics summary
     * @return GraphStats with summary metrics
     */
    @AuraEnabled(cacheable=true)
    public static GraphStats getGraphStats() {
        GraphStats stats = new GraphStats();

        List<AggregateResult> frameworkCounts = [
            SELECT Framework__c, COUNT(Id) cnt
            FROM Compliance_Gap__c
            WITH USER_MODE
            GROUP BY Framework__c
        ];

        stats.frameworkCounts = new Map<String, Integer>();
        stats.totalGaps = 0;

        for (AggregateResult ar : frameworkCounts) {
            String framework = (String) ar.get('Framework__c');
            Integer count = (Integer) ar.get('cnt');
            stats.frameworkCounts.put(framework, count);
            stats.totalGaps += count;
        }

        List<AggregateResult> severityCounts = [
            SELECT Severity__c, COUNT(Id) cnt
            FROM Compliance_Gap__c
            WITH USER_MODE
            GROUP BY Severity__c
        ];

        stats.severityCounts = new Map<String, Integer>();
        for (AggregateResult ar : severityCounts) {
            String severity = (String) ar.get('Severity__c');
            Integer count = (Integer) ar.get('cnt');
            stats.severityCounts.put(severity, count);
        }

        List<AggregateResult> statusCounts = [
            SELECT Status__c, COUNT(Id) cnt
            FROM Compliance_Gap__c
            WITH USER_MODE
            GROUP BY Status__c
        ];

        stats.statusCounts = new Map<String, Integer>();
        for (AggregateResult ar : statusCounts) {
            String status = (String) ar.get('Status__c');
            Integer count = (Integer) ar.get('cnt');
            stats.statusCounts.put(status, count);
        }

        stats.totalFrameworks = stats.frameworkCounts.size();

        // Count unique entities
        List<AggregateResult> entityCounts = [
            SELECT Entity_Type__c, COUNT_DISTINCT(Entity_Id__c) cnt
            FROM Compliance_Gap__c
            WHERE Entity_Id__c != null
            WITH USER_MODE
            GROUP BY Entity_Type__c
        ];

        stats.totalEntities = 0;
        for (AggregateResult ar : entityCounts) {
            stats.totalEntities += (Integer) ar.get('cnt');
        }

        return stats;
    }

    /**
     * @description Gets node details for a specific node
     * @param nodeId The ID of the node
     * @param nodeType The type of node (framework, policy, gap, entity)
     * @return NodeDetails with full information
     */
    @AuraEnabled(cacheable=true)
    public static NodeDetails getNodeDetails(String nodeId, String nodeType) {
        NodeDetails details = new NodeDetails();
        details.nodeId = nodeId;
        details.nodeType = nodeType;

        if (nodeType == 'framework') {
            String framework = nodeId.replace('framework-', '');
            details.name = framework;
            details.label = framework;

            Integer gapCount = [SELECT COUNT() FROM Compliance_Gap__c WHERE Framework__c = :framework WITH USER_MODE];
            details.metadata = new Map<String, Object>{
                'gapCount' => gapCount,
                'color' => FRAMEWORK_COLORS.get(framework)
            };
        } else if (nodeType == 'policy') {
            String policyName = nodeId.replace('policy-', '');
            List<Compliance_Policy__mdt> policies = [
                SELECT Label, Description__c, Risk_Category__c, Framework__c
                FROM Compliance_Policy__mdt
                WHERE DeveloperName = :policyName
                LIMIT 1
            ];

            if (!policies.isEmpty()) {
                details.name = policies[0].Label;
                details.label = policies[0].Label;
                details.metadata = new Map<String, Object>{
                    'description' => policies[0].Description__c,
                    'riskCategory' => policies[0].Risk_Category__c,
                    'framework' => policies[0].Framework__c
                };
            }
        } else if (nodeType == 'gap') {
            String gapId = nodeId.replace('gap-', '');
            List<Compliance_Gap__c> gaps = [
                SELECT Id, Name, Framework__c, Severity__c, Status__c, Gap_Description__c,
                       Risk_Score__c, Entity_Type__c, Entity_Id__c, Target_Remediation_Date__c
                FROM Compliance_Gap__c
                WHERE Id = :gapId
                WITH USER_MODE
                LIMIT 1
            ];

            if (!gaps.isEmpty()) {
                Compliance_Gap__c gap = gaps[0];
                details.name = gap.Name;
                details.label = gap.Name;
                details.metadata = new Map<String, Object>{
                    'framework' => gap.Framework__c,
                    'severity' => gap.Severity__c,
                    'status' => gap.Status__c,
                    'description' => gap.Gap_Description__c,
                    'riskScore' => gap.Risk_Score__c,
                    'entityType' => gap.Entity_Type__c,
                    'entityId' => gap.Entity_Id__c,
                    'targetDate' => gap.Target_Remediation_Date__c
                };
            }
        }

        return details;
    }

    // ============================================
    // Private Helper Methods
    // ============================================

    private static List<Compliance_Gap__c> getGapsForGraph() {
        return [
            SELECT Id, Name, Framework__c, Severity__c, Status__c, Risk_Score__c,
                   Gap_Description__c, Policy_Reference__c, Entity_Type__c, Entity_Id__c
            FROM Compliance_Gap__c
            WITH USER_MODE
            ORDER BY Framework__c, Severity__c
            LIMIT 500
        ];
    }

    private static List<Compliance_Gap__c> getGapsForFramework(String framework) {
        return [
            SELECT Id, Name, Framework__c, Severity__c, Status__c, Risk_Score__c,
                   Gap_Description__c, Policy_Reference__c, Entity_Type__c, Entity_Id__c
            FROM Compliance_Gap__c
            WHERE Framework__c = :framework
            WITH USER_MODE
            ORDER BY Severity__c
            LIMIT 200
        ];
    }

    private static Map<String, List<Compliance_Policy__mdt>> getPoliciesByFramework() {
        Map<String, List<Compliance_Policy__mdt>> result = new Map<String, List<Compliance_Policy__mdt>>();

        for (Compliance_Policy__mdt policy : [SELECT DeveloperName, Label, Framework__c, Description__c, Risk_Category__c
                                               FROM Compliance_Policy__mdt]) {
            if (!result.containsKey(policy.Framework__c)) {
                result.put(policy.Framework__c, new List<Compliance_Policy__mdt>());
            }
            result.get(policy.Framework__c).add(policy);
        }

        return result;
    }

    private static List<Compliance_Policy__mdt> getPoliciesForFramework(String framework) {
        return [SELECT DeveloperName, Label, Framework__c, Description__c, Risk_Category__c
                FROM Compliance_Policy__mdt
                WHERE Framework__c = :framework];
    }

    private static GraphNode createFrameworkNode(String framework) {
        GraphNode node = new GraphNode();
        node.id = 'framework-' + framework;
        node.label = framework;
        node.nodeType = 'framework';
        node.size = 40;
        node.color = FRAMEWORK_COLORS.containsKey(framework) ? FRAMEWORK_COLORS.get(framework) : '#757575';
        node.metadata = new Map<String, Object>{
            'framework' => framework
        };
        return node;
    }

    private static GraphNode createPolicyNode(Compliance_Policy__mdt policy) {
        GraphNode node = new GraphNode();
        node.id = 'policy-' + policy.DeveloperName;
        node.label = policy.Label;
        node.nodeType = 'policy';
        node.size = 25;
        node.color = '#607D8B';
        node.metadata = new Map<String, Object>{
            'framework' => policy.Framework__c,
            'riskCategory' => policy.Risk_Category__c,
            'description' => policy.Description__c
        };
        return node;
    }

    private static GraphNode createGapNode(Compliance_Gap__c gap) {
        GraphNode node = new GraphNode();
        node.id = 'gap-' + gap.Id;
        node.label = gap.Name;
        node.nodeType = 'gap';
        node.size = getSeveritySize(gap.Severity__c);
        node.color = SEVERITY_COLORS.containsKey(gap.Severity__c) ? SEVERITY_COLORS.get(gap.Severity__c) : '#9E9E9E';
        node.metadata = new Map<String, Object>{
            'severity' => gap.Severity__c,
            'status' => gap.Status__c,
            'riskScore' => gap.Risk_Score__c,
            'framework' => gap.Framework__c
        };
        return node;
    }

    private static GraphNode createEntityNode(String entityType, String entityId) {
        GraphNode node = new GraphNode();
        node.id = 'entity-' + entityType + '-' + entityId;
        node.label = entityType + ': ' + entityId.abbreviate(15);
        node.nodeType = 'entity';
        node.size = 20;
        node.color = '#9C27B0';
        node.metadata = new Map<String, Object>{
            'entityType' => entityType,
            'entityId' => entityId
        };
        return node;
    }

    private static Integer getSeveritySize(String severity) {
        Map<String, Integer> sizes = new Map<String, Integer>{
            'CRITICAL' => 30,
            'HIGH' => 25,
            'MEDIUM' => 20,
            'LOW' => 15
        };
        return sizes.containsKey(severity) ? sizes.get(severity) : 18;
    }

    private static Integer getSeverityWeight(String severity) {
        Map<String, Integer> weights = new Map<String, Integer>{
            'CRITICAL' => 4,
            'HIGH' => 3,
            'MEDIUM' => 2,
            'LOW' => 1
        };
        return weights.containsKey(severity) ? weights.get(severity) : 1;
    }

    private static Decimal getSeverityRiskScore(String severity) {
        Map<String, Decimal> scores = new Map<String, Decimal>{
            'CRITICAL' => 9.0,
            'HIGH' => 7.0,
            'MEDIUM' => 5.0,
            'LOW' => 3.0
        };
        return scores.containsKey(severity) ? scores.get(severity) : 5.0;
    }

    // ============================================
    // Inner Classes
    // ============================================

    /**
     * @description Complete graph data structure
     */
    public class GraphData {
        @AuraEnabled public List<GraphNode> nodes;
        @AuraEnabled public List<GraphEdge> edges;
    }

    /**
     * @description Graph node representation
     */
    public class GraphNode {
        @AuraEnabled public String id;
        @AuraEnabled public String label;
        @AuraEnabled public String nodeType;
        @AuraEnabled public Integer size;
        @AuraEnabled public String color;
        @AuraEnabled public Map<String, Object> metadata;
    }

    /**
     * @description Graph edge representation
     */
    public class GraphEdge {
        @AuraEnabled public String source;
        @AuraEnabled public String target;
        @AuraEnabled public String edgeType;
        @AuraEnabled public Integer weight;

        public GraphEdge(String source, String target, String edgeType, Integer weight) {
            this.source = source;
            this.target = target;
            this.edgeType = edgeType;
            this.weight = weight;
        }
    }

    /**
     * @description Impact analysis result
     */
    public class ImpactAnalysis {
        @AuraEnabled public String entityType;
        @AuraEnabled public String entityId;
        @AuraEnabled public List<AffectedGap> affectedGaps;
        @AuraEnabled public Set<String> affectedFrameworks;
        @AuraEnabled public Decimal riskScore;
        @AuraEnabled public Integer totalGaps;
        @AuraEnabled public Integer criticalCount;
        @AuraEnabled public Integer highCount;
        @AuraEnabled public Integer mediumCount;
        @AuraEnabled public Integer lowCount;
    }

    /**
     * @description Affected gap in impact analysis
     */
    public class AffectedGap {
        @AuraEnabled public Id gapId;
        @AuraEnabled public String gapName;
        @AuraEnabled public String framework;
        @AuraEnabled public String severity;
        @AuraEnabled public String status;
        @AuraEnabled public Decimal riskScore;
    }

    /**
     * @description Graph statistics summary
     */
    public class GraphStats {
        @AuraEnabled public Integer totalGaps;
        @AuraEnabled public Integer totalFrameworks;
        @AuraEnabled public Integer totalEntities;
        @AuraEnabled public Map<String, Integer> frameworkCounts;
        @AuraEnabled public Map<String, Integer> severityCounts;
        @AuraEnabled public Map<String, Integer> statusCounts;
    }

    /**
     * @description Node detail information
     */
    public class NodeDetails {
        @AuraEnabled public String nodeId;
        @AuraEnabled public String nodeType;
        @AuraEnabled public String name;
        @AuraEnabled public String label;
        @AuraEnabled public Map<String, Object> metadata;
    }
}
