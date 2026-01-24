/**
 * Jest tests for executiveKpiDashboard LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - KPI calculations (overall score, gaps, frameworks)
 * - Error handling
 */

import { createElement } from "lwc";
import ExecutiveKpiDashboard from "c/executiveKpiDashboard";
import getDashboardSummary from "@salesforce/apex/ComplianceDashboardController.getDashboardSummary";
import {
  runAccessibilityAudit,
  checkHeadingHierarchy,
} from "../../__tests__/axeTestHelper";

let mockDashboardCallbacks = new Set();

jest.mock(
  "@salesforce/apex/ComplianceDashboardController.getDashboardSummary",
  () => ({
    default: function MockDashboardAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockDashboardCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockDashboardCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve(null);
    },
  }),
  { virtual: true }
);

const emitDashboardData = (data) => {
  mockDashboardCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitDashboardError = (error) => {
  mockDashboardCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-executive-kpi-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockDashboardCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-executive-kpi-dashboard", {
      is: ExecutiveKpiDashboard,
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

    it("shows loading state initially", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Check DOM for spinner (loading indicator)
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("displays dashboard data after wire adapter receives data", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 85 },
          { framework: "HIPAA", score: 75 },
        ],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // After data loads, spinner should be gone and dashboard grid should show
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();

      const grid = element.shadowRoot.querySelector(".slds-grid");
      expect(grid).not.toBeNull();
    });
  });

  describe("KPI Calculations", () => {
    it("calculates overall score correctly", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 80 },
          { framework: "HIPAA", score: 90 },
          { framework: "GDPR", score: 70 },
        ],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Average: (80 + 90 + 70) / 3 = 80.0
      // Check that the overall score displays in the DOM
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(0);
      expect(headings[0].textContent).toBe("80.0%");
    });

    it("returns 0 when no frameworks", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Check that overall score shows "0" or "0%"
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(0);
      expect(headings[0].textContent).toBe("0%");
    });

    it("handles frameworks with null scores", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 80 },
          { framework: "HIPAA", score: null },
        ],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Average: (80 + 0) / 2 = 40.0
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(0);
      expect(headings[0].textContent).toBe("40.0%");
    });

    it("calculates total gaps correctly", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [
          { Id: "gap1" },
          { Id: "gap2" },
          { Id: "gap3" },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Total gaps is second KPI - index 1
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(1);
      expect(headings[1].textContent).toBe("3");
    });

    it("returns 0 when no gaps", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Total gaps should show 0
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(1);
      expect(headings[1].textContent).toBe("0");
    });

    it("calculates critical gaps correctly", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [
          { Id: "gap1", Severity__c: "CRITICAL" },
          { Id: "gap2", Severity__c: "HIGH" },
          { Id: "gap3", Severity__c: "CRITICAL" },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Critical gaps is third KPI - index 2
      const criticalGapsElement = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(criticalGapsElement).not.toBeNull();
      expect(criticalGapsElement.textContent).toBe("2");
    });

    it("returns 0 critical gaps when none exist", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [
          { Id: "gap1", Severity__c: "HIGH" },
          { Id: "gap2", Severity__c: "MEDIUM" },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Critical gaps should show 0
      const criticalGapsElement = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(criticalGapsElement).not.toBeNull();
      expect(criticalGapsElement.textContent).toBe("0");
    });

    it("calculates compliant frameworks correctly", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", status: "COMPLIANT" },
          { framework: "HIPAA", status: "ACTION_REQUIRED" },
          { framework: "GDPR", status: "COMPLIANT" },
        ],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      // Compliant frameworks is fourth KPI - index 3
      const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
      expect(headings.length).toBeGreaterThan(3);
      expect(headings[3].textContent).toBe("2");
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

      emitDashboardError(error);
      await Promise.resolve();
      await Promise.resolve();

      // Check that error message is displayed in the DOM
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Failed to load");
    });

    it("handles error without body property", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = { message: "Network error" };
      emitDashboardError(error);
      await Promise.resolve();
      await Promise.resolve();

      // Check error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Network error");
    });
  });

  describe("Accessibility (axe)", () => {
    it("should have no accessibility violations", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 85, status: "COMPLIANT" },
          { framework: "HIPAA", score: 75, status: "ACTION_REQUIRED" },
        ],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const results = await runAccessibilityAudit(element);
      expect(results.violations).toHaveLength(0);
    });

    it("should have valid heading hierarchy", async () => {
      const mockData = {
        frameworks: [{ framework: "SOC2", score: 85, status: "COMPLIANT" }],
        recentGaps: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      const { isValid, errors } = checkHeadingHierarchy(element.shadowRoot);
      if (!isValid) {
        console.warn("Heading hierarchy issues:", errors);
      }
      expect(isValid).toBe(true);
    });
  });
});
