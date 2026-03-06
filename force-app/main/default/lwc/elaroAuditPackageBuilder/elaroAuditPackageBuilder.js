import { LightningElement } from "lwc";
import generateAuditPackage from "@salesforce/apex/ElaroAuditPackageGenerator.generateAuditPackage";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";

// Custom Labels
import CARD_TITLE from "@salesforce/label/c.AUDITPKG_CardTitle";
import PACKAGE_NAME from "@salesforce/label/c.AUDITPKG_PackageName";
import FRAMEWORK from "@salesforce/label/c.AUDITPKG_Framework";
import AUDIT_PERIOD_START from "@salesforce/label/c.AUDITPKG_PeriodStart";
import AUDIT_PERIOD_END from "@salesforce/label/c.AUDITPKG_PeriodEnd";
import GENERATE_PACKAGE from "@salesforce/label/c.AUDITPKG_Generate";
import ERROR_TITLE from "@salesforce/label/c.AUDITPKG_ErrorTitle";
import SUCCESS_TITLE from "@salesforce/label/c.AUDITPKG_SuccessTitle";
import FILL_REQUIRED_FIELDS from "@salesforce/label/c.AUDITPKG_FillRequiredFields";
import PACKAGE_GENERATED from "@salesforce/label/c.AUDITPKG_PackageGenerated";
import GENERATE_FAILED from "@salesforce/label/c.AUDITPKG_GenerateFailed";

export default class ElaroAuditPackageBuilder extends NavigationMixin(LightningElement) {
  label = {
    cardTitle: CARD_TITLE,
    packageName: PACKAGE_NAME,
    framework: FRAMEWORK,
    auditPeriodStart: AUDIT_PERIOD_START,
    auditPeriodEnd: AUDIT_PERIOD_END,
    generatePackage: GENERATE_PACKAGE,
  };

  framework = "SOC2";
  packageName = "";
  startDate;
  endDate;
  isLoading = false;

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
      this.showToast(ERROR_TITLE, FILL_REQUIRED_FIELDS, "error");
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
      this.showToast(SUCCESS_TITLE, PACKAGE_GENERATED, "success");
      // Navigate to package record
      this[NavigationMixin.Navigate]({
        type: "standard__recordPage",
        attributes: {
          recordId: packageId,
          actionName: "view",
        },
      });
    } catch (error) {
      this.showToast(ERROR_TITLE, error.body?.message || GENERATE_FAILED, "error");
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
