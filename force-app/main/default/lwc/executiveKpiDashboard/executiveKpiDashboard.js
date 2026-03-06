import { LightningElement, wire } from "lwc";
import getDashboardSummary from "@salesforce/apex/ComplianceDashboardController.getDashboardSummary";
import KPI_DashboardTitle from "@salesforce/label/c.KPI_DashboardTitle";
import KPI_Loading from "@salesforce/label/c.KPI_Loading";
import KPI_ErrorLoading from "@salesforce/label/c.KPI_ErrorLoading";
import KPI_OverallComplianceScore from "@salesforce/label/c.KPI_OverallComplianceScore";
import KPI_TotalGaps from "@salesforce/label/c.KPI_TotalGaps";
import KPI_CriticalGaps from "@salesforce/label/c.KPI_CriticalGaps";
import KPI_CompliantFrameworks from "@salesforce/label/c.KPI_CompliantFrameworks";

export default class ExecutiveKpiDashboard extends LightningElement {
  dashboardData;
  error;
  loading = true;

  label = {
    KPI_DashboardTitle,
    KPI_Loading,
    KPI_ErrorLoading,
    KPI_OverallComplianceScore,
    KPI_TotalGaps,
    KPI_CriticalGaps,
    KPI_CompliantFrameworks,
  };

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

  get overallScore() {
    if (
      !this.dashboardData ||
      !this.dashboardData.frameworks ||
      this.dashboardData.frameworks.length === 0
    ) {
      return 0;
    }

    let totalScore = 0;
    for (let framework of this.dashboardData.frameworks) {
      totalScore += framework.score || 0;
    }
    return (totalScore / this.dashboardData.frameworks.length).toFixed(1);
  }

  get totalGaps() {
    return this.dashboardData && this.dashboardData.recentGaps
      ? this.dashboardData.recentGaps.length
      : 0;
  }

  get criticalGaps() {
    if (!this.dashboardData || !this.dashboardData.recentGaps) return 0;
    return this.dashboardData.recentGaps.filter((gap) => gap.Severity__c === "CRITICAL").length;
  }

  get compliantFrameworks() {
    if (!this.dashboardData || !this.dashboardData.frameworks) return 0;
    return this.dashboardData.frameworks.filter((fw) => fw.status === "COMPLIANT").length;
  }

  get errorMessage() {
    if (!this.error) return "";
    return this.error?.body?.message || this.error?.message || "An unknown error occurred";
  }
}
