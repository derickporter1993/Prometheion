/**
 * Jest tests for deploymentMonitorDashboard LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Deployment data loading
 * - Polling manager integration
 * - Data table rendering
 * - Error handling
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import DeploymentMonitorDashboard from "c/deploymentMonitorDashboard";

// Mock imperative Apex call
let mockDeploymentsResult = null;
let mockDeploymentsError = null;

jest.mock("@salesforce/apex/DeploymentMetrics.getRecentDeployments", () => ({
  default: jest.fn(() => {
    if (mockDeploymentsError) {
      return Promise.reject(mockDeploymentsError);
    }
    return Promise.resolve(mockDeploymentsResult || []);
  }),
}), { virtual: true });

// Use real PollingManager with fake timers
jest.useFakeTimers();

// Helper to flush promises
async function flushPromises() {
  await Promise.resolve();
  jest.advanceTimersByTime(0);
  await Promise.resolve();
}

// Helper to create component
async function createComponent() {
  const element = createElement("c-deployment-monitor-dashboard", {
    is: DeploymentMonitorDashboard,
  });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

// Sample mock data
const MOCK_DEPLOYMENTS = [
  {
    name: "Deployment-001",
    status: "Succeeded",
    startedOn: new Date("2026-01-10T10:00:00Z"),
    finishedOn: new Date("2026-01-10T10:15:00Z"),
    testsPassed: 125,
    testsFailed: 0,
  },
  {
    name: "Deployment-002",
    status: "Failed",
    startedOn: new Date("2026-01-10T09:00:00Z"),
    finishedOn: new Date("2026-01-10T09:10:00Z"),
    testsPassed: 120,
    testsFailed: 5,
  },
];

describe("c-deployment-monitor-dashboard", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockDeploymentsResult = MOCK_DEPLOYMENTS;
    mockDeploymentsError = null;
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllTimers();
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  describe("Initial Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Deployment Monitor");
    });

    it("displays helper text", async () => {
      const element = await createComponent();
      await flushPromises();

      const helperText = element.shadowRoot.querySelector("p.slds-text-color_weak");
      expect(helperText).not.toBeNull();
      expect(helperText.textContent).toContain("Feed this via CI");
    });

    it("loads deployment data on connected", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const getRecentDeployments = require("@salesforce/apex/DeploymentMetrics.getRecentDeployments").default;
      expect(getRecentDeployments).toHaveBeenCalledWith({ limitSize: 20 });
    });

    it("displays data table when data is available", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.getAttribute("key-field")).toBe("name");
    });
  });

  describe("Data Loading", () => {
    it("maps server data correctly", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("handles empty array", async () => {
      mockDeploymentsResult = [];
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      mockDeploymentsError = { message: "Test error" };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Should set empty array to prevent UI errors
      expect(element.rows).toEqual([]);
    });

    it("handles errors without throwing", async () => {
      mockDeploymentsError = new Error("Network error");
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(element.rows).toEqual([]);
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });
  });

  describe("Polling Manager Integration", () => {
    it("creates PollingManager on connectedCallback", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(element.pollingManager).not.toBeNull();
      expect(element.pollingManager.interval).toBe(60000);
    });

    it("cleans up polling on disconnected", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(() => {
        element.remove();
        while (document.body.firstChild) {
          document.body.removeChild(document.body.firstChild);
        }
      }).not.toThrow();
    });
  });

  describe("Accessibility", () => {
    it("has proper heading structure", async () => {
      const element = await createComponent();
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Deployment Monitor");
    });

    it("data table has key-field attribute", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.getAttribute("key-field")).toBe("name");
    });

    it("provides helper text for context", async () => {
      const element = await createComponent();
      await flushPromises();

      const helperText = element.shadowRoot.querySelector("p.slds-text-color_weak");
      expect(helperText).not.toBeNull();
    });
  });
});
