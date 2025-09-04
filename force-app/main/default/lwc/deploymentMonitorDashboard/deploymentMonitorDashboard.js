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
  connectedCallback(){ this.load(); this.timer = setInterval(()=>this.load(), 60000); }
  disconnectedCallback(){ if(this.timer) clearInterval(this.timer); }
  async load(){ try { this.rows = await recent({ limitSize: 20 }); } catch(e){ /* eslint-disable no-console */ console.error(e);} }
}
