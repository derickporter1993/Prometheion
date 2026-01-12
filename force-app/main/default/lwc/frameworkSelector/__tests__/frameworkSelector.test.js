/**
 * Jest tests for frameworkSelector LWC component
 *
 * Tests cover:
 * - Component rendering states
 * - Framework selection functionality
 * - Custom event dispatching
 * - Empty state handling
 */

import { createElement } from "lwc";
import FrameworkSelector from "c/frameworkSelector";

describe("c-framework-selector", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // Helper function to create element
  function createComponent(frameworks = []) {
    const element = createElement("c-framework-selector", {
      is: FrameworkSelector,
    });
    element.frameworks = frameworks;
    document.body.appendChild(element);
    return element;
  }

  // Test data
  const mockFrameworks = [
    { framework: "SOC2", score: 85 },
    { framework: "HIPAA", score: 78 },
    { framework: "GDPR", score: 92 },
    { framework: "PCI-DSS", score: 71 },
  ];

  describe("Component Rendering", () => {
    it("should render lightning-card", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Select Framework");
    });

    it("should display combobox when frameworks provided", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
    });

    it("should format framework options correctly", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox.options).toHaveLength(4);
      expect(combobox.options[0].label).toBe("SOC2 (85%)");
      expect(combobox.options[0].value).toBe("SOC2");
    });
  });

  describe("Empty State", () => {
    it("should show empty message when no frameworks", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector(
        ".slds-text-color_weak"
      );
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No frameworks available");
    });

    it("should not show combobox when no frameworks", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).toBeNull();
    });
  });

  describe("Framework Selection", () => {
    it("should dispatch frameworkselected event on selection", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      // Add event listener
      const handler = jest.fn();
      element.addEventListener("frameworkselected", handler);

      // Simulate selection
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "HIPAA" },
        })
      );

      await Promise.resolve();

      expect(handler).toHaveBeenCalled();
      expect(handler.mock.calls[0][0].detail.framework).toBe("HIPAA");
    });

    it("should update selected value on change", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "GDPR" },
        })
      );

      await Promise.resolve();

      // Dispatch another event to verify the previous selection was stored
      const handler = jest.fn();
      element.addEventListener("frameworkselected", handler);

      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "SOC2" },
        })
      );

      await Promise.resolve();
      expect(handler.mock.calls[0][0].detail.framework).toBe("SOC2");
    });
  });

  describe("Multiple Selections", () => {
    it("should handle multiple sequential selections", async () => {
      const element = createComponent(mockFrameworks);
      await Promise.resolve();

      const handler = jest.fn();
      element.addEventListener("frameworkselected", handler);

      const combobox = element.shadowRoot.querySelector("lightning-combobox");

      // First selection
      combobox.dispatchEvent(
        new CustomEvent("change", { detail: { value: "HIPAA" } })
      );
      await Promise.resolve();

      // Second selection
      combobox.dispatchEvent(
        new CustomEvent("change", { detail: { value: "GDPR" } })
      );
      await Promise.resolve();

      // Third selection
      combobox.dispatchEvent(
        new CustomEvent("change", { detail: { value: "SOC2" } })
      );
      await Promise.resolve();

      expect(handler).toHaveBeenCalledTimes(3);
      expect(handler.mock.calls[0][0].detail.framework).toBe("HIPAA");
      expect(handler.mock.calls[1][0].detail.framework).toBe("GDPR");
      expect(handler.mock.calls[2][0].detail.framework).toBe("SOC2");
    });
  });

  describe("Framework Options Formatting", () => {
    it("should handle frameworks with various score values", async () => {
      const variedFrameworks = [
        { framework: "TEST1", score: 0 },
        { framework: "TEST2", score: 100 },
        { framework: "TEST3", score: 50 },
      ];
      const element = createComponent(variedFrameworks);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox.options).toHaveLength(3);
      expect(combobox.options[0].label).toBe("TEST1 (0%)");
      expect(combobox.options[1].label).toBe("TEST2 (100%)");
      expect(combobox.options[2].label).toBe("TEST3 (50%)");
    });
  });

  describe("Single Framework", () => {
    it("should display single framework option", async () => {
      const singleFramework = [{ framework: "SOC2", score: 95 }];
      const element = createComponent(singleFramework);
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox.options).toHaveLength(1);
      expect(combobox.options[0].label).toBe("SOC2 (95%)");
    });
  });
});
