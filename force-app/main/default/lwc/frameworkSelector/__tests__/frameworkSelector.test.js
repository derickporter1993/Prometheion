/**
 * Jest tests for frameworkSelector LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Framework selection
 * - Empty state handling
 * - Event dispatching
 */

import { createElement } from "lwc";
import FrameworkSelector from "c/frameworkSelector";

describe("c-framework-selector", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-framework-selector", {
      is: FrameworkSelector,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  // Helper to flush all pending promises
  async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
  }

  describe("Rendering", () => {
    it("renders the component with lightning-card", async () => {
      const element = await createComponent({ frameworks: [] });
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Select Framework");
    });

    it("shows empty state when no frameworks provided", async () => {
      const element = await createComponent({ frameworks: [] });
      await flushPromises();

      const emptyDiv = element.shadowRoot.querySelector(".slds-text-align_center");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No frameworks available");
    });

    it("shows combobox when frameworks are provided", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
    });

    it("does not show empty state when frameworks exist", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      // The empty state div should not be present when frameworks exist
      const emptyDiv = element.shadowRoot.querySelector(
        ".slds-text-color_weak.slds-text-align_center"
      );
      expect(emptyDiv).toBeNull();
    });
  });

  describe("Framework Selection", () => {
    it("displays frameworks in combobox", async () => {
      const frameworks = [
        { framework: "SOC2", score: 85 },
        { framework: "HIPAA", score: 72 },
        { framework: "GDPR", score: 90 },
      ];

      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.options).toBeDefined();
      expect(combobox.options.length).toBe(3);
    });

    it("formats framework options correctly with score percentage", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.options).toEqual([{ label: "SOC2 (85%)", value: "SOC2" }]);
    });

    it("handles framework change event and dispatches custom event", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");
      const combobox = element.shadowRoot.querySelector("lightning-combobox");

      expect(combobox).not.toBeNull();

      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "SOC2" },
        })
      );

      await flushPromises();

      // Check that custom event was dispatched
      expect(dispatchEventSpy).toHaveBeenCalled();
      const customEvent = dispatchEventSpy.mock.calls[0][0];
      expect(customEvent.type).toBe("frameworkselected");
      expect(customEvent.detail.framework).toBe("SOC2");

      dispatchEventSpy.mockRestore();
    });

    it("updates combobox value after selection", async () => {
      const frameworks = [
        { framework: "SOC2", score: 85 },
        { framework: "HIPAA", score: 72 },
      ];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");

      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "HIPAA" },
        })
      );

      await flushPromises();

      // The combobox value should reflect the selection
      expect(combobox.value).toBe("HIPAA");
    });
  });

  describe("State Management", () => {
    it("shows combobox when frameworks exist", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
    });

    it("does not show combobox when no frameworks", async () => {
      const element = await createComponent({ frameworks: [] });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).toBeNull();
    });
  });

  describe("Edge Cases", () => {
    it("handles null frameworks gracefully", async () => {
      const element = await createComponent({ frameworks: null });
      await flushPromises();

      // Component should render without crashing
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();

      // Combobox should not be shown
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).toBeNull();
    });

    it("handles frameworks with zero score", async () => {
      const frameworks = [{ framework: "SOC2", score: 0 }];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.options).toEqual([{ label: "SOC2 (0%)", value: "SOC2" }]);
    });

    it("handles multiple frameworks with same score", async () => {
      const frameworks = [
        { framework: "SOC2", score: 85 },
        { framework: "HIPAA", score: 85 },
      ];
      const element = await createComponent({ frameworks });
      await flushPromises();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.options.length).toBe(2);
    });

    it("handles undefined frameworks gracefully", async () => {
      const element = await createComponent({ frameworks: undefined });
      await flushPromises();

      // Component should render without crashing
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("handles empty array of frameworks", async () => {
      const element = await createComponent({ frameworks: [] });
      await flushPromises();

      // Should show empty state
      const emptyDiv = element.shadowRoot.querySelector(".slds-text-align_center");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No frameworks available");
    });
  });
});
