import { LightningElement } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import CardTitle from "@salesforce/label/c.WIZARD_CardTitle";
import StepFramework from "@salesforce/label/c.WIZARD_StepFramework";
import StepDateRange from "@salesforce/label/c.WIZARD_StepDateRange";
import StepControls from "@salesforce/label/c.WIZARD_StepControls";
import StepPreview from "@salesforce/label/c.WIZARD_StepPreview";
import StepGenerate from "@salesforce/label/c.WIZARD_StepGenerate";
import SelectFrameworkHeading from "@salesforce/label/c.WIZARD_SelectFrameworkHeading";
import SelectFrameworkDesc from "@salesforce/label/c.WIZARD_SelectFrameworkDesc";
import SelectAuditPeriod from "@salesforce/label/c.WIZARD_SelectAuditPeriod";
import AuditPeriodDesc from "@salesforce/label/c.WIZARD_AuditPeriodDesc";
import QuickSelect from "@salesforce/label/c.WIZARD_QuickSelect";
import LastMonth from "@salesforce/label/c.WIZARD_LastMonth";
import LastQuarter from "@salesforce/label/c.WIZARD_LastQuarter";
import LastYear from "@salesforce/label/c.WIZARD_LastYear";
import SelectControlsHeading from "@salesforce/label/c.WIZARD_SelectControlsHeading";
import SelectControlsDesc from "@salesforce/label/c.WIZARD_SelectControlsDesc";
import SelectAll from "@salesforce/label/c.WIZARD_SelectAll";
import ClearAll from "@salesforce/label/c.WIZARD_ClearAll";
import SelectFailedOnly from "@salesforce/label/c.WIZARD_SelectFailedOnly";
import PreviewHeading from "@salesforce/label/c.WIZARD_PreviewHeading";
import PreviewDesc from "@salesforce/label/c.WIZARD_PreviewDesc";
import OutputOptions from "@salesforce/label/c.WIZARD_OutputOptions";
import IncludeInPackage from "@salesforce/label/c.WIZARD_IncludeInPackage";
import GeneratingHeading from "@salesforce/label/c.WIZARD_GeneratingHeading";
import PackageGenerated from "@salesforce/label/c.WIZARD_PackageGenerated";
import PackageCreatedMsg from "@salesforce/label/c.WIZARD_PackageCreatedMsg";
import DownloadPDF from "@salesforce/label/c.WIZARD_DownloadPDF";
import ViewPackage from "@salesforce/label/c.WIZARD_ViewPackage";
import CreateNewPackage from "@salesforce/label/c.WIZARD_CreateNewPackage";
import ReadyToGenerate from "@salesforce/label/c.WIZARD_ReadyToGenerate";
import ReadyToGenerateDesc from "@salesforce/label/c.WIZARD_ReadyToGenerateDesc";
import GenerateAuditPackage from "@salesforce/label/c.WIZARD_GenerateAuditPackage";
import PreviousBtn from "@salesforce/label/c.WIZARD_Previous";
import StartDateLabel from "@salesforce/label/c.WIZARD_StartDate";
import EndDateLabel from "@salesforce/label/c.WIZARD_EndDate";
import EnterPackageName from "@salesforce/label/c.WIZARD_EnterPackageName";
// PDF export will be implemented in future release
// import generateAuditPackagePDF from '@salesforce/apex/ElaroPDFExporter.generateAuditPackagePDF';

