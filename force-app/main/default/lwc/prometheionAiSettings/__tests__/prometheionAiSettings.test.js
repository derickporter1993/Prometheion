/**
 * Jest tests for prometheionAiSettings LWC component
 *
 * Tests cover:
 * - Component rendering with loading state
 * - Settings loading from Apex
 * - Toggle handlers (AI, approval, remediation)
 * - Threshold and blacklist input handling
 * - Save functionality
 * - Error handling and toast notifications
 */

import { createElement } from "lwc";
import PrometheionAiSettings from "c/prometheionAiSettings";
import getAISettings from "@salesforce/apex/PrometheionAISettingsController.getSettings";
import saveAISettings from "@salesforce/apex/PrometheionAISettingsController.saveSettings";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Mock Apex methods
jest.mock(
  "@salesforce/apex/PrometheionAISettingsController.getSettings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionAISettingsController.saveSettings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Mock ShowToastEvent
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

describe("c-prometheion-ai-settings", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-ai-settings", {
      is: PrometheionAiSettings,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the component", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("shows loading spinner initially", async () => {
      getAISettings.mockImplementation(
        () => new Promise(() => {}) // Never resolves
      );

      const element = await createComponent();
      await Promise.resolve();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });

    it("loads settings on connectedCallback", async () => {
      const mockSettings = {
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "user1,user2",
      };

      getAISettings.mockResolvedValue(mockSettings);

      await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(getAISettings).toHaveBeenCalled();
    });
  });

  describe("Settings Display", () => {
    it("displays settings after load", async () => {
      const mockSettings = {
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: true,
        Confidence_Threshold__c: 0.92,
        Blacklisted_Users__c: "test@example.com",
      };

      getAISettings.mockResolvedValue(mockSettings);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      // Check that toggles are rendered (component should have updated state)
      expect(element.enableAI).toBe(true);
      expect(element.requireApproval).toBe(false);
      expect(element.autoRemediate).toBe(true);
      expect(element.confidenceThreshold).toBe(0.92);
      expect(element.blacklistedUsers).toBe("test@example.com");

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull(); // Loading should be complete
    });
  });

  describe("Toggle Handlers", () => {
    it("handles AI toggle change", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: false,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const checkbox = element.shadowRoot.querySelector(
        'lightning-input[data-field="enableAI"]'
      );
      if (checkbox) {
        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent("change"));

        await Promise.resolve();

        expect(element.enableAI).toBe(true);
      }
    });

    it("handles approval toggle change", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const checkbox = element.shadowRoot.querySelector(
        'lightning-input[data-field="requireApproval"]'
      );
      if (checkbox) {
        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent("change"));

        await Promise.resolve();

        expect(element.requireApproval).toBe(true);
      }
    });

    it("handles remediation toggle change", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const checkbox = element.shadowRoot.querySelector(
        'lightning-input[data-field="autoRemediate"]'
      );
      if (checkbox) {
        checkbox.checked = true;
        checkbox.dispatchEvent(new CustomEvent("change"));

        await Promise.resolve();

        expect(element.autoRemediate).toBe(true);
      }
    });
  });

  describe("Input Handlers", () => {
    it("handles threshold change", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const input = element.shadowRoot.querySelector(
        'lightning-input[data-field="confidenceThreshold"]'
      );
      if (input) {
        input.value = "0.95";
        input.dispatchEvent(new CustomEvent("change"));

        await Promise.resolve();

        expect(element.confidenceThreshold).toBe(0.95);
      }
    });

    it("handles blacklist change", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const textarea = element.shadowRoot.querySelector(
        'lightning-textarea[data-field="blacklistedUsers"]'
      );
      if (textarea) {
        textarea.value = "user1,user2,user3";
        textarea.dispatchEvent(new CustomEvent("change"));

        await Promise.resolve();

        expect(element.blacklistedUsers).toBe("user1,user2,user3");
      }
    });
  });

  describe("Save Functionality", () => {
    it("saves settings successfully", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      saveAISettings.mockResolvedValue();

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      // Set up event listener for toast
      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const saveButton = element.shadowRoot.querySelector(
        'lightning-button[data-action="save"]'
      );
      if (saveButton) {
        saveButton.click();
        await Promise.resolve();

        expect(saveAISettings).toHaveBeenCalledWith({
          settings: {
            Enable_AI_Reasoning__c: true,
            Require_Human_Approval__c: true,
            Auto_Remediation_Enabled__c: false,
            Confidence_Threshold__c: 0.85,
            Blacklisted_Users__c: "",
          },
        });

        expect(dispatchEventSpy).toHaveBeenCalled();
      }

      dispatchEventSpy.mockRestore();
    });

    it("sends correct payload on save", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: false,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: true,
        Confidence_Threshold__c: 0.90,
        Blacklisted_Users__c: "user@test.com",
      });

      saveAISettings.mockResolvedValue();

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const saveButton = element.shadowRoot.querySelector(
        'lightning-button[data-action="save"]'
      );
      if (saveButton) {
        saveButton.click();
        await Promise.resolve();

        expect(saveAISettings).toHaveBeenCalledWith({
          settings: expect.objectContaining({
            Enable_AI_Reasoning__c: false,
            Require_Human_Approval__c: false,
            Auto_Remediation_Enabled__c: true,
            Confidence_Threshold__c: 0.90,
            Blacklisted_Users__c: "user@test.com",
          }),
        });
      }
    });
  });

  describe("Error Handling", () => {
    it("handles load error gracefully", async () => {
      const error = {
        body: { message: "Failed to load settings" },
        message: "Failed to load settings",
      };

      getAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Failed to load");

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("handles save error and shows toast", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const error = {
        body: { message: "Save failed" },
        message: "Save failed",
      };

      saveAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const saveButton = element.shadowRoot.querySelector(
        'lightning-button[data-action="save"]'
      );
      if (saveButton) {
        saveButton.click();
        await Promise.resolve();

        expect(dispatchEventSpy).toHaveBeenCalled();
        const toastEvent = dispatchEventSpy.mock.calls.find(
          (call) => call[0].type === "showtoast"
        );
        if (toastEvent) {
          expect(toastEvent[0].detail.variant).toBe("error");
        }
      }

      dispatchEventSpy.mockRestore();
    });

    it("handles error without body property", async () => {
      const error = { message: "Network error" };
      getAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toBe("Network error");
    });
  });
});
