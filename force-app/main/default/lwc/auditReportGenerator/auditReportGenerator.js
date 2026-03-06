import { LightningElement } from "lwc";
import generateAuditReport from "@salesforce/apex/AuditReportController.generateAuditReport";
import exportReportAsPDF from "@salesforce/apex/AuditReportController.exportReportAsPDF";
import CardTitle from "@salesforce/label/c.AUDIT_CardTitle";
import SpinnerAlt from "@salesforce/label/c.AUDIT_SpinnerAlt";
import FrameworkLabel from "@salesforce/label/c.AUDIT_FrameworkLabel";
import StartDateLabel from "@salesforce/label/c.AUDIT_StartDateLabel";
import EndDateLabel from "@salesforce/label/c.AUDIT_EndDateLabel";
import GenerateReport from "@salesforce/label/c.AUDIT_GenerateReport";
import ExportPDF from "@salesforce/label/c.AUDIT_ExportPDF";
import ReportSummary from "@salesforce/label/c.AUDIT_ReportSummary";
import OverallScore from "@salesforce/label/c.AUDIT_OverallScore";
import StatusLabel from "@salesforce/label/c.AUDIT_StatusLabel";
import TotalGaps from "@salesforce/label/c.AUDIT_TotalGaps";
import OpenGaps from "@salesforce/label/c.AUDIT_OpenGaps";
import TotalEvidence from "@salesforce/label/c.AUDIT_TotalEvidence";
import ValidationError from "@salesforce/label/c.AUDIT_ValidationError";
import GenerateFirst from "@salesforce/label/c.AUDIT_GenerateFirst";

export default class AuditReportGenerator extends LightningElement {
  label = { CardTitle, SpinnerAlt, FrameworkLabel, StartDateLabel, EndDateLabel, GenerateReport, ExportPDF, ReportSummary, OverallScore, StatusLabel, TotalGaps, OpenGaps, TotalEvidence, ValidationError, GenerateFirst };
  selectedFramework = "SOX";
  startDate;
  endDate;
  reportData;
  loading = false;
  error;

  get isLoading() {
    return this.loading;
  }

  get hasError() {
    return !!this.error;
  }

  get errorMessage() {
    if (!this.error) return "";
    return this.error?.body?.message || this.error?.message || this.error;
  }

  get notLoading() {
    return !this.loading;
  }

  frameworks = [
    { label: "SOX", value: "SOX" },
    { label: "SOC 2", value: "SOC2" },
    { label: "HIPAA", value: "HIPAA" },
    { label: "GDPR", value: "GDPR" },
    { label: "CCPA", value: "CCPA" },
    { label: "GLBA", value: "GLBA" },
    { label: "NIST 800-53", value: "NIST" },
    { label: "ISO 27001", value: "ISO27001" },
    { label: "PCI-DSS", value: "PCI_DSS" },
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
      this.error = ValidationError;
      return;
    }

    this.loading = true;
    this.error = undefined;

    generateAuditReport({
      framework: this.selectedFramework,
      startDate: this.startDate,
      endDate: this.endDate,
    })
      .then((result) => {
        this.reportData = result;
        this.loading = false;
      })
      .catch((error) => {
        this.error = error?.body?.message || error?.message || "An error occurred";
        this.loading = false;
      });
  }

  handleExportPDF() {
    if (!this.reportData) {
      this.error = GenerateFirst;
      return;
    }

    this.loading = true;
    exportReportAsPDF({ report: this.reportData })
      .then((contentDocumentId) => {
        // Navigate to file
        window.open("/lightning/r/ContentDocument/" + contentDocumentId + "/view", "_blank");
        this.loading = false;
      })
      .catch((error) => {
        this.error = error?.body?.message || error?.message || "An error occurred";
        this.loading = false;
      });
  }
}
