import { LightningElement, api, wire, track } from 'lwc';
import getFrameworkDetails from '@salesforce/apex/ComplianceScoreCardController.getFrameworkDetails';
import { NavigationMixin } from 'lightning/navigation';

export default class ComplianceScoreCard extends NavigationMixin(LightningElement) {
    @api framework;
    @track frameworkDetails = null;
    @track isLoadingDetails = false;

    get frameworkKey() {
        return this.framework?.framework || this.framework?.key || null;
    }

    @wire(getFrameworkDetails, { framework: '$frameworkKey' })
    wiredFrameworkDetails({ error, data }) {
        if (data) {
            this.frameworkDetails = data;
            this.isLoadingDetails = false;
        } else if (error) {
            console.error('Error loading framework details:', error);
            this.isLoadingDetails = false;
        } else {
            this.isLoadingDetails = true;
        }
    }

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

    get hasFrameworkDetails() {
        return this.frameworkDetails !== null;
    }

    get mappingCount() {
        return this.frameworkDetails?.mappingCount ?? 0;
    }

    get evidenceCount() {
        return this.frameworkDetails?.evidenceCount ?? 0;
    }

    get requirementCount() {
        return this.frameworkDetails?.requirementCount ?? 0;
    }

    get latestAuditPackage() {
        return this.frameworkDetails?.latestAuditPackage;
    }

    get hasLatestPackage() {
        return this.latestAuditPackage !== null && this.latestAuditPackage !== undefined;
    }

    formatDate(dateValue) {
        if (!dateValue) return '';
        const date = new Date(dateValue);
        return date.toLocaleDateString('en-US', { year: 'numeric', month: 'short', day: 'numeric' });
    }

    handleViewAuditPackage(event) {
        const packageId = event.currentTarget.dataset.packageId;
        if (packageId) {
            this[NavigationMixin.Navigate]({
                type: 'standard__recordPage',
                attributes: {
                    recordId: packageId,
                    actionName: 'view'
                }
            });
        }
    }
}
