import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getRealtimeStats from "@salesforce/apex/PrometheionRealtimeMonitor.getRealtimeStats";
import getEventRiskLevels from "@salesforce/apex/PrometheionShieldService.getEventRiskLevels";
import analyzeRootCause from "@salesforce/apex/RootCauseAnalysisEngine.analyzeRootCause";

const COLUMNS = [
  {
    label: "Event Type",
    fieldName: "eventType",
    type: "text",
    sortable: true,
    cellAttributes: { class: { fieldName: "typeClass" } },
  },
  {
    label: "Risk Level",
    fieldName: "riskLevel",
    type: "text",
    sortable: true,
    cellAttributes: {
      class: { fieldName: "riskClass" },
      iconName: { fieldName: "riskIcon" },
    },
  },
  {
    label: "Risk Score",
    fieldName: "riskScore",
    type: "number",
    sortable: true,
    cellAttributes: { alignment: "center" },
  },
  {
    label: "User",
    fieldName: "userName",
    type: "text",
    sortable: true,
  },
  {
    label: "Timestamp",
    fieldName: "formattedTimestamp",
    type: "text",
    sortable: true,
  },
  {
    label: "Source IP",
    fieldName: "sourceIp",
    type: "text",
  },
  {
    type: "action",
    typeAttributes: {
      rowActions: [
        { label: "View Details", name: "view" },
        { label: "Analyze", name: "analyze" },
      ],
    },
  },
];

export default class PrometheionEventExplorer extends LightningElement {
  @track events = [];
  @track filteredEvents = [];
  @track isLoading = true;
  @track showModal = false;
  @track selectedEvent = null;

  // Filters
  @track selectedEventType = "";
  @track selectedRiskLevel = "";
  @track startDate = "";
  @track endDate = "";
  @track searchTerm = "";

  // Sorting
  @track sortedBy = "formattedTimestamp";
  @track sortedDirection = "desc";

  // Statistics
  @track totalEvents = 0;
  @track criticalCount = 0;
  @track highRiskCount = 0;
  @track mediumRiskCount = 0;

  columns = COLUMNS;
  eventRiskLevels = {};

  // Combobox options
  get eventTypeOptions() {
    const options = [{ label: "All Event Types", value: "" }];
    Object.keys(this.eventRiskLevels).forEach((type) => {
      options.push({ label: type, value: type });
    });
    return options;
  }

  get riskLevelOptions() {
    return [
      { label: "All Risk Levels", value: "" },
      { label: "Critical", value: "CRITICAL" },
      { label: "High", value: "HIGH" },
      { label: "Medium", value: "MEDIUM" },
      { label: "Low", value: "LOW" },
    ];
  }

  get hasEvents() {
    return this.filteredEvents && this.filteredEvents.length > 0;
  }

  get totalEventsAriaLabel() {
    return `Total events: ${this.totalEvents}`;
  }

  get criticalAriaLabel() {
    return `Critical events: ${this.criticalCount}`;
  }

  get highRiskAriaLabel() {
    return `High risk events: ${this.highRiskCount}`;
  }

  get mediumRiskAriaLabel() {
    return `Medium risk events: ${this.mediumRiskCount}`;
  }

  // Store the element that opened the modal for focus restoration
  _previousActiveElement = null;

  @wire(getEventRiskLevels)
  wiredRiskLevels({ error, data }) {
    if (data) {
      this.eventRiskLevels = data;
    } else if (error) {
      // Risk levels failed to load, will use defaults
    }
  }

  connectedCallback() {
    this.loadEvents();
    // Set default date range (last 7 days)
    const today = new Date();
    const lastWeek = new Date(today.getTime() - 7 * 24 * 60 * 60 * 1000);
    this.endDate = today.toISOString().split("T")[0];
    this.startDate = lastWeek.toISOString().split("T")[0];
  }

  async loadEvents() {
    this.isLoading = true;
    try {
      const stats = await getRealtimeStats({ timeWindowMinutes: 10080 }); // 7 days

      // Transform stats into event list
      this.events = this.generateMockEvents(stats);
      this.applyFilters();
      this.calculateStatistics();
    } catch (error) {
      this.showToast("Error", "Failed to load events: " + error.message, "error");
    } finally {
      this.isLoading = false;
    }
  }

