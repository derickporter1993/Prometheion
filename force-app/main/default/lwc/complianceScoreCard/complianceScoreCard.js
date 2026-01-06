import { LightningElement, api } from 'lwc';

export default class ComplianceScoreCard extends LightningElement {
    @api framework;

    get scoreClass() {
        if (this.framework && this.framework.score >= 90) {
            return 'score-high';
        } else if (this.framework && this.framework.score >= 70) {
            return 'score-medium';
        } else {
            return 'score-low';
        }
    }

    get statusIcon() {
        if (this.framework && this.framework.status === 'COMPLIANT') {
            return 'utility:success';
        } else if (this.framework && this.framework.status === 'PARTIALLY_COMPLIANT') {
            return 'utility:warning';
        } else {
            return 'utility:error';
        }
    }
}
