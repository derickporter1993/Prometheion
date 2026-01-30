import { LightningElement, track } from "lwc";
import generateAuditPackage from "@salesforce/apex/ElaroAuditPackageGenerator.generateAuditPackage";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

export default class ElaroAuditPackageBuilder extends NavigationMixin(LightningElement) {
  @track framework = "SOC2";
  @track packageName = "";
  @track startDate;
  @track endDate;
  @track isLoading = false;

  frameworks = [
    { label: "SOC 2", value: "SOC2" },
    { label: "HIPAA", value: "HIPAA" },
    { label: "SOX", value: "SOX" },
    { label: "GDPR", value: "GDPR" },
    { label: "CCPA", value: "CCPA" },
    { label: "GLBA", value: "GLBA" },
    { label: "NIST 800-53", value: "NIST" },
    { label: "ISO 27001", value: "ISO27001" },
    { label: "PCI-DSS", value: "PCI_DSS" },
  ];

  handleFrameworkChange(event) {
    this.framework = event.detail.value;
  }

  handlePackageNameChange(event) {
    this.packageName = event.target.value;
  }

  handleStartDateChange(event) {
    this.startDate = event.detail.value;
  }

  handleEndDateChange(event) {
    this.endDate = event.detail.value;
  }

  async handleGenerate() {
    if (!this.packageName || !this.startDate || !this.endDate) {
      this.showToast("Error", "Please fill in all required fields", "error");
      return;
    }

    this.isLoading = true;
    try {
      const packageId = await generateAuditPackage({
        framework: this.framework,
        packageName: this.packageName,
        startDate: this.startDate,
        endDate: this.endDate,
      });
      this.showToast("Success", "Audit package generated successfully", "success");
      // Navigate to package record
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: packageId,
          actionName: "view",
        },
      });
    } catch (error) {
      this.showToast("Error", error.body?.message || "Failed to generate audit package", "error");
    } finally {
      this.isLoading = false;
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(
      new ShowToastEvent({
        title,
        message,
        variant,
      })
    );
  }
}
