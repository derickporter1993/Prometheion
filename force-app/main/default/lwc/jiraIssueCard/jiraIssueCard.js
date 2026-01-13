import { LightningElement, api, wire, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getIssueStatus from "@salesforce/apex/JiraIntegrationService.getIssueStatus";
import syncIssueStatus from "@salesforce/apex/JiraIntegrationService.syncIssueStatus";
import addComment from "@salesforce/apex/JiraIntegrationService.addComment";
import getAvailableTransitions from "@salesforce/apex/JiraIntegrationService.getAvailableTransitions";
import transitionIssue from "@salesforce/apex/JiraIntegrationService.transitionIssue";

export default class JiraIssueCard extends LightningElement {
  @api recordId; // Compliance_Gap__c Id
  @api jiraKey; // Jira issue key (e.g., COMPLIANCE-123)
  @api jiraUrl; // Direct link to Jira issue

  @track issue = null;
  @track transitions = [];
  @track isLoading = false;
  @track error = null;
  @track showCommentModal = false;
  @track showTransitionModal = false;
  @track commentText = "";
  @track selectedTransition = "";

  wiredIssueResult;

  get hasIssue() {
    return this.jiraKey && this.issue;
  }

  get noIssueLinked() {
    return !this.jiraKey;
  }

  get statusClass() {
    if (!this.issue || !this.issue.status) return "slds-badge";

    const status = this.issue.status.toLowerCase();
    if (status.includes("done") || status.includes("resolved") || status.includes("closed")) {
      return "slds-badge slds-theme_success";
    } else if (status.includes("progress")) {
      return "slds-badge slds-theme_warning";
    }
    return "slds-badge";
  }

  get priorityIcon() {
    if (!this.issue || !this.issue.priority) return "utility:priority";

    const priority = this.issue.priority.toLowerCase();
    if (priority === "highest" || priority === "high") {
      return "utility:arrowup";
    } else if (priority === "lowest" || priority === "low") {
      return "utility:arrowdown";
    }
    return "utility:dash";
  }

  get formattedCreatedDate() {
    if (!this.issue || !this.issue.createdAt) return "";
    return new Date(this.issue.createdAt).toLocaleDateString();
  }

  get formattedUpdatedDate() {
    if (!this.issue || !this.issue.updatedAt) return "";
    return new Date(this.issue.updatedAt).toLocaleDateString();
  }

  get transitionOptions() {
    return this.transitions.map((t) => ({
      label: t.name,
      value: t.id,
    }));
  }

  @wire(getIssueStatus, { jiraKey: "$jiraKey" })
  wiredIssue(result) {
    this.wiredIssueResult = result;
    this.isLoading = false;

    if (result.data) {
      this.issue = result.data;
      this.error = null;
    } else if (result.error) {
      this.error = this.getErrorMessage(result.error);
      this.issue = null;
    }
  }

  connectedCallback() {
    if (this.jiraKey) {
      this.isLoading = true;
    }
  }

  async handleRefresh() {
    this.isLoading = true;
    this.error = null;

    try {
      await refreshApex(this.wiredIssueResult);
      this.showToast("Success", "Issue status refreshed", "success");
    } catch (err) {
      this.error = this.getErrorMessage(err);
    } finally {
      this.isLoading = false;
    }
  }

  async handleSync() {
    if (!this.recordId) {
      this.showToast("Error", "No record ID provided", "error");
      return;
    }

    this.isLoading = true;

    try {
      await syncIssueStatus({ gapId: this.recordId });
      await refreshApex(this.wiredIssueResult);
      this.showToast("Success", "Issue synced with Salesforce", "success");
    } catch (err) {
      this.showToast("Error", this.getErrorMessage(err), "error");
    } finally {
      this.isLoading = false;
    }
  }

  handleOpenInJira() {
    if (this.jiraUrl) {
      window.open(this.jiraUrl, "_blank");
    } else if (this.issue && this.issue.url) {
      window.open(this.issue.url, "_blank");
    }
  }

  // Comment Modal
  handleOpenCommentModal() {
    this.commentText = "";
    this.showCommentModal = true;
  }

  handleCloseCommentModal() {
    this.showCommentModal = false;
    this.commentText = "";
  }

  handleCommentChange(event) {
    this.commentText = event.target.value;
  }

  async handleSubmitComment() {
    if (!this.commentText.trim()) {
      this.showToast("Error", "Please enter a comment", "error");
      return;
    }

    this.isLoading = true;

    try {
      await addComment({ jiraKey: this.jiraKey, comment: this.commentText });
      this.showToast("Success", "Comment added to Jira", "success");
      this.handleCloseCommentModal();
    } catch (err) {
      this.showToast("Error", this.getErrorMessage(err), "error");
    } finally {
      this.isLoading = false;
    }
  }

  // Transition Modal
  async handleOpenTransitionModal() {
    this.isLoading = true;
    this.selectedTransition = "";

    try {
      this.transitions = await getAvailableTransitions({ jiraKey: this.jiraKey });
      this.showTransitionModal = true;
    } catch (err) {
      this.showToast("Error", this.getErrorMessage(err), "error");
    } finally {
      this.isLoading = false;
    }
  }

  handleCloseTransitionModal() {
    this.showTransitionModal = false;
    this.selectedTransition = "";
  }

  handleTransitionChange(event) {
    this.selectedTransition = event.detail.value;
  }

  async handleSubmitTransition() {
    if (!this.selectedTransition) {
      this.showToast("Error", "Please select a transition", "error");
      return;
    }

    this.isLoading = true;

    try {
      await transitionIssue({ jiraKey: this.jiraKey, transitionId: this.selectedTransition });
      await refreshApex(this.wiredIssueResult);
      this.showToast("Success", "Issue transitioned successfully", "success");
      this.handleCloseTransitionModal();
    } catch (err) {
      this.showToast("Error", this.getErrorMessage(err), "error");
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
