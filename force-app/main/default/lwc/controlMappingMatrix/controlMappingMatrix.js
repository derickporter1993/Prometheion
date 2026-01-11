import { LightningElement, track } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

const FRAMEWORK_OPTIONS = [
  { label: "NIST CSF 2.0", value: "NIST" },
  { label: "HIPAA", value: "HIPAA" },
  { label: "SOC 2", value: "SOC2" },
  { label: "FedRAMP", value: "FedRAMP" },
  { label: "GDPR", value: "GDPR" },
  { label: "PCI DSS", value: "PCI_DSS" },
  { label: "ISO 27001", value: "ISO27001" },
];

// Control mappings between frameworks
const CONTROL_MAPPINGS = {
  NIST: {
    controls: [
      {
        id: "1",
        code: "ID.AM-1",
        name: "Asset Inventory",
        description: "Physical devices and systems are inventoried",
      },
      {
        id: "2",
        code: "ID.AM-2",
        name: "Software Inventory",
        description: "Software platforms and applications are inventoried",
      },
      {
        id: "3",
        code: "PR.AC-1",
        name: "Identity Management",
        description: "Identities and credentials are managed",
      },
      { id: "4", code: "PR.AC-3", name: "Remote Access", description: "Remote access is managed" },
      { id: "5", code: "PR.DS-1", name: "Data at Rest", description: "Data-at-rest is protected" },
      {
        id: "6",
        code: "DE.CM-1",
        name: "Network Monitoring",
        description: "The network is monitored",
      },
      {
        id: "7",
        code: "RS.RP-1",
        name: "Response Plan",
        description: "Response plan is executed during incident",
      },
      { id: "8", code: "RC.RP-1", name: "Recovery Plan", description: "Recovery plan is executed" },
    ],
    mappings: {
      HIPAA: {
        "ID.AM-1": { code: "164.310(d)", type: "direct", confidence: 95 },
        "ID.AM-2": { code: "164.312(a)", type: "partial", confidence: 70 },
        "PR.AC-1": { code: "164.312(d)", type: "direct", confidence: 90 },
        "PR.AC-3": { code: "164.312(e)", type: "direct", confidence: 85 },
        "PR.DS-1": { code: "164.312(a)(2)(iv)", type: "direct", confidence: 95 },
        "DE.CM-1": { code: "164.312(b)", type: "direct", confidence: 90 },
        "RS.RP-1": { code: "164.308(a)(6)", type: "direct", confidence: 92 },
        "RC.RP-1": { code: "164.308(a)(7)", type: "direct", confidence: 88 },
      },
      SOC2: {
        "ID.AM-1": { code: "CC6.1", type: "direct", confidence: 90 },
        "ID.AM-2": { code: "CC6.1", type: "partial", confidence: 75 },
        "PR.AC-1": { code: "CC6.1", type: "direct", confidence: 95 },
        "PR.AC-3": { code: "CC6.6", type: "direct", confidence: 88 },
        "PR.DS-1": { code: "CC6.7", type: "direct", confidence: 92 },
        "DE.CM-1": { code: "CC7.2", type: "direct", confidence: 90 },
        "RS.RP-1": { code: "CC7.4", type: "direct", confidence: 85 },
        "RC.RP-1": { code: "CC9.1", type: "partial", confidence: 70 },
      },
      FedRAMP: {
        "ID.AM-1": { code: "CM-8", type: "direct", confidence: 98 },
        "ID.AM-2": { code: "CM-8", type: "direct", confidence: 98 },
        "PR.AC-1": { code: "IA-2", type: "direct", confidence: 95 },
        "PR.AC-3": { code: "AC-17", type: "direct", confidence: 95 },
        "PR.DS-1": { code: "SC-28", type: "direct", confidence: 98 },
        "DE.CM-1": { code: "SI-4", type: "direct", confidence: 95 },
        "RS.RP-1": { code: "IR-4", type: "direct", confidence: 95 },
        "RC.RP-1": { code: "CP-10", type: "direct", confidence: 92 },
      },
      GDPR: {
        "ID.AM-1": { code: "Art.30", type: "partial", confidence: 60 },
        "PR.AC-1": { code: "Art.32", type: "partial", confidence: 70 },
        "PR.DS-1": { code: "Art.32", type: "direct", confidence: 85 },
        "RS.RP-1": { code: "Art.33", type: "direct", confidence: 90 },
      },
    },
  },
};

export default class ControlMappingMatrix extends LightningElement {
  @track sourceFramework = "NIST";
  @track targetFrameworks = ["HIPAA", "SOC2", "FedRAMP"];
  @track mappingRows = [];
  @track isLoading = false;
  @track showMappingModal = false;
  @track selectedMapping = null;