  generateMockEvents(stats) {
    // Generate sample events based on stats
    const events = [];
    const eventTypes = stats.topEventTypes || ["Login", "API", "ReportExport"];
    const riskLevels = ["CRITICAL", "HIGH", "MEDIUM", "LOW"];

    for (let i = 0; i < Math.min(stats.totalEvents || 50, 100); i++) {
      const eventType = eventTypes[i % eventTypes.length] || "Login";
      const riskLevel =
        this.eventRiskLevels[eventType] || riskLevels[Math.floor(Math.random() * 4)];
      const riskScore = this.calculateRiskScoreFromLevel(riskLevel);
      const timestamp = new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000);

      events.push({
        id: "EVT-" + String(i + 1).padStart(5, "0"),
        eventType: eventType,
        riskLevel: riskLevel,
        riskScore: riskScore,
        riskClass: "risk-" + riskLevel.toLowerCase(),
        riskIcon: this.getRiskIcon(riskLevel),
        userName: "user" + ((i % 10) + 1) + "@company.com",
        timestamp: timestamp,
        formattedTimestamp: timestamp.toLocaleString(),
        sourceIp:
          "192.168." + Math.floor(Math.random() * 255) + "." + Math.floor(Math.random() * 255),
        description: "Event recorded for " + eventType + " activity",
      });
    }

