import { LightningElement, track } from 'lwc';
import fetchGovernorStats from '@salesforce/apex/LimitMetrics.fetchGovernorStats';
import evaluateAndPublish from '@salesforce/apex/PerformanceRuleEngine.evaluateAndPublish';

export default class SystemMonitorDashboard extends LightningElement {
  @track stats;
  timer;

  get cpuPct(){ return Math.min(100, Math.round((this.stats?.cpuMs || 0)/100)); }
  get heapPct(){ return Math.min(100, Math.round(((this.stats?.heapKb || 0)/50))); }

  connectedCallback(){ this.load(); this.timer = setInterval(()=>this.load(), 60000); }
  disconnectedCallback(){ if(this.timer) clearInterval(this.timer); }

  async load(){
    try {
      this.stats = await fetchGovernorStats();
      await evaluateAndPublish({ stats: this.stats, contextRecordId: null });
    } catch(e){ /* eslint-disable no-console */ console.error(e); }
  }
  refresh(){ this.load(); }
}
