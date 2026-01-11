import { LightningElement, wire } from "lwc";
import getDashboardSummary from "@salesforce/apex/ComplianceDashboardController.getDashboardSummary";

export default class ComplianceDashboard extends LightningElement {
  dashboardData;
  error;
  loading = true;

  @wire(getDashboardSummary)
  wiredDashboard({ error, data }) {
    this.loading = false;
    if (data) {
      this.dashboardData = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.dashboardData = undefined;
    }
  }

  get hasData() {
    return this.dashboardData && this.dashboardData.frameworks;
  }

  get frameworks() {
    return this.hasData ? this.dashboardData.frameworks : [];
  }

  get recentGaps() {
    return this.hasData && this.dashboardData.recentGaps ? this.dashboardData.recentGaps : [];
  }

  get recentEvidence() {
    return this.hasData && this.dashboardData.recentEvidence
      ? this.dashboardData.recentEvidence
      : [];
  }

  get errorMessage() {
    if (!this.error) return '';
    return this.error?.body?.message || this.error?.message || 'An unknown error occurred';
  }
}
