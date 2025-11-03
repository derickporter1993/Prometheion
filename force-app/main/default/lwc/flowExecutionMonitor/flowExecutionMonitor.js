import { LightningElement, track } from 'lwc';
import topFlows from '@salesforce/apex/FlowExecutionStats.topFlows';

export default class FlowExecutionMonitor extends LightningElement {
  @track rows = [];
  columns = [
    { label: 'Flow', fieldName: 'flowName' },
    { label: 'Runs', fieldName: 'runs', type: 'number' },
    { label: 'Faults', fieldName: 'faults', type: 'number' },
    { label: 'Last Run', fieldName: 'lastRun', type: 'date' }
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
      this.rows = await topFlows({ limitSize: 20 });
    } catch (e) {
      /* eslint-disable no-console */
      console.error(e);
    }
  }
}
