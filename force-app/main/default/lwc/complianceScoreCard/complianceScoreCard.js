import { LightningElement, api } from 'lwc';

export default class ComplianceScoreCard extends LightningElement {
    @api framework;

    get scoreClass() {
        if (this.framework && this.framework.score >= 90) {
            return 'score-high';
        }
        if (this.framework && this.framework.score >= 70) {
            return 'score-medium';
        }
        return 'score-low';
    }

    get statusIcon() {
        if (this.framework && this.framework.status === 'COMPLIANT') {
            return 'utility:success';
        }
        if (this.framework && this.framework.status === 'PARTIALLY_COMPLIANT') {
            return 'utility:warning';
        }
        return 'utility:error';
    }
}
