import { LightningElement, api } from 'lwc';

export default class ComplianceGapList extends LightningElement {
    @api gaps = [];

    get hasGaps() {
        return this.gaps && this.gaps.length > 0;
    }

    get severityClass() {
        return (gap) => {
            if (gap.Severity__c === 'CRITICAL') return 'slds-text-color_error';
            if (gap.Severity__c === 'HIGH') return 'slds-text-color_warning';
            return 'slds-text-color_default';
        };
    }
}
