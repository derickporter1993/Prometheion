/**
 * Jest tests for frameworkSelector LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Framework selection
 * - Loading and error states
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

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ frameworks: [] });
      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Select Framework");
    });

    it("shows loading spinner when isLoading is true", async () => {
      const element = await createComponent({ frameworks: [], isLoading: true });
      await Promise.resolve();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });

    it("shows error message when hasError is true", async () => {
      const element = await createComponent({
        frameworks: [],
        hasError: true,
        errorMessage: "Error loading frameworks",
      });
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Error loading frameworks");
    });

    it("shows empty state when no frameworks", async () => {
      const element = await createComponent({ frameworks: [] });
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector(".slds-text-align_center");
      if (emptyDiv) {
        expect(emptyDiv.textContent).toContain("No frameworks available");
      }
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
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.options).toBeDefined();
      expect(combobox.options.length).toBe(3);
    });

    it("formats framework options correctly", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await Promise.resolve();

      expect(element.frameworkOptions).toEqual([
        { label: "SOC2 (85%)", value: "SOC2" },
      ]);
    });

    it("handles framework change event", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");
      const combobox = element.shadowRoot.querySelector("lightning-combobox");

      if (combobox) {
        combobox.dispatchEvent(
          new CustomEvent("change", {
            detail: { value: "SOC2" },
          })
        );

        await Promise.resolve();

        expect(element.selectedFramework).toBe("SOC2");
        expect(dispatchEventSpy).toHaveBeenCalled();
        const customEvent = dispatchEventSpy.mock.calls[0][0];
        expect(customEvent.detail.framework).toBe("SOC2");
        expect(customEvent.type).toBe("frameworkselected");
      }

      dispatchEventSpy.mockRestore();
    });
  });

  describe("State Management", () => {
    it("hasFrameworks returns true when frameworks exist", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      expect(element.hasFrameworks).toBe(true);
    });

    it("hasFrameworks returns false when frameworks empty", async () => {
      const element = await createComponent({ frameworks: [] });
      expect(element.hasFrameworks).toBe(false);
    });

    it("isEmpty returns true when no frameworks and not loading", async () => {
      const element = await createComponent({
        frameworks: [],
        isLoading: false,
        hasError: false,
      });
      expect(element.isEmpty).toBe(true);
    });

    it("isEmpty returns false when frameworks exist", async () => {
      const frameworks = [{ framework: "SOC2", score: 85 }];
      const element = await createComponent({ frameworks });
      expect(element.isEmpty).toBe(false);
    });

    it("notLoading returns true when not loading", async () => {
      const element = await createComponent({ frameworks: [], isLoading: false });
      expect(element.notLoading).toBe(true);
    });

    it("notError returns true when no error", async () => {
      const element = await createComponent({ frameworks: [], hasError: false });
      expect(element.notError).toBe(true);
    });
  });

  describe("Edge Cases", () => {
    it("handles null frameworks gracefully", async () => {
      const element = await createComponent({ frameworks: null });
      expect(element.hasFrameworks).toBe(false);
    });

    it("handles frameworks with zero score", async () => {
      const frameworks = [{ framework: "SOC2", score: 0 }];
      const element = await createComponent({ frameworks });
      await Promise.resolve();

      expect(element.frameworkOptions).toEqual([
        { label: "SOC2 (0%)", value: "SOC2" },
      ]);
    });

    it("handles multiple frameworks with same score", async () => {
      const frameworks = [
        { framework: "SOC2", score: 85 },
        { framework: "HIPAA", score: 85 },
      ];
      const element = await createComponent({ frameworks });
      await Promise.resolve();

      expect(element.frameworkOptions.length).toBe(2);
    });
  });
});
