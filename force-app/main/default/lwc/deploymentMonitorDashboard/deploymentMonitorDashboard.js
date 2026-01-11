import { LightningElement, track } from "lwc";
import getRecentDeployments from "@salesforce/apex/DeploymentMetrics.getRecentDeployments";
import PollingManager from "c/pollingManager";

export default class DeploymentMonitorDashboard extends LightningElement {
  @track rows = [];
  @track isLoading = true;
  @track hasError = false;
  @track errorMessage = "";
  columns = [
    { label: "Name", fieldName: "name" },
    { label: "Status", fieldName: "status" },
    { label: "Started", fieldName: "startedOn", type: "date" },
    { label: "Finished", fieldName: "finishedOn", type: "date" },
    { label: "Passed", fieldName: "testsPassed", type: "number" },
    { label: "Failed", fieldName: "testsFailed", type: "number" },
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
      this.rows = await getRecentDeployments({ limitSize: 20 });
      this.isLoading = false;
    } catch (error) {
      this.isLoading = false;
      this.hasError = true;
      this.errorMessage = error?.body?.message || error?.message || "Failed to load deployment data";
      this.rows = [];
    }
  }
}
