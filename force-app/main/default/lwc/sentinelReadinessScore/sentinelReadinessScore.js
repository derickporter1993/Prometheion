import { LightningElement, wire, track } from 'lwc';
import calculateReadinessScore from '@salesforce/apex/SentinelComplianceScorer.calculateReadinessScore';
import generateEvidencePack from '@salesforce/apex/SentinelLegalDocumentGenerator.generateLegalAttestation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { NavigationMixin } from 'lightning/navigation';

export default class SentinelReadinessScore extends NavigationMixin(LightningElement) {
    @track score = 0;
    @track accessScore = 0;
    @track configScore = 0;
    @track automationScore = 0;
    @track evidenceScore = 0;
    @track scoreStatus = 'Calculating...';
    @track currentStep = 'access';

    @wire(calculateReadinessScore)
    wiredScore({ error, data }) {
        if (data) {
            this.score = data;
            this.calculateSubScores();
            this.updateScoreStatus();
            this.updateProgressStep();
        } else if (error) {
            this.showToast('Error', error.body.message, 'error');
            this.scoreStatus = 'Error';
        }
    }

    calculateSubScores() {
        this.accessScore = Math.round(this.score * 0.25);
        this.configScore = Math.round(this.score * 0.25);
        this.automationScore = Math.round(this.score * 0.25);
        this.evidenceScore = Math.round(this.score * 0.25);
    }

    updateScoreStatus() {
        if (this.score >= 80) {
            this.scoreStatus = 'Audit Ready';
            this.currentStep = 'evidence';
        } else if (this.score >= 60) {
            this.scoreStatus = 'Action Required';
            this.currentStep = 'automation';
        } else {
            this.scoreStatus = 'Critical Risks';
            this.currentStep = 'access';
        }
    }

    updateProgressStep() {
        const scores = [
            { name: 'access', value: this.accessScore },
            { name: 'config', value: this.configScore },
            { name: 'automation', value: this.automationScore },
            { name: 'evidence', value: this.evidenceScore }
        ];
        const weakest = scores.reduce((min, score) => score.value < min.value ? score : min);
        this.currentStep = weakest.name;
    }

    get normalizedScore() {
        return this.score / 100;
    }

    get accessClass() {
        return this.accessScore >= 80 ? 'slds-text-color_success slds-text-heading_medium' :
               this.accessScore >= 60 ? 'slds-text-color_warning slds-text-heading_medium' :
               'slds-text-color_error slds-text-heading_medium';
    }

    get configClass() {
        return this.configScore >= 80 ? 'slds-text-color_success slds-text-heading_medium' :
               this.configScore >= 60 ? 'slds-text-color_warning slds-text-heading_medium' :
               'slds-text-color_error slds-text-heading_medium';
    }

    get automationClass() {
        return this.automationScore >= 80 ? 'slds-text-color_success slds-text-heading_medium' :
               this.automationScore >= 60 ? 'slds-text-color_warning slds-text-heading_medium' :
               'slds-text-color_error slds-text-heading_medium';
    }

    get evidenceClass() {
        return this.evidenceScore >= 80 ? 'slds-text-color_success slds-text-heading_medium' :
               this.evidenceScore >= 60 ? 'slds-text-color_warning slds-text-heading_medium' :
               'slds-text-color_error slds-text-heading_medium';
    }

    handleGenerateSoc2() {
        this.generatePack('SOC2');
    }

    handleGenerateHipaa() {
        this.generatePack('HIPAA');
    }

    generatePack(framework) {
        const today = new Date();
        const startDate = new Date(today.getFullYear(), today.getMonth() - 3, 1);
        generateEvidencePack({ framework: framework, startDate: startDate, endDate: today })
            .then(contentDocId => {
                this.showToast('Success', `${framework} evidence pack generated`, 'success');
                this.navigateToContent(contentDocId);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    navigateToContent(contentDocId) {
        this[NavigationMixin.Navigate]({
            type: 'standard__recordPage',
            attributes: { recordId: contentDocId, actionName: 'view' }
        });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }
}
