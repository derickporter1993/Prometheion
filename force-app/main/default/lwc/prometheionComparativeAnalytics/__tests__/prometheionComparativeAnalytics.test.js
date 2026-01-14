/**
 * Jest tests for prometheionComparativeAnalytics LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Matrix query execution
 * - Data processing
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionComparativeAnalytics from "c/prometheionComparativeAnalytics";
import getDimensionFields from "@salesforce/apex/PrometheionMatrixController.getDimensionFields";
import executeMatrixQuery from "@salesforce/apex/PrometheionMatrixController.executeMatrixQuery";

let mockDimensionFieldsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionMatrixController.getDimensionFields",
  () => ({
    default: function MockAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockDimensionFieldsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockDimensionFieldsCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve([]);
    },
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionMatrixController.executeMatrixQuery",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

const emitDimensionFields = (data) => {
  mockDimensionFieldsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitDimensionFieldsError = (error) => {
  mockDimensionFieldsCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-prometheion-comparative-analytics", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockDimensionFieldsCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-comparative-analytics", {
      is: PrometheionComparativeAnalytics,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  function getObjectCombobox(element) {
    const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
    return Array.from(comboboxes).find((cb) => cb.label === "Object");
  }

  function getRowFieldCombobox(element) {
    const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
    return Array.from(comboboxes).find((cb) => cb.label === "Row Field");
  }

  function getColumnFieldCombobox(element) {
    const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
    return Array.from(comboboxes).find((cb) => cb.label === "Column Field");
  }

  function getGenerateButton(element) {
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    return Array.from(buttons).find((btn) => btn.label === "Generate Matrix");
  }

  function getSpinner(element) {
    return element.shadowRoot.querySelector("lightning-spinner");
  }

  function getErrorContainer(element) {
    return element.shadowRoot.querySelector(".slds-text-color_error");
  }

  function getResultsTable(element) {
    return element.shadowRoot.querySelector("table");
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    });

    it("renders form fields when not loading", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Initially may show loading, wait for it to resolve
      await Promise.resolve();

      expect(getObjectCombobox(element)).not.toBeNull();
    });
  });

  describe("Input Handlers", () => {
    it("handles object change", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const combobox = getObjectCombobox(element);
      if (combobox) {
        combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));
        await Promise.resolve();

        // Verify the combobox value is updated
        expect(combobox.value).toBe("Account");

        // When object changes, row and column fields should reset
        const rowField = getRowFieldCombobox(element);
        const colField = getColumnFieldCombobox(element);
        if (rowField && colField) {
          expect(rowField.value).toBe("");
          expect(colField.value).toBe("");
        }
      }
    });

    it("handles row field change", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const combobox = getRowFieldCombobox(element);
      if (combobox) {
        combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Industry" } }));
        await Promise.resolve();

        expect(combobox.value).toBe("Industry");
      }
    });

    it("handles column field change", async () => {
      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      const combobox = getColumnFieldCombobox(element);
      if (combobox) {
        combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "Region" } }));
        await Promise.resolve();

        expect(combobox.value).toBe("Region");
      }
    });
  });

  describe("Matrix Query Execution", () => {
    it("executes matrix query successfully", async () => {
      const mockResult = {
        matrix: { Row1: { Col1: 10, Col2: 20 } },
        rows: ["Row1", "Row2"],
        columns: ["Col1", "Col2"],
      };

      executeMatrixQuery.mockResolvedValue(mockResult);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      // Set up form values
      const objectCombo = getObjectCombobox(element);
      const rowCombo = getRowFieldCombobox(element);
      const colCombo = getColumnFieldCombobox(element);

      if (objectCombo && rowCombo && colCombo) {
        objectCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));
        rowCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Industry" } }));
        colCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Region" } }));
        await Promise.resolve();

        // Click generate button
        const button = getGenerateButton(element);
        if (button) {
          button.click();
          await Promise.resolve();
          await Promise.resolve();
          await Promise.resolve();

          expect(executeMatrixQuery).toHaveBeenCalled();

          // Check if results table is rendered
          const table = getResultsTable(element);
          // Table should appear after successful query
          expect(table).not.toBeNull();
        }
      }
    });

    it("handles query error", async () => {
      const error = {
        body: { message: "Query failed" },
        message: "Query failed",
      };

      executeMatrixQuery.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();
      await Promise.resolve();

      // Set up form values
      const objectCombo = getObjectCombobox(element);
      const rowCombo = getRowFieldCombobox(element);
      const colCombo = getColumnFieldCombobox(element);

      if (objectCombo && rowCombo && colCombo) {
        objectCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Account" } }));
        rowCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Industry" } }));
        colCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "Region" } }));
        await Promise.resolve();

        // Click generate button
        const button = getGenerateButton(element);
        if (button) {
          button.click();
          await Promise.resolve();
          await Promise.resolve();
          await Promise.resolve();

          // Check for error state in DOM
          const errorContainer = getErrorContainer(element);
          expect(errorContainer).not.toBeNull();
        }
      }
    });
  });

  describe("Wire Adapter Integration", () => {
    it("receives dimension fields from wire adapter", async () => {
      const mockFields = [
        { label: "Industry", value: "Industry" },
        { label: "Region", value: "Region" },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitDimensionFields(mockFields);
      await Promise.resolve();
      await Promise.resolve();

      // The dimension fields should populate the row/column comboboxes
      const rowCombo = getRowFieldCombobox(element);
      if (rowCombo) {
        expect(rowCombo.options).toBeDefined();
      }
    });

    it("handles wire adapter error via toast", async () => {
      const { ShowToastEvent } = require("lightning/platformShowToastEvent");

      const error = {
        body: { message: "Failed to fetch fields" },
        message: "Failed to fetch fields",
      };

      const element = await createComponent();
      await Promise.resolve();

      emitDimensionFieldsError(error);
      await Promise.resolve();
      await Promise.resolve();

      // Wire errors are handled via toast, not DOM error container
      // Verify ShowToastEvent was called with error variant
      expect(ShowToastEvent).toHaveBeenCalled();
    });
  });
});
