import { LightningElement, wire } from "lwc";
import getRecentActivity from "@salesforce/apex/CommandCenterController.getRecentActivity";
import CC_ActivityFeed from "@salesforce/label/c.CC_ActivityFeed";
import CC_NoActivity from "@salesforce/label/c.CC_NoActivity";

export default class ComplianceNotificationFeed extends LightningElement {
  label = {
    CC_ActivityFeed,
    CC_NoActivity,
  };

  activities;
  error;

  @wire(getRecentActivity, { recordLimit: 20 })
  wiredActivity({ data, error }) {
    if (data) {
      this.activities = data;
      this.error = undefined;
    } else if (error) {
      this.error = error;
      this.activities = undefined;
    }
  }

  get hasActivities() {
    return this.activities && this.activities.length > 0;
  }

  get indexedActivities() {
    return (this.activities || []).map((item, idx) => ({
      ...item,
      key: `activity-${idx}`,
      severityClass: this.getSeverityClass(item.severity),
      formattedTime: this.formatRelativeTime(item.timestamp),
      iconName: this.getActivityIcon(item.activityType),
    }));
  }

  getSeverityClass(severity) {
    if (severity === "CRITICAL") return "slds-badge slds-badge_inverse";
    if (severity === "HIGH") return "slds-badge slds-theme_error";
    if (severity === "MEDIUM") return "slds-badge slds-theme_warning";
    return "slds-badge slds-badge_lightest";
  }

  getActivityIcon(activityType) {
    if (activityType === "GAP_UPDATE") return "utility:warning";
    if (activityType === "SCORE_CHANGE") return "utility:trending";
    if (activityType === "REMEDIATION") return "utility:check";
    return "utility:notification";
  }

  formatRelativeTime(timestamp) {
    if (!timestamp) return "";
    const now = new Date();
    const then = new Date(timestamp);
    const diffMs = now - then;
    const diffMins = Math.floor(diffMs / 60000);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffMins < 1) return "Just now";
    if (diffMins < 60) return diffMins + "m ago";
    if (diffHours < 24) return diffHours + "h ago";
    if (diffDays < 7) return diffDays + "d ago";
    return then.toLocaleDateString();
  }
}
