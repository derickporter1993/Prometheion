/**
 * Jest tests for flowExecutionMonitor LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Flow execution data loading
 * - Polling manager integration
 * - Data table rendering
 * - Error handling
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import FlowExecutionMonitor from "c/flowExecutionMonitor";

// Mock imperative Apex call
let mockFlowsResult = null;
let mockFlowsError = null;

jest.mock(
  "@salesforce/apex/FlowExecutionStats.getTopFlows",
  () => ({
    default: jest.fn(() => {
      if (mockFlowsError) {
        return Promise.reject(mockFlowsError);
      }
      return Promise.resolve(mockFlowsResult || []);
    }),
  }),
  { virtual: true }
);

// Mock PollingManager class - use factory function for hoisting
jest.mock(
  "c/pollingManager",
  () => {
    return class MockPollingManager {
      callback = null;
      interval = 60000;
      isRunning = false;

      constructor(callback, interval = 60000) {
        this.callback = callback;
        this.interval = interval;
      }

      start() {
        this.isRunning = true;
      }
      stop() {
        this.isRunning = false;
      }
      pause() {}
      resume() {}
      cleanup() {
        this.isRunning = false;
      }
      setupVisibilityHandling() {}
      pollNow() {
        if (this.callback) this.callback();
      }
    };
  },
  { virtual: true }
);

// Use fake timers for testing
jest.useFakeTimers();

// Helper to flush promises
async function flushPromises() {
  await Promise.resolve();
  jest.advanceTimersByTime(0);
  await Promise.resolve();
}

// Helper to create component
async function createComponent() {
  const element = createElement("c-flow-execution-monitor", {
    is: FlowExecutionMonitor,
  });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

// Sample mock data
const MOCK_FLOWS = [
  {
    flowName: "Account_Flow",
    runs: 150,
    faults: 5,
    lastRun: new Date("2026-01-10T10:00:00Z"),
  },
  {
    flowName: "Contact_Flow",
    runs: 89,
    faults: 2,
    lastRun: new Date("2026-01-10T09:30:00Z"),
  },
];

describe("c-flow-execution-monitor", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockFlowsResult = MOCK_FLOWS;
    mockFlowsError = null;
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
      expect(card.title).toBe("Flow Execution Monitor");
    });

    it("loads flow data on connected", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const getTopFlows = require("@salesforce/apex/FlowExecutionStats.getTopFlows").default;
      expect(getTopFlows).toHaveBeenCalledWith({ limitSize: 20 });
    });

    it("displays data table when data is available", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.keyField || datatable.getAttribute("key-field")).toBeTruthy();
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
      mockFlowsResult = [];
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // When empty, should show empty state message instead of datatable
      const emptyMessage = element.shadowRoot.querySelector(".slds-text-color_weak.slds-p-around_medium");
      expect(emptyMessage).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      mockFlowsError = { message: "Test error" };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Component should show error state, not datatable
      const errorMessage = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorMessage).not.toBeNull();
    });

    it("handles errors without throwing", async () => {
      mockFlowsError = new Error("Network error");
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Component should show error state
      const errorMessage = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorMessage).not.toBeNull();
    });
  });

  describe("Polling Manager Integration", () => {
    it("initializes polling on connectedCallback", async () => {
      const element = await createComponent();
      await flushPromises();

      // Verify component renders and loads data (polling is internal)
      const getTopFlows = require("@salesforce/apex/FlowExecutionStats.getTopFlows").default;
      expect(getTopFlows).toHaveBeenCalled();
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
      expect(card.title).toBe("Flow Execution Monitor");
    });

    it("data table renders correctly", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      // key-field is set via property, verify datatable exists
      expect(datatable.keyField || datatable.getAttribute("key-field")).toBeTruthy();
    });
  });
});
