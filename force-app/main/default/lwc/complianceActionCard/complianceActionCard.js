import { LightningElement, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import CC_PrioritizedActions from "@salesforce/label/c.CC_PrioritizedActions";
import CC_NoActions from "@salesforce/label/c.CC_NoActions";
import CC_GoToSetup from "@salesforce/label/c.CC_GoToSetup";
import CC_RemediationSteps from "@salesforce/label/c.CC_RemediationSteps";

export default class ComplianceActionCard extends NavigationMixin(LightningElement) {
  label = {
    CC_PrioritizedActions,
    CC_NoActions,
    CC_GoToSetup,
    CC_RemediationSteps,
  };

  @api actions = [];

  expandedActionKey;

  get hasActions() {
    return this.actions && this.actions.length > 0;
  }

  get indexedActions() {
    return (this.actions || []).map((action, idx) => ({
      ...action,
      key: `action-${idx}`,
      severityClass: this.getSeverityClass(action.severity),
      severityBadge: action.severity,
      isExpanded: this.expandedActionKey === `action-${idx}`,
      hasSetupPath: !!action.setupPath,
      hasRemediationSteps: !!action.remediationSteps,
    }));
  }

  getSeverityClass(severity) {
    if (severity === "CRITICAL") return "slds-badge slds-badge_inverse";
    if (severity === "HIGH") return "slds-badge slds-theme_error";
    if (severity === "MEDIUM") return "slds-badge slds-theme_warning";
    return "slds-badge slds-badge_lightest";
  }

  handleToggleExpand(event) {
    const key = event.currentTarget.dataset.key;
    this.expandedActionKey = this.expandedActionKey === key ? null : key;
  }

  handleGoToSetup(event) {
    const setupPath = event.currentTarget.dataset.path;
    if (setupPath) {
      this[NavigationMixin.Navigate]({
        type: "standard__webPage",
        attributes: {
          url: "/lightning/setup/" + setupPath,
        },
      });
    }
  }
}
