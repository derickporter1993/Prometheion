import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fetchGovernorStats from "@salesforce/apex/LimitMetrics.fetchGovernorStats";
import evaluateAndPublish from "@salesforce/apex/PerformanceRuleEngine.evaluateAndPublish";
import PollingManager from "c/pollingManager";

export default class SystemMonitorDashboard extends LightningElement {
  @track stats;
  pollingManager = null;

  get cpuPct() {
    return Math.min(100, Math.round((this.stats?.cpuMs || 0) / 100));
  }

  get heapPct() {
    return Math.min(100, Math.round((this.stats?.heapKb || 0) / 50));
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
      this.stats = await fetchGovernorStats();
      await evaluateAndPublish({ stats: this.stats, contextRecordId: null });
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
      this.showError("Failed to load governor stats", e.body?.message || e.message);
    }
  }

  refresh() {
    this.load();
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
