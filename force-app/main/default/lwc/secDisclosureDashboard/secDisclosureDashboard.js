import { LightningElement, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getOpenAssessments from "@salesforce/apex/SECDisclosureController.getOpenAssessments";
import SECDashboardTitle from "@salesforce/label/c.SEC_DashboardTitle";
import SECOpenAssessments from "@salesforce/label/c.SEC_OpenAssessments";
import SECNoOpenAssessments from "@salesforce/label/c.SEC_NoOpenAssessments";
import SECLoading from "@salesforce/label/c.SEC_Loading";
import SECErrorTitle from "@salesforce/label/c.SEC_ErrorTitle";
import SECAtRisk from "@salesforce/label/c.SEC_AtRisk";
import SECOnTrack from "@salesforce/label/c.SEC_OnTrack";

/**
 * Main dashboard component for SEC Cybersecurity Disclosure Module.
 * Displays all open materiality assessments with filing deadlines and SLA status.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 */
export default class SecDisclosureDashboard extends NavigationMixin(LightningElement) {
  label = {
    SECDashboardTitle,
    SECOpenAssessments,
    SECNoOpenAssessments,
    SECLoading,
    SECErrorTitle,
    SECAtRisk,
    SECOnTrack,
  };

  assessments = [];
  error;
  isLoading = true;

  @wire(getOpenAssessments)
  wiredAssessments({ error, data }) {
    this.isLoading = false;
    if (data) {
      this.assessments = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.assessments = [];
    }
  }

  get hasAssessments() {
    return this.assessments && this.assessments.length > 0;
  }

  get atRiskCount() {
    if (!this.assessments) return 0;
    return this.assessments.filter((a) => {
      if (!a.Filing_Deadline__c) return false;
      const deadline = new Date(a.Filing_Deadline__c);
      const today = new Date();
      const daysRemaining = Math.floor((deadline - today) / (1000 * 60 * 60 * 24));
      return daysRemaining <= 1 && daysRemaining >= 0;
    }).length;
  }

  get onTrackCount() {
    if (!this.assessments) return 0;
    return this.assessments.filter((a) => {
      if (!a.Filing_Deadline__c) return false;
      const deadline = new Date(a.Filing_Deadline__c);
      const today = new Date();
      const daysRemaining = Math.floor((deadline - today) / (1000 * 60 * 60 * 24));
      return daysRemaining > 1;
    }).length;
  }

  get errorMessage() {
    if (!this.error) return "";
    return this.error?.body?.message || this.error?.message || "An unknown error occurred";
  }

  handleViewAssessment(event) {
    const assessmentId = event.detail.assessmentId;
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: assessmentId,
        objectApiName: "Materiality_Assessment__c",
        actionName: "view",
      },
    });
  }

  handleNewAssessment() {
    this[NavigationMixin.Navigate]({
      type: "standard__objectPage",
      attributes: {
        objectApiName: "Materiality_Assessment__c",
        actionName: "new",
      },
    });
  }

  handleRefresh() {
    this.isLoading = true;
    return refreshApex(this.wiredAssessments);
  }
}
