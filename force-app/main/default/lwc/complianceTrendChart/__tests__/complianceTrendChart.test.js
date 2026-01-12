/**
 * Jest tests for complianceTrendChart LWC component
 *
 * Tests cover:
 * - Chart data formatting
 * - Data display
 * - Loading and error states
 */

import { createElement } from "lwc";
import ComplianceTrendChart from "c/complianceTrendChart";

describe("c-compliance-trend-chart", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-compliance-trend-chart", {
      is: ComplianceTrendChart,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: [],
      });
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Chart Data", () => {
    it("formats chart data correctly", async () => {
      const mockData = [
        { date: "2025-01-01", score: 85 },
        { date: "2025-02-01", score: 87 },
        { date: "2025-03-01", score: 90 },
      ];

      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: mockData,
      });
      await Promise.resolve();

      const chartData = element.chartData;
      expect(chartData).toBeDefined();
      expect(chartData.labels).toEqual(["2025-01-01", "2025-02-01", "2025-03-01"]);
      expect(chartData.datasets).toBeDefined();
      expect(chartData.datasets[0].data).toEqual([85, 87, 90]);
    });

    it("handles empty data array", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: [],
      });
      await Promise.resolve();

      const chartData = element.chartData;
      expect(chartData.labels).toEqual([]);
      expect(chartData.datasets[0].data).toEqual([]);
    });
  });

  describe("State Management", () => {
    it("hasData returns true when data exists", async () => {
      const element = await createComponent({
        data: [{ date: "2025-01-01", score: 85 }],
      });
      await Promise.resolve();

      expect(element.hasData).toBe(true);
    });

    it("hasData returns false when data is empty", async () => {
      const element = await createComponent({ data: [] });
      await Promise.resolve();

      expect(element.hasData).toBe(false);
    });

    it("isEmpty returns true when no data and not loading", async () => {
      const element = await createComponent({
        data: [],
        isLoading: false,
        hasError: false,
      });
      await Promise.resolve();

      expect(element.isEmpty).toBe(true);
    });

    it("notLoading returns true when not loading", async () => {
      const element = await createComponent({ isLoading: false });
      await Promise.resolve();

      expect(element.notLoading).toBe(true);
    });

    it("notError returns true when no error", async () => {
      const element = await createComponent({ hasError: false });
      await Promise.resolve();

      expect(element.notError).toBe(true);
    });
  });
});
