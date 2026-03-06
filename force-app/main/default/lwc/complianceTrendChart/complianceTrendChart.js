import { LightningElement, api } from "lwc";

// Custom Labels
import CARD_TITLE from "@salesforce/label/c.TREND_CardTitle";
import LOADING_TREND from "@salesforce/label/c.TREND_Loading";
import NO_TREND_DATA from "@salesforce/label/c.TREND_NoData";
import COMPLIANCE_SCORE_LABEL from "@salesforce/label/c.TREND_ComplianceScore";

export default class ComplianceTrendChart extends LightningElement {
  label = {
    cardTitle: CARD_TITLE,
    loadingTrend: LOADING_TREND,
    noTrendData: NO_TREND_DATA,
  };

  @api framework;
  @api data = [];
  isLoading = false;
  hasError = false;
  errorMessage = "";

  get chartData() {
    // Format data for chart library (Chart.js or similar)
    return {
      labels: this.data.map((d) => d.date),
      datasets: [
        {
          label: COMPLIANCE_SCORE_LABEL,
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
