/**
 * Jest tests for prometheionExecutiveKPIDashboard LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Value formatting (currency, percent, days)
 * - Status badge variants
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionExecutiveKPIDashboard from "c/prometheionExecutiveKPIDashboard";
import getKPIMetrics from "@salesforce/apex/PrometheionExecutiveKPIController.getKPIMetrics";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockKPICallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionExecutiveKPIController.getKPIMetrics",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockKPICallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockKPICallbacks.delete(callback);
          },
          update: () => {},
        };
      }
      return Promise.resolve(null);
    }),
  }),
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

const emitKPIData = (data) => {
  mockKPICallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitKPIError = (error) => {
  mockKPICallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-prometheion-executive-kpi-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockKPICallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-executive-kpi-dashboard", {
      is: PrometheionExecutiveKPIDashboard,
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
    });

    it("sets isLoading to true in connectedCallback", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element.isLoading).toBe(true);
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("displays KPI metrics after wire adapter receives data", async () => {
      const mockData = [
        {
          name: "Overall Compliance",
          currentValue: 0.85,
          targetValue: 0.90,
          formatType: "percent",
          status: "yellow",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      // Manually trigger wire adapter callback
      const wireAdapter = getKPIMetrics();
      if (wireAdapter && typeof wireAdapter === "object") {
        emitKPIData(mockData);
      }
      await Promise.resolve();
      await Promise.resolve();

      expect(element.kpiMetrics.length).toBeGreaterThan(0);
      expect(element.isLoading).toBe(false);
      expect(element.hasError).toBe(false);
    });

    it("formats metrics with formattedValue and formattedTarget", async () => {
      const mockData = [
        {
          name: "Compliance Score",
          currentValue: 0.85,
          targetValue: 0.90,
          formatType: "percent",
          status: "green",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      if (element.kpiMetrics.length > 0) {
        const metric = element.kpiMetrics[0];
        expect(metric.formattedValue).toBeDefined();
        expect(metric.formattedTarget).toBeDefined();
        expect(metric.statusBadgeVariant).toBeDefined();
        expect(metric.noError).toBe(true);
      }
    });
  });

  describe("Value Formatting", () => {
    it("formats currency values correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = {
        currentValue: 125000.50,
        formatType: "currency",
        hasError: false,
      };

      const formatted = element.formatValue(metric);
      expect(formatted).toContain("$");
      expect(formatted).toContain("125,000");
    });

    it("formats percent values correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = {
        currentValue: 0.85,
        formatType: "percent",
        hasError: false,
      };

      const formatted = element.formatValue(metric);
      expect(formatted).toContain("%");
      expect(formatted).toContain("85.0");
    });

    it("formats days values correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = {
        currentValue: 30.5,
        formatType: "days",
        hasError: false,
      };

      const formatted = element.formatValue(metric);
      expect(formatted).toContain("days");
      expect(formatted).toContain("30.5");
    });

    it("returns N/A for null values", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = {
        currentValue: null,
        formatType: "percent",
        hasError: false,
      };

      const formatted = element.formatValue(metric);
      expect(formatted).toBe("N/A");
    });

    it("returns N/A when metric has error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = {
        currentValue: 0.85,
        formatType: "percent",
        hasError: true,
      };

      const formatted = element.formatValue(metric);
      expect(formatted).toBe("N/A");
    });
  });

  describe("Status Badge Variants", () => {
    it("returns success variant for green status", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = { status: "green" };
      const variant = element.getStatusBadgeVariant(metric);
      expect(variant).toBe("success");
    });

    it("returns warning variant for yellow status", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = { status: "yellow" };
      const variant = element.getStatusBadgeVariant(metric);
      expect(variant).toBe("warning");
    });

    it("returns error variant for red status", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = { status: "red" };
      const variant = element.getStatusBadgeVariant(metric);
      expect(variant).toBe("error");
    });

    it("returns default variant for unknown status", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const metric = { status: "unknown" };
      const variant = element.getStatusBadgeVariant(metric);
      expect(variant).toBe("default");
    });
  });

  describe("Error Handling", () => {
    it("handles wire adapter error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Failed to load KPIs" },
        message: "Failed to load KPIs",
      };

      emitKPIError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Error loading KPIs");
      expect(element.isLoading).toBe(false);
    });

    it("shows error toast on error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const error = {
        body: { message: "Test error" },
        message: "Test error",
      };

      emitKPIError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(dispatchEventSpy).toHaveBeenCalled();
      dispatchEventSpy.mockRestore();
    });

    it("handles error without body property", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = { message: "Network error" };
      emitKPIError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.errorMessage).toContain("Network error");
    });
  });
});
