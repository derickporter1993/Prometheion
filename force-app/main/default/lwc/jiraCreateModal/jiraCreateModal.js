import { LightningElement, api, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createIssue from "@salesforce/apex/JiraIntegrationService.createIssue";
import isConfigured from "@salesforce/apex/JiraIntegrationService.isConfigured";

export default class JiraCreateModal extends LightningElement {
  @api recordId; // Compliance_Gap__c Id

  @track isOpen = false;
  @track isLoading = false;
  @track isConfigured = false;
  @track selectedPriority = "";
  @track error = null;

  get priorityOptions() {
    return [
      { label: "Highest", value: "Highest" },
      { label: "High", value: "High" },
      { label: "Medium", value: "Medium" },
      { label: "Low", value: "Low" },
      { label: "Lowest", value: "Lowest" },
    ];
  }

  get isCreateDisabled() {
    return this.isLoading || !this.isConfigured;
  }

  connectedCallback() {
    this.checkConfiguration();
  }

  async checkConfiguration() {
    try {
      this.isConfigured = await isConfigured();
    } catch {
      this.isConfigured = false;
    }
  }

  @api
  open() {
    this.isOpen = true;
    this.error = null;
    this.selectedPriority = "";
    this.checkConfiguration();
  }

  @api
  close() {
    this.isOpen = false;
    this.error = null;
  }

  handlePriorityChange(event) {
    this.selectedPriority = event.detail.value;
  }

  handleClose() {
    this.close();
  }

  async handleCreate() {
    if (!this.recordId) {
      this.showToast("Error", "No record ID provided", "error");
      return;
    }

    this.isLoading = true;
    this.error = null;

    try {
      const result = await createIssue({
        gapId: this.recordId,
        priority: this.selectedPriority || null,
      });

      this.showToast("Success", `Jira issue ${result.key} created successfully`, "success");

      // Dispatch event to notify parent
      this.dispatchEvent(
        new CustomEvent("issuecreated", {
          detail: {
            issueKey: result.key,
            issueUrl: result.url,
          },
        })
      );

      this.close();
    } catch (err) {
      this.error = this.getErrorMessage(err);
      this.showToast("Error", this.error, "error");
    } finally {
      this.isLoading = false;
    }
  }

  getErrorMessage(error) {
    if (error?.body?.message) return error.body.message;
    if (error?.message) return error.message;
    return "An unexpected error occurred";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
