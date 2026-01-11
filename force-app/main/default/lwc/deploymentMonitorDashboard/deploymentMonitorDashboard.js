import { LightningElement, track } from "lwc";
import getRecentDeployments from "@salesforce/apex/DeploymentMetrics.getRecentDeployments";
import PollingManager from "c/pollingManager";

export default class DeploymentMonitorDashboard extends LightningElement {
  @track rows = [];
  columns = [
    { label: "Name", fieldName: "name" },
    { label: "Status", fieldName: "status" },
    { label: "Started", fieldName: "startedOn", type: "date" },
    { label: "Finished", fieldName: "finishedOn", type: "date" },
    { label: "Passed", fieldName: "testsPassed", type: "number" },
    { label: "Failed", fieldName: "testsFailed", type: "number" },
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
      this.rows = await getRecentDeployments({ limitSize: 20 });
    } catch {
      // Set empty array to prevent UI errors
      this.rows = [];
    }
  }
}
