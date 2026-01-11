import { LightningElement, track } from "lwc";
import getTopFlows from "@salesforce/apex/FlowExecutionStats.getTopFlows";
import PollingManager from "c/pollingManager";

export default class FlowExecutionMonitor extends LightningElement {
  @track rows = [];
  columns = [
    { label: "Flow", fieldName: "flowName" },
    { label: "Runs", fieldName: "runs", type: "number" },
    { label: "Faults", fieldName: "faults", type: "number" },
    { label: "Last Run", fieldName: "lastRun", type: "date" },
  ];
  pollingManager = null;

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
      this.rows = await getTopFlows({ limitSize: 20 });
    } catch {
      // Set empty array to prevent UI errors
      this.rows = [];
    }
  }
}
