import { LightningElement, track } from 'lwc';
import getSnapshots from '@salesforce/apex/ApiUsageDashboardController.recent';

export default class ApiUsageDashboard extends LightningElement {
  @track rows = [];
  columns = [
    { label: 'Taken On', fieldName: 'takenOn', type: 'date' },
    { label: 'Used', fieldName: 'used', type: 'number' },
    { label: 'Limit', fieldName: 'limit', type: 'number' },
    { label: 'Percent', fieldName: 'percent', type: 'percent' },
    { label: 'Projected Exhaustion', fieldName: 'projected', type: 'date' }
  ];
  connectedCallback(){ this.load(); this.timer = setInterval(()=>this.load(), 60000); }
  disconnectedCallback(){ if(this.timer) clearInterval(this.timer); }
  async load(){
    try {
      const data = await getSnapshots({ limitSize: 20 });
      this.rows = data.map((r, idx)=> ({ id: idx, ...r }));
    } catch(e) { /* eslint-disable no-console */ console.error(e); }
  }
}
