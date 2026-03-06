import { LightningElement, api, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getIssueStatus from "@salesforce/apex/JiraIntegrationService.getIssueStatus";
import syncIssueStatus from "@salesforce/apex/JiraIntegrationService.syncIssueStatus";
import addComment from "@salesforce/apex/JiraIntegrationService.addComment";
import getAvailableTransitions from "@salesforce/apex/JiraIntegrationService.getAvailableTransitions";
import transitionIssue from "@salesforce/apex/JiraIntegrationService.transitionIssue";
import JIRA_IssueCardTitle from "@salesforce/label/c.JIRA_IssueCardTitle";
import JIRA_Loading from "@salesforce/label/c.JIRA_Loading";
import JIRA_NoIssueLinked from "@salesforce/label/c.JIRA_NoIssueLinked";
import JIRA_CreateIssueHint from "@salesforce/label/c.JIRA_CreateIssueHint";
import JIRA_IssueKeyLabel from "@salesforce/label/c.JIRA_IssueKeyLabel";
import JIRA_SummaryLabel from "@salesforce/label/c.JIRA_SummaryLabel";
import JIRA_PriorityFieldLabel from "@salesforce/label/c.JIRA_PriorityFieldLabel";
import JIRA_AssigneeLabel from "@salesforce/label/c.JIRA_AssigneeLabel";
import JIRA_Unassigned from "@salesforce/label/c.JIRA_Unassigned";
import JIRA_CreatedLabel from "@salesforce/label/c.JIRA_CreatedLabel";
import JIRA_UpdatedLabel from "@salesforce/label/c.JIRA_UpdatedLabel";
import JIRA_RefreshButton from "@salesforce/label/c.JIRA_RefreshButton";
import JIRA_SyncButton from "@salesforce/label/c.JIRA_SyncButton";
import JIRA_AddCommentButton from "@salesforce/label/c.JIRA_AddCommentButton";
import JIRA_TransitionButton from "@salesforce/label/c.JIRA_TransitionButton";
import JIRA_OpenInJiraButton from "@salesforce/label/c.JIRA_OpenInJiraButton";
import JIRA_CancelButton from "@salesforce/label/c.JIRA_CancelButton";
import JIRA_CommentLabel from "@salesforce/label/c.JIRA_CommentLabel";
import JIRA_CommentPlaceholder from "@salesforce/label/c.JIRA_CommentPlaceholder";
import JIRA_TransitionToLabel from "@salesforce/label/c.JIRA_TransitionToLabel";
import JIRA_TransitionPlaceholder from "@salesforce/label/c.JIRA_TransitionPlaceholder";
import JIRA_CurrentStatus from "@salesforce/label/c.JIRA_CurrentStatus";
import JIRA_IssueRefreshed from "@salesforce/label/c.JIRA_IssueRefreshed";
import JIRA_IssueSynced from "@salesforce/label/c.JIRA_IssueSynced";
import JIRA_NoRecordId from "@salesforce/label/c.JIRA_NoRecordId";
import JIRA_EnterComment from "@salesforce/label/c.JIRA_EnterComment";
import JIRA_CommentAdded from "@salesforce/label/c.JIRA_CommentAdded";
import JIRA_SelectTransition from "@salesforce/label/c.JIRA_SelectTransition";
import JIRA_TransitionSuccess from "@salesforce/label/c.JIRA_TransitionSuccess";
import JIRA_UnexpectedError from "@salesforce/label/c.JIRA_UnexpectedError";

export default class JiraIssueCard extends LightningElement {
  @api recordId; // Compliance_Gap__c Id
  @api jiraKey; // Jira issue key (e.g., COMPLIANCE-123)
  @api jiraUrl; // Direct link to Jira issue

  issue = null;
  transitions = [];
  isLoading = false;
  error = null;
  showCommentModal = false;
  showTransitionModal = false;
  commentText = "";
  selectedTransition = "";

  wiredIssueResult;

  label = {
    JIRA_IssueCardTitle,
    JIRA_Loading,
    JIRA_NoIssueLinked,
    JIRA_CreateIssueHint,
    JIRA_IssueKeyLabel,
    JIRA_SummaryLabel,
    JIRA_PriorityFieldLabel,
    JIRA_AssigneeLabel,
    JIRA_Unassigned,
    JIRA_CreatedLabel,
    JIRA_UpdatedLabel,
    JIRA_RefreshButton,
    JIRA_SyncButton,
    JIRA_AddCommentButton,
    JIRA_TransitionButton,
    JIRA_OpenInJiraButton,
    JIRA_CancelButton,
    JIRA_CommentLabel,
    JIRA_CommentPlaceholder,
    JIRA_TransitionToLabel,
    JIRA_TransitionPlaceholder,
    JIRA_CurrentStatus,
    JIRA_IssueRefreshed,
    JIRA_IssueSynced,
    JIRA_NoRecordId,
    JIRA_EnterComment,
    JIRA_CommentAdded,
    JIRA_SelectTransition,
    JIRA_TransitionSuccess,
    JIRA_UnexpectedError,
  };

  get hasIssue() {
    return this.jiraKey && this.issue;
  }

  get noIssueLinked() {
    return !this.jiraKey;
  }

  get commentModalTitle() {
    return `${this.label.JIRA_AddCommentButton} to ${this.jiraKey}`;
  }

  get transitionModalTitle() {
    return `${this.label.JIRA_TransitionButton} ${this.jiraKey}`;
  }

  get currentStatusText() {
    return `${this.label.JIRA_CurrentStatus} ${this.issue?.status ?? ""}`;
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
    if (!this.transitions || !Array.isArray(this.transitions)) {
      return [];
    }
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
      this.showToast("Success", this.label.JIRA_IssueRefreshed, "success");
    } catch (err) {
      this.error = this.getErrorMessage(err);
    } finally {
      this.isLoading = false;
    }
  }

  async handleSync() {
    if (!this.recordId) {
      this.showToast("Error", this.label.JIRA_NoRecordId, "error");
      return;
    }

    this.isLoading = true;

    try {
      await syncIssueStatus({ gapId: this.recordId });
      await refreshApex(this.wiredIssueResult);
      this.showToast("Success", this.label.JIRA_IssueSynced, "success");
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

  handleCommentModalKeydown(event) {
    if (event.key === "Escape") {
      this.handleCloseCommentModal();
    }
  }

  handleTransitionModalKeydown(event) {
    if (event.key === "Escape") {
      this.handleCloseTransitionModal();
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
      this.showToast("Error", this.label.JIRA_EnterComment, "error");
      return;
    }

    this.isLoading = true;

    try {
      await addComment({ jiraKey: this.jiraKey, comment: this.commentText });
      this.showToast("Success", this.label.JIRA_CommentAdded, "success");
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
      this.showToast("Error", this.label.JIRA_SelectTransition, "error");
      return;
    }

    this.isLoading = true;

    try {
      await transitionIssue({ jiraKey: this.jiraKey, transitionId: this.selectedTransition });
      await refreshApex(this.wiredIssueResult);
      this.showToast("Success", this.label.JIRA_TransitionSuccess, "success");
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
    return this.label.JIRA_UnexpectedError;
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
