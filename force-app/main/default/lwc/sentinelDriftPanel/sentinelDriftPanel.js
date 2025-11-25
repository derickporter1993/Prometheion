import { LightningElement, wire } from 'lwc';
import getActiveAlerts from '@salesforce/apex/SentinelAlertService.getActiveAlerts';
import acknowledgeAlert from '@salesforce/apex/SentinelAlertService.acknowledgeAlert';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

const COLUMNS = [
    {
        label: 'Title',
        fieldName: 'title',
        type: 'text',
        wrapText: true
    },
    {
        label: 'Type',
        fieldName: 'alertType',
        type: 'text'
    },
    {
        label: 'Severity',
        fieldName: 'severity',
        type: 'text',
        cellAttributes: {
            class: { fieldName: 'severityClass' }
        }
    },
    {
        label: 'Created',
        fieldName: 'createdDate',
        type: 'date',
        typeAttributes: {
            year: 'numeric',
            month: 'short',
            day: '2-digit',
            hour: '2-digit',
            minute: '2-digit'
        }
    },
    {
        type: 'action',
        typeAttributes: {
            rowActions: [
                { label: 'Acknowledge', name: 'acknowledge' },
                { label: 'View Details', name: 'view' }
            ]
        }
    }
];

export default class SentinelDriftPanel extends LightningElement {
    alerts = [];
    columns = COLUMNS;
    wiredAlertsResult;

    @wire(getActiveAlerts)
    wiredAlerts(result) {
        this.wiredAlertsResult = result;
        if (result.data) {
            this.alerts = result.data.map(alert => ({
                ...alert,
                severityClass: this.getSeverityClass(alert.severity)
            }));
        } else if (result.error) {
            this.showToast('Error', 'Failed to load alerts', 'error');
        }
    }

    get hasAlerts() {
        return this.alerts && this.alerts.length > 0;
    }

    get alertCountLabel() {
        const count = this.alerts ? this.alerts.length : 0;
        return `${count} ${count === 1 ? 'Alert' : 'Alerts'}`;
    }

    getSeverityClass(severity) {
        switch (severity) {
            case 'CRITICAL':
                return 'slds-text-color_error';
            case 'HIGH':
                return 'slds-text-color_warning';
            case 'MEDIUM':
                return 'slds-text-color_default';
            default:
                return '';
        }
    }

    handleRowAction(event) {
        const actionName = event.detail.action.name;
        const row = event.detail.row;

        switch (actionName) {
            case 'acknowledge':
                this.handleAcknowledge(row);
                break;
            case 'view':
                this.handleView(row);
                break;
            default:
                break;
        }
    }

    handleAcknowledge(row) {
        acknowledgeAlert({ alertId: row.id })
            .then(() => {
                this.showToast('Success', 'Alert acknowledged', 'success');
                return refreshApex(this.wiredAlertsResult);
            })
            .catch(error => {
                this.showToast('Error', error.body.message, 'error');
            });
    }

    handleView(row) {
        this.showToast('Info', `Viewing alert: ${row.title}`, 'info');
        // In production: Navigate to alert record page
    }

    showToast(title, message, variant) {
        const event = new ShowToastEvent({ title, message, variant });
        this.dispatchEvent(event);
    }
}
