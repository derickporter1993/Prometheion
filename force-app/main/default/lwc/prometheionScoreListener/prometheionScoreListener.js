import { LightningElement } from 'lwc';
import { subscribe, unsubscribe, onError } from 'lightning/empApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PrometheionScoreListener extends LightningElement {
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
     * Subscribe to Prometheion_Score_Result__e Platform Event
     */
    subscribeToScoreEvents() {
        const messageCallback = (response) => {
            console.log('New score result received: ', JSON.stringify(response));
            this.handleScoreUpdate(response.data.payload);
        };

        // Subscribe to the Platform Event
        subscribe('/event/Prometheion_Score_Result__e', -1, messageCallback).then(response => {
            console.log('Subscription request sent to: ', JSON.stringify(response.channel));
            this.subscription = response;
            this.isSubscribed = true;
            this.error = undefined;
        }).catch(error => {
            console.error('Subscription error: ', JSON.stringify(error));
            this.error = error;
        });
    }

    /**
     * Unsubscribe from Platform Event
     */
    unsubscribeFromScoreEvents() {
        unsubscribe(this.subscription, response => {
            console.log('Unsubscribed from channel: ', JSON.stringify(response));
            this.isSubscribed = false;
        });
    }

    /**
     * Register error listener
     */
    registerErrorListener() {
        onError(error => {
            console.error('Received error from server: ', JSON.stringify(error));
            this.error = error;
        });
    }

    /**
     * Handle score update from Platform Event
     */
    handleScoreUpdate(payload) {
        // Dispatch custom event for parent components
        const scoreUpdateEvent = new CustomEvent('scoreupdate', {
            detail: {
                scoreId: payload.Score_ID__c,
                overallScore: payload.Overall_Score__c,
                frameworkScores: payload.Framework_Scores__c,
                riskLevel: payload.Risk_Level__c
            }
        });
        
        this.dispatchEvent(scoreUpdateEvent);

        // Show toast notification for high-risk scores
        if (payload.Risk_Level__c === 'CRITICAL' || payload.Risk_Level__c === 'HIGH') {
            this.showToast('Compliance Score Updated', 
                `Risk Level: ${payload.Risk_Level__c}`, 
                'warning');
        }
    }

    /**
     * Show toast notification
     */
    showToast(title, message, variant) {
        const evt = new ShowToastEvent({
            title: title,
            message: message,
            variant: variant
        });
        this.dispatchEvent(evt);
    }

    get subscriptionStatus() {
        return this.isSubscribed ? 'Subscribed' : 'Not Subscribed';
    }
}

