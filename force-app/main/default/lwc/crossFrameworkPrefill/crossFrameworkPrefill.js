import { LightningElement, api } from "lwc";
import getPrefillData from "@salesforce/apex/AssessmentWizardController.getPrefillData";
import AW_PrefillAvailable from "@salesforce/label/c.AW_PrefillAvailable";
import AW_ApplyPrefill from "@salesforce/label/c.AW_ApplyPrefill";
import AW_SkipPrefill from "@salesforce/label/c.AW_SkipPrefill";

export default class CrossFrameworkPrefill extends LightningElement {
  @api wizardName;
  @api framework;

  label = {
    AW_PrefillAvailable,
    AW_ApplyPrefill,
    AW_SkipPrefill,
  };

  prefillData;
  hasPrefill = false;
  isLoading = true;
  dismissed = false;

  async connectedCallback() {
    if (!this.wizardName) {
      this.isLoading = false;
      return;
    }

    try {
      this.prefillData = await getPrefillData({
        currentWizardName: this.wizardName,
        framework: this.framework || null,
      });
      this.hasPrefill = this.prefillData && Object.keys(this.prefillData).length > 0;
    } catch (_err) {
      this.hasPrefill = false;
    } finally {
      this.isLoading = false;
    }
  }

  get showBanner() {
    return this.hasPrefill && !this.dismissed && !this.isLoading;
  }

  get prefillCount() {
    return this.prefillData ? Object.keys(this.prefillData).length : 0;
  }

  handleApply() {
    this.dispatchEvent(
      new CustomEvent("applyprefill", {
        detail: { prefillData: this.prefillData },
      })
    );
    this.dismissed = true;
  }

  handleSkip() {
    this.dismissed = true;
    this.dispatchEvent(new CustomEvent("skipprefill"));
  }
}
