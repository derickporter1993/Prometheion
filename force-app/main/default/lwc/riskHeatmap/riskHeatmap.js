import { LightningElement, api, track } from "lwc";

export default class RiskHeatmap extends LightningElement {
  @api risks = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  get riskMatrix() {
    // Organize risks by severity and framework
    let matrix = {};

    if (this.risks && this.risks.length > 0) {
      for (let risk of this.risks) {
        let key = risk.framework + "_" + risk.severity;
        if (!matrix[key]) {
          matrix[key] = 0;
        }
        matrix[key]++;
      }
    }

    return matrix;
  }

  get hasRisks() {
    return this.risks && this.risks.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.hasRisks;
  }

  get riskClass() {
    return (severity) => {
      if (severity === "CRITICAL") return "risk-critical";
      if (severity === "HIGH") return "risk-high";
      if (severity === "MEDIUM") return "risk-medium";
      return "risk-low";
    };
  }
}
