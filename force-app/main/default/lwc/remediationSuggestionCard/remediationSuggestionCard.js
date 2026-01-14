import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getSuggestions from "@salesforce/apex/RemediationSuggestionService.getSuggestions";
import generateSuggestions from "@salesforce/apex/RemediationSuggestionService.generateSuggestions";
import approveSuggestion from "@salesforce/apex/RemediationSuggestionService.approveSuggestion";
import rejectSuggestion from "@salesforce/apex/RemediationSuggestionService.rejectSuggestion";
import executeRemediation from "@salesforce/apex/RemediationExecutor.executeRemediation";
import markAsManuallyApplied from "@salesforce/apex/RemediationExecutor.markAsManuallyApplied";

const STATUS_VARIANTS = {
  PENDING: "warning",
  APPROVED: "success",
  REJECTED: "error",
  APPLIED: "success",
  FAILED: "error",
};

const TYPE_ICONS = {
  PERMISSION_CHANGE: "utility:key",
  PROFILE_UPDATE: "utility:user",
  FIELD_LEVEL_SECURITY: "utility:lock",
  SHARING_RULE: "utility:share",
  FLOW_MODIFICATION: "utility:flow",
  VALIDATION_RULE: "utility:check",
  TRIGGER_UPDATE: "utility:apex",
  ENCRYPTION: "utility:shield",
  AUDIT_TRAIL: "utility:activity",
  MANUAL_REVIEW: "utility:search",
};

export default class RemediationSuggestionCard extends LightningElement {
  @api recordId; // Compliance_Gap__c record ID
  @track suggestions = [];
  @track isLoading = false;
  @track isRejectModalOpen = false;
  @track isManualApplyModalOpen = false;
  @track selectedSuggestion = null;
  @track rejectionReason = "";
  @track manualNotes = "";

  wiredSuggestionsResult;

  get hasSuggestions() {
    return this.suggestions && this.suggestions.length > 0;
  }

  get pendingSuggestions() {
    return this.suggestions.filter((s) => s.status === "PENDING");
  }

  get approvedSuggestions() {
    return this.suggestions.filter((s) => s.status === "APPROVED");
  }

  get processedSuggestions() {
    return this.suggestions.filter((s) => ["APPLIED", "REJECTED", "FAILED"].includes(s.status));
  }

  get hasPending() {
    return this.pendingSuggestions.length > 0;
  }

  get hasApproved() {
    return this.approvedSuggestions.length > 0;
  }

  get hasProcessed() {
    return this.processedSuggestions.length > 0;
  }

  @wire(getSuggestions, { gapId: "$recordId" })
  wiredSuggestions(result) {
    this.wiredSuggestionsResult = result;
    if (result.data) {
      this.suggestions = result.data.map((suggestion) => this.mapSuggestion(suggestion));
    } else if (result.error) {
      this.handleError(result.error);
    }
  }

  mapSuggestion(suggestion) {
    return {
      id: suggestion.Id,
      name: suggestion.Name,
      type: suggestion.Suggestion_Type__c,
      typeLabel: this.formatTypeLabel(suggestion.Suggestion_Type__c),
      typeIcon: TYPE_ICONS[suggestion.Suggestion_Type__c] || "utility:question",
      description: suggestion.Description__c,
      steps: suggestion.Implementation_Steps__c,
      autoAvailable: suggestion.Auto_Remediation_Available__c,
      status: suggestion.Status__c,
      statusVariant: STATUS_VARIANTS[suggestion.Status__c] || "warning",
      confidence: suggestion.Confidence_Score__c
        ? Math.round(suggestion.Confidence_Score__c * 100)
        : 0,
      riskReduction: suggestion.Risk_Reduction_Score__c,
      effort: suggestion.Effort_Estimate__c,
      effortLabel: this.formatEffortLabel(suggestion.Effort_Estimate__c),
      priority: suggestion.Priority_Score__c,
      framework: suggestion.Framework__c,
      appliedAt: suggestion.Applied_At__c,
      appliedBy: suggestion.Applied_By__r ? suggestion.Applied_By__r.Name : null,
      reviewedBy: suggestion.Reviewed_By__r ? suggestion.Reviewed_By__r.Name : null,
      reviewedAt: suggestion.Reviewed_At__c,
      rejectionReason: suggestion.Rejection_Reason__c,
      isPending: suggestion.Status__c === "PENDING",
      isApproved: suggestion.Status__c === "APPROVED",
      isApplied: suggestion.Status__c === "APPLIED",
      isRejected: suggestion.Status__c === "REJECTED",
      isFailed: suggestion.Status__c === "FAILED",
    };
  }

