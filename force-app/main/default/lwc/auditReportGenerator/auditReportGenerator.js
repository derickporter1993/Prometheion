import { LightningElement } from 'lwc';
import generateAuditReport from '@salesforce/apex/AuditReportController.generateAuditReport';
import exportReportAsPDF from '@salesforce/apex/AuditReportController.exportReportAsPDF';

export default class AuditReportGenerator extends LightningElement {
    selectedFramework = 'SOX';
    startDate;
    endDate;
    reportData;
    loading = false;
    error;

    frameworks = [
        { label: 'SOX', value: 'SOX' },
        { label: 'SOC 2', value: 'SOC2' },
        { label: 'HIPAA', value: 'HIPAA' },
        { label: 'GDPR', value: 'GDPR' },
        { label: 'CCPA', value: 'CCPA' },
        { label: 'GLBA', value: 'GLBA' },
        { label: 'NIST 800-53', value: 'NIST' },
        { label: 'ISO 27001', value: 'ISO27001' },
        { label: 'PCI-DSS', value: 'PCI_DSS' }
    ];

    handleFrameworkChange(event) {
        this.selectedFramework = event.detail.value;
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
    }

    handleEndDateChange(event) {
        this.endDate = event.detail.value;
    }

    handleGenerateReport() {
        if (!this.selectedFramework || !this.startDate || !this.endDate) {
            this.error = 'Please select framework and date range';
            return;
        }

        this.loading = true;
        this.error = undefined;

        generateAuditReport({
            framework: this.selectedFramework,
            startDate: this.startDate,
            endDate: this.endDate
        })
        .then(result => {
            this.reportData = result;
            this.loading = false;
        })
        .catch(error => {
            this.error = error.body.message;
            this.loading = false;
        });
    }

    handleExportPDF() {
        if (!this.reportData) {
            this.error = 'Please generate a report first';
            return;
        }

        this.loading = true;
        exportReportAsPDF({ report: this.reportData })
        .then(contentDocumentId => {
            // Navigate to file
            window.open('/lightning/r/ContentDocument/' + contentDocumentId + '/view', '_blank');
            this.loading = false;
        })
        .catch(error => {
            this.error = error.body.message;
            this.loading = false;
        });
    }
}
