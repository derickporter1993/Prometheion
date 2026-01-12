import { LightningElement, api, track } from "lwc";

export default class ComplianceGapList extends LightningElement {
  @api gaps = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

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
