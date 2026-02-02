/**
 * Jest tests for prometheionScoreListener LWC component
 *
 * Tests cover:
 * - EMP API subscription
 * - Score update handling
 * - Event dispatching
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionScoreListener from "c/prometheionScoreListener";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

jest.mock(
  "lightning/empApi",
  () => ({
    subscribe: jest.fn((channel, replayId, callback) => {
      return Promise.resolve({ id: "mock-subscription-id" });
    }),
    unsubscribe: jest.fn((subscription, callback) => {
      if (callback) callback();
    }),
    onError: jest.fn((callback) => {
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

// Helper to wait for multiple microtasks
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-prometheion-score-listener", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-score-listener", {
      is: PrometheionScoreListener,
    });
    document.body.appendChild(element);
    await flushPromises();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(element).not.toBeNull();
    });
  });

  describe("Subscription", () => {
    it("subscribes to score events on connectedCallback", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(subscribe).toHaveBeenCalledWith(
        "/event/Prometheion_Score_Result__e",
        -1,
        expect.any(Function)
      );
    });

    it("unsubscribes on disconnectedCallback", async () => {
      const element = await createComponent();
      await flushPromises();

      element.remove();
      await flushPromises();

      expect(unsubscribe).toHaveBeenCalled();
    });

    it("registers error listener on connectedCallback", async () => {
      const element = await createComponent();
      await flushPromises();

      expect(onError).toHaveBeenCalledWith(expect.any(Function));
    });
  });

  describe("Score Update Handling", () => {
    it("dispatches scoreupdate event when message received", async () => {
      let capturedCallback;
      subscribe.mockImplementation((channel, replayId, callback) => {
        capturedCallback = callback;
        return Promise.resolve({ id: "mock-subscription-id" });
      });

      const element = await createComponent();
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      // Simulate receiving a platform event
      const mockPayload = {
        data: {
          payload: {
            Score_ID__c: "score123",
            Overall_Score__c: 85,
            Framework_Scores__c: '{"SOC2": 90, "HIPAA": 80}',
            Risk_Level__c: "MEDIUM",
          },
        },
      };

      if (capturedCallback) {
        capturedCallback(mockPayload);
        await flushPromises();

        expect(dispatchEventSpy).toHaveBeenCalled();
        const scoreUpdateEvent = dispatchEventSpy.mock.calls.find(
          (call) => call[0].type === "scoreupdate"
        );
        expect(scoreUpdateEvent).toBeDefined();
        expect(scoreUpdateEvent[0].detail.scoreId).toBe("score123");
        expect(scoreUpdateEvent[0].detail.overallScore).toBe(85);
      }

      dispatchEventSpy.mockRestore();
    });

    it("shows warning toast for CRITICAL risk level", async () => {
      let capturedCallback;
      subscribe.mockImplementation((channel, replayId, callback) => {
        capturedCallback = callback;
        return Promise.resolve({ id: "mock-subscription-id" });
      });

      const element = await createComponent();
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const mockPayload = {
        data: {
          payload: {
            Score_ID__c: "score123",
            Overall_Score__c: 40,
            Framework_Scores__c: '{"SOC2": 35}',
            Risk_Level__c: "CRITICAL",
          },
        },
      };

      if (capturedCallback) {
        capturedCallback(mockPayload);
        await flushPromises();

        const toastEvent = dispatchEventSpy.mock.calls.find((call) => call[0].type === "showtoast");
        expect(toastEvent).toBeDefined();
        expect(toastEvent[0].detail.variant).toBe("warning");
      }

      dispatchEventSpy.mockRestore();
    });

    it("shows warning toast for HIGH risk level", async () => {
      let capturedCallback;
      subscribe.mockImplementation((channel, replayId, callback) => {
        capturedCallback = callback;
        return Promise.resolve({ id: "mock-subscription-id" });
      });

      const element = await createComponent();
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const mockPayload = {
        data: {
          payload: {
            Score_ID__c: "score123",
            Overall_Score__c: 55,
            Framework_Scores__c: '{"SOC2": 50}',
            Risk_Level__c: "HIGH",
          },
        },
      };

      if (capturedCallback) {
        capturedCallback(mockPayload);
        await flushPromises();

        const toastEvent = dispatchEventSpy.mock.calls.find((call) => call[0].type === "showtoast");
        expect(toastEvent).toBeDefined();
        expect(toastEvent[0].detail.variant).toBe("warning");
      }

      dispatchEventSpy.mockRestore();
    });

    it("does not show warning toast for MEDIUM risk level", async () => {
      let capturedCallback;
      subscribe.mockImplementation((channel, replayId, callback) => {
        capturedCallback = callback;
        return Promise.resolve({ id: "mock-subscription-id" });
      });

      const element = await createComponent();
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const mockPayload = {
        data: {
          payload: {
            Score_ID__c: "score123",
            Overall_Score__c: 75,
            Framework_Scores__c: '{"SOC2": 75}',
            Risk_Level__c: "MEDIUM",
          },
        },
      };

      if (capturedCallback) {
        capturedCallback(mockPayload);
        await flushPromises();

        // Only scoreupdate event should be dispatched, no toast
        const toastEvent = dispatchEventSpy.mock.calls.find((call) => call[0].type === "showtoast");
        expect(toastEvent).toBeUndefined();
      }

      dispatchEventSpy.mockRestore();
    });
  });

  describe("Error Handling", () => {
    it("handles subscription error by showing error toast", async () => {
      const subscribeError = new Error("Subscription failed");
      subscribe.mockRejectedValue(subscribeError);

      // Create component - error happens during connectedCallback
      const element = createElement("c-prometheion-score-listener", {
        is: PrometheionScoreListener,
      });

      // Set up spy before adding to DOM so we capture the toast event
      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      document.body.appendChild(element);
      await flushPromises();

      // Error toast should be dispatched with error variant
      const toastEvent = dispatchEventSpy.mock.calls.find((call) => call[0].type === "showtoast");
      expect(toastEvent).toBeDefined();
      expect(toastEvent[0].detail.variant).toBe("error");
      expect(toastEvent[0].detail.title).toBe("Subscription Error");

      dispatchEventSpy.mockRestore();
    });
  });
});
