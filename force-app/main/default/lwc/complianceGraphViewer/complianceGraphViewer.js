import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getComplianceGraph from "@salesforce/apex/ComplianceGraphService.getComplianceGraph";
import getGraphByFramework from "@salesforce/apex/ComplianceGraphService.getGraphByFramework";
import getGraphStats from "@salesforce/apex/ComplianceGraphService.getGraphStats";
import getNodeDetails from "@salesforce/apex/ComplianceGraphService.getNodeDetails";
import analyzeImpact from "@salesforce/apex/ComplianceGraphService.analyzeImpact";

const FRAMEWORK_OPTIONS = [
  { label: "All Frameworks", value: "ALL" },
  { label: "SOX", value: "SOX" },
  { label: "SOC 2", value: "SOC2" },
  { label: "HIPAA", value: "HIPAA" },
  { label: "GDPR", value: "GDPR" },
  { label: "CCPA", value: "CCPA" },
  { label: "PCI-DSS", value: "PCI_DSS" },
  { label: "NIST 800-53", value: "NIST" },
  { label: "ISO 27001", value: "ISO27001" },
];

export default class ComplianceGraphViewer extends LightningElement {
  @track graphData = null;
  @track stats = null;
  @track isLoading = true;
  @track selectedFramework = "ALL";
  @track selectedNode = null;
  @track nodeDetails = null;
  @track impactAnalysis = null;
  @track showDetailsPanel = false;
  @track showImpactPanel = false;

  frameworkOptions = FRAMEWORK_OPTIONS;
  simulation = null;
  svgWidth = 800;
  svgHeight = 600;

  get hasGraph() {
    return this.graphData && this.graphData.nodes && this.graphData.nodes.length > 0;
  }

  get statsForDisplay() {
    if (!this.stats) return [];
    return [
      { label: "Total Gaps", value: this.stats.totalGaps || 0, icon: "utility:warning" },
      {
        label: "Frameworks",
        value: this.stats.totalFrameworks || 0,
        icon: "utility:bundle_policy",
      },
      {
        label: "Entities",
        value: this.stats.totalEntities || 0,
        icon: "utility:component_customization",
      },
    ];
  }

  get severityStats() {
    if (!this.stats || !this.stats.severityCounts) return [];
    const severities = ["CRITICAL", "HIGH", "MEDIUM", "LOW"];
    return severities.map((s) => ({
      label: s,
      value: this.stats.severityCounts[s] || 0,
      variant: this.getSeverityVariant(s),
    }));
  }

  get frameworkStats() {
    if (!this.stats || !this.stats.frameworkCounts) return [];
    return Object.keys(this.stats.frameworkCounts).map((f) => ({
      label: f,
      value: this.stats.frameworkCounts[f],
    }));
  }

  get nodeTypeLabel() {
    if (!this.selectedNode) return "";
    const labels = {
      framework: "Framework",
      policy: "Policy",
      gap: "Compliance Gap",
      entity: "Entity",
    };
    return labels[this.selectedNode.nodeType] || this.selectedNode.nodeType;
  }

  get showImpactButton() {
    return this.selectedNode && this.selectedNode.nodeType === "entity";
  }

  connectedCallback() {
    this.loadStats();
    this.loadGraph();
  }

  async loadStats() {
    try {
      this.stats = await getGraphStats();
    } catch {
      // Stats loading failed silently - non-critical
    }
  }

