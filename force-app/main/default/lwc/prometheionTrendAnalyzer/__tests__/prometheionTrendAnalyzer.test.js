/**
 * Jest tests for prometheionTrendAnalyzer LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Form input handling
 * - Trend analysis execution
 * - Results display
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionTrendAnalyzer from "c/prometheionTrendAnalyzer";
import getTimeSeries from "@salesforce/apex/PrometheionTrendController.getTimeSeries";
import getDateFields from "@salesforce/apex/PrometheionTrendController.getDateFields";
import getMetricFields from "@salesforce/apex/PrometheionTrendController.getMetricFields";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockDateFieldsCallbacks = new Set();
let mockMetricFieldsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionTrendController.getDateFields",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockDateFieldsCallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockDateFieldsCallbacks.delete(callback);
          },
          update: () => {},
        };
      }
      return Promise.resolve([]);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionTrendController.getMetricFields",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockMetricFieldsCallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockMetricFieldsCallbacks.delete(callback);
          },
          update: () => {},
        };
      }
      return Promise.resolve([]);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionTrendController.getTimeSeries",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

const emitDateFields = (data) => {
  mockDateFieldsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitMetricFields = (data) => {
  mockMetricFieldsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

describe("c-prometheion-trend-analyzer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockDateFieldsCallbacks = new Set();
    mockMetricFieldsCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-trend-analyzer", {
      is: PrometheionTrendAnalyzer,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("loads date fields when object is selected", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const mockDateFields = [
        { label: "Created Date", apiName: "CreatedDate" },
        { label: "Last Modified Date", apiName: "LastModifiedDate" },
      ];

      element.selectedObject = "Account";
      await Promise.resolve();

      emitDateFields(mockDateFields);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.dateFields.length).toBe(2);
      expect(element.dateFields[0].label).toBe("Created Date");
    });

    it("loads metric fields when object is selected", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const mockMetricFields = [
        { label: "Annual Revenue", apiName: "AnnualRevenue" },
        { label: "Number of Employees", apiName: "NumberOfEmployees" },
      ];

      element.selectedObject = "Account";
      await Promise.resolve();

      emitMetricFields(mockMetricFields);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.metricFields.length).toBe(2);
    });
  });

  describe("Input Handlers", () => {
    it("handles object change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "Account" },
      });

      element.handleObjectChange(event);

      expect(element.selectedObject).toBe("Account");
      expect(element.dateField).toBe("");
      expect(element.metricField).toBe("");
      expect(element.trendData).toBeNull();
    });

    it("handles date field change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "CreatedDate" },
      });

      element.handleDateFieldChange(event);

      expect(element.dateField).toBe("CreatedDate");
    });

    it("handles metric field change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "AnnualRevenue" },
      });

      element.handleMetricFieldChange(event);

      expect(element.metricField).toBe("AnnualRevenue");
    });

    it("handles granularity change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "week" },
      });

      element.handleGranularityChange(event);

      expect(element.granularity).toBe("week");
    });

    it("handles months back change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "24" },
      });

      element.handleMonthsBackChange(event);

      expect(element.monthsBack).toBe(24);
    });
  });

  describe("Analysis Execution", () => {
    it("executes trend analysis when canAnalyze is true", async () => {
      getTimeSeries.mockResolvedValue({
        buckets: [],
        total: 1000,
        average: 100,
        trendDirection: "up",
      });

      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "Account";
      element.dateField = "CreatedDate";
      element.metricField = "AnnualRevenue";
      element.granularity = "month";

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      element.handleAnalyze();
      await Promise.resolve();

      expect(getTimeSeries).toHaveBeenCalled();
      expect(element.isLoading).toBe(false);

      dispatchEventSpy.mockRestore();
    });

    it("does not execute when canAnalyze is false", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "";
      element.dateField = "";
      element.metricField = "";

      element.handleAnalyze();

      expect(getTimeSeries).not.toHaveBeenCalled();
    });
  });

  describe("Results Display", () => {
    it("displays trend results correctly", async () => {
      const mockResults = {
        buckets: [
          { bucketDate: "2025-01", metricValue: 100, changeFromPrevious: 10, percentChange: 10 },
          { bucketDate: "2025-02", metricValue: 110, changeFromPrevious: 10, percentChange: 9 },
        ],
        total: 210,
        average: 105,
        trendDirection: "up",
      };

      getTimeSeries.mockResolvedValue(mockResults);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "Account";
      element.dateField = "CreatedDate";
      element.metricField = "AnnualRevenue";
      element.granularity = "month";

      element.handleAnalyze();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasResults).toBe(true);
      expect(element.trendBuckets.length).toBe(2);
      expect(element.trendTotal).toBe("210.00");
      expect(element.trendAverage).toBe("105.00");
      expect(element.trendDirection).toBe("up");
    });
  });

  describe("Error Handling", () => {
    it("handles analysis error gracefully", async () => {
      const error = {
        body: { message: "Analysis failed" },
        message: "Analysis failed",
      };

      getTimeSeries.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "Account";
      element.dateField = "CreatedDate";
      element.metricField = "AnnualRevenue";
      element.granularity = "month";

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      element.handleAnalyze();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Error analyzing trend");
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });
  });
});
