import { LightningElement, api, track } from "lwc";

export default class ComplianceTrendChart extends LightningElement {
  @api framework;
  @api data = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  get chartData() {
    // Format data for chart library (Chart.js or similar)
    return {
      labels: this.data.map((d) => d.date),
      datasets: [
        {
          label: "Compliance Score",
          data: this.data.map((d) => d.score),
          borderColor: "rgb(75, 192, 192)",
          backgroundColor: "rgba(75, 192, 192, 0.2)",
        },
      ],
    };
  }

  get hasData() {
    return this.data && this.data.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.hasData;
  }

  get notLoading() {
    return !this.isLoading;
  }

  get notError() {
    return !this.hasError;
  }
}
