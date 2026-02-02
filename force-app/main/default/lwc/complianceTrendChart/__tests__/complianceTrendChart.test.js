/**
 * Jest tests for complianceTrendChart LWC component
 *
 * Tests cover:
 * - Chart data formatting
 * - Data display
 * - Loading and error states via DOM
 */

import { createElement } from "lwc";
import ComplianceTrendChart from "c/complianceTrendChart";

// Helper to wait for multiple microtasks
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

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
    await flushPromises();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: [],
      });
      await flushPromises();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Chart Data Display", () => {
    it("renders chart container when data exists", async () => {
      const mockData = [
        { date: "2025-01-01", score: 85 },
        { date: "2025-02-01", score: 87 },
        { date: "2025-03-01", score: 90 },
      ];

      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: mockData,
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      // Check that chart container is rendered
      const chartContainer = element.shadowRoot.querySelector(".chart-container");
      expect(chartContainer).not.toBeNull();

      // Check that canvas element exists
      const canvas = element.shadowRoot.querySelector("canvas");
      expect(canvas).not.toBeNull();
    });

    it("does not render chart container when data is empty", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: [],
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      const chartContainer = element.shadowRoot.querySelector(".chart-container");
      expect(chartContainer).toBeNull();
    });
  });

  describe("State Management via DOM", () => {
    it("shows chart canvas when data exists and not loading", async () => {
      const element = await createComponent({
        data: [{ date: "2025-01-01", score: 85 }],
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      const canvas = element.shadowRoot.querySelector("canvas");
      expect(canvas).not.toBeNull();
    });

    it("shows empty message when data is empty and not loading", async () => {
      const element = await createComponent({
        data: [],
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      const emptyMessage = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(emptyMessage).not.toBeNull();
      expect(emptyMessage.textContent).toContain("No trend data available");
    });

    it("does not show loading spinner in default state", async () => {
      // Note: isLoading is @track (private), defaults to false
      const element = await createComponent({
        data: [],
      });
      await flushPromises();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();
    });

    it("does not show error message in default state", async () => {
      // Note: hasError is @track (private), defaults to false
      const element = await createComponent({
        data: [],
      });
      await flushPromises();

      // Error messages should not appear in default state
      const errorIcon = element.shadowRoot.querySelector(
        "lightning-icon[icon-name='utility:error']"
      );
      expect(errorIcon).toBeNull();
    });
  });

  describe("Chart Configuration", () => {
    it("renders canvas with data attribute", async () => {
      const mockData = [
        { date: "2025-01-01", score: 85 },
        { date: "2025-02-01", score: 87 },
      ];

      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: mockData,
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      const canvas = element.shadowRoot.querySelector("canvas");
      expect(canvas).not.toBeNull();
      // The canvas should have data-chart-data attribute bound to chartData
      expect(canvas.hasAttribute("data-chart-data")).toBe(true);
    });
  });

  describe("Multiple Data Points", () => {
    it("handles multiple data points correctly", async () => {
      const mockData = [
        { date: "2025-01-01", score: 70 },
        { date: "2025-02-01", score: 75 },
        { date: "2025-03-01", score: 80 },
        { date: "2025-04-01", score: 85 },
        { date: "2025-05-01", score: 90 },
      ];

      const element = await createComponent({
        framework: { framework: "SOC2" },
        data: mockData,
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      // Chart should be rendered with data
      const canvas = element.shadowRoot.querySelector("canvas");
      expect(canvas).not.toBeNull();
    });
  });

  describe("Framework Display", () => {
    it("renders component with different framework", async () => {
      const mockData = [{ date: "2025-01-01", score: 85 }];

      const element = await createComponent({
        framework: { framework: "HIPAA" },
        data: mockData,
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });
});
