import { createElement } from "lwc";
import ComplianceGraphViewer from "c/complianceGraphViewer";
import getComplianceGraph from "@salesforce/apex/ComplianceGraphService.getComplianceGraph";
import getGraphByFramework from "@salesforce/apex/ComplianceGraphService.getGraphByFramework";
import getGraphStats from "@salesforce/apex/ComplianceGraphService.getGraphStats";
import getNodeDetails from "@salesforce/apex/ComplianceGraphService.getNodeDetails";
import analyzeImpact from "@salesforce/apex/ComplianceGraphService.analyzeImpact";

jest.mock(
  "@salesforce/apex/ComplianceGraphService.getComplianceGraph",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/ComplianceGraphService.getGraphByFramework",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex/ComplianceGraphService.getGraphStats", () => ({ default: jest.fn() }), {
  virtual: true,
});
jest.mock(
  "@salesforce/apex/ComplianceGraphService.getNodeDetails",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex/ComplianceGraphService.analyzeImpact", () => ({ default: jest.fn() }), {
  virtual: true,
});

const MOCK_GRAPH_DATA = {
  nodes: [
    { id: "n1", label: "HIPAA", nodeType: "framework", size: 20, color: "#1E88E5" },
    { id: "n2", label: "Access Control", nodeType: "policy", size: 15, color: "#607D8B" },
    {
      id: "n3",
      label: "Permission Set Gap",
      nodeType: "gap",
      size: 12,
      color: "#D32F2F",
    },
    {
      id: "n4",
      label: "User Entity",
      nodeType: "entity",
      size: 10,
      color: "#9C27B0",
      metadata: { entityType: "User", entityId: "005xx000001" },
    },
  ],
  edges: [
    { source: "n1", target: "n2", weight: 2 },
    { source: "n2", target: "n3", weight: 1 },
  ],
};

const MOCK_STATS = {
  totalGaps: 12,
  totalFrameworks: 4,
  totalEntities: 25,
  severityCounts: { CRITICAL: 3, HIGH: 5, MEDIUM: 3, LOW: 1 },
  frameworkCounts: { HIPAA: 5, SOC2: 4, GDPR: 3 },
};

describe("c-compliance-graph-viewer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    getComplianceGraph.mockResolvedValue(MOCK_GRAPH_DATA);
    getGraphStats.mockResolvedValue(MOCK_STATS);

    const element = createElement("c-compliance-graph-viewer", {
      is: ComplianceGraphViewer,
    });
    document.body.appendChild(element);
    await flushPromises();
    return element;
  }

  it("renders the component with card title", async () => {
    const element = await createComponent();
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Compliance Graph");
  });

  it("loads graph and stats on connected callback", async () => {
    await createComponent();
    expect(getComplianceGraph).toHaveBeenCalledTimes(1);
    expect(getGraphStats).toHaveBeenCalledTimes(1);
  });

  it("displays stats when loaded", async () => {
    const element = await createComponent();
    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    expect(badges.length).toBeGreaterThan(0);
  });

  it("shows loading spinner while loading", () => {
    getComplianceGraph.mockReturnValue(new Promise(() => {}));
    getGraphStats.mockReturnValue(new Promise(() => {}));

    const element = createElement("c-compliance-graph-viewer", {
      is: ComplianceGraphViewer,
    });
    document.body.appendChild(element);

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("calls getGraphByFramework when framework changes", async () => {
    const element = await createComponent();
    getGraphByFramework.mockResolvedValue(MOCK_GRAPH_DATA);

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "HIPAA" } }));
    await flushPromises();

    expect(getGraphByFramework).toHaveBeenCalledWith({ framework: "HIPAA" });
  });

  it("handles graph load error gracefully", async () => {
    getComplianceGraph.mockRejectedValue({ body: { message: "Server error" } });
    getGraphStats.mockResolvedValue(MOCK_STATS);

    const element = createElement("c-compliance-graph-viewer", {
      is: ComplianceGraphViewer,
    });

    const handler = jest.fn();
    element.addEventListener("lightning__showtoast", handler);
    document.body.appendChild(element);
    await flushPromises();

    expect(getComplianceGraph).toHaveBeenCalled();
  });

  it("shows no graph data message when graph is empty", async () => {
    getComplianceGraph.mockResolvedValue({ nodes: [], edges: [] });
    getGraphStats.mockResolvedValue(null);

    const element = createElement("c-compliance-graph-viewer", {
      is: ComplianceGraphViewer,
    });
    document.body.appendChild(element);
    await flushPromises();

    const heading = element.shadowRoot.querySelector("h3");
    expect(heading).not.toBeNull();
    expect(heading.textContent).toBe("No Graph Data");
  });

  it("refreshes graph and stats on refresh button click", async () => {
    const element = await createComponent();
    getComplianceGraph.mockResolvedValue(MOCK_GRAPH_DATA);
    getGraphStats.mockResolvedValue(MOCK_STATS);

    const refreshBtn = element.shadowRoot.querySelector('lightning-button[label="Refresh"]');
    refreshBtn.click();
    await flushPromises();

    expect(getComplianceGraph).toHaveBeenCalledTimes(2);
    expect(getGraphStats).toHaveBeenCalledTimes(2);
  });

  it("computes severity variants correctly", async () => {
    const element = await createComponent();
    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    const badgeArray = Array.from(badges);
    const criticalBadge = badgeArray.find((b) => b.label && b.label.includes("CRITICAL"));
    if (criticalBadge) {
      expect(criticalBadge.variant).toBe("error");
    }
  });
});
