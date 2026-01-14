/**
 * Jest tests for riskHeatmap LWC component
 *
 * Tests cover:
 * - Risk matrix generation
 * - Risk class assignment
 * - State management
 */

import { createElement } from "lwc";
import RiskHeatmap from "c/riskHeatmap";

describe("c-risk-heatmap", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-risk-heatmap", {
      is: RiskHeatmap,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Risk Display", () => {
    it("displays risk items when risks are provided", async () => {
      const risks = [
        { id: "r1", framework: "SOC2", severity: "CRITICAL", score: 9 },
        { id: "r2", framework: "SOC2", severity: "HIGH", score: 7 },
        { id: "r3", framework: "HIPAA", severity: "CRITICAL", score: 8 },
      ];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // Check that risk items are rendered in the DOM
      const riskItems = element.shadowRoot.querySelectorAll('[role="listitem"]');
      expect(riskItems.length).toBe(3);
    });

    it("handles empty risks array", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      // No risk items should be rendered
      const riskItems = element.shadowRoot.querySelectorAll('[role="listitem"]');
      expect(riskItems.length).toBe(0);
    });

    it("displays multiple risks with same framework and severity", async () => {
      const risks = [
        { id: "r1", framework: "SOC2", severity: "CRITICAL", score: 9 },
        { id: "r2", framework: "SOC2", severity: "CRITICAL", score: 8 },
        { id: "r3", framework: "SOC2", severity: "CRITICAL", score: 9.5 },
      ];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // All 3 risks should be rendered
      const riskItems = element.shadowRoot.querySelectorAll('[role="listitem"]');
      expect(riskItems.length).toBe(3);
    });
  });

  describe("Risk Classes", () => {
    it("assigns risk-critical class for CRITICAL severity", async () => {
      const risks = [{ id: "r1", framework: "SOC2", severity: "CRITICAL", score: 9 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // Check that risk-critical class is applied
      const criticalBox = element.shadowRoot.querySelector(".risk-critical");
      expect(criticalBox).not.toBeNull();
    });

    it("assigns risk-high class for HIGH severity", async () => {
      const risks = [{ id: "r1", framework: "SOC2", severity: "HIGH", score: 7 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // Check that risk-high class is applied
      const highBox = element.shadowRoot.querySelector(".risk-high");
      expect(highBox).not.toBeNull();
    });

    it("assigns risk-medium class for MEDIUM severity", async () => {
      const risks = [{ id: "r1", framework: "SOC2", severity: "MEDIUM", score: 5 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // Check that risk-medium class is applied
      const mediumBox = element.shadowRoot.querySelector(".risk-medium");
      expect(mediumBox).not.toBeNull();
    });

    it("assigns risk-low class for LOW severity", async () => {
      const risks = [{ id: "r1", framework: "SOC2", severity: "LOW", score: 2 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      // Check that risk-low class is applied
      const lowBox = element.shadowRoot.querySelector(".risk-low");
      expect(lowBox).not.toBeNull();
    });

    it("handles empty risks array with no classes", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      // No risk boxes should be rendered
      const sldcBoxes = element.shadowRoot.querySelectorAll(".slds-box");
      expect(sldcBoxes.length).toBe(0);
    });
  });

  describe("State Management", () => {
    it("shows risk grid when risks exist", async () => {
      const element = await createComponent({
        risks: [{ id: "r1", framework: "SOC2", severity: "HIGH", score: 7 }],
      });
      await Promise.resolve();

      // Grid should be visible
      const grid = element.shadowRoot.querySelector('[role="list"]');
      expect(grid).not.toBeNull();
    });

    it("shows no risks message when risks are empty", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      // "No risk data available" message should be shown
      const noRisksMessage = element.shadowRoot.querySelector('[role="status"]');
      expect(noRisksMessage).not.toBeNull();
      expect(noRisksMessage.textContent).toContain("No risk data available");
    });

    it("hides no risks message when risks exist", async () => {
      const element = await createComponent({
        risks: [{ id: "r1", framework: "SOC2", severity: "HIGH", score: 7 }],
      });
      await Promise.resolve();

      // "No risk data available" status should not be rendered
      const noRisksMessage = element.shadowRoot.querySelector('[role="status"]');
      expect(noRisksMessage).toBeNull();
    });

    it("displays framework name in risk box", async () => {
      const element = await createComponent({
        risks: [{ id: "r1", framework: "SOC2", severity: "HIGH", score: 7 }],
      });
      await Promise.resolve();

      // Check framework name is displayed
      const frameworkText = element.shadowRoot.querySelector(".slds-text-heading_small");
      expect(frameworkText).not.toBeNull();
      expect(frameworkText.textContent).toBe("SOC2");
    });
  });
});
