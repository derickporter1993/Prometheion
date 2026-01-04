import { LightningElement, track } from "lwc";
import getAISettings from "@salesforce/apex/SentinelAISettingsController.getSettings";
import saveAISettings from "@salesforce/apex/SentinelAISettingsController.saveSettings";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class SentinelAiSettings extends LightningElement {
  @track enableAI = true;
  @track requireApproval = true;
  @track autoRemediate = false;
  @track confidenceThreshold = 0.85;
  @track blacklistedUsers = "";

  connectedCallback() {
    this.loadSettings();
  }

  loadSettings() {
    getAISettings()
      .then((result) => {
        this.enableAI = result.Enable_AI_Reasoning__c;
        this.requireApproval = result.Require_Human_Approval__c;
        this.autoRemediate = result.Auto_Remediation_Enabled__c;
        this.confidenceThreshold = result.Confidence_Threshold__c;
        this.blacklistedUsers = result.Blacklisted_Users__c || "";
      })
      .catch((error) => {
        this.showToast("Load Error", error.body.message, "error");
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
        this.showToast("Save Error", error.body.message, "error");
      });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
