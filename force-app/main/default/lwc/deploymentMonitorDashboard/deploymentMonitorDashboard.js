import { LightningElement, track } from 'lwc';
import recent from '@salesforce/apex/DeploymentMetrics.recent';

export default class DeploymentMonitorDashboard extends LightningElement {
  @track rows = [];
  columns = [
    { label: 'Name', fieldName: 'name' },
    { label: 'Status', fieldName: 'status' },
    { label: 'Started', fieldName: 'startedOn', type: 'date' },
    { label: 'Finished', fieldName: 'finishedOn', type: 'date' },
    { label: 'Passed', fieldName: 'testsPassed', type: 'number' },
    { label: 'Failed', fieldName: 'testsFailed', type: 'number' }
  ];
  timer;
  
  connectedCallback() {
    this.load();
    this.startPolling();
    // Pause polling when tab is hidden
    document.addEventListener('visibilitychange', this.handleVisibilityChange);
  }

  disconnectedCallback() {
    this.stopPolling();
    document.removeEventListener('visibilitychange', this.handleVisibilityChange);
  }
  
  handleVisibilityChange = () => {
    if (document.visibilityState === 'visible') {
      this.startPolling();
      this.load(); // Load immediately when becoming visible
    } else {
      this.stopPolling();
    }
  };
  
  startPolling() {
    if (!this.timer && document.visibilityState === 'visible') {
      this.timer = setInterval(() => this.load(), 60000);
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
      this.rows = await recent({ limitSize: 20 });
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
    }
  }
}
