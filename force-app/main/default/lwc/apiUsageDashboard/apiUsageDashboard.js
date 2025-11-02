import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getSnapshots from '@salesforce/apex/ApiUsageDashboardController.recent';

export default class ApiUsageDashboard extends LightningElement {
  @track rows = [];
  timer = null;
  pollInterval = 60000; // Base poll interval (60s)
  currentInterval = 60000; // Current interval with backoff
  errorBackoffMultiplier = 1; // Exponential backoff multiplier
  maxBackoffMultiplier = 8; // Max backoff is 8x base interval

  columns = [
    { label: 'Taken On', fieldName: 'takenOn', type: 'date' },
    { label: 'Used', fieldName: 'used', type: 'number' },
    { label: 'Limit', fieldName: 'limit', type: 'number' },
    { label: 'Percent', fieldName: 'percent', type: 'percent' },
    { label: 'Projected Exhaustion', fieldName: 'projected', type: 'date' }
  ];

  connectedCallback() {
    this.load();
    this.startPolling();
    // Listen for visibility changes to pause/resume polling
    document.addEventListener('visibilitychange', this.handleVisibilityChange);
  }

  disconnectedCallback() {
    this.stopPolling();
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
  }

  handleVisibilityChange = () => {
    if (document.visibilityState === 'visible') {
      // Resume polling when tab becomes visible
      this.startPolling();
      this.load(); // Load immediately when becoming visible
    } else {
      // Pause polling when tab is hidden
      this.stopPolling();
    }
  };

  startPolling() {
    if (!this.timer && document.visibilityState === 'visible') {
      this.timer = setInterval(() => this.load(), this.currentInterval);
    }
  }

  stopPolling() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  async load() {
    try {
      const data = await getSnapshots({ limitSize: 20 });
      // Use stable IDs from server data if available, otherwise fallback to index
      this.rows = data.map((r, idx) => ({ 
        id: r.id || `row-${idx}`, 
        ...r 
      }));
      
      // Reset backoff on success
      if (this.errorBackoffMultiplier > 1) {
        this.errorBackoffMultiplier = 1;
        this.currentInterval = this.pollInterval;
        // Restart timer with normal interval
        this.stopPolling();
        this.startPolling();
      }
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
      this.showError('Failed to load API usage data', e.body?.message || e.message);
      
      // Apply exponential backoff on error
      if (this.errorBackoffMultiplier < this.maxBackoffMultiplier) {
        this.errorBackoffMultiplier *= 2;
        this.currentInterval = this.pollInterval * this.errorBackoffMultiplier;
        // Restart timer with increased interval
        this.stopPolling();
        this.startPolling();
      }
    }
  }

  showError(title, message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: title,
        message: message,
        variant: 'error'
      })
    );
  }
}
