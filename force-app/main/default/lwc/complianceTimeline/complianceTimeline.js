import { LightningElement, api } from 'lwc';

export default class ComplianceTimeline extends LightningElement {
    @api events = [];

    get sortedEvents() {
        if (!this.events || this.events.length === 0) {
            return [];
        }
        
        // Sort by date (most recent first)
        return [...this.events].sort((a, b) => {
            let dateA = new Date(a.date || a.CreatedDate);
            let dateB = new Date(b.date || b.CreatedDate);
            return dateB - dateA;
        });
    }

    get hasEvents() {
        return this.events && this.events.length > 0;
    }

    get eventIcon() {
        return (eventType) => {
            if (eventType === 'GAP_DETECTED') return 'utility:error';
            if (eventType === 'GAP_REMEDIATED') return 'utility:success';
            if (eventType === 'EVIDENCE_COLLECTED') return 'utility:file';
            if (eventType === 'ASSESSMENT_COMPLETE') return 'utility:check';
            return 'utility:info';
        };
    }
}
