import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import CC_FrameworkSummary from "@salesforce/label/c.CC_FrameworkSummary";
import CC_RecentGaps from "@salesforce/label/c.CC_RecentGaps";
import CC_NoGaps from "@salesforce/label/c.CC_NoGaps";
import CC_ViewDetails from "@salesforce/label/c.CC_ViewDetails";

export default class ComplianceContextSidebar extends NavigationMixin(LightningElement) {
  label = {
    CC_FrameworkSummary,
    CC_RecentGaps,
    CC_NoGaps,
    CC_ViewDetails,
  };

  @api frameworkSummaries = [];
  @api recentGaps = [];

  get hasFrameworks() {
    return this.frameworkSummaries && this.frameworkSummaries.length > 0;
  }

  get hasGaps() {
    return this.recentGaps && this.recentGaps.length > 0;
  }

  get indexedFrameworks() {
    return (this.frameworkSummaries || []).map((fw, idx) => ({
      ...fw,
      key: `fw-${idx}`,
      scoreClass: this.getScoreClass(fw.score),
    }));
  }

  get indexedGaps() {
    return (this.recentGaps || []).map((gap, idx) => ({
      ...gap,
      key: `gap-${idx}`,
      severityClass: this.getSeverityClass(gap.severity),
    }));
  }

  getScoreClass(score) {
    if (score >= 80) return "slds-text-color_success";
    if (score >= 60) return "slds-text-color_default";
    return "slds-text-color_error";
  }

  getSeverityClass(severity) {
    if (severity === "CRITICAL") return "slds-badge slds-badge_inverse";
    if (severity === "HIGH") return "slds-badge slds-theme_error";
    if (severity === "MEDIUM") return "slds-badge slds-theme_warning";
    return "slds-badge slds-badge_lightest";
  }

  handleViewGap(event) {
    const gapId = event.currentTarget.dataset.id;
    if (gapId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: gapId,
          objectApiName: "Compliance_Gap__c",
          actionName: "view",
        },
      });
    }
  }
}
