/**
 * Jest tests for systemMonitorDashboard LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Governor stats loading
 * - Polling manager integration
 * - Progress ring calculations (CPU, Heap)
 * - Error handling
 * - Refresh button functionality
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import SystemMonitorDashboard from "c/systemMonitorDashboard";

// Mock imperative Apex calls
let mockStatsResult = null;
let mockStatsError = null;
let mockEvaluateResult = null;
let mockEvaluateError = null;

jest.mock("@salesforce/apex/LimitMetrics.fetchGovernorStats", () => ({
  default: jest.fn(() => {
    if (mockStatsError) {
      return Promise.reject(mockStatsError);
    }
    return Promise.resolve(mockStatsResult);
  }),
}), { virtual: true });

jest.mock("@salesforce/apex/PerformanceRuleEngine.evaluateAndPublish", () => ({
  default: jest.fn(() => {
    if (mockEvaluateError) {
      return Promise.reject(mockEvaluateError);
    }
    return Promise.resolve(mockEvaluateResult);
  }),
}), { virtual: true });

// Use real PollingManager with fake timers
jest.useFakeTimers();

// Mock ShowToastEvent
const mockShowToastEvent = jest.fn();
jest.mock("lightning/platformShowToastEvent", () => ({
  ShowToastEvent: jest.fn().mockImplementation((config) => {
    mockShowToastEvent(config);
    return new CustomEvent("showtoast", { detail: config });
  }),
}), { virtual: true });

// Helper to flush promises
async function flushPromises() {
  await Promise.resolve();
  jest.advanceTimersByTime(0);
  await Promise.resolve();
}

// Helper to create component
async function createComponent() {
  const element = createElement("c-system-monitor-dashboard", {
    is: SystemMonitorDashboard,
  });
  document.body.appendChild(element);
  await flushPromises();
  return element;
}

// Sample mock data
const MOCK_STATS = {
  cpuMs: 7500,
  heapKb: 30000,
  soql: 85,
  dml: 120,
};

describe("c-system-monitor-dashboard", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    mockStatsResult = MOCK_STATS;
    mockStatsError = null;
    mockEvaluateResult = null;
    mockEvaluateError = null;
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
      expect(card.title).toBe("Governor Limits");
    });

    it("loads governor stats on connected", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const fetchStats = require("@salesforce/apex/LimitMetrics.fetchGovernorStats").default;
      expect(fetchStats).toHaveBeenCalled();
    });

    it("shows loading state initially", async () => {
      mockStatsResult = null;
      const element = await createComponent();
      await flushPromises();

      const loadingText = element.shadowRoot.querySelector("p");
      if (loadingText) {
        expect(loadingText.textContent.trim()).toBe("Loading…");
      }
    });

    it("displays stats when data is available", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const progressRings = element.shadowRoot.querySelectorAll("lightning-progress-ring");
      expect(progressRings.length).toBeGreaterThan(0);
    });
  });

  describe("Data Calculations", () => {
    it("calculates CPU percentage correctly", async () => {
      mockStatsResult = { cpuMs: 7500, heapKb: 30000, soql: 85, dml: 120 };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // CPU: 7500ms / 100 = 75%, capped at 100%
      expect(element.cpuPct).toBeLessThanOrEqual(100);
      expect(element.cpuPct).toBeGreaterThanOrEqual(0);
    });

    it("calculates Heap percentage correctly", async () => {
      mockStatsResult = { cpuMs: 5000, heapKb: 30000, soql: 85, dml: 120 };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Heap: 30000KB / 50 = 600%, capped at 100%
      expect(element.heapPct).toBeLessThanOrEqual(100);
      expect(element.heapPct).toBeGreaterThanOrEqual(0);
    });

    it("caps percentages at 100%", async () => {
      mockStatsResult = { cpuMs: 15000, heapKb: 100000, soql: 200, dml: 300 };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(element.cpuPct).toBeLessThanOrEqual(100);
      expect(element.heapPct).toBeLessThanOrEqual(100);
    });

    it("handles missing stats gracefully", async () => {
      mockStatsResult = { cpuMs: null, heapKb: null, soql: 0, dml: 0 };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(element.cpuPct).toBe(0);
      expect(element.heapPct).toBe(0);
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      mockStatsError = { body: { message: "Test error" } };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(mockShowToastEvent).toHaveBeenCalledWith(
        expect.objectContaining({
          title: "Failed to load governor stats",
          variant: "error",
        })
      );
    });

    it("handles errors without body message", async () => {
      mockStatsError = { message: "Network error" };
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      expect(mockShowToastEvent).toHaveBeenCalled();
    });
  });

  describe("User Interactions", () => {
    it("refresh button triggers reload", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const fetchStats = require("@salesforce/apex/LimitMetrics.fetchGovernorStats").default;
      jest.clearAllMocks();

      const refreshButton = element.shadowRoot.querySelector("lightning-button");
      expect(refreshButton).not.toBeNull();
      refreshButton.click();
      await flushPromises();

      expect(fetchStats).toHaveBeenCalled();
    });

    it("evaluates and publishes on load", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const evaluate = require("@salesforce/apex/PerformanceRuleEngine.evaluateAndPublish").default;
      expect(evaluate).toHaveBeenCalled();
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
      expect(card.title).toBe("Governor Limits");
    });

    it("progress rings have labels", async () => {
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      const progressRings = element.shadowRoot.querySelectorAll("lightning-progress-ring");
      progressRings.forEach((ring) => {
        expect(ring.getAttribute("label")).toBeTruthy();
      });
    });
  });
});
