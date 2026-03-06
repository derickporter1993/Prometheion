import { LightningElement, api } from "lwc";
import CardTitle from "@salesforce/label/c.GAP_CardTitle";
import LoadingAlt from "@salesforce/label/c.GAP_LoadingAlt";
import NoGapsFound from "@salesforce/label/c.GAP_NoGapsFound";
import StatusPrefix from "@salesforce/label/c.GAP_StatusPrefix";
import RiskPrefix from "@salesforce/label/c.GAP_RiskPrefix";

export default class ComplianceGapList extends LightningElement {
  label = { CardTitle, LoadingAlt, NoGapsFound, StatusPrefix, RiskPrefix };
  @api gaps = [];
  isLoading = false;
  hasError = false;
  errorMessage = "";

  get hasGaps() {
    return this.gaps && this.gaps.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.hasGaps;
  }

  get notLoading() {
    return !this.isLoading;
  }

  get notError() {
    return !this.hasError;
  }

  get severityClass() {
    return (gap) => {
      if (gap.Severity__c === "CRITICAL") return "slds-text-color_error";
      if (gap.Severity__c === "HIGH") return "slds-text-color_warning";
      return "slds-text-color_default";
    };
  }
}
