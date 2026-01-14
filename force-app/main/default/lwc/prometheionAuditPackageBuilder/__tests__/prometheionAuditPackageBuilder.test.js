/**
 * Jest tests for prometheionAuditPackageBuilder LWC component
 *
 * Tests cover:
 * - Form input handling
 * - Package generation
 * - Navigation
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionAuditPackageBuilder from "c/prometheionAuditPackageBuilder";
import generateAuditPackage from "@salesforce/apex/PrometheionAuditPackageGenerator.generateAuditPackage";

jest.mock(
  "@salesforce/apex/PrometheionAuditPackageGenerator.generateAuditPackage",
  () => ({ default: jest.fn() }),
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

const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: (Base) => {
      return class extends Base {
        [Symbol.for("NavigationMixin.Navigate")](pageReference) {
          return mockNavigate(pageReference);
        }
      };
    },
  }),
  { virtual: true }
);

describe("c-prometheion-audit-package-builder", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-audit-package-builder", {
      is: PrometheionAuditPackageBuilder,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  function getPackageNameInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Package Name");
  }

  function getFrameworkCombobox(element) {
    const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
    return Array.from(comboboxes).find((cb) => cb.label === "Framework");
  }

  function getStartDateInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Audit Period Start");
  }

  function getEndDateInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Audit Period End");
  }

  function getGenerateButton(element) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((btn) => btn.label === "Generate Audit Package");
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    });

    it("renders all form fields", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(getPackageNameInput(element)).not.toBeNull();
      expect(getFrameworkCombobox(element)).not.toBeNull();
      expect(getStartDateInput(element)).not.toBeNull();
      expect(getEndDateInput(element)).not.toBeNull();
      expect(getGenerateButton(element)).not.toBeNull();
    });
  });

  describe("Input Handlers", () => {
    it("handles framework change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const combobox = getFrameworkCombobox(element);
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "HIPAA" } }));
      await Promise.resolve();

      // Verify the combobox value is updated in DOM
      expect(combobox.value).toBe("HIPAA");
    });

    it("handles package name change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getPackageNameInput(element);
      input.value = "Q1 2025 Audit Package";
      input.dispatchEvent(new Event("change"));
      await Promise.resolve();

      expect(input.value).toBe("Q1 2025 Audit Package");
    });

    it("handles start date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getStartDateInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));
      await Promise.resolve();

      expect(input.value).toBe("2025-01-01");
    });

    it("handles end date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getEndDateInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));
      await Promise.resolve();

      expect(input.value).toBe("2025-03-31");
    });
  });

  describe("Package Generation", () => {
    it("calls generateAuditPackage when form is submitted", async () => {
      generateAuditPackage.mockResolvedValue("001xx0000000001");

      const element = await createComponent();
      await Promise.resolve();

      // Set form values via DOM events
      const packageNameInput = getPackageNameInput(element);
      packageNameInput.value = "Q1 2025 Package";
      packageNameInput.dispatchEvent(new Event("change"));

      const startDateInput = getStartDateInput(element);
      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));

      const endDateInput = getEndDateInput(element);
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));
      await Promise.resolve();

      // Click the generate button
      const button = getGenerateButton(element);
      button.click();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Verify the Apex method was called with correct parameters
      expect(generateAuditPackage).toHaveBeenCalledWith({
        framework: "SOC2",
        packageName: "Q1 2025 Package",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
      });
    });

    it("validates required fields", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Don't set any form values - leave them empty
      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      // Click the generate button without filling form
      const button = getGenerateButton(element);
      button.click();
      await Promise.resolve();
      await Promise.resolve();

      expect(generateAuditPackage).not.toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });

    it("handles generation error", async () => {
      const error = {
        body: { message: "Generation failed" },
        message: "Generation failed",
      };

      generateAuditPackage.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      // Set form values
      const packageNameInput = getPackageNameInput(element);
      packageNameInput.value = "Test Package";
      packageNameInput.dispatchEvent(new Event("change"));

      const startDateInput = getStartDateInput(element);
      startDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-01-01" } }));

      const endDateInput = getEndDateInput(element);
      endDateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "2025-03-31" } }));
      await Promise.resolve();

      // Click the generate button
      const button = getGenerateButton(element);
      button.click();
      await Promise.resolve();
      await Promise.resolve();

      // After error, button should not be disabled (isLoading should be false)
      expect(button.disabled).toBe(false);
    });
  });
});
