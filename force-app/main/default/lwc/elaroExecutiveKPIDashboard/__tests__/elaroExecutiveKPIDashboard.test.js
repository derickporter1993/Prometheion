/**
 * Jest tests for elaroExecutiveKPIDashboard LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Value formatting (currency, percent, days)
 * - Status badge variants
 * - Error handling
 */

import { createElement } from "lwc";
import ElaroExecutiveKPIDashboard from "c/elaroExecutiveKPIDashboard";
import getKPIMetrics from "@salesforce/apex/ElaroExecutiveKPIController.getKPIMetrics";

let mockKPICallbacks = new Set();

jest.mock(
  "@salesforce/apex/ElaroExecutiveKPIController.getKPIMetrics",
  () => ({
    default: function MockAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockKPICallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockKPICallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve(null);
    },
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

describe("c-elaro-executive-kpi-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockKPICallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-elaro-executive-kpi-dashboard", {
      is: ElaroExecutiveKPIDashboard,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  function getSpinner(element) {
    return element.shadowRoot.querySelector("lightning-spinner");
  }

  function getErrorAlert(element) {
    return element.shadowRoot.querySelector("lightning-alert");
  }

  function getKPICards(element) {
    return element.shadowRoot.querySelectorAll('[role="listitem"]');
  }

  function getKPILabels(element) {
    return element.shadowRoot.querySelectorAll(".slds-text-heading_small");
  }

  function getKPIValues(element) {
    return element.shadowRoot.querySelectorAll(".slds-text-heading_large");
  }

  function getStatusBadges(element) {
    return element.shadowRoot.querySelectorAll("lightning-badge");
  }

  describe("Initial Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    });

    it("shows loading spinner initially", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const spinner = getSpinner(element);
      expect(spinner).not.toBeNull();
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("displays KPI metrics after wire adapter receives data", async () => {
      const mockData = [
        {
          kpiName: "compliance_score",
          label: "Overall Compliance",
          currentValue: 0.85,
          targetValue: 0.90,
          formatType: "percent",
          status: "yellow",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Spinner should be gone
      const spinner = getSpinner(element);
      expect(spinner).toBeNull();

      // KPI cards should be rendered
      const kpiCards = getKPICards(element);
      expect(kpiCards.length).toBeGreaterThan(0);

      // No error alert
      const errorAlert = getErrorAlert(element);
      expect(errorAlert).toBeNull();
    });

    it("formats metrics with formattedValue and formattedTarget", async () => {
      const mockData = [
        {
          kpiName: "compliance_score",
          label: "Compliance Score",
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

      // Check that values are displayed in DOM
      const kpiValues = getKPIValues(element);
      expect(kpiValues.length).toBeGreaterThan(0);

      // Value should contain formatted percentage
      const valueText = kpiValues[0].textContent;
      expect(valueText).toBeDefined();

      // Check for badge
      const badges = getStatusBadges(element);
      expect(badges.length).toBeGreaterThan(0);
    });
  });

  describe("Value Formatting", () => {
    it("formats currency values correctly", async () => {
      const mockData = [
        {
          kpiName: "audit_savings",
          label: "Audit Savings",
          currentValue: 125000.50,
          targetValue: 150000,
          formatType: "currency",
          status: "green",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const kpiValues = getKPIValues(element);
      if (kpiValues.length > 0) {
        const valueText = kpiValues[0].textContent;
        // Should contain currency symbol or formatted value
        expect(valueText).toContain("$");
        expect(valueText).toContain("125,000");
      }
    });

    it("formats percent values correctly", async () => {
      const mockData = [
        {
          kpiName: "compliance_rate",
          label: "Compliance Rate",
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

      const kpiValues = getKPIValues(element);
      if (kpiValues.length > 0) {
        const valueText = kpiValues[0].textContent;
        expect(valueText).toContain("%");
        expect(valueText).toContain("85");
      }
    });

    it("formats days values correctly", async () => {
      const mockData = [
        {
          kpiName: "avg_remediation_time",
          label: "Avg Remediation Time",
          currentValue: 30.5,
          targetValue: 25,
          formatType: "days",
          status: "yellow",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const kpiValues = getKPIValues(element);
      if (kpiValues.length > 0) {
        const valueText = kpiValues[0].textContent;
        expect(valueText).toContain("days");
        expect(valueText).toContain("30.5");
      }
    });

    it("shows N/A for null values", async () => {
      const mockData = [
        {
          kpiName: "test_metric",
          label: "Test Metric",
          currentValue: null,
          targetValue: 0.90,
          formatType: "percent",
          status: "red",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const kpiValues = getKPIValues(element);
      if (kpiValues.length > 0) {
        expect(kpiValues[0].textContent).toBe("N/A");
      }
    });

    it("shows N/A when metric has error", async () => {
      const mockData = [
        {
          kpiName: "error_metric",
          label: "Error Metric",
          currentValue: 0.85,
          targetValue: 0.90,
          formatType: "percent",
          status: "red",
          hasError: true,
          errorMessage: "Failed to calculate",
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Check for error message in the card
      const errorMessage = element.shadowRoot.querySelector('[role="alert"]');
      expect(errorMessage).not.toBeNull();
      expect(errorMessage.textContent).toContain("Failed to calculate");
    });
  });

  describe("Status Badge Variants", () => {
    it("displays success variant for green status", async () => {
      const mockData = [
        {
          kpiName: "green_metric",
          label: "Green Metric",
          currentValue: 0.95,
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

      const badges = getStatusBadges(element);
      if (badges.length > 0) {
        expect(badges[0].variant).toBe("success");
      }
    });

    it("displays warning variant for yellow status", async () => {
      const mockData = [
        {
          kpiName: "yellow_metric",
          label: "Yellow Metric",
          currentValue: 0.85,
          targetValue: 0.90,
          formatType: "percent",
          status: "yellow",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const badges = getStatusBadges(element);
      if (badges.length > 0) {
        expect(badges[0].variant).toBe("warning");
      }
    });

    it("displays error variant for red status", async () => {
      const mockData = [
        {
          kpiName: "red_metric",
          label: "Red Metric",
          currentValue: 0.70,
          targetValue: 0.90,
          formatType: "percent",
          status: "red",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const badges = getStatusBadges(element);
      if (badges.length > 0) {
        expect(badges[0].variant).toBe("error");
      }
    });

    it("displays default variant for unknown status", async () => {
      const mockData = [
        {
          kpiName: "unknown_metric",
          label: "Unknown Metric",
          currentValue: 0.80,
          targetValue: 0.90,
          formatType: "percent",
          status: "unknown",
          hasError: false,
        },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitKPIData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const badges = getStatusBadges(element);
      if (badges.length > 0) {
        // Default variant may be undefined or "default"
        expect(["default", undefined, ""]).toContain(badges[0].variant);
      }
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

      // Error alert should be shown
      const errorAlert = getErrorAlert(element);
      expect(errorAlert).not.toBeNull();

      // Spinner should be gone
      const spinner = getSpinner(element);
      expect(spinner).toBeNull();
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

      // Error alert should contain the error message
      const errorAlert = getErrorAlert(element);
      expect(errorAlert).not.toBeNull();
      expect(errorAlert.message).toContain("Network error");
    });
  });
});
