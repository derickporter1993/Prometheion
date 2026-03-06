import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSnapshots from "@salesforce/apex/ApiUsageDashboardController.getRecentSnapshots";
import PollingManager from "c/pollingManager";
import DashboardTitle from "@salesforce/label/c.API_DashboardTitle";
import LoadingAlt from "@salesforce/label/c.API_LoadingAlt";
import NoSnapshots from "@salesforce/label/c.API_NoSnapshots";
import ColTakenOn from "@salesforce/label/c.API_ColTakenOn";
import ColUsed from "@salesforce/label/c.API_ColUsed";
import ColLimit from "@salesforce/label/c.API_ColLimit";
import ColPercent from "@salesforce/label/c.API_ColPercent";
import ColProjectedExhaustion from "@salesforce/label/c.API_ColProjectedExhaustion";

export default class ApiUsageDashboard extends LightningElement {
  label = { DashboardTitle, LoadingAlt, NoSnapshots, ColTakenOn, ColUsed, ColLimit, ColPercent, ColProjectedExhaustion };
  rows = [];
  isLoading = true;
  pollingManager = null;
  pollInterval = 60000; // Base poll interval (60s)
  currentInterval = 60000; // Current interval with backoff
  errorBackoffMultiplier = 1; // Exponential backoff multiplier
  maxBackoffMultiplier = 8; // Max backoff is 8x base interval

  columns = [
    { label: ColTakenOn, fieldName: "takenOn", type: "date" },
    { label: ColUsed, fieldName: "used", type: "number" },
    { label: ColLimit, fieldName: "dailyLimit", type: "number" },
    { label: ColPercent, fieldName: "percent", type: "percent" },
    { label: ColProjectedExhaustion, fieldName: "projected", type: "date" },
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
    this.isLoading = true;
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
    } finally {
      this.isLoading = false;
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
