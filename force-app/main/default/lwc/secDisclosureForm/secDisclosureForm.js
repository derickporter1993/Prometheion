import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import createAssessment from "@salesforce/apex/SECDisclosureController.createAssessment";

export default class SecDisclosureForm extends LightningElement {
  @track formData = {};

  handleInputChange(event) {
    const field = event.target.dataset.field;
    this.formData[field] = event.target.value;
  }

  async handleSave() {
    try {
      const assessmentId = await createAssessment({
        incidentDescription: this.formData.description,
        discoveryDate: this.formData.discoveryDate,
      });
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Success",
          message: "Materiality Assessment created",
          variant: "success",
        })
      );
      this.dispatchEvent(new CustomEvent("assessmentcreated", { detail: { assessmentId } }));
    } catch (error) {
      this.dispatchEvent(
        new ShowToastEvent({
          title: "Error",
          message: error.body?.message || "Error creating assessment",
          variant: "error",
        })
      );
    }
  }
}
