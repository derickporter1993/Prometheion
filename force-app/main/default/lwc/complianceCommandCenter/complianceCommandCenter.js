import { LightningElement, wire } from "lwc";
import getComplianceContext from "@salesforce/apex/CommandCenterController.getComplianceContext";
import CC_DashboardTitle from "@salesforce/label/c.CC_DashboardTitle";
import CC_Loading from "@salesforce/label/c.CC_Loading";
import CC_ErrorLoading from "@salesforce/label/c.CC_ErrorLoading";
import CC_OverviewTitle from "@salesforce/label/c.CC_OverviewTitle";
import CC_OverallScore from "@salesforce/label/c.CC_OverallScore";
import CC_OpenGaps from "@salesforce/label/c.CC_OpenGaps";
import CC_CriticalGaps from "@salesforce/label/c.CC_CriticalGaps";
import CC_Remediated from "@salesforce/label/c.CC_Remediated";

export default class ComplianceCommandCenter extends LightningElement {
  label = {
    CC_DashboardTitle,
    CC_Loading,
    CC_ErrorLoading,
    CC_OverviewTitle,
    CC_OverallScore,
    CC_OpenGaps,
    CC_CriticalGaps,
    CC_Remediated,
  };

  context;
  error;

  @wire(getComplianceContext)
  wiredContext({ data, error }) {
    if (data) {
      this.context = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.context = undefined;
    }
  }

  get isLoading() {
    return !this.context && !this.error;
  }

  get hasError() {
    return !!this.error;
  }

  get hasData() {
    return !!this.context;
  }

  get overview() {
    return this.context?.overview;
  }

  get overallScore() {
    return this.context?.overview?.overallScore ?? 0;
  }

  get openGaps() {
    return this.context?.overview?.openGaps ?? 0;
  }

  get criticalGaps() {
    return this.context?.overview?.criticalGaps ?? 0;
  }

  get remediatedGaps() {
    return this.context?.overview?.remediatedGaps ?? 0;
  }

  get riskRating() {
    return this.context?.overview?.riskRating ?? "Unknown";
  }

  get scoreClass() {
    const score = this.overallScore;
    if (score >= 80) return "slds-text-color_success";
    if (score >= 60) return "slds-text-color_default";
    return "slds-text-color_error";
  }

  get frameworkSummaries() {
    return this.context?.frameworkSummaries ?? [];
  }

  get prioritizedActions() {
    return this.context?.prioritizedActions ?? [];
  }

  get recentGaps() {
    return this.context?.recentGaps ?? [];
  }
}
