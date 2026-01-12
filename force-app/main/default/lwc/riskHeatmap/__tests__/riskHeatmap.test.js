/**
 * Jest tests for riskHeatmap LWC component
 *
 * Tests cover:
 * - Component rendering with risk data
 * - Risk severity class assignment
 * - Empty state handling
 * - Risk matrix organization
 */

import { createElement } from "lwc";
import RiskHeatmap from "c/riskHeatmap";

describe("c-risk-heatmap", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // Helper function to create element
  function createComponent(risks = []) {
    const element = createElement("c-risk-heatmap", {
      is: RiskHeatmap,
    });
    element.risks = risks;
    document.body.appendChild(element);
    return element;
  }

  // Test data
  const mockRisks = [
    { id: "risk001", framework: "SOC2", severity: "CRITICAL", score: 95 },
    { id: "risk002", framework: "HIPAA", severity: "HIGH", score: 75 },
    { id: "risk003", framework: "GDPR", severity: "MEDIUM", score: 50 },
    { id: "risk004", framework: "PCI-DSS", severity: "LOW", score: 25 },
  ];

  describe("Component Rendering", () => {
    it("should render lightning-card", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Risk Heatmap");
      expect(card.iconName).toBe("standard:warning");
    });

    it("should display risk items when risks provided", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(4);
    });

    it("should display framework name for each risk", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const headings = element.shadowRoot.querySelectorAll(
        ".slds-text-heading_small"
      );
      expect(headings).toHaveLength(4);
      expect(headings[0].textContent).toBe("SOC2");
      expect(headings[1].textContent).toBe("HIPAA");
      expect(headings[2].textContent).toBe("GDPR");
      expect(headings[3].textContent).toBe("PCI-DSS");
    });

    it("should display severity for each risk", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const severityDivs = element.shadowRoot.querySelectorAll(
        ".slds-box .slds-text-body_small"
      );
      expect(severityDivs[0].textContent).toBe("CRITICAL");
      expect(severityDivs[2].textContent).toBe("HIGH");
      expect(severityDivs[4].textContent).toBe("MEDIUM");
      expect(severityDivs[6].textContent).toBe("LOW");
    });

    it("should display score for each risk", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const scoreDivs = element.shadowRoot.querySelectorAll(
        ".slds-box .slds-text-body_small"
      );
      expect(scoreDivs[1].textContent).toBe("Score: 95");
      expect(scoreDivs[3].textContent).toBe("Score: 75");
      expect(scoreDivs[5].textContent).toBe("Score: 50");
      expect(scoreDivs[7].textContent).toBe("Score: 25");
    });
  });

  describe("Risk Severity Classes", () => {
    it("should apply risk-critical class for CRITICAL severity", async () => {
      const criticalRisk = [
        { id: "risk001", framework: "SOC2", severity: "CRITICAL", score: 95 },
      ];
      const element = createComponent(criticalRisk);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("risk-critical");
    });

    it("should apply risk-high class for HIGH severity", async () => {
      const highRisk = [
        { id: "risk001", framework: "HIPAA", severity: "HIGH", score: 75 },
      ];
      const element = createComponent(highRisk);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("risk-high");
    });

    it("should apply risk-medium class for MEDIUM severity", async () => {
      const mediumRisk = [
        { id: "risk001", framework: "GDPR", severity: "MEDIUM", score: 50 },
      ];
      const element = createComponent(mediumRisk);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("risk-medium");
    });

    it("should apply risk-low class for LOW severity", async () => {
      const lowRisk = [
        { id: "risk001", framework: "PCI-DSS", severity: "LOW", score: 25 },
      ];
      const element = createComponent(lowRisk);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("risk-low");
    });

    it("should apply risk-low class for unknown severity", async () => {
      const unknownRisk = [
        { id: "risk001", framework: "TEST", severity: "UNKNOWN", score: 10 },
      ];
      const element = createComponent(unknownRisk);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("risk-low");
    });
  });

  describe("Empty State", () => {
    it("should show empty message when no risks", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector("[role='status']");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No risk data available");
    });

    it("should not show risk grid when no risks", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const grid = element.shadowRoot.querySelector(".slds-grid[role='list']");
      expect(grid).toBeNull();
    });

    it("should have aria-live attribute for accessibility", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector("[role='status']");
      expect(emptyDiv.getAttribute("aria-live")).toBe("polite");
    });
  });

  describe("Accessibility", () => {
    it("should have role list on risk grid", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const grid = element.shadowRoot.querySelector(".slds-grid");
      expect(grid.getAttribute("role")).toBe("list");
    });

    it("should have aria-label on risk grid", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const grid = element.shadowRoot.querySelector(".slds-grid");
      expect(grid.getAttribute("aria-label")).toBe("Risk heatmap");
    });

    it("should have role listitem on risk items", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      const items = element.shadowRoot.querySelectorAll(".slds-col");
      items.forEach((item) => {
        expect(item.getAttribute("role")).toBe("listitem");
      });
    });
  });

  describe("Single Risk", () => {
    it("should display single risk correctly", async () => {
      const singleRisk = [mockRisks[0]];
      const element = createComponent(singleRisk);
      await Promise.resolve();

      const riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(1);

      const heading = element.shadowRoot.querySelector(".slds-text-heading_small");
      expect(heading.textContent).toBe("SOC2");
    });
  });

  describe("Multiple Risks", () => {
    it("should handle many risks", async () => {
      const manyRisks = [];
      for (let i = 0; i < 12; i++) {
        manyRisks.push({
          id: `risk${i}`,
          framework: `FW${i}`,
          severity: "MEDIUM",
          score: i * 8,
        });
      }
      const element = createComponent(manyRisks);
      await Promise.resolve();

      const riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(12);
    });
  });

  describe("Dynamic Updates", () => {
    it("should update when risks are changed", async () => {
      const element = createComponent([mockRisks[0]]);
      await Promise.resolve();

      let riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(1);

      // Update risks
      element.risks = mockRisks;
      await Promise.resolve();

      riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(4);
    });

    it("should show empty state when risks are cleared", async () => {
      const element = createComponent(mockRisks);
      await Promise.resolve();

      let riskItems = element.shadowRoot.querySelectorAll(".slds-col");
      expect(riskItems).toHaveLength(4);

      // Clear risks
      element.risks = [];
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector("[role='status']");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No risk data available");
    });
  });

  describe("Combined Class", () => {
    it("should have slds-box and slds-text-align_center in combined class", async () => {
      const element = createComponent([mockRisks[0]]);
      await Promise.resolve();

      const riskBox = element.shadowRoot.querySelector(".slds-box");
      expect(riskBox.className).toContain("slds-box");
      expect(riskBox.className).toContain("slds-text-align_center");
    });
  });
});