  // Statistics
  @track totalControls = 0;
  @track directMappings = 0;
  @track partialMappings = 0;
  @track unmappedControls = 0;

  frameworkOptions = FRAMEWORK_OPTIONS;

  get availableTargetFrameworks() {
    return FRAMEWORK_OPTIONS.filter((f) => f.value !== this.sourceFramework);
  }

  get tableAriaLabel() {
    return `Control mapping matrix from ${this.sourceFramework} to ${this.targetFrameworks.join(", ")}`;
  }

  get totalControlsAriaLabel() {
    return `Total controls: ${this.totalControls}`;
  }

  get directMappingsAriaLabel() {
    return `Direct mappings: ${this.directMappings}`;
  }

  get partialMappingsAriaLabel() {
    return `Partial mappings: ${this.partialMappings}`;
  }

  get unmappedAriaLabel() {
    return `Gaps: ${this.unmappedControls}`;
  }

  // Store element that triggered modal for focus restoration
  _previousActiveElement = null;

  connectedCallback() {
    this.loadMappings();
  }

  handleSourceChange(event) {
    this.sourceFramework = event.detail.value;
    // Reset target frameworks
    this.targetFrameworks = this.availableTargetFrameworks.slice(0, 3).map((f) => f.value);
    this.loadMappings();
  }

  handleTargetChange(event) {
    this.targetFrameworks = event.detail.value;
    this.loadMappings();
  }

  loadMappings() {
    this.isLoading = true;

    try {
      const sourceData = CONTROL_MAPPINGS[this.sourceFramework];
      if (!sourceData) {
        this.mappingRows = [];
        return;
      }

      let directCount = 0;
      let partialCount = 0;
      let gapCount = 0;

      this.mappingRows = sourceData.controls.map((control) => {
        const mappings = this.targetFrameworks.map((framework) => {
          const frameworkMappings = sourceData.mappings[framework] || {};
          const mapping = frameworkMappings[control.code];

          if (mapping) {
            if (mapping.type === "direct") directCount++;
            else partialCount++;
          } else {
            gapCount++;
          }

          const typeLabel =
            mapping?.type === "direct"
              ? "Direct"
              : mapping?.type === "partial"
                ? "Partial"
                : "None";
          return {
            framework: framework,
            hasMapping: !!mapping,
            targetCode: mapping?.code || "",
            type: mapping?.type || "none",
            confidence: mapping?.confidence || 0,
            icon: this.getMappingIcon(mapping?.type),
            cellClass: "mapping-cell " + (mapping?.type || "none"),
            ariaLabel: mapping
              ? `${framework} mapping: ${mapping.code}, ${typeLabel} mapping. Click for details.`
              : `No ${framework} mapping. Click for details.`,
            mappingTypeAlt: typeLabel + " mapping",
          };
        });

        // Calculate coverage for this control
        const mappedCount = mappings.filter((m) => m.hasMapping).length;
        const coveragePercent =
          this.targetFrameworks.length > 0
            ? Math.round((mappedCount / this.targetFrameworks.length) * 100)
            : 0;

        return {
          id: control.id,
          controlCode: control.code,
          controlName: control.name,
          controlDescription: control.description,
          mappings: mappings,
          coveragePercent: coveragePercent,
          coverageVariant: this.getCoverageVariant(coveragePercent),
          coverageAriaLabel: `Coverage: ${coveragePercent}%`,
        };
      });

      this.totalControls = sourceData.controls.length;
      this.directMappings = directCount;
      this.partialMappings = partialCount;
      this.unmappedControls = gapCount;
    } finally {
      this.isLoading = false;
    }
  }

  getMappingIcon(type) {
    switch (type) {
      case "direct":
        return "utility:success";
      case "partial":
        return "utility:warning";
      default:
        return "";
    }
  }

  getCoverageVariant(percent) {
    if (percent >= 80) return "base-autocomplete";
    if (percent >= 50) return "warning";
    return "expired";
  }

