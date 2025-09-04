import { LightningElement, track } from 'lwc';
import { subscribe, onError } from 'lightning/empApi';
import recent from '@salesforce/apex/AlertHistoryService.recent';

export default class PerformanceAlertPanel extends LightningElement {
  channelName = '/event/Performance_Alert__e';
  subscription = {};
  @track rows = [];
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

  handleSubscribe() {
    const messageCallback = (response) => {
      const e = response?.data?.payload || {};
      const rec = {
        key: `${Date.now()}`,
        metric: e.Metric__c,
        value: e.Value__c,
        threshold: e.Threshold__c,
        contextRecordId: e.Context_Record__c,
        createdDate: new Date().toISOString()
      };
      this.rows = [rec, ...this.rows].slice(0, 50);
    };
    subscribe(this.channelName, -1, messageCallback).then(resp => { this.subscription = resp; });
  }
}
