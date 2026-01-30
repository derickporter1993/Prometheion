/**
 * Jest tests for elaroTrendAnalyzer LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Form input handling
 * - Trend analysis execution
 * - Results display
 * - Error handling
 */

import { createElement } from "lwc";
import ElaroTrendAnalyzer from "c/elaroTrendAnalyzer";
import getTimeSeries from "@salesforce/apex/ElaroTrendController.getTimeSeries";
import getDateFields from "@salesforce/apex/ElaroTrendController.getDateFields";
import getMetricFields from "@salesforce/apex/ElaroTrendController.getMetricFields";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockDateFieldsCallbacks = new Set();
let mockMetricFieldsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/ElaroTrendController.getDateFields",
  () => ({
    default: function MockDateFieldsAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockDateFieldsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockDateFieldsCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve([]);
    },
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ElaroTrendController.getMetricFields",
  () => ({
    default: function MockMetricFieldsAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockMetricFieldsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockMetricFieldsCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve([]);
    },
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ElaroTrendController.getTimeSeries",
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

describe("c-elaro-trend-analyzer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockDateFieldsCallbacks = new Set();
    mockMetricFieldsCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-elaro-trend-analyzer", {
      is: ElaroTrendAnalyzer,
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

    it("renders object selection combobox", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      expect(comboboxes.length).toBeGreaterThan(0);
    });

    it("renders analyze button", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const button = element.shadowRoot.querySelector("lightning-button");
      expect(button).not.toBeNull();
      expect(button.label).toBe("Analyze Trend");
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("populates date fields combobox when data is received", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const mockDateFields = [
        { label: "Created Date", apiName: "CreatedDate" },
        { label: "Last Modified Date", apiName: "LastModifiedDate" },
      ];

      emitDateFields(mockDateFields);
      await Promise.resolve();
      await Promise.resolve();

      // Date field combobox should have options
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      const dateFieldCombobox = Array.from(comboboxes).find(
        (cb) => cb.label === "Date Field"
      );
      expect(dateFieldCombobox).toBeDefined();
      expect(dateFieldCombobox.options.length).toBe(2);
    });

    it("populates metric fields combobox when data is received", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const mockMetricFields = [
        { label: "Annual Revenue", apiName: "AnnualRevenue" },
        { label: "Number of Employees", apiName: "NumberOfEmployees" },
      ];

      emitMetricFields(mockMetricFields);
      await Promise.resolve();
      await Promise.resolve();

      // Metric field combobox should have options
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      const metricFieldCombobox = Array.from(comboboxes).find(
        (cb) => cb.label === "Metric Field"
      );
      expect(metricFieldCombobox).toBeDefined();
      expect(metricFieldCombobox.options.length).toBe(2);
    });
  });

  describe("Input Handlers", () => {
    it("handles object change via combobox", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      const objectCombobox = Array.from(comboboxes).find(
        (cb) => cb.label === "Object"
      );

      objectCombobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "Account" },
        })
      );
      await Promise.resolve();

      // Verify the combobox value changed
      expect(objectCombobox.value).toBe("Account");
    });

    it("handles date field change via combobox", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      const dateFieldCombobox = Array.from(comboboxes).find(
        (cb) => cb.label === "Date Field"
      );

      dateFieldCombobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "CreatedDate" },
        })
      );
      await Promise.resolve();

      expect(dateFieldCombobox.value).toBe("CreatedDate");
    });

    it("handles granularity change via combobox", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      const granularityCombobox = Array.from(comboboxes).find(
        (cb) => cb.label === "Granularity"
      );

      granularityCombobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "week" },
        })
      );
      await Promise.resolve();

      expect(granularityCombobox.value).toBe("week");
    });

    it("handles months back change via input", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Find input by label property since attribute selectors don't work for LWC properties
      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      const monthsBackInput = Array.from(inputs).find((inp) => inp.label === "Months Back");
      expect(monthsBackInput).not.toBeNull();

      monthsBackInput.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "24" },
        })
      );
      await Promise.resolve();

      expect(monthsBackInput.value).toBe(24);
    });
  });

  describe("Analysis Execution", () => {
    it("calls getTimeSeries when analyze button is clicked with valid inputs", async () => {
      getTimeSeries.mockResolvedValue({
        buckets: [],
        total: 1000,
        average: 100,
        trendDirection: "up",
      });

      const element = await createComponent();
      await Promise.resolve();

      // Set up required inputs
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");

      const objectCombobox = Array.from(comboboxes).find((cb) => cb.label === "Object");
      objectCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));

      const dateFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Date Field");
      dateFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "CreatedDate" } }));

      const metricFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Metric Field");
      metricFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "AnnualRevenue" } }));

      await Promise.resolve();

      // Click analyze button
      const analyzeButton = element.shadowRoot.querySelector("lightning-button");
      analyzeButton.click();
      await Promise.resolve();
      await Promise.resolve();

      expect(getTimeSeries).toHaveBeenCalled();
    });

    it("does not call getTimeSeries when required fields are missing", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Do not set up required inputs - leave them empty
      const analyzeButton = element.shadowRoot.querySelector("lightning-button");
      analyzeButton.click();
      await Promise.resolve();

      expect(getTimeSeries).not.toHaveBeenCalled();
    });
  });

  describe("Results Display", () => {
    it("displays trend results after successful analysis", async () => {
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

      // Set up required inputs
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");

      const objectCombobox = Array.from(comboboxes).find((cb) => cb.label === "Object");
      objectCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));

      const dateFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Date Field");
      dateFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "CreatedDate" } }));

      const metricFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Metric Field");
      metricFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "AnnualRevenue" } }));

      await Promise.resolve();

      // Click analyze button
      const analyzeButton = element.shadowRoot.querySelector("lightning-button");
      analyzeButton.click();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Check that results region is displayed
      const resultsRegion = element.shadowRoot.querySelector('[role="region"]');
      expect(resultsRegion).not.toBeNull();

      // Check that trend data table is rendered
      const table = element.shadowRoot.querySelector('table[role="table"]');
      expect(table).not.toBeNull();
    });

    it("displays trend summary values", async () => {
      const mockResults = {
        buckets: [
          { bucketDate: "2025-01", metricValue: 100, changeFromPrevious: 10, percentChange: 10 },
        ],
        total: 210,
        average: 105,
        trendDirection: "up",
      };

      getTimeSeries.mockResolvedValue(mockResults);

      const element = await createComponent();
      await Promise.resolve();

      // Set up required inputs
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");

      const objectCombobox = Array.from(comboboxes).find((cb) => cb.label === "Object");
      objectCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));

      const dateFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Date Field");
      dateFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "CreatedDate" } }));

      const metricFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Metric Field");
      metricFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "AnnualRevenue" } }));

      await Promise.resolve();

      // Click analyze button
      const analyzeButton = element.shadowRoot.querySelector("lightning-button");
      analyzeButton.click();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Check that summary values are displayed
      const summaryText = element.shadowRoot.querySelector(".slds-text-body_regular");
      expect(summaryText).not.toBeNull();
      expect(summaryText.textContent).toContain("210.00");
      expect(summaryText.textContent).toContain("105.00");
      expect(summaryText.textContent).toContain("up");
    });
  });

  describe("Error Handling", () => {
    it("shows error message when analysis fails", async () => {
      const error = {
        body: { message: "Analysis failed" },
        message: "Analysis failed",
      };

      getTimeSeries.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      // Set up required inputs
      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");

      const objectCombobox = Array.from(comboboxes).find((cb) => cb.label === "Object");
      objectCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));

      const dateFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Date Field");
      dateFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "CreatedDate" } }));

      const metricFieldCombobox = Array.from(comboboxes).find((cb) => cb.label === "Metric Field");
      metricFieldCombobox.dispatchEvent(new CustomEvent("change", { detail: { value: "AnnualRevenue" } }));

      await Promise.resolve();

      // Click analyze button
      const analyzeButton = element.shadowRoot.querySelector("lightning-button");
      analyzeButton.click();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Check that error is displayed in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Error analyzing trend");

      // ShowToastEvent should have been dispatched
      expect(ShowToastEvent).toHaveBeenCalled();
    });
  });
});
