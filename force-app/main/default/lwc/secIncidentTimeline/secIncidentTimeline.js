import { LightningElement, api } from "lwc";
import SECIncidentTimeline from "@salesforce/label/c.SEC_IncidentTimeline";
import SECEventType from "@salesforce/label/c.SEC_EventType";
import SECNoEvents from "@salesforce/label/c.SEC_NoEvents";

export default class SecIncidentTimeline extends LightningElement {
  @api events = [];

  label = { SECIncidentTimeline, SECEventType, SECNoEvents };

  get sortedEvents() {
    if (!this.events || this.events.length === 0) return [];
    return [...this.events].sort((a, b) => new Date(b.Event_Date__c) - new Date(a.Event_Date__c));
  }

  get hasEvents() {
    return this.sortedEvents.length > 0;
  }

  getEventIcon(eventType) {
    const iconMap = {
      Discovery: "utility:warning",
      Determination: "utility:check",
      "Board Approval": "utility:success",
      Filing: "utility:email",
    };
    return iconMap[eventType] || "utility:event";
  }

  formatDate(dateStr) {
    if (!dateStr) return "";
    return new Date(dateStr).toLocaleString();
  }
}
