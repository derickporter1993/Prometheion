import { LightningElement, track, wire } from 'lwc';
import calculateReadinessScore from '@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PrometheionDashboard extends LightningElement {
    @track scoreResult = null;
    @track isLoading = true;
    @track lastUpdated = new Date();
    @track selectedFramework = 'ALL';
    @track showDrillDown = false;

    @wire(calculateReadinessScore)
    wiredScore({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.scoreResult = data;
            this.lastUpdated = new Date();
        } else if (error) {
            const errorMessage = this.extractErrorMessage(error);
            this.showToast('Error', errorMessage, 'error');
        }
    }

    get displayScore() {
        return this.scoreResult?.overallScore ?? 0;
    }

    get rating() {
        return this.scoreResult?.rating ?? 'N/A';
    }

    get ratingBadgeClass() {
        const rating = this.rating.toLowerCase();
        return `rating-badge rating-${rating === 'needs_improvement' ? 'fair' : rating}`;
    }

    get scoreRingStyle() {
        const score = this.displayScore;
        return `--score-percent: ${score}`;
    }

    get formattedLastUpdate() {
        return this.lastUpdated.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    get refreshIconClass() {
        return this.isLoading ? 'spinning' : '';
    }

    get frameworkList() {
        if (!this.scoreResult?.frameworkScores) return [];

        const frameworks = [
            { key: 'HIPAA', name: 'HIPAA', color: '#6366f1', description: 'Health Insurance Portability and Accountability Act' },
            { key: 'SOC2', name: 'SOC 2', color: '#8b5cf6', description: 'Service Organization Control 2' },
            { key: 'NIST', name: 'NIST', color: '#a855f7', description: 'National Institute of Standards and Technology' },
            { key: 'FedRAMP', name: 'FedRAMP', color: '#22d3ee', description: 'Federal Risk and Authorization Management Program' },
            { key: 'GDPR', name: 'GDPR', color: '#10b981', description: 'General Data Protection Regulation' },
            { key: 'SOX', name: 'SOX', color: '#f59e0b', description: 'Sarbanes-Oxley Act' },
            { key: 'PCI_DSS', name: 'PCI-DSS', color: '#ef4444', description: 'Payment Card Industry Data Security Standard' },
            { key: 'CCPA', name: 'CCPA', color: '#06b6d4', description: 'California Consumer Privacy Act' },
            { key: 'GLBA', name: 'GLBA', color: '#84cc16', description: 'Gramm-Leach-Bliley Act' },
            { key: 'ISO27001', name: 'ISO 27001', color: '#8b5cf6', description: 'ISO/IEC 27001 Information Security Management' }
        ];

        let filteredFrameworks = frameworks;
        if (this.selectedFramework !== 'ALL') {
            filteredFrameworks = frameworks.filter(fw => fw.key === this.selectedFramework);
        }

        return filteredFrameworks.map(fw => {
            const score = this.scoreResult?.frameworkScores?.[fw.key] ?? 0;
            return {
                ...fw,
                score: Math.round(score),
                scoreClass: this.getScoreClass(score),
                progressStyle: `width: ${score}%; background: ${fw.color}`,
                isSelected: this.selectedFramework === fw.key
            };
        });
    }

    get filteredTopRisks() {
        if (!this.scoreResult?.topRisks) return [];
        if (this.selectedFramework === 'ALL') return this.topRisks;
        return this.topRisks.filter(risk => risk.framework === this.selectedFramework);
    }

    get selectedFrameworkDetails() {
        if (this.selectedFramework === 'ALL' || !this.scoreResult?.frameworkScores) return null;
        const frameworks = this.frameworkList;
        return frameworks.find(fw => fw.key === this.selectedFramework) || null;
    }

    get frameworkOptions() {
        return [
            { label: 'All Frameworks', value: 'ALL' },
            { label: 'HIPAA', value: 'HIPAA' },
            { label: 'SOC 2', value: 'SOC2' },
            { label: 'NIST', value: 'NIST' },
            { label: 'FedRAMP', value: 'FedRAMP' },
            { label: 'GDPR', value: 'GDPR' },
            { label: 'SOX', value: 'SOX' },
            { label: 'PCI-DSS', value: 'PCI_DSS' },
            { label: 'CCPA', value: 'CCPA' },
            { label: 'GLBA', value: 'GLBA' },
            { label: 'ISO 27001', value: 'ISO27001' }
        ];
    }

    get factors() {
        if (!this.scoreResult?.factors) return [];

        return this.scoreResult.factors.map(factor => ({
            ...factor,
            statusClass: this.getStatusClass(factor.status),
            barStyle: `width: ${factor.score}%; background: ${this.getBarColor(factor.score)}`,
            weightPercent: Math.round(factor.weight * 100)
        }));
    }

    get topRisks() {
        if (!this.scoreResult?.topRisks) return [];

        return this.scoreResult.topRisks.map(risk => ({
            ...risk,
            severityClass: `severity-badge severity-${risk.severity.toLowerCase()}`,
            viewDetailsLabel: `View details for ${risk.title || 'risk'}`
        }));
    }

    get hasRisks() {
        return this.filteredTopRisks.length > 0;
    }

    get showFrameworkGrid() {
        return !this.showDrillDown;
    }

    getScoreClass(score) {
        if (score >= 80) return 'framework-score score-high';
        if (score >= 60) return 'framework-score score-medium';
        return 'framework-score score-low';
    }

    getStatusClass(status) {
        const statusMap = {
            'EXCELLENT': 'status-badge status-excellent',
            'GOOD': 'status-badge status-good',
            'WARNING': 'status-badge status-warning',
            'CRITICAL': 'status-badge status-critical'
        };
        return statusMap[status] || 'status-badge status-warning';
    }

    getBarColor(score) {
        if (score >= 80) return '#10b981';
        if (score >= 60) return '#f59e0b';
        return '#ef4444';
    }

    refreshData() {
        this.isLoading = true;
        // Force refresh by calling imperative Apex
        calculateReadinessScore()
            .then(result => {
                this.scoreResult = result;
                this.lastUpdated = new Date();
                this.isLoading = false;
            })
            .catch(error => {
                this.isLoading = false;
                const errorMessage = this.extractErrorMessage(error);
                this.showToast('Error', errorMessage, 'error');
            });
    }

    handleGenerateSoc2() {
        this.showToast('Coming Soon', 'SOC2 report generation will be available in the next release.', 'info');
    }

    handleGenerateHipaa() {
        this.showToast('Coming Soon', 'HIPAA report generation will be available in the next release.', 'info');
    }

    handleFrameworkFilter(event) {
        this.selectedFramework = event.detail.value;
        this.showDrillDown = event.detail.value !== 'ALL';
    }

    handleFrameworkClick(event) {
        const frameworkKey = event.currentTarget.dataset.framework;
        if (frameworkKey) {
            this.selectedFramework = frameworkKey;
            this.showDrillDown = true;
        }
    }

    handleBackToAll() {
        this.selectedFramework = 'ALL';
        this.showDrillDown = false;
    }

    handleRiskClick(event) {
        const nodeId = event.currentTarget.dataset.nodeId;
        this.showToast('Risk Details', `Viewing details for risk: ${nodeId}`, 'info');
    }

    extractErrorMessage(error) {
        if (error?.body?.message) {
            return error.body.message;
        }
        if (error?.message) {
            return error.message;
        }
        return 'An unexpected error occurred. Please try again.';
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title,
                message,
                variant
            })
        );
    }
}
