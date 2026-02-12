import { LightningElement, api } from "lwc";
import SECIncidentDescription from "@salesforce/label/c.SEC_IncidentDescription";
import SECDiscoveryDate from "@salesforce/label/c.SEC_DiscoveryDate";
import SECFilingDeadline from "@salesforce/label/c.SEC_FilingDeadline";
import SECDeterminationResult from "@salesforce/label/c.SEC_DeterminationResult";
import SECSLAStatus from "@salesforce/label/c.SEC_SLAStatus";
import SECOnTrack from "@salesforce/label/c.SEC_OnTrack";
import SECAtRisk from "@salesforce/label/c.SEC_AtRisk";
import SECBreached from "@salesforce/label/c.SEC_Breached";

/**
 * Card component displaying a single materiality assessment with SLA status.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 */
export default class SecMaterialityCard extends LightningElement {
  @api assessment;

  label = {
    SECIncidentDescription,
    SECDiscoveryDate,
    SECFilingDeadline,
    SECDeterminationResult,
    SECSLAStatus,
    SECOnTrack,
    SECAtRisk,
    SECBreached,
  };

  get cardClass() {
    const sla = this.slaStatus;
    return `slds-card sla-${sla.toLowerCase().replace(" ", "-")}`;
  }

  get severityClass() {
    const result = this.assessment?.Determination_Result__c;
    if (result === "Material") return "severity-high";
    if (result === "Under Review") return "severity-medium";
    return "severity-low";
  }

  get slaStatus() {
    if (!this.assessment?.Filing_Deadline__c) return this.label.SECOnTrack;

    const deadline = new Date(this.assessment.Filing_Deadline__c);
    const today = new Date();
    const daysRemaining = Math.floor((deadline - today) / (1000 * 60 * 60 * 24));

    if (daysRemaining < 0) return this.label.SECBreached;
    if (daysRemaining <= 1) return this.label.SECAtRisk;
    return this.label.SECOnTrack;
  }

  get slaVariant() {
    const status = this.slaStatus;
    if (status === this.label.SECBreached) return "error";
    if (status === this.label.SECAtRisk) return "warning";
    return "success";
  }

  get formattedDiscoveryDate() {
    if (!this.assessment?.Discovery_Date__c) return "";
    return new Date(this.assessment.Discovery_Date__c).toLocaleDateString();
  }

  get formattedFilingDeadline() {
    if (!this.assessment?.Filing_Deadline__c) return "";
    return new Date(this.assessment.Filing_Deadline__c).toLocaleDateString();
  }

  handleCardClick() {
    this.dispatchEvent(
      new CustomEvent("viewassessment", {
        detail: { assessmentId: this.assessment.Id },
      })
    );
  }
}
