import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSnapshots from "@salesforce/apex/ApiUsageDashboardController.recent";
import PollingManager from "c/pollingManager";

export default class ApiUsageDashboard extends LightningElement {
  @track rows = [];
  pollingManager = null;
  pollInterval = 60000; // Base poll interval (60s)
  currentInterval = 60000; // Current interval with backoff
  errorBackoffMultiplier = 1; // Exponential backoff multiplier
  maxBackoffMultiplier = 8; // Max backoff is 8x base interval

  columns = [
    { label: "Taken On", fieldName: "takenOn", type: "date" },
    { label: "Used", fieldName: "used", type: "number" },
    { label: "Limit", fieldName: "limit", type: "number" },
    { label: "Percent", fieldName: "percent", type: "percent" },
    { label: "Projected Exhaustion", fieldName: "projected", type: "date" },
  ];

  connectedCallback() {
    this.pollingManager = new PollingManager(() => this.load(), this.currentInterval);
    this.load();
    this.pollingManager.start();
    this.pollingManager.setupVisibilityHandling();
  }

  disconnectedCallback() {
    if (this.pollingManager) {
      this.pollingManager.cleanup();
    }
  }

  async load() {
    try {
      const data = await getSnapshots({ limitSize: 20 });
      // Use stable IDs from server data if available, otherwise fallback to index
      this.rows = data.map((r, idx) => ({
        id: r.id || `row-${idx}`,
        ...r,
      }));

      // Reset backoff on success
      if (this.errorBackoffMultiplier > 1) {
        this.errorBackoffMultiplier = 1;
        this.currentInterval = this.pollInterval;
        // Update polling manager interval to normal interval
        this.pollingManager.updateInterval(this.currentInterval);
      }
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
      this.showError("Failed to load API usage data", e.body?.message || e.message);

      // Apply exponential backoff on error
      if (this.errorBackoffMultiplier < this.maxBackoffMultiplier) {
        this.errorBackoffMultiplier *= 2;
        this.currentInterval = this.pollInterval * this.errorBackoffMultiplier;
        // Update polling manager interval to increased interval
        this.pollingManager.updateInterval(this.currentInterval);
      }
    }
  }

  showError(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: "error",
      })
    );
  }
}
