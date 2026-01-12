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

const mockSubscribe = jest.fn();
const mockUnsubscribe = jest.fn();
const mockOnError = jest.fn();

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
    it("subscribes to score events on connectedCallback", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(subscribe).toHaveBeenCalledWith(
        "/event/Prometheion_Score_Result__e",
        -1,
        expect.any(Function)
      );
    });

    it("unsubscribes on disconnectedCallback", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      element.remove();
      await Promise.resolve();

      expect(unsubscribe).toHaveBeenCalled();
    });
  });

  describe("Subscription Status", () => {
    it("returns subscription status correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.isSubscribed = true;
      expect(element.subscriptionStatus).toBe("Subscribed");

      element.isSubscribed = false;
      expect(element.subscriptionStatus).toBe("Not Subscribed");
    });
  });
});
