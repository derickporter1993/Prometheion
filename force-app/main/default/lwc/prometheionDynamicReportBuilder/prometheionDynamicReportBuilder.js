import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getAvailableObjects from '@salesforce/apex/PrometheionDynamicReportController.getAvailableObjects';
import getFieldMetadata from '@salesforce/apex/PrometheionDynamicReportController.getFieldMetadata';
import executeReport from '@salesforce/apex/PrometheionDynamicReportController.executeReport';

export default class PrometheionDynamicReportBuilder extends LightningElement {
    @track selectedObject = '';
    @track objectOptions = [];
    @track availableFields = [];
    @track selectedFields = [];
    @track fieldsLoaded = false;
    @track filters = [];
    @track filterableFields = [];
    @track sortableFields = [];
    @track sortBy = '';
    @track sortDirection = 'ASC';
    @track maxRows = 1000;
    @track reportData = [];
    @track columns = [];
    @track recordCount = 0;
    @track isLoading = false;
    @track hasError = false;
    @track errorMessage = '';

    operatorOptions = [
        { label: 'Equals', value: '=' },
        { label: 'Not Equals', value: '!=' },
        { label: 'Greater Than', value: '>' },
        { label: 'Less Than', value: '<' },
        { label: 'Greater or Equal', value: '>=' },
        { label: 'Less or Equal', value: '<=' },
        { label: 'Contains', value: 'LIKE' },
        { label: 'In', value: 'IN' },
        { label: 'Not In', value: 'NOT IN' }
    ];

    sortDirectionOptions = [
        { label: 'Ascending', value: 'ASC' },
        { label: 'Descending', value: 'DESC' }
    ];

    @wire(getAvailableObjects)
    wiredObjects({ error, data }) {
        if (data) {
            this.objectOptions = data.map(obj => ({
                label: obj.label,
                value: obj.value
            }));
        } else if (error) {
            this.showError('Error loading objects: ' + error.body.message);
        }
    }

    handleObjectChange(event) {
        this.selectedObject = event.detail.value;
        this.selectedFields = [];
        this.filters = [];
        this.sortBy = '';
        this.reportData = [];
        this.columns = [];
        this.recordCount = 0;
        this.hasError = false;

        if (this.selectedObject) {
            this.loadFields();
        } else {
            this.fieldsLoaded = false;
        }
    }

    loadFields() {
        this.isLoading = true;
        this.fieldsLoaded = false;

        getFieldMetadata({ objectApiName: this.selectedObject })
            .then(result => {
                this.availableFields = result.map(field => ({
                    label: field.label,
                    value: field.apiName
                }));

                this.filterableFields = result
                    .filter(field => field.isFilterable)
                    .map(field => ({
                        label: field.label,
                        value: field.apiName
                    }));

                this.sortableFields = result
                    .filter(field => field.isSortable)
                    .map(field => ({
                        label: field.label,
                        value: field.apiName
                    }));

                this.fieldsLoaded = true;
                this.isLoading = false;
            })
            .catch(error => {
                this.showError('Error loading fields: ' + error.body.message);
                this.isLoading = false;
            });
    }

    handleFieldChange(event) {
        this.selectedFields = event.detail.value;
    }

    handleAddFilter() {
        // Create new array reference to trigger reactivity
        this.filters = [
            ...this.filters,
            {
                id: Date.now() + Math.random(),
                field: '',
                operator: '=',
                value: ''
            }
        ];
    }

    handleRemoveFilter(event) {
        const filterId = event.currentTarget.dataset.filterId;
        this.filters = this.filters.filter(f => f.id !== filterId);
    }

    handleFilterFieldChange(event) {
        const filterId = event.currentTarget.dataset.filterId;
        // Create new array with updated filter to trigger reactivity
        this.filters = this.filters.map(f => 
            f.id === filterId 
                ? { ...f, field: event.detail.value }
                : f
        );
    }

    handleFilterOperatorChange(event) {
        const filterId = event.currentTarget.dataset.filterId;
        // Create new array with updated filter to trigger reactivity
        this.filters = this.filters.map(f => 
            f.id === filterId 
                ? { ...f, operator: event.detail.value }
                : f
        );
    }

    handleFilterValueChange(event) {
        const filterId = event.currentTarget.dataset.filterId;
        // Create new array with updated filter to trigger reactivity
        this.filters = this.filters.map(f => 
            f.id === filterId 
                ? { ...f, value: event.detail.value }
                : f
        );
    }

    handleSortByChange(event) {
        this.sortBy = event.detail.value;
    }

    handleSortDirectionChange(event) {
        this.sortDirection = event.detail.value;
    }

    handleMaxRowsChange(event) {
        this.maxRows = parseInt(event.detail.value, 10) || 1000;
    }

    handleRunReport() {
        if (!this.canRunReport) {
            return;
        }

        this.isLoading = true;
        this.hasError = false;

        const config = {
            objectApiName: this.selectedObject,
            fields: this.selectedFields,
            filters: this.filters.map(f => ({
                field: f.field,
                operator: f.operator,
                value: f.value
            })),
            maxRows: this.maxRows,
            orderBy: this.sortBy,
            orderDirection: this.sortDirection
        };

        executeReport({ reportConfigJson: JSON.stringify(config) })
            .then(result => {
                this.reportData = result.data;
                this.recordCount = result.recordCount;

                // Build columns from selected fields
                this.columns = this.selectedFields.map(field => {
                    const fieldMeta = this.availableFields.find(f => f.value === field);
                    return {
                        label: fieldMeta ? fieldMeta.label : field,
                        fieldName: field,
                        type: this.getFieldType(field)
                    };
                });

                this.isLoading = false;
                this.showSuccess('Report executed successfully');
            })
            .catch(error => {
                this.showError('Error executing report: ' + (error.body ? error.body.message : error.message));
                this.isLoading = false;
            });
    }

    handleClear() {
        this.selectedObject = '';
        this.selectedFields = [];
        this.filters = [];
        this.sortBy = '';
        this.sortDirection = 'ASC';
        this.maxRows = 1000;
        this.reportData = [];
        this.columns = [];
        this.recordCount = 0;
        this.fieldsLoaded = false;
        this.hasError = false;
    }

    get canRunReport() {
        return this.selectedObject &&
               this.selectedFields &&
               this.selectedFields.length > 0 &&
               !this.isLoading;
    }

    get isRunDisabled() {
        return this.isLoading || !this.canRunReport;
    }

    get showFilters() {
        return this.fieldsLoaded && this.filterableFields.length > 0;
    }

    get showSortOptions() {
        return this.fieldsLoaded && this.sortableFields.length > 0;
    }

    get hasResults() {
        return this.reportData && this.reportData.length > 0;
    }

    getFieldType(fieldName) {
        // Simple type detection - can be enhanced
        if (fieldName.toLowerCase().includes('date')) {
            return 'date';
        }
        if (fieldName.toLowerCase().includes('amount') ||
            fieldName.toLowerCase().includes('price') ||
            fieldName.toLowerCase().includes('revenue')) {
            return 'currency';
        }
        return 'text';
    }

    showError(message) {
        this.hasError = true;
        this.errorMessage = message;
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