  handleCellClick(event) {
    const rowId = event.currentTarget.dataset.row;
    const framework = event.currentTarget.dataset.framework;

    const row = this.mappingRows.find((r) => r.id === rowId);
    const mapping = row?.mappings.find((m) => m.framework === framework);

    if (row && mapping && mapping.hasMapping) {
      this._previousActiveElement = event.currentTarget;
      const sourceData = CONTROL_MAPPINGS[this.sourceFramework];
      const sourceControl = sourceData.controls.find((c) => c.id === rowId);
      const frameworkMappings = sourceData.mappings[framework];
      const targetMapping = frameworkMappings[row.controlCode];

      this.selectedMapping = {
        sourceCode: row.controlCode,
        sourceName: row.controlName,
        sourceDescription: sourceControl?.description || "",
        targetCode: mapping.targetCode,
        targetName: this.getTargetControlName(framework, mapping.targetCode),
        targetDescription: "Control requirement for " + framework,
        mappingType: mapping.type === "direct" ? "Direct" : "Partial",
        confidence: targetMapping?.confidence || 0,
        notes: this.getMappingNotes(mapping.type),
      };

      this.showMappingModal = true;
      // Focus modal after it renders
      setTimeout(() => {
        this.focusModalCloseButton();
      }, 100);
    }
  }

  handleCellKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.handleCellClick(event);
    }
  }

  focusModalCloseButton() {
    const closeButton = this.template.querySelector(".slds-modal__close");
    if (closeButton) {
      closeButton.focus();
    }
  }

  handleBackdropKeydown(event) {
    if (event.key === "Escape") {
      this.closeMappingModal();
    }
  }

  handleModalKeydown(event) {
    if (event.key === "Escape") {
      this.closeMappingModal();
    }

    // Trap focus within modal
    if (event.key === "Tab") {
      const modal = this.template.querySelector(".slds-modal");
      if (!modal) return;

      const focusableElements = modal.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"]), lightning-button'
      );
      const firstElement = focusableElements[0];
      const lastElement = focusableElements[focusableElements.length - 1];

      if (event.shiftKey && document.activeElement === firstElement) {
        event.preventDefault();
        lastElement.focus();
      } else if (!event.shiftKey && document.activeElement === lastElement) {
        event.preventDefault();
        firstElement.focus();
      }
    }
  }

  getTargetControlName(framework, code) {
    const names = {
      HIPAA: {
        "164.310(d)": "Device and Media Controls",
        "164.312(a)": "Access Control",
        "164.312(d)": "Person or Entity Authentication",
        "164.312(e)": "Transmission Security",
        "164.312(b)": "Audit Controls",
        "164.308(a)(6)": "Security Incident Procedures",
        "164.308(a)(7)": "Contingency Plan",
      },
      SOC2: {
        "CC6.1": "Logical and Physical Access Controls",
        "CC6.6": "System Operations",
        "CC6.7": "Change Management",
        "CC7.2": "Security Monitoring",
        "CC7.4": "Incident Response",
        "CC9.1": "Risk Mitigation",
      },
      FedRAMP: {
        "CM-8": "System Component Inventory",
        "IA-2": "Identification and Authentication",
        "AC-17": "Remote Access",
        "SC-28": "Protection of Information at Rest",
        "SI-4": "System Monitoring",
        "IR-4": "Incident Handling",
        "CP-10": "System Recovery",
      },
    };
    return names[framework]?.[code] || code;
  }

  getMappingNotes(type) {
    if (type === "direct") {
      return "This control directly maps to the target framework requirement with high confidence.";
    } else if (type === "partial") {
      return "This control partially addresses the target requirement. Additional controls may be needed.";
    }
    return "No mapping exists for this control.";
  }

  closeMappingModal() {
    this.showMappingModal = false;
    this.selectedMapping = null;

    // Restore focus to the element that opened the modal
    if (this._previousActiveElement) {
      setTimeout(() => {
        this._previousActiveElement.focus();
        this._previousActiveElement = null;
      }, 0);
    }
  }

  handleExport() {
    if (!this.mappingRows || this.mappingRows.length === 0) {
      this.showToast("Warning", "No mappings to export", "warning");
      return;
    }

    // Build CSV
    const headers = ["Source Control", "Control Name", ...this.targetFrameworks, "Coverage %"];
    const rows = this.mappingRows.map((row) => {
      const mappingValues = row.mappings.map((m) => m.targetCode || "-");
      return [row.controlCode, row.controlName, ...mappingValues, row.coveragePercent];
    });

    let csv = headers.join(",") + "\n";
    rows.forEach((row) => {
      csv += row.map((v) => '"' + String(v).replace(/"/g, '""') + '"').join(",") + "\n";
    });

    // Download
    const blob = new Blob([csv], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download =
      "control_mapping_" +
      this.sourceFramework +
      "_" +
      new Date().toISOString().split("T")[0] +
      ".csv";
    a.click();
    window.URL.revokeObjectURL(url);

    this.showToast("Success", "Matrix exported successfully", "success");
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
