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
    });

    it("shows loading state initially", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element.loading).toBe(true);
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

      expect(element.loading).toBe(false);
      expect(element.dashboardData).toEqual(mockData);
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
      expect(element.overallScore).toBe("80.0");
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

      expect(element.overallScore).toBe("0");
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
      expect(element.overallScore).toBe("40.0");
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

      expect(element.totalGaps).toBe(3);
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

      expect(element.totalGaps).toBe(0);
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

      expect(element.criticalGaps).toBe(2);
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

      expect(element.criticalGaps).toBe(0);
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

      expect(element.compliantFrameworks).toBe(2);
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

      expect(element.loading).toBe(false);
      expect(element.error).toBeDefined();
      expect(element.errorMessage).toContain("Failed to load");
    });

    it("handles error without body property", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = { message: "Network error" };
      emitDashboardError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.errorMessage).toBe("Network error");
    });
  });
});
