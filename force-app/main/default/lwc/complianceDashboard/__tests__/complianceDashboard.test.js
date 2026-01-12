/**
 * Jest tests for complianceDashboard LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Dashboard data display
 * - Error handling
 * - Loading states
 */

import { createElement } from "lwc";
import ComplianceDashboard from "c/complianceDashboard";
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

describe("c-compliance-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockDashboardCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-compliance-dashboard", {
      is: ComplianceDashboard,
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

      expect(element.loading).toBe(true);
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("displays dashboard data after wire adapter receives data", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 85, status: "COMPLIANT" },
          { framework: "HIPAA", score: 72, status: "ACTION_REQUIRED" },
        ],
        recentGaps: [
          { Id: "gap1", Severity__c: "HIGH", Title__c: "Test Gap 1" },
        ],
        recentEvidence: [
          { Id: "ev1", Evidence_Type__c: "Login", Status__c: "COLLECTED" },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.loading).toBe(false);
      expect(element.dashboardData).toEqual(mockData);
      expect(element.hasData).toBe(true);
      expect(element.frameworks.length).toBe(2);
    });

    it("handles empty frameworks array", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [],
        recentEvidence: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasData).toBe(false);
      expect(element.frameworks).toEqual([]);
    });
  });

  describe("Data Getters", () => {
    it("returns frameworks from dashboard data", async () => {
      const mockData = {
        frameworks: [
          { framework: "SOC2", score: 85 },
          { framework: "GDPR", score: 90 },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.frameworks.length).toBe(2);
      expect(element.frameworks[0].framework).toBe("SOC2");
    });

    it("returns recent gaps from dashboard data", async () => {
      const mockData = {
        frameworks: [],
        recentGaps: [
          { Id: "gap1", Title__c: "Gap 1" },
          { Id: "gap2", Title__c: "Gap 2" },
        ],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.recentGaps.length).toBe(2);
    });

    it("returns empty array when gaps are missing", async () => {
      const mockData = {
        frameworks: [],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.recentGaps).toEqual([]);
    });

    it("returns recent evidence from dashboard data", async () => {
      const mockData = {
        frameworks: [],
        recentEvidence: [{ Id: "ev1", Evidence_Type__c: "Login" }],
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.recentEvidence.length).toBe(1);
    });
  });

  describe("Error Handling", () => {
    it("handles wire adapter error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Failed to load dashboard" },
        message: "Failed to load dashboard",
      };

      emitDashboardError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.loading).toBe(false);
      expect(element.error).toBeDefined();
      expect(element.errorMessage).toContain("Failed to load");
    });

    it("displays error message in UI", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Test error" },
        message: "Test error",
      };

      emitDashboardError(error);
      await Promise.resolve();
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
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

    it("returns empty string when no error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const mockData = { frameworks: [] };
      emitDashboardData(mockData);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.errorMessage).toBe("");
    });
  });
});
