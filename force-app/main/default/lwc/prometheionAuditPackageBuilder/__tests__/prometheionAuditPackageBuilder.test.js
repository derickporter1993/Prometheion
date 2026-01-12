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
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

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

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Input Handlers", () => {
    it("handles framework change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "HIPAA" },
      });

      element.handleFrameworkChange(event);

      expect(element.framework).toBe("HIPAA");
    });

    it("handles package name change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = {
        target: { value: "Q1 2025 Audit Package" },
      };

      element.handlePackageNameChange(event);

      expect(element.packageName).toBe("Q1 2025 Audit Package");
    });

    it("handles start date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "2025-01-01" },
      });

      element.handleStartDateChange(event);

      expect(element.startDate).toBe("2025-01-01");
    });

    it("handles end date change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "2025-03-31" },
      });

      element.handleEndDateChange(event);

      expect(element.endDate).toBe("2025-03-31");
    });
  });

  describe("Package Generation", () => {
    it("generates package successfully and navigates", async () => {
      generateAuditPackage.mockResolvedValue("001xx0000000001");

      const element = await createComponent();
      await Promise.resolve();

      element.packageName = "Q1 2025 Package";
      element.startDate = "2025-01-01";
      element.endDate = "2025-03-31";

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      await element.handleGenerate();
      await Promise.resolve();

      expect(generateAuditPackage).toHaveBeenCalledWith({
        framework: "SOC2",
        packageName: "Q1 2025 Package",
        startDate: "2025-01-01",
        endDate: "2025-03-31",
      });
      expect(mockNavigate).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });

    it("validates required fields", async () => {
      const element = await createComponent();
      await Promise.resolve();

      element.packageName = "";
      element.startDate = "";
      element.endDate = "";

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      await element.handleGenerate();
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

      element.packageName = "Test Package";
      element.startDate = "2025-01-01";
      element.endDate = "2025-03-31";

      await element.handleGenerate();
      await Promise.resolve();

      expect(element.isLoading).toBe(false);
    });
  });
});
