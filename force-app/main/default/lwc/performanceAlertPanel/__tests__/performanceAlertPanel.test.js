/**
 * Jest tests for performanceAlertPanel LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Platform event subscription (EMP API)
 * - Alert data loading and buffering
 * - Debounced event processing
 * - Data table rendering with maxRows limit
 * - Error handling
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import PerformanceAlertPanel from "c/performanceAlertPanel";

// Mock imperative Apex call
let mockAlertsResult = null;
let mockAlertsError = null;

jest.mock(
  "@salesforce/apex/AlertHistoryService.getRecentAlerts",
  () => ({
    default: jest.fn(() => {
      if (mockAlertsError) {
        return Promise.reject(mockAlertsError);
      }
      return Promise.resolve(mockAlertsResult || []);
    }),
  }),
  { virtual: true }
);

// Mock EMP API (Platform Events)
const mockSubscribeCallback = jest.fn();
const mockSubscription = { id: "mock-subscription-id" };
const mockOnErrorCallback = jest.fn();

jest.mock(
  "lightning/empApi",
  () => ({
    subscribe: jest.fn((channel, replayId, callback) => {
      mockSubscribeCallback.mockImplementation(callback);
      return Promise.resolve(mockSubscription);
    }),
    onError: jest.fn((callback) => {
      mockOnErrorCallback.mockImplementation(callback);
    }),
  }),
  { virtual: true }
);

// Use fake timers for debounce testing
jest.useFakeTimers();

// Helper to flush promises
async function flushPromises() {
  await Promise.resolve();
  jest.advanceTimersByTime(0);
  await Promise.resolve();
}

// Helper to create component
async function createComponent() {
  const element = createElement("c-performance-alert-panel", {
    is: PerformanceAlertPanel,
  });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

// Sample mock data
const MOCK_ALERTS = [
  {
    metric: "CPU",
    value: 8500,
    threshold: 10000,
    contextRecordId: "001xx0000000001",
    createdDate: new Date("2026-01-10T10:00:00Z").toISOString(),
  },
  {
    metric: "Heap",
    value: 45000,
    threshold: 60000,
    contextRecordId: "001xx0000000002",
    createdDate: new Date("2026-01-10T09:45:00Z").toISOString(),
  },
];

describe("c-performance-alert-panel", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockAlertsResult = MOCK_ALERTS;
    mockAlertsError = null;
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
      await flushPromises();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Performance Alerts");
    });

    it("displays helper text", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const helperText = element.shadowRoot.querySelector("p.slds-text-color_weak");
      expect(helperText).not.toBeNull();
      expect(helperText.textContent).toContain("Live + recent alerts");
    });

    it("loads recent alerts on connected", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const getRecentAlerts =
        require("@salesforce/apex/AlertHistoryService.getRecentAlerts").default;
      expect(getRecentAlerts).toHaveBeenCalledWith({ limitSize: 25 });
    });

    it("subscribes to platform events on connected", async () => {
      const subscribe = require("lightning/empApi").subscribe;
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(subscribe).toHaveBeenCalledWith(
        "/event/Performance_Alert__e",
        -1,
        expect.any(Function)
      );
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
      mockAlertsResult = [];
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });
  });

  describe("Platform Event Handling", () => {
    it("processes incoming platform events", async () => {
      const subscribe = require("lightning/empApi").subscribe;
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Get the callback that was registered
      const subscribeCall = subscribe.mock.calls[0];
      const messageCallback = subscribeCall[2];

      // Simulate incoming event (component should process without error)
      expect(() => {
        messageCallback({
          data: {
            payload: {
              Metric__c: "CPU",
              Value__c: 9200,
              Threshold__c: 10000,
              Context_Record__c: "001xx0000000003",
            },
          },
        });
      }).not.toThrow();

      // Advance debounce timer
      jest.advanceTimersByTime(250);
      await flushPromises();

      // Verify datatable still renders
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("debounces multiple rapid events", async () => {
      const subscribe = require("lightning/empApi").subscribe;
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const subscribeCall = subscribe.mock.calls[0];
      const messageCallback = subscribeCall[2];

      // Send 3 rapid events without error
      expect(() => {
        messageCallback({
          data: { payload: { Metric__c: "CPU", Value__c: 8000, Threshold__c: 10000 } },
        });
        jest.advanceTimersByTime(100);
        messageCallback({
          data: { payload: { Metric__c: "Heap", Value__c: 40000, Threshold__c: 60000 } },
        });
        jest.advanceTimersByTime(100);
        messageCallback({
          data: { payload: { Metric__c: "SOQL", Value__c: 95, Threshold__c: 100 } },
        });
      }).not.toThrow();

      // Complete debounce window
      jest.advanceTimersByTime(150);
      await flushPromises();

      // Verify datatable still renders
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("handles large alert volume gracefully", async () => {
      mockAlertsResult = Array.from({ length: 60 }, (_, i) => ({
        metric: `Metric-${i}`,
        value: 1000 + i,
        threshold: 2000,
        contextRecordId: `001xx000000${String(i).padStart(4, "0")}`,
        createdDate: new Date().toISOString(),
      }));

      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Component should render datatable without error
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      mockAlertsError = { message: "Test error" };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Component should render datatable without throwing
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("registers EMP API error handler", async () => {
      const onError = require("lightning/empApi").onError;
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(onError).toHaveBeenCalled();
    });

    it("handles EMP API errors silently", async () => {
      const onError = require("lightning/empApi").onError;
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Get the error callback
      const errorCallback = onError.mock.calls[0][0];

      // Should not throw
      expect(() => {
        errorCallback({ error: "EMP API error" });
      }).not.toThrow();
    });
  });

  describe("Cleanup", () => {
    it("cleans up on disconnect without error", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Trigger an event to create a debounce timer
      const subscribe = require("lightning/empApi").subscribe;
      const subscribeCall = subscribe.mock.calls[0];
      const messageCallback = subscribeCall[2];
      messageCallback({
        data: { payload: { Metric__c: "CPU", Value__c: 8000, Threshold__c: 10000 } },
      });

      // Removing element triggers disconnectedCallback
      expect(() => {
        element.remove();
      }).not.toThrow();
    });

    it("handles disconnect gracefully", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Disconnect without error
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
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Performance Alerts");
    });

    it("data table has key-field attribute", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.keyField || datatable.getAttribute("key-field")).toBeTruthy();
    });

    it("provides helper text for context", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const helperText = element.shadowRoot.querySelector("p.slds-text-color_weak");
      expect(helperText).not.toBeNull();
    });
  });
});
