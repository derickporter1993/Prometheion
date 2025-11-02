import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getSnapshots from "@salesforce/apex/ApiUsageDashboardController.recent";

export default class ApiUsageDashboard extends LightningElement {
  @track rows = [];
  timer = null;

  columns = [
    { label: "Taken On", fieldName: "takenOn", type: "date" },
    { label: "Used", fieldName: "used", type: "number" },
    { label: "Limit", fieldName: "limit", type: "number" },
    { label: "Percent", fieldName: "percent", type: "percent" },
    { label: "Projected Exhaustion", fieldName: "projected", type: "date" },
  ];

  connectedCallback() {
    this.load();
    this.timer = setInterval(() => this.load(), 60000);
  }

  disconnectedCallback() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async load() {
    try {
      const data = await getSnapshots({ limitSize: 20 });
      this.rows = data.map((r, idx) => ({ id: idx, ...r }));
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
      this.showError("Failed to load API usage data", e.body?.message || e.message);
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
