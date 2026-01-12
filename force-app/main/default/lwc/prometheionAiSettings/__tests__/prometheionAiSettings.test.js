/**
 * Jest tests for prometheionAiSettings LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Settings loading from Apex
 * - Toggle handlers
 * - Save functionality
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionAiSettings from "c/prometheionAiSettings";
import getAISettings from "@salesforce/apex/PrometheionAISettingsController.getSettings";
import saveAISettings from "@salesforce/apex/PrometheionAISettingsController.saveSettings";

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

// Mock settings data
const mockSettings = {
  Enable_AI_Reasoning__c: true,
  Require_Human_Approval__c: true,
  Auto_Remediation_Enabled__c: false,
  Confidence_Threshold__c: 0.85,
  Blacklisted_Users__c: "005xx000001Sv6z",
};

describe("c-prometheion-ai-settings", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  // Helper function to create element
  async function createComponent() {
    const element = createElement("c-prometheion-ai-settings", {
      is: PrometheionAiSettings,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  // Helper to flush promises
  async function flushPromises() {
    return Promise.resolve();
  }

  describe("Component Rendering", () => {
    it("should render lightning-card", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("AI Governance Settings");
      expect(card.iconName).toBe("custom:custom30");
    });

    it("should show spinner while loading", async () => {
      // Don't resolve the promise to keep loading state
      getAISettings.mockImplementation(() => new Promise(() => {}));
      const element = await createComponent();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
      expect(spinner.alternativeText).toBe("Loading AI settings");
    });

    it("should display settings form when loaded", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      expect(inputs.length).toBeGreaterThan(0);
    });
  });

  describe("Settings Loading", () => {
    it("should call getAISettings on connectedCallback", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      await createComponent();
      await flushPromises();

      expect(getAISettings).toHaveBeenCalled();
    });

    it("should populate form with loaded settings", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      // Find checkbox inputs
      const checkboxes = Array.from(inputs).filter(
        (input) => input.type === "checkbox"
      );
      expect(checkboxes.length).toBe(3);
    });

    it("should handle load error by setting error state", async () => {
      getAISettings.mockRejectedValue({ message: "Load failed" });
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Verify error state was set
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("should display error message on load failure", async () => {
      getAISettings.mockRejectedValue({ message: "Load failed" });
      const element = await createComponent();
      await flushPromises();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });
  });

  describe("Toggle Handlers", () => {
    it("should handle AI toggle change", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      const aiToggle = Array.from(inputs).find(
        (input) => input.label === "Enable AI Reasoning"
      );
      expect(aiToggle).not.toBeNull();

      // Simulate toggle change
      aiToggle.dispatchEvent(
        new CustomEvent("change", { target: { checked: false } })
      );
      await flushPromises();
    });

    it("should handle approval toggle change", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      const approvalToggle = Array.from(inputs).find((input) =>
        input.label.includes("Human Approval")
      );
      expect(approvalToggle).not.toBeNull();
    });

    it("should handle remediation toggle change", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      const remediationToggle = Array.from(inputs).find((input) =>
        input.label.includes("Auto-Remediation")
      );
      expect(remediationToggle).not.toBeNull();
    });
  });

  describe("Threshold and Blacklist", () => {
    it("should display threshold input", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      const thresholdInput = Array.from(inputs).find(
        (input) => input.type === "number"
      );
      expect(thresholdInput).not.toBeNull();
      expect(thresholdInput.min).toBe("0.0");
      expect(thresholdInput.max).toBe("1.0");
    });

    it("should display blacklist textarea", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const textarea = element.shadowRoot.querySelector("lightning-textarea");
      expect(textarea).not.toBeNull();
      expect(textarea.label).toContain("Blacklisted Users");
    });

    it("should display help text for blacklist", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const helpText = element.shadowRoot.querySelector("#blacklistedUsersHelp");
      expect(helpText).not.toBeNull();
      expect(helpText.textContent).toContain("Enter one or more Salesforce User IDs");
    });
  });

  describe("Save Functionality", () => {
    it("should display save button", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      const element = await createComponent();
      await flushPromises();

      const button = element.shadowRoot.querySelector("lightning-button");
      expect(button).not.toBeNull();
      expect(button.label).toBe("Save Settings");
      expect(button.variant).toBe("brand");
    });

    it("should call saveAISettings on save click", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      saveAISettings.mockResolvedValue();
      const element = await createComponent();
      await flushPromises();

      const button = element.shadowRoot.querySelector("lightning-button");
      button.click();
      await flushPromises();

      expect(saveAISettings).toHaveBeenCalled();
    });

    it("should successfully save settings when save button clicked", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      saveAISettings.mockResolvedValue();
      const element = await createComponent();
      await flushPromises();

      const button = element.shadowRoot.querySelector("lightning-button");
      button.click();
      await flushPromises();

      // Verify save was called with correct settings
      expect(saveAISettings).toHaveBeenCalled();
      const callArgs = saveAISettings.mock.calls[0][0];
      expect(callArgs.settings.Enable_AI_Reasoning__c).toBe(true);
      expect(callArgs.settings.Require_Human_Approval__c).toBe(true);
    });

    it("should handle save failure gracefully", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      saveAISettings.mockRejectedValue({ message: "Save failed" });
      const element = await createComponent();
      await flushPromises();

      const button = element.shadowRoot.querySelector("lightning-button");
      button.click();
      await flushPromises();

      // Verify save was attempted even though it failed
      expect(saveAISettings).toHaveBeenCalled();
      // Form should still be displayed (no crash)
      const inputs = element.shadowRoot.querySelectorAll("lightning-input");
      expect(inputs.length).toBeGreaterThan(0);
    });

    it("should pass correct settings structure to saveAISettings", async () => {
      getAISettings.mockResolvedValue(mockSettings);
      saveAISettings.mockResolvedValue();
      const element = await createComponent();
      await flushPromises();

      const button = element.shadowRoot.querySelector("lightning-button");
      button.click();
      await flushPromises();

      const callArgs = saveAISettings.mock.calls[0][0];
      expect(callArgs.settings).toHaveProperty("Enable_AI_Reasoning__c");
      expect(callArgs.settings).toHaveProperty("Require_Human_Approval__c");
      expect(callArgs.settings).toHaveProperty("Auto_Remediation_Enabled__c");
      expect(callArgs.settings).toHaveProperty("Confidence_Threshold__c");
      expect(callArgs.settings).toHaveProperty("Blacklisted_Users__c");
    });
  });

  describe("Empty Blacklist", () => {
    it("should handle empty blacklist users", async () => {
      const settingsWithEmptyBlacklist = {
        ...mockSettings,
        Blacklisted_Users__c: null,
      };
      getAISettings.mockResolvedValue(settingsWithEmptyBlacklist);
      const element = await createComponent();
      await flushPromises();

      const textarea = element.shadowRoot.querySelector("lightning-textarea");
      expect(textarea).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("should handle error with body.message format", async () => {
      getAISettings.mockRejectedValue({ body: { message: "Server error" } });
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Verify error state was set
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("should handle error with message format", async () => {
      getAISettings.mockRejectedValue({ message: "Direct error" });
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Verify error state was set
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("should handle error with no message", async () => {
      getAISettings.mockRejectedValue({});
      const element = await createComponent();
      await flushPromises();
      await flushPromises();

      // Verify error state was set with default message
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });
  });
});
