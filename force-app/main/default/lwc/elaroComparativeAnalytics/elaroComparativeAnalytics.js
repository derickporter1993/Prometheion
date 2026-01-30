import { LightningElement, track, wire } from "lwc";
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import getDimensionFields from "@salesforce/apex/ElaroMatrixController.getDimensionFields";
import executeMatrixQuery from "@salesforce/apex/ElaroMatrixController.executeMatrixQuery";

export default class ElaroComparativeAnalytics extends LightningElement {
  @track selectedObject = "";
  @track objectOptions = [
    { label: "Account", value: "Account" },
    { label: "Opportunity", value: "Opportunity" },
    { label: "Case", value: "Case" },
  ];
  @track dimensionFields = [];
  @track rowField = "";
  @track columnField = "";
  @track aggregateExpression = "SUM(Amount)";
  @track matrixData = {};
  @track matrixRows = [];
  @track matrixColumns = [];
  @track computedMatrixData = [];
  @track isLoading = false;
  @track hasError = false;
  @track errorMessage = "";

  @wire(getDimensionFields, { objectApiName: "$selectedObject" })
  wiredDimensionFields({ error, data }) {
    if (data) {
      this.dimensionFields = data.map((field) => ({
        label: field.label,
        value: field.apiName,
      }));
    } else if (error) {
      this.showError(
        "Error loading fields: " +
          (error?.body?.message || error?.message || "An unknown error occurred")
      );
    }
  }

  handleObjectChange(event) {
    this.selectedObject = event.detail.value;
    this.rowField = "";
    this.columnField = "";
    this.matrixData = {};
    this.matrixRows = [];
    this.matrixColumns = [];
  }

  handleRowFieldChange(event) {
    this.rowField = event.detail.value;
  }

  handleColumnFieldChange(event) {
    this.columnField = event.detail.value;
  }

  handleAggregateChange(event) {
    this.aggregateExpression = event.detail.value;
  }

  handleGenerate() {
    if (!this.canGenerate) {
      return;
    }

    this.isLoading = true;
    this.hasError = false;

    const config = {
      objectName: this.selectedObject,
      rowField: this.rowField,
      columnField: this.columnField,
      aggregateExpression: this.aggregateExpression,
      filters: "",
    };

    executeMatrixQuery({ configJson: JSON.stringify(config) })
      .then((result) => {
        this.matrixData = result.matrix;
        this.matrixRows = result.rows || [];
        this.matrixColumns = result.columns || [];
        // Pre-compute matrix display data
        this.computedMatrixData = this.computeMatrixDisplayData();
        this.isLoading = false;
        this.showSuccess("Matrix generated successfully");
      })
      .catch((error) => {
        this.hasError = true;
        this.errorMessage =
          "Error generating matrix: " +
          (error?.body?.message || error?.message || "An unknown error occurred");
        this.isLoading = false;
        this.showError(this.errorMessage);
      });
  }

  computeMatrixDisplayData() {
    if (!this.matrixData || !this.matrixRows || !this.matrixColumns) {
      return [];
    }

    return this.matrixRows.map((row) => {
      const rowData = {
        row: row,
        cells: this.matrixColumns.map((col) => {
          const value =
            this.matrixData[row] && this.matrixData[row][col]
              ? this.matrixData[row][col].toFixed(2)
              : "0.00";
          return { col: col, value: value };
        }),
        total: this.computeRowTotal(row),
      };
      return rowData;
    });
  }

  computeRowTotal(row) {
    if (this.matrixData && this.matrixData[row]) {
      let total = 0;
      for (let col of this.matrixColumns) {
        if (this.matrixData[row][col]) {
          total += this.matrixData[row][col];
        }
      }
      return total.toFixed(2);
    }
    return "0.00";
  }

  get canGenerate() {
    return (
      this.selectedObject &&
      this.rowField &&
      this.columnField &&
      this.aggregateExpression &&
      !this.isLoading
    );
  }

  get isButtonDisabled() {
    return this.isLoading || !this.canGenerate;
  }

  get notLoading() {
    return !this.isLoading;
  }

  get hasResults() {
    return this.matrixRows && this.matrixRows.length > 0;
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
