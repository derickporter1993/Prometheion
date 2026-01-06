import { LightningElement, track, wire } from 'lwc';
import calculateReadinessScore from '@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

export default class PrometheionDashboard extends LightningElement {
    @track scoreResult = null;
    @track isLoading = true;
    @track lastUpdated = new Date();

    @wire(calculateReadinessScore)
    wiredScore({ error, data }) {
        this.isLoading = false;
        if (data) {
            this.scoreResult = data;
            this.lastUpdated = new Date();
        } else if (error) {
            console.error('Error loading score:', error);
            this.showToast('Error', 'Failed to load compliance score', 'error');
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
            { key: 'HIPAA', name: 'HIPAA', color: '#6366f1' },
            { key: 'SOC2', name: 'SOC 2', color: '#8b5cf6' },
            { key: 'NIST', name: 'NIST', color: '#a855f7' },
            { key: 'FedRAMP', name: 'FedRAMP', color: '#22d3ee' },
            { key: 'GDPR', name: 'GDPR', color: '#10b981' }
        ];

        return frameworks.map(fw => {
            const score = this.scoreResult?.frameworkScores?.[fw.key] ?? 0;
            return {
                ...fw,
                score: Math.round(score),
                scoreClass: this.getScoreClass(score),
                progressStyle: `width: ${score}%; background: ${fw.color}`
            };
        });
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
        return this.topRisks.length > 0;
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
                console.error('Refresh error:', error);
                this.isLoading = false;
                this.showToast('Error', 'Failed to refresh data', 'error');
            });
    }

    handleGenerateSoc2() {
        this.showToast('Coming Soon', 'SOC2 report generation will be available in the next release.', 'info');
    }

    handleGenerateHipaa() {
        this.showToast('Coming Soon', 'HIPAA report generation will be available in the next release.', 'info');
    }

    handleRiskClick(event) {
        const nodeId = event.currentTarget.dataset.nodeId;
        this.showToast('Risk Details', `Viewing details for risk: ${nodeId}`, 'info');
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
