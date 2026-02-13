import { LightningElement, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { refreshApex } from "@salesforce/apex";
import getGovernanceSummary from "@salesforce/apex/AIGovernanceController.getGovernanceSummary";
import getRegisteredSystems from "@salesforce/apex/AIGovernanceController.getRegisteredSystems";
import discoverAISystems from "@salesforce/apex/AIGovernanceController.discoverAISystems";
import registerAISystem from "@salesforce/apex/AIGovernanceController.registerAISystem";
import getAIAuditTrail from "@salesforce/apex/AIGovernanceController.getAIAuditTrail";
import updateRiskLevel from "@salesforce/apex/AIGovernanceController.updateRiskLevel";

import AI_DiscoveryInProgress from "@salesforce/label/c.AI_DiscoveryInProgress";
import AI_DiscoveryComplete from "@salesforce/label/c.AI_DiscoveryComplete";
import AI_NoSystemsFound from "@salesforce/label/c.AI_NoSystemsFound";
import AI_RiskUnacceptable from "@salesforce/label/c.AI_RiskUnacceptable";
import AI_RiskHigh from "@salesforce/label/c.AI_RiskHigh";
import AI_RiskLimited from "@salesforce/label/c.AI_RiskLimited";
import AI_RiskMinimal from "@salesforce/label/c.AI_RiskMinimal";
import AI_RegisterSystem from "@salesforce/label/c.AI_RegisterSystem";
import AI_ComplianceScore from "@salesforce/label/c.AI_ComplianceScore";
import AI_TotalSystems from "@salesforce/label/c.AI_TotalSystems";
import AI_HighRiskSystems from "@salesforce/label/c.AI_HighRiskSystems";
import AI_GapsIdentified from "@salesforce/label/c.AI_GapsIdentified";
import AI_EUAIAct from "@salesforce/label/c.AI_EUAIAct";
import AI_NISTRMF from "@salesforce/label/c.AI_NISTRMF";
import AI_RefreshData from "@salesforce/label/c.AI_RefreshData";
import AI_ErrorGeneric from "@salesforce/label/c.AI_ErrorGeneric";
import AI_DashboardTitle from "@salesforce/label/c.AI_DashboardTitle";
import AI_DiscoverSystems from "@salesforce/label/c.AI_DiscoverSystems";
import AI_SystemRegistry from "@salesforce/label/c.AI_SystemRegistry";
import AI_NoGaps from "@salesforce/label/c.AI_NoGaps";
import AI_AuditTrail from "@salesforce/label/c.AI_AuditTrail";
import AI_NoAuditEntries from "@salesforce/label/c.AI_NoAuditEntries";

const RISK_BADGE_MAP = {
  Unacceptable: "slds-badge_inverse",
  High: "slds-badge_error",
  Limited: "slds-badge_warning",
  Minimal: "slds-badge_success",
};

const RISK_LABEL_MAP = {
  Unacceptable: AI_RiskUnacceptable,
  High: AI_RiskHigh,
  Limited: AI_RiskLimited,
  Minimal: AI_RiskMinimal,
};

const REGISTRY_COLUMNS = [
  { label: "System Name", fieldName: "Name", sortable: true },
  { label: "Type", fieldName: "System_Type__c", sortable: true },
  {
    label: "Risk Level",
    fieldName: "Risk_Level__c",
    sortable: true,
    cellAttributes: { class: { fieldName: "riskClass" } },
  },
  { label: "Status", fieldName: "Status__c", sortable: true },
  { label: "Detection Method", fieldName: "Detection_Method__c" },
  {
    type: "action",
    typeAttributes: {
      rowActions: [
        { label: "View Details", name: "view" },
        { label: "Set Unacceptable", name: "risk_Unacceptable" },
        { label: "Set High", name: "risk_High" },
        { label: "Set Limited", name: "risk_Limited" },
        { label: "Set Minimal", name: "risk_Minimal" },
      ],
    },
  },
];

const DISCOVERED_COLUMNS = [
  { label: "System Name", fieldName: "systemName" },
  { label: "Type", fieldName: "systemType" },
  { label: "Detection Method", fieldName: "detectionMethod" },
  { label: "Namespace", fieldName: "namespacePrefix" },
  {
    type: "button",
    typeAttributes: {
      label: AI_RegisterSystem,
      name: "register",
      variant: "brand",
      iconName: "utility:add",
    },
  },
];

const AUDIT_COLUMNS = [
  { label: "Action", fieldName: "actionType" },
  { label: "Section", fieldName: "section" },
  { label: "Changed By", fieldName: "changedBy" },
  { label: "Severity", fieldName: "severity" },
  { label: "Details", fieldName: "display", wrapText: true },
  {
    label: "Date",
    fieldName: "changeDate",
    type: "date",
    typeAttributes: {
      year: "numeric",
      month: "short",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
    },
  },
];

const AUDIT_LOOKBACK_DAYS = 90;

export default class AiGovernanceDashboard extends LightningElement {
  label = {
    AI_DiscoveryInProgress,
    AI_DiscoveryComplete,
    AI_NoSystemsFound,
    AI_RiskUnacceptable,
    AI_RiskHigh,
    AI_RiskLimited,
    AI_RiskMinimal,
    AI_RegisterSystem,
    AI_ComplianceScore,
    AI_TotalSystems,
    AI_HighRiskSystems,
    AI_GapsIdentified,
    AI_EUAIAct,
    AI_NISTRMF,
    AI_RefreshData,
    AI_ErrorGeneric,
    AI_DashboardTitle,
    AI_DiscoverSystems,
    AI_SystemRegistry,
    AI_NoGaps,
    AI_AuditTrail,
    AI_NoAuditEntries,
  };

  registryColumns = REGISTRY_COLUMNS;
  discoveredColumns = DISCOVERED_COLUMNS;
  auditColumns = AUDIT_COLUMNS;

  isLoading = true;
  error;
  isDiscovering = false;

  // Summary data
  complianceScore = 0;
  totalSystems = 0;
  highRiskCount = 0;
  gaps = [];
  lastScanDate;

  // Registry data
  registeredSystems = [];
  _wiredRegistryResult;
  sortedBy = "Name";
  sortedDirection = "asc";

  // Discovery data
  discoveredSystems = [];

  // Audit data
  auditEntries = [];

  get formattedScore() {
    return Math.round(this.complianceScore ?? 0);
  }

  get gapCount() {
    return this.gaps?.length ?? 0;
  }

  get hasRegisteredSystems() {
    return this.registeredSystems?.length > 0;
  }

  get hasDiscoveredSystems() {
    return this.discoveredSystems?.length > 0;
  }

  get hasGaps() {
    return this.gaps?.length > 0;
  }

  get hasAuditEntries() {
    return this.auditEntries?.length > 0;
  }

  get discoveredCountMessage() {
    const count = this.discoveredSystems?.length ?? 0;
    return `Found ${count} AI system(s). Click Register to add them to your governance registry.`;
  }

  @wire(getRegisteredSystems)
  wiredSystems(result) {
    this._wiredRegistryResult = result;
    if (result.data) {
      this.registeredSystems = result.data.map((sys) => ({
        ...sys,
        riskClass: this._riskCellClass(sys.Risk_Level__c),
      }));
    } else if (result.error) {
      this.error = result.error?.body?.message ?? this.label.AI_ErrorGeneric;
    }
  }

  connectedCallback() {
    this._loadDashboard();
  }

  async _loadDashboard() {
    this.isLoading = true;
    this.error = undefined;
    try {
      const [summary, auditTrail] = await Promise.all([
        getGovernanceSummary(),
        getAIAuditTrail({ lookbackDays: AUDIT_LOOKBACK_DAYS }),
      ]);

      this.complianceScore = summary.complianceScore ?? 0;
      this.totalSystems = summary.totalSystems ?? 0;
      this.highRiskCount = summary.highRiskCount ?? 0;
      this.lastScanDate = summary.lastScanDate;
      this.gaps = (summary.gaps ?? []).map((g) => ({
        ...g,
        badgeClass: `slds-badge ${RISK_BADGE_MAP[g.severity] ?? ""}`,
      }));

      this.auditEntries = (auditTrail ?? []).map((entry, idx) => ({
        ...entry,
        uniqueKey: `${entry.actionType}-${entry.changeDate}-${idx}`,
      }));
    } catch (e) {
      this.error = e?.body?.message ?? this.label.AI_ErrorGeneric;
    } finally {
      this.isLoading = false;
    }
  }

  async handleDiscoverSystems() {
    this.isDiscovering = true;
    this.discoveredSystems = [];
    try {
      const systems = await discoverAISystems();
      this.discoveredSystems = systems ?? [];
      if (this.discoveredSystems.length === 0) {
        this._showToast(this.label.AI_DiscoveryComplete, this.label.AI_NoSystemsFound, "info");
      } else {
        this._showToast(
          this.label.AI_DiscoveryComplete,
          `Found ${this.discoveredSystems.length} AI system(s)`,
          "success"
        );
      }
    } catch (e) {
      this._showToast("Error", e?.body?.message ?? this.label.AI_ErrorGeneric, "error");
    } finally {
      this.isDiscovering = false;
    }
  }

  async handleRegisterSystem(event) {
    const row = event.detail.row;
    try {
      await registerAISystem({
        systemMetadataJson: JSON.stringify(row),
        useCase: row.useCaseDescription ?? "",
      });
      this._showToast("Registered", `${row.systemName} added to registry`, "success");
      this.discoveredSystems = this.discoveredSystems.filter(
        (s) => s.systemName !== row.systemName
      );
      await this._refreshAll();
    } catch (e) {
      this._showToast("Error", e?.body?.message ?? this.label.AI_ErrorGeneric, "error");
    }
  }

  async handleRegistryAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;

    if (action.name === "view") {
      window.open(`/${row.Id}`, "_blank");
      return;
    }

    if (action.name.startsWith("risk_")) {
      const newLevel = action.name.replace("risk_", "");
      try {
        await updateRiskLevel({ systemId: row.Id, newRiskLevel: newLevel });
        this._showToast(
          "Updated",
          `${row.Name} risk level set to ${RISK_LABEL_MAP[newLevel] ?? newLevel}`,
          "success"
        );
        await this._refreshAll();
      } catch (e) {
        this._showToast("Error", e?.body?.message ?? this.label.AI_ErrorGeneric, "error");
      }
    }
  }

  handleSort(event) {
    this.sortedBy = event.detail.fieldName;
    this.sortedDirection = event.detail.sortDirection;
    this._sortData();
  }

  async handleRefresh() {
    await this._refreshAll();
  }

  async _refreshAll() {
    await Promise.all([refreshApex(this._wiredRegistryResult), this._loadDashboard()]);
  }

  _sortData() {
    const data = [...this.registeredSystems];
    const field = this.sortedBy;
    const dir = this.sortedDirection === "asc" ? 1 : -1;
    data.sort((a, b) => {
      const valA = a[field] ?? "";
      const valB = b[field] ?? "";
      if (valA < valB) return -1 * dir;
      if (valA > valB) return 1 * dir;
      return 0;
    });
    this.registeredSystems = data;
  }

  _riskCellClass(riskLevel) {
    const map = {
      Unacceptable: "slds-text-color_error",
      High: "slds-text-color_error",
      Limited: "slds-text-color_warning",
      Minimal: "slds-text-color_success",
    };
    return map[riskLevel] ?? "";
  }

  _showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
