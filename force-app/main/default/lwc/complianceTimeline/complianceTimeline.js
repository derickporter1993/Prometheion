import { LightningElement, api } from "lwc";

// Custom Labels
import CARD_TITLE from "@salesforce/label/c.TIMELINE_CardTitle";
import LOADING_TIMELINE from "@salesforce/label/c.TIMELINE_Loading";
import NO_TIMELINE_EVENTS from "@salesforce/label/c.TIMELINE_NoEvents";

export default class ComplianceTimeline extends LightningElement {
  label = {
    cardTitle: CARD_TITLE,
    loadingTimeline: LOADING_TIMELINE,
    noTimelineEvents: NO_TIMELINE_EVENTS,
  };

  @api events = [];
  isLoading = false;
  hasError = false;
  errorMessage = "";

  get sortedEvents() {
    if (!this.events || this.events.length === 0) {
      return [];
    }

    // Sort by date (most recent first) and add icon
    return [...this.events]
      .sort((a, b) => {
        let dateA = new Date(a.date || a.CreatedDate);
        let dateB = new Date(b.date || b.CreatedDate);
        return dateB - dateA;
      })
      .map((event) => ({
        ...event,
        iconName: this.getEventIcon(event.type),
      }));
  }

  get hasEvents() {
    return this.events && this.events.length > 0;
  }

  get isEmpty() {
    return !this.isLoading && !this.hasError && !this.hasEvents;
  }

  get notLoading() {
    return !this.isLoading;
  }

  get notError() {
    return !this.hasError;
  }

  getEventIcon(eventType) {
    if (eventType === "GAP_DETECTED") return "utility:error";
    if (eventType === "GAP_REMEDIATED") return "utility:success";
    if (eventType === "EVIDENCE_COLLECTED") return "utility:file";
    if (eventType === "ASSESSMENT_COMPLETE") return "utility:check";
    return "utility:info";
  }
}
