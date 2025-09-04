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
  connectedCallback(){ this.load(); this.timer = setInterval(()=>this.load(), 60000); }
  disconnectedCallback(){ if(this.timer) clearInterval(this.timer); }
  async load(){ try { this.rows = await topFlows({ limitSize: 20 }); } catch(e){ /* eslint-disable no-console */ console.error(e);} }
}
