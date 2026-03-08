import { LightningElement, api } from "lwc";
import TC_ComplianceScore from "@salesforce/label/c.TC_ComplianceScore";
import TC_CertificationStatus from "@salesforce/label/c.TC_CertificationStatus";
import TC_LastAuditDate from "@salesforce/label/c.TC_LastAuditDate";
import TC_Certified from "@salesforce/label/c.TC_Certified";
import TC_InProgress from "@salesforce/label/c.TC_InProgress";
import TC_RenewalRequired from "@salesforce/label/c.TC_RenewalRequired";
import TC_NotStarted from "@salesforce/label/c.TC_NotStarted";
import TC_ScoreExcellent from "@salesforce/label/c.TC_ScoreExcellent";
import TC_ScoreGood from "@salesforce/label/c.TC_ScoreGood";
import TC_ScoreNeedsWork from "@salesforce/label/c.TC_ScoreNeedsWork";
import TC_ScoreCritical from "@salesforce/label/c.TC_ScoreCritical";

const SCORE_THRESHOLD_EXCELLENT = 80;
const SCORE_THRESHOLD_GOOD = 50;

const CERTIFICATION_LABEL_MAP = {
  Certified: TC_Certified,
  In_Progress: TC_InProgress,
  Renewal_Required: TC_RenewalRequired,
  Not_Started: TC_NotStarted,
};

/**
 * Reusable compliance badge component displaying framework compliance status.
 * Renders a visual card with color-coded progress bar and certification info.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Trust Center
 */
export default class TrustCenterBadge extends LightningElement {
  /** @api Framework display name (e.g., "SOC 2", "HIPAA") */
  @api frameworkName = "";

  /** @api Compliance percentage (0-100) */
  @api compliancePercentage = 0;

  /** @api Certification status picklist value */
  @api certificationStatus = "";

  /** @api Last audit date in ISO format */
  @api lastAuditDate;

  label = {
    TC_ComplianceScore,
    TC_CertificationStatus,
    TC_LastAuditDate,
    TC_Certified,
    TC_InProgress,
    TC_RenewalRequired,
    TC_NotStarted,
    TC_ScoreExcellent,
    TC_ScoreGood,
    TC_ScoreNeedsWork,
    TC_ScoreCritical,
  };

  get formattedPercentage() {
    const pct = Number(this.compliancePercentage);
    if (Number.isNaN(pct)) {
      return "0";
    }
    return pct % 1 === 0 ? String(Math.round(pct)) : pct.toFixed(1);
  }

  get formattedAuditDate() {
    if (!this.lastAuditDate) {
      return "--";
    }
    try {
      const date = new Date(this.lastAuditDate);
      return date.toLocaleDateString(undefined, {
        year: "numeric",
        month: "short",
        day: "numeric",
      });
    } catch (e) {
      return "--";
    }
  }

  get certificationDisplayValue() {
    return CERTIFICATION_LABEL_MAP[this.certificationStatus] ?? this.certificationStatus ?? "--";
  }

  get scoreCategory() {
    const pct = Number(this.compliancePercentage) || 0;
    if (pct >= SCORE_THRESHOLD_EXCELLENT) {
      return "excellent";
    }
    if (pct >= SCORE_THRESHOLD_GOOD) {
      return "good";
    }
    return "critical";
  }

  get statusLabel() {
    const category = this.scoreCategory;
    if (category === "excellent") {
      return this.label.TC_ScoreExcellent;
    }
    if (category === "good") {
      return this.label.TC_ScoreNeedsWork;
    }
    return this.label.TC_ScoreCritical;
  }

  get statusIcon() {
    const category = this.scoreCategory;
    if (category === "excellent") {
      return "utility:success";
    }
    if (category === "good") {
      return "utility:warning";
    }
    return "utility:error";
  }

  get badgeCardClass() {
    const base = "slds-card badge-card";
    const category = this.scoreCategory;
    if (category === "excellent") {
      return `${base} badge-card_success`;
    }
    if (category === "good") {
      return `${base} badge-card_warning`;
    }
    return `${base} badge-card_error`;
  }

  get iconContainerClass() {
    const category = this.scoreCategory;
    if (category === "excellent") {
      return "slds-icon_container slds-icon-utility-success icon-success";
    }
    if (category === "good") {
      return "slds-icon_container slds-icon-utility-warning icon-warning";
    }
    return "slds-icon_container slds-icon-utility-error icon-error";
  }

  get statusBadgeClass() {
    const base = "slds-badge";
    const category = this.scoreCategory;
    if (category === "excellent") {
      return `${base} badge-success`;
    }
    if (category === "good") {
      return `${base} badge-warning`;
    }
    return `${base} badge-error`;
  }

  get scoreTextClass() {
    const base = "slds-text-body_small slds-text-title_bold";
    const category = this.scoreCategory;
    if (category === "excellent") {
      return `${base} text-success`;
    }
    if (category === "good") {
      return `${base} text-warning`;
    }
    return `${base} text-error`;
  }

  get progressBarClass() {
    const base = "slds-progress-bar__value";
    const category = this.scoreCategory;
    if (category === "excellent") {
      return `${base} progress-success`;
    }
    if (category === "good") {
      return `${base} progress-warning`;
    }
    return `${base} progress-error`;
  }

  get progressBarStyle() {
    const pct = Math.min(100, Math.max(0, Number(this.compliancePercentage) || 0));
    return `width: ${pct}%`;
  }

  get progressBarLabel() {
    return `${this.frameworkName} ${this.label.TC_ComplianceScore}`;
  }
}
