import { LightningElement, track } from "lwc";
import getTopFlows from "@salesforce/apex/FlowExecutionStats.getTopFlows";
import PollingManager from "c/pollingManager";

export default class FlowExecutionMonitor extends LightningElement {
  @track rows = [];
  @track isLoading = true;
  @track hasError = false;
  @track errorMessage = "";
  columns = [
    { label: "Flow", fieldName: "flowName" },
    { label: "Runs", fieldName: "runs", type: "number" },
    { label: "Faults", fieldName: "faults", type: "number" },
    { label: "Last Run", fieldName: "lastRun", type: "date" },
  ];
  pollingManager = null;

  get isEmpty() {
    return !this.isLoading && !this.hasError && (!this.rows || this.rows.length === 0);
  }

  connectedCallback() {
    this.pollingManager = new PollingManager(() => this.load(), 60000);
    this.pollingManager.setupVisibilityHandling();
    this.load();
    this.pollingManager.start();
  }

  disconnectedCallback() {
    if (this.pollingManager) {
      this.pollingManager.cleanup();
    }
  }

  async load() {
    try {
      this.isLoading = true;
      this.hasError = false;
      this.errorMessage = "";
      this.rows = await getTopFlows({ limitSize: 20 });
      this.isLoading = false;
    } catch (error) {
      this.isLoading = false;
      this.hasError = true;
      this.errorMessage = error?.body?.message || error?.message || "Failed to load flow execution data";
      this.rows = [];
    }
  }
}
