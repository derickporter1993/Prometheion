import { LightningElement } from "lwc";
import { subscribe, unsubscribe, onError } from "lightning/empApi";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

export default class ElaroScoreListener extends LightningElement {
  subscription = {};
  isSubscribed = false;
  error;

  connectedCallback() {
    // Register error listener
    this.registerErrorListener();
    // Subscribe to Platform Event
    this.subscribeToScoreEvents();
  }

  disconnectedCallback() {
    this.unsubscribeFromScoreEvents();
  }

  /**
   * Subscribe to Elaro_Score_Result__e Platform Event
   */
  subscribeToScoreEvents() {
    const messageCallback = (response) => {
      this.handleScoreUpdate(response.data.payload);
    };

    // Subscribe to the Platform Event
    subscribe("/event/Elaro_Score_Result__e", -1, messageCallback)
      .then((response) => {
        this.subscription = response;
        this.isSubscribed = true;
        this.error = undefined;
      })
      .catch((error) => {
        this.error = error;
        this.showToast("Subscription Error", "Unable to subscribe to score updates.", "error");
      });
  }

  /**
   * Unsubscribe from Platform Event
   */
  unsubscribeFromScoreEvents() {
    unsubscribe(this.subscription, () => {
      this.isSubscribed = false;
    });
  }

  /**
   * Register error listener
   */
  registerErrorListener() {
    onError((error) => {
      this.error = error;
      this.showToast(
        "Streaming Error",
        "An error occurred while listening for score updates.",
        "error"
      );
    });
  }

  /**
   * Handle score update from Platform Event
   */
  handleScoreUpdate(payload) {
    // Dispatch custom event for parent components
    const scoreUpdateEvent = new CustomEvent("scoreupdate", {
      detail: {
        scoreId: payload.Score_ID__c,
        overallScore: payload.Overall_Score__c,
        frameworkScores: payload.Framework_Scores__c,
        riskLevel: payload.Risk_Level__c,
      },
    });

    this.dispatchEvent(scoreUpdateEvent);

    // Show toast notification for high-risk scores
    if (payload.Risk_Level__c === "CRITICAL" || payload.Risk_Level__c === "HIGH") {
      this.showToast("Compliance Score Updated", `Risk Level: ${payload.Risk_Level__c}`, "warning");
    }
  }

  /**
   * Show toast notification
   */
  showToast(title, message, variant) {
    const evt = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant,
    });
    this.dispatchEvent(evt);
  }

  get subscriptionStatus() {
    return this.isSubscribed ? "Subscribed" : "Not Subscribed";
  }
}
