import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getKPIMetrics from "@salesforce/apex/PrometheionExecutiveKPIController.getKPIMetrics";

export default class PrometheionExecutiveKPIDashboard extends LightningElement {
  @track kpiMetrics = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  @wire(getKPIMetrics, { metadataRecordIds: "" })
  wiredKPIs({ error, data }) {
    if (data) {
      // Format values for display
      this.kpiMetrics = data.map((metric) => ({
        ...metric,
        formattedValue: this.formatValue(metric),
        formattedTarget: this.formatTarget(metric),
        statusBadgeVariant: this.getStatusBadgeVariant(metric),
        noError: !metric.hasError,
      }));
      this.isLoading = false;
      this.hasError = false;
    } else if (error) {
      this.hasError = true;
      this.errorMessage =
        "Error loading KPIs: " +
        (error?.body?.message || error?.message || "An unknown error occurred");
      this.isLoading = false;
      this.showError(this.errorMessage);
    }
  }

  connectedCallback() {
    this.isLoading = true;
  }

  formatValue(metric) {
    if (!metric || metric.hasError) return "N/A";
    const value = metric.currentValue;
    if (value == null) return "N/A";

    if (metric.formatType === "currency") {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value);
    } else if (metric.formatType === "percent") {
      return (value * 100).toFixed(1) + "%";
    } else if (metric.formatType === "days") {
      return value.toFixed(1) + " days";
    }
    return value.toFixed(2);
  }

  formatTarget(metric) {
    if (!metric || !metric.targetValue) return "N/A";
    const value = metric.targetValue;

    if (metric.formatType === "currency") {
      return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(value);
    } else if (metric.formatType === "percent") {
      return (value * 100).toFixed(1) + "%";
    } else if (metric.formatType === "days") {
      return value.toFixed(1) + " days";
    }
    return value.toFixed(2);
  }

  getStatusBadgeVariant(metric) {
    if (!metric) return "default";
    if (metric.status === "green") return "success";
    if (metric.status === "yellow") return "warning";
    if (metric.status === "red") return "error";
    return "default";
  }

  showError(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: message,
        variant: "error",
      })
    );
  }
}
