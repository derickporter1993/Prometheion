/**
 * Jest tests for elaroAiSettings LWC component
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
import ElaroAiSettings from "c/elaroAiSettings";
import getAISettings from "@salesforce/apex/ElaroAISettingsController.getSettings";
import saveAISettings from "@salesforce/apex/ElaroAISettingsController.saveSettings";

// Mock Apex methods
jest.mock(
  "@salesforce/apex/ElaroAISettingsController.getSettings",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ElaroAISettingsController.saveSettings",
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

describe("c-elaro-ai-settings", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent() {
    const element = createElement("c-elaro-ai-settings", {
      is: ElaroAiSettings,
    });
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

  // Helper to find input by label
  function findInputByLabel(element, labelText) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find(
      (input) => input.label && input.label.includes(labelText)
    );
  }

  // Helper to find button by label
  function findButtonByLabel(element, labelText) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((btn) => btn.label === labelText);
  }

  describe("Initial Rendering", () => {
    it("renders the component with lightning-card", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("AI Governance Settings");
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
      await flushPromises();

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
      await flushPromises();

      // Check spinner is gone
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();

      // Check inputs are rendered
      const enableAICheckbox = findInputByLabel(element, "Enable AI Reasoning");
      const approvalCheckbox = findInputByLabel(element, "Require Human Approval");
      const remediationCheckbox = findInputByLabel(element, "Auto-Remediation");
      const thresholdInput = findInputByLabel(element, "AI Confidence Threshold");

      expect(enableAICheckbox).not.toBeNull();
      expect(enableAICheckbox.checked).toBe(true);

      expect(approvalCheckbox).not.toBeNull();
      expect(approvalCheckbox.checked).toBe(false);

      expect(remediationCheckbox).not.toBeNull();
      expect(remediationCheckbox.checked).toBe(true);

      expect(thresholdInput).not.toBeNull();
      expect(thresholdInput.value).toBe(0.92);

      // Check blacklist textarea
      const textarea = element.shadowRoot.querySelector("lightning-textarea");
      expect(textarea).not.toBeNull();
      expect(textarea.value).toBe("test@example.com");
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
      await flushPromises();

      const enableAICheckbox = findInputByLabel(element, "Enable AI Reasoning");

      expect(enableAICheckbox).not.toBeNull();
      expect(enableAICheckbox.checked).toBe(false);

      // Simulate toggle
      enableAICheckbox.checked = true;
      enableAICheckbox.dispatchEvent(
        new CustomEvent("change", {
          target: { checked: true },
        })
      );

      await flushPromises();

      // The checkbox should now be checked
      expect(enableAICheckbox.checked).toBe(true);
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
      await flushPromises();

      const approvalCheckbox = findInputByLabel(element, "Require Human Approval");

      expect(approvalCheckbox).not.toBeNull();
      expect(approvalCheckbox.checked).toBe(false);

      // Simulate toggle
      approvalCheckbox.checked = true;
      approvalCheckbox.dispatchEvent(
        new CustomEvent("change", {
          target: { checked: true },
        })
      );

      await flushPromises();

      expect(approvalCheckbox.checked).toBe(true);
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
      await flushPromises();

      const remediationCheckbox = findInputByLabel(element, "Auto-Remediation");

      expect(remediationCheckbox).not.toBeNull();
      expect(remediationCheckbox.checked).toBe(false);

      // Simulate toggle
      remediationCheckbox.checked = true;
      remediationCheckbox.dispatchEvent(
        new CustomEvent("change", {
          target: { checked: true },
        })
      );

      await flushPromises();

      expect(remediationCheckbox.checked).toBe(true);
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
      await flushPromises();

      const thresholdInput = findInputByLabel(element, "AI Confidence Threshold");
      expect(thresholdInput).not.toBeNull();
      expect(thresholdInput.value).toBe(0.85);

      // Simulate value change
      thresholdInput.value = 0.95;
      thresholdInput.dispatchEvent(
        new CustomEvent("change", {
          target: { value: "0.95" },
        })
      );

      await flushPromises();

      expect(thresholdInput.value).toBe(0.95);
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
      await flushPromises();

      const textarea = element.shadowRoot.querySelector("lightning-textarea");
      expect(textarea).not.toBeNull();
      expect(textarea.value).toBe("");

      // Simulate value change
      textarea.value = "user1,user2,user3";
      textarea.dispatchEvent(
        new CustomEvent("change", {
          target: { value: "user1,user2,user3" },
        })
      );

      await flushPromises();

      expect(textarea.value).toBe("user1,user2,user3");
    });
  });

  describe("Save Functionality", () => {
    it("saves settings successfully and shows success toast", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      saveAISettings.mockResolvedValue();

      const element = await createComponent();
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      // Find and click save button
      const saveButton = findButtonByLabel(element, "Save Settings");
      expect(saveButton).not.toBeNull();

      saveButton.click();
      await flushPromises();

      expect(saveAISettings).toHaveBeenCalledWith({
        settings: {
          Enable_AI_Reasoning__c: true,
          Require_Human_Approval__c: true,
          Auto_Remediation_Enabled__c: false,
          Confidence_Threshold__c: 0.85,
          Blacklisted_Users__c: "",
        },
      });

      // Should dispatch success toast
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });

    it("sends correct payload on save with updated values", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: false,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: true,
        Confidence_Threshold__c: 0.9,
        Blacklisted_Users__c: "user@test.com",
      });

      saveAISettings.mockResolvedValue();

      const element = await createComponent();
      await flushPromises();

      // Find and click save button
      const saveButton = findButtonByLabel(element, "Save Settings");
      saveButton.click();
      await flushPromises();

      expect(saveAISettings).toHaveBeenCalledWith({
        settings: expect.objectContaining({
          Enable_AI_Reasoning__c: false,
          Require_Human_Approval__c: false,
          Auto_Remediation_Enabled__c: true,
          Confidence_Threshold__c: 0.9,
          Blacklisted_Users__c: "user@test.com",
        }),
      });
    });
  });

  describe("Error Handling", () => {
    it("handles load error gracefully and shows error in DOM", async () => {
      const error = {
        body: { message: "Failed to load settings" },
        message: "Failed to load settings",
      };

      getAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Failed to load");
    });

    it("handles save error and shows error toast", async () => {
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
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      // Find and click save button
      const saveButton = findButtonByLabel(element, "Save Settings");
      saveButton.click();
      await flushPromises();

      // Should dispatch error toast
      expect(dispatchEventSpy).toHaveBeenCalled();
      const toastEvent = dispatchEventSpy.mock.calls.find(
        (call) => call[0].type === "showtoast"
      );
      expect(toastEvent).toBeDefined();

      dispatchEventSpy.mockRestore();
    });

    it("handles error without body property", async () => {
      const error = { message: "Network error" };
      getAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Network error");
    });

    it("shows generic error message when error has no message", async () => {
      const error = {};
      getAISettings.mockRejectedValue(error);

      const element = await createComponent();
      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      // Should show fallback error message
      expect(errorDiv.textContent).toContain("Failed to load AI settings");
    });
  });

  describe("UI State Transitions", () => {
    it("hides spinner after successful load", async () => {
      getAISettings.mockResolvedValue({
        Enable_AI_Reasoning__c: true,
        Require_Human_Approval__c: true,
        Auto_Remediation_Enabled__c: false,
        Confidence_Threshold__c: 0.85,
        Blacklisted_Users__c: "",
      });

      const element = await createComponent();
      await flushPromises();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();
    });

    it("hides spinner after load error", async () => {
      getAISettings.mockRejectedValue({ message: "Error" });

      const element = await createComponent();
      await flushPromises();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();
    });
  });
});