const FRAMEWORKS = [
  {
    value: "HIPAA",
    label: "HIPAA",
    icon: "custom:custom50",
    description: "Health Insurance Portability and Accountability Act",
  },
  {
    value: "SOC2",
    label: "SOC 2",
    icon: "custom:custom51",
    description: "System and Organization Controls 2",
  },
  {
    value: "GDPR",
    label: "GDPR",
    icon: "custom:custom52",
    description: "General Data Protection Regulation",
  },
  {
    value: "FINRA",
    label: "FINRA",
    icon: "custom:custom53",
    description: "Financial Industry Regulatory Authority",
  },
  {
    value: "NIST",
    label: "NIST CSF",
    icon: "custom:custom54",
    description: "NIST Cybersecurity Framework",
  },
  {
    value: "FedRAMP",
    label: "FedRAMP",
    icon: "custom:custom55",
    description: "Federal Risk and Authorization Management Program",
  },
  {
    value: "PCI_DSS",
    label: "PCI DSS",
    icon: "custom:custom56",
    description: "Payment Card Industry Data Security Standard",
  },
  {
    value: "ISO27001",
    label: "ISO 27001",
    icon: "custom:custom57",
    description: "Information Security Management",
  },
];

const OUTPUT_OPTIONS = [
  { label: "PDF Report", value: "pdf" },
  { label: "Evidence CSV", value: "csv" },
  { label: "JSON Export", value: "json" },
  { label: "Executive Summary", value: "executive" },
];

export default class ElaroAuditWizard extends NavigationMixin(LightningElement) {
  label = { CardTitle, StepFramework, StepDateRange, StepControls, StepPreview, StepGenerate, SelectFrameworkHeading, SelectFrameworkDesc, SelectAuditPeriod, AuditPeriodDesc, QuickSelect, LastMonth, LastQuarter, LastYear, SelectControlsHeading, SelectControlsDesc, SelectAll, ClearAll, SelectFailedOnly, PreviewHeading, PreviewDesc, OutputOptions, IncludeInPackage, GeneratingHeading, PackageGenerated, PackageCreatedMsg, DownloadPDF, ViewPackage, CreateNewPackage, ReadyToGenerate, ReadyToGenerateDesc, GenerateAuditPackage, PreviousBtn, StartDateLabel, EndDateLabel, EnterPackageName };
  currentStep = "1";
  selectedFramework = "";
  auditStartDate = "";
  auditEndDate = "";
  controls = [];
  packageName = "";
  selectedOutputOptions = ["pdf", "executive"];

  isGenerating = false;
  generationComplete = false;
  generationProgress = 0;
  generationStatus = "";
  generatedPackageId = "";

  _progressTimer = null;
  outputOptions = OUTPUT_OPTIONS;

  get frameworks() {
    return FRAMEWORKS.map((f) => ({
      ...f,
      cardClass:
        "framework-card slds-box slds-var-p-around_medium slds-text-align_center" +
        (f.value === this.selectedFramework ? " selected" : ""),
      isSelected: f.value === this.selectedFramework ? "true" : "false",
      ariaLabel: `${f.label}: ${f.description}${f.value === this.selectedFramework ? " (selected)" : ""}`,
    }));
  }

  get progressAriaLabel() {
    return `Generation progress: ${this.generationProgress}%`;
  }

  get isStep1() {
    return this.currentStep === "1";
  }
  get isStep2() {
    return this.currentStep === "2";
  }
  get isStep3() {
    return this.currentStep === "3";
  }
  get isStep4() {
    return this.currentStep === "4";
  }
  get isStep5() {
    return this.currentStep === "5";
  }

  get isPreviousDisabled() {
    return this.currentStep === "1" || this.isGenerating;
  }

  get isNextDisabled() {
    if (this.isGenerating) return true;
    if (this.currentStep === "1" && !this.selectedFramework) return true;
    if (this.currentStep === "2" && (!this.auditStartDate || !this.auditEndDate)) return true;
    if (this.currentStep === "3" && this.selectedControlsCount === 0) return true;
    if (this.currentStep === "5") return true;
    return false;
  }

  get nextButtonLabel() {
    return this.currentStep === "4" ? "Finish" : "Next";
  }

  get selectedFrameworkLabel() {
    const framework = FRAMEWORKS.find((f) => f.value === this.selectedFramework);
    return framework ? framework.label : "";
  }

  get selectedControlsCount() {
    return this.controls.filter((c) => c.selected).length;
  }

  get totalControlsCount() {
    return this.controls.length;
  }

