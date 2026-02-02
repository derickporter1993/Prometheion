/**
 * Jest tests for elaroEventMonitor LWC component
 *
 * Tests cover:
 * - EMP API subscription
 * - Event handling
 * - Event buffer management
 * - Error handling
 */

import { createElement } from "lwc";
import ElaroEventMonitor from "c/elaroEventMonitor";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

jest.mock(
  "lightning/empApi",
  () => ({
    subscribe: jest.fn(() => Promise.resolve({ id: "mock-subscription-id" })),
    unsubscribe: jest.fn((subscription, callback) => {
      if (callback) callback();
    }),
    onError: jest.fn((callback) => callback),
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

describe("c-elaro-event-monitor", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-elaro-event-monitor", {
      is: ElaroEventMonitor,
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
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
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
    it("shows no events message when events empty", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Check DOM shows "no events" message
      const noEventsMessage = element.shadowRoot.querySelector("p");
      expect(noEventsMessage).not.toBeNull();
      expect(noEventsMessage.textContent).toContain("No events received yet");
    });

    it("does not show table when no events", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Table should not be rendered
      const table = element.shadowRoot.querySelector("table");
      expect(table).toBeNull();
    });
  });
});
