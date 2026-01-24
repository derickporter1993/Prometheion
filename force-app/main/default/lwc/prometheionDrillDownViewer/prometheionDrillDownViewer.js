import { LightningElement, track, api } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import { NavigationMixin } from "lightning/navigation";
import getRecords from "@salesforce/apex/PrometheionDrillDownController.getRecords";
import exportToCSV from "@salesforce/apex/PrometheionDrillDownController.exportToCSV";

export default class PrometheionDrillDownViewer extends NavigationMixin(LightningElement) {
  @api contextJson;
  @track records = [];
  @track columns = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";
  @track totalCount = 0;
  @track pageSize = 50;
  @track currentOffset = 0;
  @track hasMore = false;
  _context;

  connectedCallback() {
    if (this.contextJson) {
      this.loadRecords();
    }
  }

  loadRecords() {
    this.loadRecordsWithContext();
  }

  loadRecordsWithContext(contextOverride) {
    this.isLoading = true;
    this.hasError = false;

    const context = contextOverride ? { ...contextOverride } : this.getContext();
    context.pageSize = this.pageSize;
    context.offset = this.currentOffset;
    this._context = context;

    getRecords({ contextJson: JSON.stringify(context) })
      .then((result) => {
        this.records = result.records;
        this.columns = result.columns.map((col) => ({
          label: col.label,
          fieldName: col.fieldName,
          type: col.type,
          sortable: col.sortable,
        }));
        this.totalCount = result.totalCount;
        this.hasMore = result.hasMore;
        this.isLoading = false;
      })
      .catch((error) => {
        this.hasError = true;
        this.errorMessage =
          "Error loading records: " +
          (error?.body?.message || error?.message || "An unknown error occurred");
        this.isLoading = false;
        this.showError(this.errorMessage);
      });
  }

  handleRowAction(event) {
    const row = event.detail.row;

    // Navigate to record detail page
    this[NavigationMixin.Navigate]({
      type: "standard__recordPage",
      attributes: {
        recordId: row.Id,
        actionName: "view",
      },
    });
  }

  handleSort(event) {
    const context = this.getContext();
    context.orderBy = event.detail.fieldName;
    context.orderDirection = event.detail.sortDirection === "asc" ? "ASC" : "DESC";
    this.currentOffset = 0;
    this.loadRecordsWithContext(context);
  }

  handleLoadMore() {
    if (this.hasMore) {
      this.currentOffset += this.pageSize;
      this.loadRecords();
    }
  }

  handleExport() {
    this.isLoading = true;
    const context = this.getContext();

    exportToCSV({ contextJson: JSON.stringify(context) })
      .then((csvData) => {
        // Create download link
        const blob = new Blob([csvData], { type: "text/csv" });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement("a");
        a.href = url;
        a.download = "drilldown_export.csv";
        a.click();
        window.URL.revokeObjectURL(url);

        this.isLoading = false;
        this.showSuccess("Export completed successfully");
      })
      .catch((error) => {
        this.isLoading = false;
        this.showError(
          "Error exporting: " +
            (error?.body?.message || error?.message || "An unknown error occurred")
        );
      });
  }

  get hasRecords() {
    return this.records && this.records.length > 0;
  }

  get noRecords() {
    return !this.hasRecords;
  }

  get notLoading() {
    return !this.isLoading;
  }

  get notError() {
    return !this.hasError;
  }

  get isExportDisabled() {
    return this.isLoading || !this.hasRecords;
  }

  getContext() {
    if (this._context) {
      return { ...this._context };
    }
    try {
      return JSON.parse(this.contextJson);
    } catch {
      this.showError("Invalid context data. Please refresh the page.");
      return {};
    }
  }

  showError(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Error",
        message: message,
        variant: "error",
      })
    );
  }

  showSuccess(message) {
    this.dispatchEvent(
      new ShowToastEvent({
        title: "Success",
        message: message,
        variant: "success",
      })
    );
  }
}
