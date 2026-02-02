import { LightningElement, track } from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ElaroEventMonitor extends LightningElement {
  @track events = [];
  @track isLoading = false;
  subscription = {};
  channelName = "/event/Elaro_Event__e";

  connectedCallback() {
    this.handleSubscribe();
    this.registerErrorListener();
  }

  disconnectedCallback() {
    this.handleUnsubscribe();
  }

  handleSubscribe() {
    const messageCallback = (response) => {
      const event = response.data.payload;
      this.events = [
        {
          id: Date.now() + Math.random(),
          eventType: event.Event_Type__c,
          entityType: event.Entity_Type__c,
          entityId: event.Entity_Id__c,
          framework: event.Framework__c,
          timestamp: event.Timestamp__c,
          correlationId: event.Correlation_Id__c,
        },
        ...this.events,
      ].slice(0, 100); // Keep last 100 events
    };

    subscribe(this.channelName, -1, messageCallback).then((response) => {
      this.subscription = response;
      this.showToast("Success", "Subscribed to Elaro Events", "success");
    });
  }

  handleUnsubscribe() {
    unsubscribe(this.subscription, () => {
      this.showToast("Info", "Unsubscribed from Elaro Events", "info");
    });
  }

  registerErrorListener() {
    onError((error) => {
      this.showToast("Error", "Event subscription error: " + JSON.stringify(error), "error");
    });
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant,
      })
    );
  }

  get hasEvents() {
    return this.events.length > 0;
  }

  get noEvents() {
    return !this.hasEvents;
  }
}