  async loadGraph() {
    this.isLoading = true;
    try {
      if (this.selectedFramework === "ALL") {
        this.graphData = await getComplianceGraph();
      } else {
        this.graphData = await getGraphByFramework({ framework: this.selectedFramework });
      }
      this.renderGraph();
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleFrameworkChange(event) {
    this.selectedFramework = event.detail.value;
    this.loadGraph();
  }

  renderGraph() {
    if (!this.graphData || !this.graphData.nodes) return;

    // Get the container
    const container = this.template.querySelector(".graph-container");
    if (!container) return;

    // Clear previous content
    container.innerHTML = "";

    // Create SVG
    const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");
    svg.setAttribute("width", "100%");
    svg.setAttribute("height", "500");
    svg.setAttribute("viewBox", `0 0 ${this.svgWidth} ${this.svgHeight}`);

    // Create groups for edges and nodes
    const edgesGroup = document.createElementNS("http://www.w3.org/2000/svg", "g");
    edgesGroup.setAttribute("class", "edges");

    const nodesGroup = document.createElementNS("http://www.w3.org/2000/svg", "g");
    nodesGroup.setAttribute("class", "nodes");

    svg.appendChild(edgesGroup);
    svg.appendChild(nodesGroup);

    // Position nodes using simple force layout simulation
    const nodePositions = this.calculateNodePositions();

    // Draw edges
    this.graphData.edges.forEach((edge) => {
      const sourcePos = nodePositions[edge.source];
      const targetPos = nodePositions[edge.target];

      if (sourcePos && targetPos) {
        const line = document.createElementNS("http://www.w3.org/2000/svg", "line");
        line.setAttribute("x1", sourcePos.x);
        line.setAttribute("y1", sourcePos.y);
        line.setAttribute("x2", targetPos.x);
        line.setAttribute("y2", targetPos.y);
        line.setAttribute("stroke", "#ccc");
        line.setAttribute("stroke-width", Math.max(1, edge.weight * 0.5));
        line.setAttribute("opacity", "0.6");
        edgesGroup.appendChild(line);
      }
    });

    // Draw nodes
    this.graphData.nodes.forEach((node) => {
      const pos = nodePositions[node.id];
      if (!pos) return;

      const group = document.createElementNS("http://www.w3.org/2000/svg", "g");
      group.setAttribute("class", "node");
      group.setAttribute("transform", `translate(${pos.x}, ${pos.y})`);
      group.style.cursor = "pointer";

      // Node circle
      const circle = document.createElementNS("http://www.w3.org/2000/svg", "circle");
      circle.setAttribute("r", node.size || 15);
      circle.setAttribute("fill", node.color || "#1E88E5");
      circle.setAttribute("stroke", "#fff");
      circle.setAttribute("stroke-width", "2");

      // Node label
      const text = document.createElementNS("http://www.w3.org/2000/svg", "text");
      text.setAttribute("dy", node.size + 12);
      text.setAttribute("text-anchor", "middle");
      text.setAttribute("font-size", "10");
      text.setAttribute("fill", "#333");
      text.textContent = node.label.substring(0, 15);

      group.appendChild(circle);
      group.appendChild(text);

      // Add click handler
      group.addEventListener("click", () => this.handleNodeClick(node));

      nodesGroup.appendChild(group);
    });

    container.appendChild(svg);
  }

  calculateNodePositions() {
    const positions = {};
    const nodes = this.graphData.nodes;
    const centerX = this.svgWidth / 2;
    const centerY = this.svgHeight / 2;

    // Group nodes by type
    const nodesByType = {
      framework: [],
      policy: [],
      gap: [],
      entity: [],
    };

    nodes.forEach((node) => {
      if (nodesByType[node.nodeType]) {
        nodesByType[node.nodeType].push(node);
      }
    });

    // Position frameworks in inner circle
    const frameworkRadius = 100;
    nodesByType.framework.forEach((node, i) => {
      const angle = (2 * Math.PI * i) / Math.max(1, nodesByType.framework.length);
      positions[node.id] = {
        x: centerX + frameworkRadius * Math.cos(angle),
        y: centerY + frameworkRadius * Math.sin(angle),
      };
    });

    // Position policies in middle ring
    const policyRadius = 200;
    nodesByType.policy.forEach((node, i) => {
      const angle = (2 * Math.PI * i) / Math.max(1, nodesByType.policy.length);
      positions[node.id] = {
        x: centerX + policyRadius * Math.cos(angle),
        y: centerY + policyRadius * Math.sin(angle),
      };
    });

    // Position gaps in outer ring
    const gapRadius = 280;
    nodesByType.gap.forEach((node, i) => {
      const angle = (2 * Math.PI * i) / Math.max(1, nodesByType.gap.length);
      // Add some randomness to avoid overlap
      const jitter = Math.random() * 20 - 10;
      positions[node.id] = {
        x: centerX + (gapRadius + jitter) * Math.cos(angle),
        y: centerY + (gapRadius + jitter) * Math.sin(angle),
      };
    });

    // Position entities around edges
    nodesByType.entity.forEach((node, i) => {
      const angle = (2 * Math.PI * i) / Math.max(1, nodesByType.entity.length);
      const radius = 350;
      positions[node.id] = {
        x: centerX + radius * Math.cos(angle),
        y: centerY + radius * Math.sin(angle),
      };
    });

    return positions;
  }

  async handleNodeClick(node) {
    this.selectedNode = node;
    this.showDetailsPanel = true;
    this.showImpactPanel = false;

    try {
      this.nodeDetails = await getNodeDetails({
        nodeId: node.id,
        nodeType: node.nodeType,
      });
    } catch {
      // Node details loading failed silently
    }
  }

  async handleAnalyzeImpact() {
    if (!this.selectedNode || this.selectedNode.nodeType !== "entity") return;

    this.isLoading = true;
    try {
      const entityType = this.selectedNode.metadata.entityType;
      const entityId = this.selectedNode.metadata.entityId;

      this.impactAnalysis = await analyzeImpact({
        entityType: entityType,
        entityId: entityId,
      });
      this.showImpactPanel = true;
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  closeDetailsPanel() {
    this.showDetailsPanel = false;
    this.selectedNode = null;
    this.nodeDetails = null;
  }

  closeImpactPanel() {
    this.showImpactPanel = false;
    this.impactAnalysis = null;
  }

  handleRefresh() {
    this.loadStats();
    this.loadGraph();
  }

  getSeverityVariant(severity) {
    const variants = {
      CRITICAL: "error",
      HIGH: "warning",
      MEDIUM: "warning",
      LOW: "success",
    };
    return variants[severity] || "default";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    const message = error.body?.message || error.message || "An error occurred";
    this.showToast("Error", message, "error");
  }
}