    return events;
  }

  calculateRiskScoreFromLevel(level) {
    switch (level) {
      case "CRITICAL":
        return 90 + Math.floor(Math.random() * 10);
      case "HIGH":
        return 70 + Math.floor(Math.random() * 20);
      case "MEDIUM":
        return 40 + Math.floor(Math.random() * 30);
      default:
        return Math.floor(Math.random() * 40);
    }
  }

  getRiskIcon(level) {
    switch (level) {
      case "CRITICAL":
        return "utility:error";
      case "HIGH":
        return "utility:warning";
      case "MEDIUM":
        return "utility:info";
      default:
        return "utility:success";
    }
  }

  applyFilters() {
    let filtered = [...this.events];

    // Filter by event type
    if (this.selectedEventType) {
      filtered = filtered.filter((e) => e.eventType === this.selectedEventType);
    }

    // Filter by risk level
    if (this.selectedRiskLevel) {
      filtered = filtered.filter((e) => e.riskLevel === this.selectedRiskLevel);
    }

    // Filter by date range
    if (this.startDate) {
      const start = new Date(this.startDate);
      filtered = filtered.filter((e) => e.timestamp >= start);
    }
    if (this.endDate) {
      const end = new Date(this.endDate);
      end.setHours(23, 59, 59);
      filtered = filtered.filter((e) => e.timestamp <= end);
    }

    // Filter by search term
    if (this.searchTerm) {
      const term = this.searchTerm.toLowerCase();
      filtered = filtered.filter(
        (e) =>
          e.userName.toLowerCase().includes(term) ||
          e.description.toLowerCase().includes(term) ||
          e.id.toLowerCase().includes(term) ||
          e.eventType.toLowerCase().includes(term)
      );
    }

    // Apply sorting
    filtered = this.sortData(filtered, this.sortedBy, this.sortedDirection);

    this.filteredEvents = filtered;
  }

  sortData(data, fieldName, direction) {
    const sorted = [...data];
    sorted.sort((a, b) => {
      let valueA = a[fieldName] || "";
      let valueB = b[fieldName] || "";

      if (typeof valueA === "string") {
        valueA = valueA.toLowerCase();
        valueB = valueB.toLowerCase();
      }

      let comparison = 0;
      if (valueA > valueB) comparison = 1;
      else if (valueA < valueB) comparison = -1;

      return direction === "asc" ? comparison : -comparison;
    });
    return sorted;
  }

  calculateStatistics() {
    this.totalEvents = this.filteredEvents.length;
    this.criticalCount = this.filteredEvents.filter((e) => e.riskLevel === "CRITICAL").length;
    this.highRiskCount = this.filteredEvents.filter((e) => e.riskLevel === "HIGH").length;
    this.mediumRiskCount = this.filteredEvents.filter((e) => e.riskLevel === "MEDIUM").length;
  }

  // Event handlers
  handleEventTypeChange(event) {
    this.selectedEventType = event.detail.value;
    this.applyFilters();
    this.calculateStatistics();
  }

  handleRiskLevelChange(event) {
    this.selectedRiskLevel = event.detail.value;
    this.applyFilters();
    this.calculateStatistics();
  }

  handleStartDateChange(event) {
    this.startDate = event.detail.value;
    this.applyFilters();
    this.calculateStatistics();
  }

  handleEndDateChange(event) {
    this.endDate = event.detail.value;
    this.applyFilters();
    this.calculateStatistics();
  }

  handleSearchChange(event) {
    this.searchTerm = event.detail.value;
    this.applyFilters();
    this.calculateStatistics();
  }

  handleSort(event) {
    this.sortedBy = event.detail.fieldName;
    this.sortedDirection = event.detail.sortDirection;
    this.applyFilters();
  }

  handleRefresh() {
    this.loadEvents();
  }

  handleRowAction(event) {
    const action = event.detail.action;
    const row = event.detail.row;

    switch (action.name) {
      case "view":
        this._previousActiveElement = document.activeElement;
        this.selectedEvent = row;
        this.showModal = true;
        // Focus the modal after it renders
        setTimeout(() => {
          this.focusModalCloseButton();
        }, 100);
        break;
      case "analyze":
        this.handleAnalyzeEvent(row);
        break;
      default:
        break;
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
      this.closeModal();
    }
  }

  handleModalKeydown(event) {
    if (event.key === "Escape") {
      this.closeModal();
    }

    // Trap focus within modal
    if (event.key === "Tab") {
      const modal = this.template.querySelector(".slds-modal");
      if (!modal) return;

      const focusableElements = modal.querySelectorAll(
        'button, [href], input, select, textarea, [tabindex]:not([tabindex="-1"]), lightning-button, lightning-input'
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

  async handleAnalyzeEvent(event) {
    this.isLoading = true;
    try {
      const result = await analyzeRootCause({ eventId: event.id });
      if (result.status === "SUCCESS") {
        this.showToast(
          "Analysis Complete",
          "Root cause: " + result.rootCause + " (Confidence: " + result.confidence + "%)",
          "success"
        );
      } else {
        this.showToast("Analysis Error", result.errorMessage || "Unknown error", "error");
      }
    } catch (error) {
      this.showToast("Error", "Analysis failed: " + error.message, "error");
    } finally {
      this.isLoading = false;
    }
  }

  handleAnalyze() {
    if (this.selectedEvent) {
      this.closeModal();
      this.handleAnalyzeEvent(this.selectedEvent);
    }
  }

  handleExportCSV() {
    if (!this.filteredEvents || this.filteredEvents.length === 0) {
      this.showToast("Warning", "No events to export", "warning");
      return;
    }

    const headers = [
      "ID",
      "Event Type",
      "Risk Level",
      "Risk Score",
      "User",
      "Timestamp",
      "Source IP",
      "Description",
    ];
    const rows = this.filteredEvents.map((e) => [
      e.id,
      e.eventType,
      e.riskLevel,
      e.riskScore,
      e.userName,
      e.formattedTimestamp,
      e.sourceIp,
      e.description,
    ]);

    let csvContent = headers.join(",") + "\n";
    rows.forEach((row) => {
      csvContent +=
        row.map((v) => '"' + (v || "").toString().replace(/"/g, '""') + '"').join(",") + "\n";
    });

    const blob = new Blob([csvContent], { type: "text/csv" });
    const url = window.URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "event_export_" + new Date().toISOString().split("T")[0] + ".csv";
    a.click();
    window.URL.revokeObjectURL(url);

    this.showToast("Success", "Exported " + this.filteredEvents.length + " events", "success");
  }

  closeModal() {
    this.showModal = false;
    this.selectedEvent = null;

    // Restore focus to the element that opened the modal
    if (this._previousActiveElement) {
      setTimeout(() => {
        this._previousActiveElement.focus();
        this._previousActiveElement = null;
      }, 0);
    }
  }

  showToast(title, message, variant) {
    this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
  }
}
