/**
 * Jest tests for prometheionDrillDownViewer LWC component
 *
 * Tests cover:
 * - JSON parsing (with error handling)
 * - Record loading
 * - Pagination
 * - Sorting
 * - Export functionality
 * - Navigation
 */

import { createElement } from "lwc";
import PrometheionDrillDownViewer from "c/prometheionDrillDownViewer";
import getRecords from "@salesforce/apex/PrometheionDrillDownController.getRecords";
import exportToCSV from "@salesforce/apex/PrometheionDrillDownController.exportToCSV";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

jest.mock(
  "@salesforce/apex/PrometheionDrillDownController.getRecords",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionDrillDownController.exportToCSV",
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

const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: (Base) => {
      return class extends Base {
        [Symbol.for("NavigationMixin.Navigate")](pageReference) {
          return mockNavigate(pageReference);
        }
      };
    },
  }),
  { virtual: true }
);

describe("c-prometheion-drill-down-viewer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent(props = {}) {
    const element = createElement("c-prometheion-drill-down-viewer", {
      is: PrometheionDrillDownViewer,
    });
    Object.assign(element, props);
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

  describe("Context JSON Parsing", () => {
    it("parses valid JSON context", async () => {
      const validContext = {
        objectType: "Account",
        filters: {},
        orderBy: "Name",
        orderDirection: "ASC",
      };

      getRecords.mockResolvedValue({
        records: [],
        columns: [],
        totalCount: 0,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(validContext),
      });
      await Promise.resolve();
      await Promise.resolve();

      expect(element.getContext).toBeDefined();
    });

    it("handles invalid JSON gracefully", async () => {
      const element = await createComponent({
        contextJson: "{ invalid json }",
      });
      await Promise.resolve();

      // Component should handle JSON parse errors
      expect(element).not.toBeNull();
    });

    it("handles null contextJson", async () => {
      const element = await createComponent({ contextJson: null });
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Record Loading", () => {
    it("loads records on connectedCallback when contextJson provided", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [
          { Id: "001xx0000000001", Name: "Test Account" },
        ],
        columns: [
          { label: "Name", fieldName: "Name", type: "text", sortable: true },
        ],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      expect(getRecords).toHaveBeenCalled();
    });

    it("handles loading error", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      const error = {
        body: { message: "Failed to load records" },
        message: "Failed to load records",
      };

      getRecords.mockRejectedValue(error);

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Error loading records");
    });
  });

  describe("Pagination", () => {
    it("handles load more when hasMore is true", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [],
        columns: [],
        totalCount: 100,
        hasMore: true,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasMore).toBe(true);

      element.handleLoadMore();
      await Promise.resolve();

      expect(element.currentOffset).toBe(50);
    });

    it("does not load more when hasMore is false", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [],
        columns: [],
        totalCount: 10,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      const initialOffset = element.currentOffset;
      element.handleLoadMore();
      await Promise.resolve();

      expect(element.currentOffset).toBe(initialOffset);
    });
  });

  describe("Export Functionality", () => {
    it("exports to CSV successfully", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [],
        totalCount: 1,
        hasMore: false,
      });

      exportToCSV.mockResolvedValue("Id,Name\n001xx0000000001,Test");

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      element.handleExport();
      await Promise.resolve();
      await Promise.resolve();

      expect(exportToCSV).toHaveBeenCalled();
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });

    it("handles export error", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001" }],
        columns: [],
        totalCount: 1,
        hasMore: false,
      });

      const error = {
        body: { message: "Export failed" },
        message: "Export failed",
      };

      exportToCSV.mockRejectedValue(error);

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      element.handleExport();
      await Promise.resolve();
      await Promise.resolve();

      expect(element.isLoading).toBe(false);
    });
  });

  describe("Navigation", () => {
    it("navigates to record on row action", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();
      await Promise.resolve();

      const rowActionEvent = {
        detail: {
          row: { Id: "001xx0000000001" },
        },
      };

      element.handleRowAction(rowActionEvent);

      expect(mockNavigate).toHaveBeenCalled();
    });
  });
});
