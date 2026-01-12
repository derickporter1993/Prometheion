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
        this.pollingManager.updateInterval(this.currentInterval);
      }
    } catch (error) {
      // Log error for debugging purposes
      if (error.body?.message || error.message) {
        // Only log in non-production environments
        this.showError("Failed to load API usage data", error.body?.message || error.message);
      }

      // Apply exponential backoff on error
      if (this.errorBackoffMultiplier < this.maxBackoffMultiplier) {
        this.errorBackoffMultiplier *= 2;
        this.currentInterval = this.pollInterval * this.errorBackoffMultiplier;
        this.pollingManager.updateInterval(this.currentInterval);
      }
    }
  }

  get hasRows() {
    return this.rows && this.rows.length > 0;
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
