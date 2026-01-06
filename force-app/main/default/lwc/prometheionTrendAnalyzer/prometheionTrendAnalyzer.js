import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getTimeSeries from '@salesforce/apex/PrometheionTrendController.getTimeSeries';
import getDateFields from '@salesforce/apex/PrometheionTrendController.getDateFields';
import getMetricFields from '@salesforce/apex/PrometheionTrendController.getMetricFields';

export default class PrometheionTrendAnalyzer extends LightningElement {
    @track selectedObject = '';
    @track objectOptions = [
        { label: 'Account', value: 'Account' },
        { label: 'Opportunity', value: 'Opportunity' },
        { label: 'Case', value: 'Case' }
    ];
    @track dateFields = [];
    @track metricFields = [];
    @track dateField = '';
    @track metricField = '';
    @track granularity = 'month';
    @track monthsBack = 12;
    @track trendData = null;
    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';

    granularityOptions = [
        { label: 'Day', value: 'day' },
        { label: 'Week', value: 'week' },
        { label: 'Month', value: 'month' },
        { label: 'Quarter', value: 'quarter' },
        { label: 'Year', value: 'year' }
    ];

    @wire(getDateFields, { objectApiName: '$selectedObject' })
    wiredDateFields({ error, data }) {
        if (data) {
            this.dateFields = data.map(field => ({
                label: field.label,
                value: field.apiName
            }));
        } else if (error) {
            this.showError('Error loading date fields: ' + (error.body ? error.body.message : error.message));
        }
    }

    @wire(getMetricFields, { objectApiName: '$selectedObject' })
    wiredMetricFields({ error, data }) {
        if (data) {
            this.metricFields = data.map(field => ({
                label: field.label,
                value: field.apiName
            }));
        } else if (error) {
            this.showError('Error loading metric fields: ' + (error.body ? error.body.message : error.message));
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.dateField = '';
        this.metricField = '';
        this.trendData = null;
    }

    handleDateFieldChange(event) {
        this.dateField = event.detail.value;
    }

    handleMetricFieldChange(event) {
        this.metricField = event.detail.value;
    }

    handleGranularityChange(event) {
        this.granularity = event.detail.value;
    }

    handleMonthsBackChange(event) {
        this.monthsBack = parseInt(event.detail.value, 10) || 12;
    }

    handleAnalyze() {
        if (!this.canAnalyze) {
            return;
        }

        this.isLoading = true;
        this.hasError = false;

        getTimeSeries({
            objectApiName: this.selectedObject,
            dateField: this.dateField,
            metricField: this.metricField,
            granularity: this.granularity,
            monthsBack: this.monthsBack,
            additionalFilters: ''
        })
        .then(result => {
            this.trendData = result;
            this.isLoading = false;
            this.showSuccess('Trend analysis completed');
        })
        .catch(error => {
            this.hasError = true;
            this.errorMessage = 'Error analyzing trend: ' + (error.body ? error.body.message : error.message);
            this.isLoading = false;
            this.showError(this.errorMessage);
        });
    }

    get canAnalyze() {
        return this.selectedObject &&
               this.dateField &&
               this.metricField &&
               this.granularity &&
               !this.isLoading;
    }

    get isButtonDisabled() {
        return this.isLoading || !this.canAnalyze;
    }

    get hasResults() {
        return this.trendData && this.trendData.buckets && this.trendData.buckets.length > 0;
    }

    get trendBuckets() {
        return this.trendData ? this.trendData.buckets : [];
    }

    get trendTotal() {
        return this.trendData ? this.trendData.total.toFixed(2) : '0.00';
    }

    get trendAverage() {
        return this.trendData ? this.trendData.average.toFixed(2) : '0.00';
    }

    get trendDirection() {
        if (!this.trendData) return 'N/A';
        return this.trendData.trendDirection || 'unknown';
    }

    showError(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Error',
                message: message,
                variant: 'error'
            })
        );
    }

    showSuccess(message) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: 'Success',
                message: message,
                variant: 'success'
            })
        );
    }
}
