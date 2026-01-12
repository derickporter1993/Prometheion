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
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockDimensionFieldsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionMatrixController.getDimensionFields",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockDimensionFieldsCallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockDimensionFieldsCallbacks.delete(callback);
          },
          update: () => {},
        };
      }
      return Promise.resolve([]);
    }),
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

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Input Handlers", () => {
    it("handles object change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "Account" },
      });

      element.handleObjectChange(event);

      expect(element.selectedObject).toBe("Account");
      expect(element.rowField).toBe("");
      expect(element.columnField).toBe("");
    });

    it("handles row field change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "Industry" },
      });

      element.handleRowFieldChange(event);

      expect(element.rowField).toBe("Industry");
    });

    it("handles column field change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "Region" },
      });

      element.handleColumnFieldChange(event);

      expect(element.columnField).toBe("Region");
    });
  });

  describe("Matrix Query Execution", () => {
    it("executes matrix query successfully", async () => {
      const mockResult = {
        matrix: {},
        rows: ["Row1", "Row2"],
        columns: ["Col1", "Col2"],
      };

      executeMatrixQuery.mockResolvedValue(mockResult);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "Account";
      element.rowField = "Industry";
      element.columnField = "Region";

      element.handleGenerate();
      await Promise.resolve();
      await Promise.resolve();

      expect(executeMatrixQuery).toHaveBeenCalled();
      expect(element.matrixData).toEqual(mockResult.matrix);
    });

    it("handles query error", async () => {
      const error = {
        body: { message: "Query failed" },
        message: "Query failed",
      };

      executeMatrixQuery.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      element.selectedObject = "Account";
      element.rowField = "Industry";
      element.columnField = "Region";

      element.handleGenerate();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
    });
  });
});
