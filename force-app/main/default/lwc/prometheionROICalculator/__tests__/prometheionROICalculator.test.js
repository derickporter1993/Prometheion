/**
 * Jest tests for prometheionROICalculator LWC component
 *
 * Tests cover:
 * - ROI calculation
 * - Industry defaults
 * - Input handlers
 * - Results display
 */

import { createElement } from "lwc";
import PrometheionROICalculator from "c/prometheionROICalculator";

describe("c-prometheion-roi-calculator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-prometheion-roi-calculator", {
      is: PrometheionROICalculator,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("ROI Calculation", () => {
    it("calculates ROI correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.industry = "healthcare";
      element.orgSize = 500;
      element.currentAuditPrepHours = 600;
      element.currentAuditSpend = 150000;
      element.hourlyRate = 200;

      element.calculateROI();
      await Promise.resolve();

      expect(element.roiResults).not.toBeNull();
      expect(element.showResults).toBe(true);
    });

    it("updates defaults when industry changes", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "finance" },
      });

      element.handleIndustryChange(event);
      await Promise.resolve();

      expect(element.industry).toBe("finance");
      expect(element.currentAuditPrepHours).toBe(500);
      expect(element.currentAuditSpend).toBe(120000);
    });
  });

  describe("Input Handlers", () => {
    it("handles org size change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "1000" },
      });

      element.handleOrgSizeChange(event);

      expect(element.orgSize).toBe(1000);
    });

    it("handles audit spend change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "200000" },
      });

      element.handleAuditSpendChange(event);

      expect(element.currentAuditSpend).toBe(200000);
    });

    it("handles hours change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "800" },
      });

      element.handleHoursChange(event);

      expect(element.currentAuditPrepHours).toBe(800);
    });

    it("handles rate change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "250" },
      });

      element.handleRateChange(event);

      expect(element.hourlyRate).toBe(250);
    });
  });

  describe("State Management", () => {
    it("isEmpty returns true when no results", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element.isEmpty).toBe(true);
    });

    it("isEmpty returns false when results exist", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.calculateROI();
      await Promise.resolve();

      expect(element.isEmpty).toBe(false);
    });
  });
});