  connectedCallback() {
    // Set default dates (last quarter)
    const today = new Date();
    const quarterStart = new Date(today.getFullYear(), Math.floor(today.getMonth() / 3) * 3 - 3, 1);
    const quarterEnd = new Date(quarterStart.getFullYear(), quarterStart.getMonth() + 3, 0);

    this.auditStartDate = quarterStart.toISOString().split("T")[0];
    this.auditEndDate = quarterEnd.toISOString().split("T")[0];
  }

  disconnectedCallback() {
    if (this._progressTimer) {
      clearTimeout(this._progressTimer);
    }
  }

  // Framework selection
  handleFrameworkSelect(event) {
    this.selectedFramework = event.currentTarget.dataset.value;
    this.loadControlsForFramework();
  }

  handleFrameworkKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.handleFrameworkSelect(event);
    }
  }

  loadControlsForFramework() {
    // Load controls based on selected framework
    const controlsByFramework = {
      HIPAA: [
        {
          id: "1",
          code: "164.308",
          name: "Administrative Safeguards",
          status: "Compliant",
          selected: true,
        },
        {
          id: "2",
          code: "164.310",
          name: "Physical Safeguards",
          status: "Compliant",
          selected: true,
        },
        {
          id: "3",
          code: "164.312",
          name: "Technical Safeguards",
          status: "At Risk",
          selected: true,
        },
        {
          id: "4",
          code: "164.314",
          name: "Organizational Requirements",
          status: "Compliant",
          selected: true,
        },
        {
          id: "5",
          code: "164.316",
          name: "Documentation Requirements",
          status: "Compliant",
          selected: true,
        },
      ],
      SOC2: [
        {
          id: "1",
          code: "CC6.1",
          name: "Logical Access Controls",
          status: "Compliant",
          selected: true,
        },
        {
          id: "2",
          code: "CC6.6",
          name: "System Boundary Protection",
          status: "Compliant",
          selected: true,
        },
        { id: "3", code: "CC7.1", name: "Threat Detection", status: "At Risk", selected: true },
        {
          id: "4",
          code: "CC7.2",
          name: "Security Monitoring",
          status: "Compliant",
          selected: true,
        },
        { id: "5", code: "CC8.1", name: "Change Management", status: "Compliant", selected: true },
        { id: "6", code: "CC9.1", name: "Risk Mitigation", status: "Compliant", selected: true },
      ],
      GDPR: [
        {
          id: "1",
          code: "Art.5",
          name: "Data Processing Principles",
          status: "Compliant",
          selected: true,
        },
        { id: "2", code: "Art.6", name: "Lawful Processing", status: "Compliant", selected: true },
        { id: "3", code: "Art.17", name: "Right to Erasure", status: "At Risk", selected: true },
        {
          id: "4",
          code: "Art.25",
          name: "Data Protection by Design",
          status: "Compliant",
          selected: true,
        },
        {
          id: "5",
          code: "Art.33",
          name: "Breach Notification",
          status: "Compliant",
          selected: true,
        },
      ],
      FINRA: [
        { id: "1", code: "3110", name: "Supervision", status: "Compliant", selected: true },
        { id: "2", code: "4511", name: "Books and Records", status: "Compliant", selected: true },
        { id: "3", code: "4370", name: "Business Continuity", status: "Compliant", selected: true },
      ],
    };

    this.controls = (controlsByFramework[this.selectedFramework] || []).map((c) => ({
      ...c,
      statusClass: c.status === "Compliant" ? "slds-text-color_success" : "slds-text-color_error",
      statusAriaLabel: `Status: ${c.status}`,
      codeAriaLabel: `Control code: ${c.code}`,
    }));

    this.packageName =
      this.selectedFrameworkLabel + " Audit Package - " + new Date().toISOString().split("T")[0];
  }

  // Date range handlers
  handleStartDateChange(event) {
    this.auditStartDate = event.detail.value;
  }

  handleEndDateChange(event) {
    this.auditEndDate = event.detail.value;
  }

  handleLastMonth() {
    const today = new Date();
    const lastMonth = new Date(today.getFullYear(), today.getMonth() - 1, 1);
    const lastMonthEnd = new Date(today.getFullYear(), today.getMonth(), 0);
    this.auditStartDate = lastMonth.toISOString().split("T")[0];
    this.auditEndDate = lastMonthEnd.toISOString().split("T")[0];
  }

  handleLastQuarter() {
    const today = new Date();
    const quarterStart = new Date(today.getFullYear(), Math.floor(today.getMonth() / 3) * 3 - 3, 1);
    const quarterEnd = new Date(quarterStart.getFullYear(), quarterStart.getMonth() + 3, 0);
    this.auditStartDate = quarterStart.toISOString().split("T")[0];
    this.auditEndDate = quarterEnd.toISOString().split("T")[0];
  }

  handleLastYear() {
    const today = new Date();
    this.auditStartDate = today.getFullYear() - 1 + "-01-01";
    this.auditEndDate = today.getFullYear() - 1 + "-12-31";
  }

  handleYTD() {
    const today = new Date();
    this.auditStartDate = today.getFullYear() + "-01-01";
    this.auditEndDate = today.toISOString().split("T")[0];
  }

  // Control selection handlers
  handleControlToggle(event) {
    const controlId = event.target.dataset.id;
    this.controls = this.controls.map((c) =>
      c.id === controlId ? { ...c, selected: event.target.checked } : c
    );
  }

  handleSelectAll() {
    this.controls = this.controls.map((c) => ({ ...c, selected: true }));
  }

  handleClearAll() {
    this.controls = this.controls.map((c) => ({ ...c, selected: false }));
  }

  handleSelectFailed() {
    this.controls = this.controls.map((c) => ({
      ...c,
      selected: c.status !== "Compliant",
    }));
  }

  // Preview handlers
  handlePackageNameChange(event) {
    this.packageName = event.detail.value;
  }

  handleOutputOptionsChange(event) {
    this.selectedOutputOptions = event.detail.value;
  }

  // Navigation handlers
  handlePrevious() {
    const step = parseInt(this.currentStep, 10);
    if (step > 1) {
      this.currentStep = String(step - 1);
    }
  }

  handleNext() {
    const step = parseInt(this.currentStep, 10);
    if (step < 5) {
      this.currentStep = String(step + 1);
    }
  }

  // Generation handlers
  async handleGenerate() {
    this.isGenerating = true;
    this.generationProgress = 0;
    this.generationStatus = "Initializing...";

    try {
      // Simulate generation progress
      await this.simulateProgress("Collecting evidence...", 20);
      await this.simulateProgress("Processing controls...", 40);
      await this.simulateProgress("Generating reports...", 60);
      await this.simulateProgress("Creating PDF...", 80);
      await this.simulateProgress("Finalizing package...", 100);

      this.generationComplete = true;
      this.generatedPackageId = "a0A" + Math.random().toString(36).substr(2, 15);

      this.showToast("Success", "Audit package generated successfully!", "success");
    } catch (error) {
      this.showToast("Error", "Failed to generate package: " + error.message, "error");
    } finally {
      this.isGenerating = false;
    }
  }

  simulateProgress(status, progress) {
    return new Promise((resolve) => {
      this._progressTimer = setTimeout(() => {
        this.generationStatus = status;
        this.generationProgress = progress;
        resolve();
      }, 500);
    });
  }

  handleDownloadPDF() {
    this.showToast("Info", "PDF download initiated", "info");
  }

  handleViewPackage() {
    if (this.generatedPackageId) {
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: this.generatedPackageId,
          objectApiName: "Elaro_Audit_Package__c",
          actionName: "view",
        },
      });
    }
  }

  handleReset() {
    this.currentStep = "1";
    this.selectedFramework = "";
    this.controls = [];
    this.generationComplete = false;
    this.generatedPackageId = "";
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