  formatTypeLabel(type) {
    if (!type) return "Unknown";
    return type
      .split("_")
      .map((word) => word.charAt(0) + word.slice(1).toLowerCase())
      .join(" ");
  }

  formatEffortLabel(effort) {
    const labels = {
      LOW: "Low (< 1 hour)",
      MEDIUM: "Medium (1-4 hours)",
      HIGH: "High (4-8 hours)",
      VERY_HIGH: "Very High (> 8 hours)",
    };
    return labels[effort] || effort;
  }

  async handleGenerateSuggestions() {
    this.isLoading = true;
    try {
      await generateSuggestions({ gapId: this.recordId });
      await refreshApex(this.wiredSuggestionsResult);
      this.showToast("Success", "Remediation suggestions generated", "success");
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleApprove(event) {
    const suggestionId = event.currentTarget.dataset.id;
    this.isLoading = true;
    try {
      await approveSuggestion({ suggestionId });
      await refreshApex(this.wiredSuggestionsResult);
      this.showToast("Success", "Suggestion approved", "success");
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleRejectClick(event) {
    const suggestionId = event.currentTarget.dataset.id;
    this.selectedSuggestion = this.suggestions.find((s) => s.id === suggestionId);
    this.rejectionReason = "";
    this.isRejectModalOpen = true;
  }

  async handleReject() {
    if (!this.rejectionReason.trim()) {
      this.showToast("Error", "Please provide a rejection reason", "error");
      return;
    }

    this.isLoading = true;
    try {
      await rejectSuggestion({
        suggestionId: this.selectedSuggestion.id,
        reason: this.rejectionReason,
      });
      await refreshApex(this.wiredSuggestionsResult);
      this.showToast("Success", "Suggestion rejected", "success");
      this.closeRejectModal();
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  async handleExecute(event) {
    const suggestionId = event.currentTarget.dataset.id;
    this.isLoading = true;
    try {
      const result = await executeRemediation({ suggestionId });
      await refreshApex(this.wiredSuggestionsResult);

      if (result.success) {
        let message = result.message || "Remediation executed successfully";
        if (result.requiresDeployment) {
          message += ". Deployment package has been queued.";
        }
        this.showToast("Success", message, "success");
      } else {
        this.showToast("Error", result.errorMessage || "Execution failed", "error");
      }
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleManualApplyClick(event) {
    const suggestionId = event.currentTarget.dataset.id;
    this.selectedSuggestion = this.suggestions.find((s) => s.id === suggestionId);
    this.manualNotes = "";
    this.isManualApplyModalOpen = true;
  }

  async handleManualApply() {
    this.isLoading = true;
    try {
      await markAsManuallyApplied({
        suggestionId: this.selectedSuggestion.id,
        notes: this.manualNotes,
      });
      await refreshApex(this.wiredSuggestionsResult);
      this.showToast("Success", "Marked as manually applied", "success");
      this.closeManualApplyModal();
    } catch (error) {
      this.handleError(error);
    } finally {
      this.isLoading = false;
    }
  }

  handleReasonChange(event) {
    this.rejectionReason = event.target.value;
  }

  handleNotesChange(event) {
    this.manualNotes = event.target.value;
  }

  closeRejectModal() {
    this.isRejectModalOpen = false;
    this.selectedSuggestion = null;
    this.rejectionReason = "";
  }

  closeManualApplyModal() {
    this.isManualApplyModalOpen = false;
    this.selectedSuggestion = null;
    this.manualNotes = "";
  }

  handleRefresh() {
    this.isLoading = true;
    refreshApex(this.wiredSuggestionsResult).finally(() => {
      this.isLoading = false;
    });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }

  handleError(error) {
    const message = error.body?.message || error.message || "An error occurred";
    this.showToast("Error", message, "error");
    console.error("Error:", error);
  }
}
