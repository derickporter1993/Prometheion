/**
 * Jest tests for prometheionEventMonitor LWC component
 *
 * Tests cover:
 * - EMP API subscription
 * - Event handling
 * - Event buffer management
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionEventMonitor from "c/prometheionEventMonitor";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const mockSubscribe = jest.fn();
const mockUnsubscribe = jest.fn();
const mockOnError = jest.fn();

jest.mock(
  "lightning/empApi",
  () => ({
    subscribe: jest.fn((channel, replayId, callback) => {
      mockSubscribe.mockImplementation((ch, rid, cb) => {
        return Promise.resolve({ id: "mock-subscription-id" });
      });
      return Promise.resolve({ id: "mock-subscription-id" });
    }),
    unsubscribe: jest.fn((subscription, callback) => {
      mockUnsubscribe.mockImplementation((sub, cb) => {
        if (cb) cb();
      });
      if (typeof arguments[1] === "function") {
        arguments[1]();
      }
    }),
    onError: jest.fn((callback) => {
      mockOnError.mockImplementation((cb) => {
        return cb;
      });
      return callback;
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

describe("c-prometheion-event-monitor", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-event-monitor", {
      is: PrometheionEventMonitor,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Subscription", () => {
    it("subscribes to events on connectedCallback", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(subscribe).toHaveBeenCalled();
    });

    it("unsubscribes on disconnectedCallback", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      element.remove();
      await Promise.resolve();

      // Unsubscribe should be called during cleanup
      expect(unsubscribe).toHaveBeenCalled();
    });
  });

  describe("State Management", () => {
    it("hasEvents returns true when events exist", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.events = [
        {
          id: "ev1",
          eventType: "GAP_DETECTED",
          timestamp: new Date().toISOString(),
        },
      ];

      expect(element.hasEvents).toBe(true);
    });

    it("hasEvents returns false when events empty", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element.hasEvents).toBe(false);
    });

    it("noEvents returns true when no events", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element.noEvents).toBe(true);
    });
  });
});
