import { LightningElement, track } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';
import recent from '@salesforce/apex/AlertHistoryService.recent';

export default class PerformanceAlertPanel extends LightningElement {
  channelName = '/event/Performance_Alert__e';
  subscription = {};
  @track rows = [];
  pendingEvents = []; // Buffer for batching incoming events
  debounceTimer = null; // Timer for debouncing event processing
  maxRows = 50; // Cap array size to prevent memory issues
  
  columns = [
    { label: 'Metric', fieldName: 'metric' },
    { label: 'Value', fieldName: 'value', type: 'number' },
    { label: 'Threshold', fieldName: 'threshold', type: 'number' },
    { label: 'Context', fieldName: 'contextRecordId' },
    { label: 'Created', fieldName: 'createdDate', type: 'date' }
  ];

  async connectedCallback(){
    this.rows = (await recent({ limitSize: 25 })).map((r, idx)=> ({ key: `${r.createdDate}-${idx}`, ...r }));
    this.handleSubscribe();
    onError(error => { /* eslint-disable no-console */ console.error('EMP API error: ', error); });
  }

  disconnectedCallback() {
    // Clean up debounce timer and flush any pending events
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
      this.debounceTimer = null;
    }
    this.pendingEvents = [];
  }

  handleSubscribe() {
    const messageCallback = (response) => {
      const e = response?.data?.payload || {};
      const rec = {
        key: `${Date.now()}-${Math.random()}`, // Ensure unique key
        metric: e.Metric__c,
        value: e.Value__c,
        threshold: e.Threshold__c,
        contextRecordId: e.Context_Record__c,
        createdDate: new Date().toISOString()
      };
      
      // Add to pending buffer
      this.pendingEvents.push(rec);
      
      // Debounce: batch multiple events within 250ms window
      if (this.debounceTimer) {
        clearTimeout(this.debounceTimer);
      }
      this.debounceTimer = setTimeout(() => {
        this.flushPendingEvents();
      }, 250);
    };
    subscribe(this.channelName, -1, messageCallback).then(resp => { this.subscription = resp; });
  }

  flushPendingEvents() {
    if (this.pendingEvents.length === 0) return;
    
    // Efficiently prepend new events and cap at maxRows
    // This avoids copying large arrays repeatedly
    const newEvents = this.pendingEvents.splice(0);
    this.rows = [...newEvents, ...this.rows].slice(0, this.maxRows);
    
    this.debounceTimer = null;
  }
}
