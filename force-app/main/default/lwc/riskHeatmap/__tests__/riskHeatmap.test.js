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
    });
  });

  describe("Risk Matrix", () => {
    it("generates risk matrix correctly", async () => {
      const risks = [
        { framework: "SOC2", severity: "CRITICAL", score: 9 },
        { framework: "SOC2", severity: "HIGH", score: 7 },
        { framework: "HIPAA", severity: "CRITICAL", score: 8 },
      ];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const matrix = element.riskMatrix;
      expect(matrix["SOC2_CRITICAL"]).toBe(1);
      expect(matrix["SOC2_HIGH"]).toBe(1);
      expect(matrix["HIPAA_CRITICAL"]).toBe(1);
    });

    it("handles empty risks array", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      const matrix = element.riskMatrix;
      expect(Object.keys(matrix).length).toBe(0);
    });

    it("counts multiple risks with same key", async () => {
      const risks = [
        { framework: "SOC2", severity: "CRITICAL", score: 9 },
        { framework: "SOC2", severity: "CRITICAL", score: 8 },
        { framework: "SOC2", severity: "CRITICAL", score: 9.5 },
      ];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const matrix = element.riskMatrix;
      expect(matrix["SOC2_CRITICAL"]).toBe(3);
    });
  });

  describe("Risk Classes", () => {
    it("assigns risk-critical class for CRITICAL severity", async () => {
      const risks = [
        { framework: "SOC2", severity: "CRITICAL", score: 9 },
      ];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const risksWithClasses = element.risksWithClasses;
      expect(risksWithClasses[0].combinedClass).toContain("risk-critical");
    });

    it("assigns risk-high class for HIGH severity", async () => {
      const risks = [{ framework: "SOC2", severity: "HIGH", score: 7 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const risksWithClasses = element.risksWithClasses;
      expect(risksWithClasses[0].combinedClass).toContain("risk-high");
    });

    it("assigns risk-medium class for MEDIUM severity", async () => {
      const risks = [{ framework: "SOC2", severity: "MEDIUM", score: 5 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const risksWithClasses = element.risksWithClasses;
      expect(risksWithClasses[0].combinedClass).toContain("risk-medium");
    });

    it("assigns risk-low class for LOW severity", async () => {
      const risks = [{ framework: "SOC2", severity: "LOW", score: 2 }];

      const element = await createComponent({ risks });
      await Promise.resolve();

      const risksWithClasses = element.risksWithClasses;
      expect(risksWithClasses[0].combinedClass).toContain("risk-low");
    });

    it("handles empty risks array", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      expect(element.risksWithClasses).toEqual([]);
    });
  });

  describe("State Management", () => {
    it("hasRisks returns true when risks exist", async () => {
      const element = await createComponent({
        risks: [{ framework: "SOC2", severity: "HIGH", score: 7 }],
      });
      await Promise.resolve();

      expect(element.hasRisks).toBe(true);
    });

    it("hasRisks returns false when risks are empty", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      expect(element.hasRisks).toBe(false);
    });

    it("noRisks returns true when no risks", async () => {
      const element = await createComponent({ risks: [] });
      await Promise.resolve();

      expect(element.noRisks).toBe(true);
    });

    it("noRisks returns false when risks exist", async () => {
      const element = await createComponent({
        risks: [{ framework: "SOC2", severity: "HIGH", score: 7 }],
      });
      await Promise.resolve();

      expect(element.noRisks).toBe(false);
    });
  });
});
