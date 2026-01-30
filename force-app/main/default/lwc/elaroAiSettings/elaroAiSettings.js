import { LightningElement } from "lwc";
import getAISettings from "@salesforce/apex/ElaroAISettingsController.getSettings";
import saveAISettings from "@salesforce/apex/ElaroAISettingsController.saveSettings";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ElaroAiSettings extends LightningElement {
  enableAI = true;
  requireApproval = true;
  autoRemediate = false;
  confidenceThreshold = 0.85;
  blacklistedUsers = "";
  isLoading = true;
  hasError = false;
  errorMessage = "";

  get notLoading() {
    return !this.isLoading;
  }

  get notError() {
    return !this.hasError;
  }

  connectedCallback() {
    this.loadSettings();
  }

  loadSettings() {
    this.isLoading = true;
    this.hasError = false;
    this.errorMessage = "";
    getAISettings()
      .then((result) => {
        this.enableAI = result.Enable_AI_Reasoning__c;
        this.requireApproval = result.Require_Human_Approval__c;
        this.autoRemediate = result.Auto_Remediation_Enabled__c;
        this.confidenceThreshold = result.Confidence_Threshold__c;
        this.blacklistedUsers = result.Blacklisted_Users__c || "";
        this.isLoading = false;
      })
      .catch((error) => {
        this.isLoading = false;
        this.hasError = true;
        this.errorMessage = error?.body?.message || error?.message || "Failed to load AI settings";
        this.showToast("Load Error", this.errorMessage, "error");
      });
  }

  handleToggleAI(event) {
    this.enableAI = event.target.checked;
  }

  handleToggleApproval(event) {
    this.requireApproval = event.target.checked;
  }

  handleToggleRemediation(event) {
    this.autoRemediate = event.target.checked;
  }

  handleThresholdChange(event) {
    this.confidenceThreshold = parseFloat(event.target.value);
  }

  handleBlacklistChange(event) {
    this.blacklistedUsers = event.target.value;
  }

  handleSave() {
    const settings = {
      Enable_AI_Reasoning__c: this.enableAI,
      Require_Human_Approval__c: this.requireApproval,
      Auto_Remediation_Enabled__c: this.autoRemediate,
      Confidence_Threshold__c: this.confidenceThreshold,
      Blacklisted_Users__c: this.blacklistedUsers,
    };

    saveAISettings({ settings: settings })
      .then(() => {
        this.showToast("Success", "AI settings saved successfully", "success");
      })
      .catch((error) => {
        const errorMsg = error?.body?.message || error?.message || "Failed to save AI settings";
        this.showToast("Save Error", errorMsg, "error");
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
