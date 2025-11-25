import { LightningElement, wire } from 'lwc';
import calculateReadinessScore from '@salesforce/apex/SentinelComplianceScorer.calculateReadinessScore';
import getScoreBreakdown from '@salesforce/apex/SentinelComplianceScorer.getScoreBreakdown';
import generateEvidencePack from '@salesforce/apex/SentinelEvidenceEngine.generateEvidencePack';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

export default class SentinelReadinessScore extends LightningElement {
    score = 0;
    accessScore = 0;
    configScore = 0;
    automationScore = 0;
    evidenceScore = 0;
    scoreStatus = 'Calculating...';
    isGenerating = false;
    wiredScoreResult;
    wiredBreakdownResult;

    @wire(calculateReadinessScore)
    wiredScore(result) {
        this.wiredScoreResult = result;
        if (result.data) {
            this.score = result.data;
            this.updateScoreStatus();
        } else if (result.error) {
            this.showToast('Error', 'Failed to calculate score', 'error');
        }
    }

    @wire(getScoreBreakdown)
    wiredBreakdown(result) {
        this.wiredBreakdownResult = result;
        if (result.data) {
            this.accessScore = result.data.access || 0;
            this.configScore = result.data.config || 0;
            this.automationScore = result.data.automation || 0;
            this.evidenceScore = result.data.evidence || 0;
        }
    }

    updateScoreStatus() {
        if (this.score >= 80) {
            this.scoreStatus = '✅ Audit Ready';
        } else if (this.score >= 60) {
            this.scoreStatus = '⚠️ Action Required';
        } else {
            this.scoreStatus = '❌ Critical Risks';
        }
    }

    get scoreStatusClass() {
        if (this.score >= 80) {
            return 'slds-text-color_success slds-m-top_small';
        } else if (this.score >= 60) {
            return 'slds-text-color_warning slds-m-top_small';
        }
        return 'slds-text-color_error slds-m-top_small';
    }

    get accessClass() {
        return this.accessScore >= 80 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get configClass() {
        return this.configScore >= 80 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get automationClass() {
        return this.automationScore >= 80 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    get evidenceClass() {
        return this.evidenceScore >= 80 ? 'slds-text-color_success' : 'slds-text-color_error';
    }

    handleGenerateEvidence() {
        this.isGenerating = true;

        generateEvidencePack({ frameworkName: 'SOC2' })
            .then(summary => {
                this.showToast('Success', 'Evidence pack generated successfully', 'success');
                console.log('Evidence Summary:', summary);
                this.isGenerating = false;
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
                this.isGenerating = false;
            });
    }

    handleRefresh() {
        return Promise.all([
            refreshApex(this.wiredScoreResult),
            refreshApex(this.wiredBreakdownResult)
        ]);
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
