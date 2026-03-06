import { LightningElement, wire } from "lwc";
import getDashboardSummary from "@salesforce/apex/ComplianceDashboardController.getDashboardSummary";

// Custom Labels
import CARD_TITLE from "@salesforce/label/c.DASHBOARD_CardTitle";
import LOADING from "@salesforce/label/c.DASHBOARD_Loading";
import ERROR_LOADING_DASHBOARD from "@salesforce/label/c.DASHBOARD_ErrorLoading";
import RECENT_EVIDENCE from "@salesforce/label/c.DASHBOARD_RecentEvidence";
import UNKNOWN_ERROR from "@salesforce/label/c.DASHBOARD_UnknownError";

export default class ComplianceDashboard extends LightningElement {
  label = {
    cardTitle: CARD_TITLE,
    loading: LOADING,
    errorLoadingDashboard: ERROR_LOADING_DASHBOARD,
    recentEvidence: RECENT_EVIDENCE,
  };

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
    if (!this.error) return "";
    return this.error?.body?.message || this.error?.message || UNKNOWN_ERROR;
  }
}
