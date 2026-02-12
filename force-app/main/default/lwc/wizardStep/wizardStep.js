import { LightningElement, api } from "lwc";
import AW_AutoScanRunning from "@salesforce/label/c.AW_AutoScanRunning";
import AW_AutoScanComplete from "@salesforce/label/c.AW_AutoScanComplete";
import AW_AttestationPrompt from "@salesforce/label/c.AW_AttestationPrompt";
import AW_EvidenceUploadPrompt from "@salesforce/label/c.AW_EvidenceUploadPrompt";
import AW_ApprovalPrompt from "@salesforce/label/c.AW_ApprovalPrompt";
import AW_ReviewPrompt from "@salesforce/label/c.AW_ReviewPrompt";
import AW_NextStep from "@salesforce/label/c.AW_NextStep";
import AW_SaveProgress from "@salesforce/label/c.AW_SaveProgress";

export default class WizardStep extends LightningElement {
  @api step;
  @api sessionId;

  label = {
    AW_AutoScanRunning,
    AW_AutoScanComplete,
    AW_AttestationPrompt,
    AW_EvidenceUploadPrompt,
    AW_ApprovalPrompt,
    AW_ReviewPrompt,
    AW_NextStep,
    AW_SaveProgress,
  };

  responseValue = "";
  attestationChecked = false;
  isScanning = false;
  scanComplete = false;

  get stepType() {
    return this.step?.stepType || "";
  }

  get isAutoScan() {
    return this.stepType === "Auto_Scan";
  }

  get isManualAttestation() {
    return this.stepType === "Manual_Attestation";
  }

  get isEvidenceUpload() {
    return this.stepType === "Evidence_Upload";
  }

  get isApproval() {
    return this.stepType === "Approval";
  }

  get isReview() {
    return this.stepType === "Review";
  }

  get stepPrompt() {
    if (this.isAutoScan) return this.label.AW_AutoScanRunning;
    if (this.isManualAttestation) return this.label.AW_AttestationPrompt;
    if (this.isEvidenceUpload) return this.label.AW_EvidenceUploadPrompt;
    if (this.isApproval) return this.label.AW_ApprovalPrompt;
    if (this.isReview) return this.label.AW_ReviewPrompt;
    return "";
  }

  get helpText() {
    return this.step?.helpText || "";
  }

  get controlReference() {
    return this.step?.controlReference || "";
  }

  get isCompleted() {
    return this.step?.status === "Completed";
  }

  get submitLabel() {
    return this.isAutoScan ? this.label.AW_NextStep : this.label.AW_SaveProgress;
  }

  get canSubmit() {
    if (this.isCompleted) return false;
    if (this.isAutoScan) return this.scanComplete;
    if (this.isManualAttestation) return this.attestationChecked;
    if (this.isEvidenceUpload) return !!this.responseValue;
    return true;
  }

  connectedCallback() {
    if (this.isAutoScan && !this.isCompleted) {
      this.runAutoScan();
    }
  }

  async runAutoScan() {
    this.isScanning = true;
    // Simulate scan — in production, call a scanner via Apex
    await new Promise((resolve) => {
      setTimeout(resolve, 2000);
    });
    this.isScanning = false;
    this.scanComplete = true;
    this.responseValue = JSON.stringify({
      scanResult: "passed",
      timestamp: new Date().toISOString(),
    });
  }

  handleAttestationChange(event) {
    this.attestationChecked = event.target.checked;
    this.responseValue = this.attestationChecked ? "attested" : "";
  }

  handleTextChange(event) {
    this.responseValue = event.target.value;
  }

  handleSubmit() {
    if (!this.canSubmit) return;

    this.dispatchEvent(
      new CustomEvent("stepcomplete", {
        detail: {
          stepId: this.step?.stepId,
          responseData: this.responseValue,
        },
      })
    );
  }
}
