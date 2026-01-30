import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

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
    value: "SOX",
    label: "SOX",
    icon: "custom:custom57",
    description: "Sarbanes-Oxley Act",
  },
  {
    value: "ISO27001",
    label: "ISO 27001",
    icon: "custom:custom58",
    description: "Information Security Management",
  },
  {
    value: "CCPA",
    label: "CCPA",
    icon: "custom:custom59",
    description: "California Consumer Privacy Act",
  },
];

const SCORE_THRESHOLD_OPTIONS = [
  { label: "90% (Excellent)", value: "90" },
  { label: "80% (Good)", value: "80" },
  { label: "70% (Acceptable)", value: "70" },
  { label: "60% (Needs Improvement)", value: "60" },
  { label: "50% (Critical)", value: "50" },
];

const SEVERITY_OPTIONS = [
  { label: "Critical", value: "CRITICAL" },
  { label: "High", value: "HIGH" },
  { label: "Medium", value: "MEDIUM" },
  { label: "Low", value: "LOW" },
];

export default class ElaroSetupWizard extends NavigationMixin(LightningElement) {
  @track currentStep = "1";

  // Framework selection
  @track selectedFrameworks = [];

  // Notification settings
  @track enableEmailNotifications = true;
  @track notificationEmail = "";
  @track enableSlackNotifications = false;
  @track slackWebhookUrl = "";
  @track scoreThreshold = "70";
  @track selectedSeverities = ["CRITICAL", "HIGH"];

  // AI settings
  @track enableAI = true;
  @track requireApproval = true;
  @track autoRemediate = false;
  @track confidenceThreshold = 85;

  // Setup state
  @track isSaving = false;
  @track setupComplete = false;

  scoreThresholdOptions = SCORE_THRESHOLD_OPTIONS;
  severityOptions = SEVERITY_OPTIONS;

  // Step getters
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

  get showConfirmation() {
    return this.isStep5 && !this.isSaving && !this.setupComplete;
  }

  // Framework getters
  get frameworks() {
    return FRAMEWORKS.map((f) => ({
      ...f,
      cardClass:
        "framework-card slds-box slds-var-p-around_small" +
        (this.selectedFrameworks.includes(f.value) ? " selected" : ""),
      isSelected: this.selectedFrameworks.includes(f.value) ? "true" : "false",
      ariaLabel: `${f.label}: ${f.description}${this.selectedFrameworks.includes(f.value) ? " (selected)" : ""}`,
    }));
  }

  get selectedFrameworksCount() {
    return this.selectedFrameworks.length;
  }

  get selectedFrameworksList() {
    if (this.selectedFrameworks.length === 0) return "None selected";
    return this.selectedFrameworks
      .map((v) => {
        const fw = FRAMEWORKS.find((f) => f.value === v);
        return fw ? fw.label : v;
      })
      .join(", ");
  }

  // AI getters
  get confidenceThresholdDisplay() {
    return this.confidenceThreshold;
  }

  // Status getters for summary
  get emailNotificationStatus() {
    return this.enableEmailNotifications ? "Enabled" : "Disabled";
  }

  get slackNotificationStatus() {
    return this.enableSlackNotifications ? "Enabled" : "Disabled";
  }

  get aiStatus() {
    return this.enableAI ? "Enabled" : "Disabled";
  }

  // Navigation getters
  get isPreviousDisabled() {
    return this.currentStep === "1" || this.isSaving || this.setupComplete;
  }

  get isNextDisabled() {
    if (this.isSaving || this.setupComplete) return true;
    if (this.currentStep === "2" && this.selectedFrameworks.length === 0) return true;
    if (this.currentStep === "5") return true;
    return false;
  }

  get nextButtonLabel() {
    if (this.currentStep === "4") return "Review";
    return "Next";
  }

  // Framework selection handler
  handleFrameworkToggle(event) {
    const value = event.currentTarget.dataset.value;
    if (this.selectedFrameworks.includes(value)) {
      this.selectedFrameworks = this.selectedFrameworks.filter((f) => f !== value);
    } else {
      this.selectedFrameworks = [...this.selectedFrameworks, value];
    }
  }

  // Notification handlers
  handleEmailToggle(event) {
    this.enableEmailNotifications = event.target.checked;
  }

  handleEmailChange(event) {
    this.notificationEmail = event.detail.value;
  }

  handleSlackToggle(event) {
    this.enableSlackNotifications = event.target.checked;
  }

  handleSlackUrlChange(event) {
    this.slackWebhookUrl = event.detail.value;
  }

  handleScoreThresholdChange(event) {
    this.scoreThreshold = event.detail.value;
  }

  handleSeverityChange(event) {
    this.selectedSeverities = event.detail.value;
  }

  // AI handlers
  handleAIToggle(event) {
    this.enableAI = event.target.checked;
  }

  handleApprovalToggle(event) {
    this.requireApproval = event.target.checked;
  }

  handleRemediationToggle(event) {
    this.autoRemediate = event.target.checked;
  }

  handleConfidenceChange(event) {
    this.confidenceThreshold = event.detail.value;
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

  // Completion handlers
  async handleCompleteSetup() {
    this.isSaving = true;

    try {
      // Simulate saving configuration
      await this.delay(1500);

      // In a real implementation, you would call Apex to save settings
      // await saveElaroSettings({
      //   frameworks: this.selectedFrameworks,
      //   emailNotifications: this.enableEmailNotifications,
      //   notificationEmail: this.notificationEmail,
      //   slackNotifications: this.enableSlackNotifications,
      //   slackWebhookUrl: this.slackWebhookUrl,
      //   scoreThreshold: this.scoreThreshold,
      //   severities: this.selectedSeverities,
      //   enableAI: this.enableAI,
      //   requireApproval: this.requireApproval,
      //   autoRemediate: this.autoRemediate,
      //   confidenceThreshold: this.confidenceThreshold
      // });

      this.setupComplete = true;
      this.showToast("Success", "Elaro setup completed successfully!", "success");
    } catch (error) {
      this.showToast("Error", "Failed to save configuration: " + error.message, "error");
    } finally {
      this.isSaving = false;
    }
  }

  handleGoToDashboard() {
    this[NavigationMixin.Navigate]({
      type: "standard__navItemPage",
      attributes: {
        apiName: "Elaro_Dashboard",
      },
    });
  }

  handleRunInitialScan() {
    this.showToast(
      "Info",
      "Initial compliance scan started. You will be notified when complete.",
      "info"
    );
    // In a real implementation, you would trigger an async scan job
  }

  // Utility methods
  delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
