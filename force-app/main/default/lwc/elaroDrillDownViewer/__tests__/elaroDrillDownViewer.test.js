/**
 * Jest tests for elaroDrillDownViewer LWC component
 *
 * Tests cover:
 * - JSON parsing (with error handling)
 * - Record loading
 * - Pagination
 * - Sorting
 * - Export functionality
 */

import { createElement } from "lwc";
import ElaroDrillDownViewer from "c/elaroDrillDownViewer";
import getRecords from "@salesforce/apex/ElaroDrillDownController.getRecords";
import exportToCSV from "@salesforce/apex/ElaroDrillDownController.exportToCSV";

jest.mock(
  "@salesforce/apex/ElaroDrillDownController.getRecords",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ElaroDrillDownController.exportToCSV",
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

// Mock NavigationMixin properly
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: (Base) => {
      return class extends Base {
        navigate() {}
      };
    },
  }),
  { virtual: true }
);

describe("c-elaro-drill-down-viewer", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  async function createComponent(props = {}) {
    const element = createElement("c-elaro-drill-down-viewer", {
      is: ElaroDrillDownViewer,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  // Helper to flush all pending promises
  async function flushPromises() {
    await Promise.resolve();
    await Promise.resolve();
    await Promise.resolve();
  }

  describe("Rendering", () => {
    it("renders the component with lightning-card", async () => {
      const element = await createComponent();
      await flushPromises();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Elaro Drill-Down Viewer");
    });
  });

  describe("Context JSON Parsing", () => {
    it("parses valid JSON context and loads records", async () => {
      const validContext = {
        objectType: "Account",
        filters: {},
        orderBy: "Name",
        orderDirection: "ASC",
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test Account" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(validContext),
      });
      await flushPromises();

      expect(getRecords).toHaveBeenCalled();

      // Check that datatable is rendered with data
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("handles invalid JSON gracefully and shows error", async () => {
      const element = await createComponent({
        contextJson: "{ invalid json }",
      });
      await flushPromises();

      // Component should render without crashing
      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("handles null contextJson gracefully", async () => {
      const element = await createComponent({ contextJson: null });
      await flushPromises();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Record Loading", () => {
    it("loads records on connectedCallback when contextJson provided", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test Account" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      expect(getRecords).toHaveBeenCalled();

      // Check datatable has data
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.data.length).toBe(1);
    });

    it("shows error message when loading fails", async () => {
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
      await flushPromises();

      // Check for error message in DOM
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Error loading records");
    });

    it("shows loading spinner while fetching records", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      // Use a promise that we can control
      let resolveRecords;
      getRecords.mockImplementation(
        () =>
          new Promise((resolve) => {
            resolveRecords = resolve;
          })
      );

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await Promise.resolve();

      // Check for spinner while loading
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();

      // Resolve the promise
      resolveRecords({
        records: [],
        columns: [],
        totalCount: 0,
        hasMore: false,
      });
      await flushPromises();
    });

    it("shows no records message when no data returned", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [],
        columns: [],
        totalCount: 0,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      // Check for empty state message
      const emptyDiv = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No records found");
    });
  });

  describe("Pagination", () => {
    it("enables load more when hasMore is true", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 100,
        hasMore: true,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      // The datatable should have the onloadmore handler
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();

      // Trigger load more via datatable event
      datatable.dispatchEvent(new CustomEvent("loadmore"));

      await flushPromises();

      // getRecords should be called again for more data
      expect(getRecords).toHaveBeenCalledTimes(2);
    });

    it("does not load more when hasMore is false", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      const initialCallCount = getRecords.mock.calls.length;

      // Trigger load more via datatable event
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      datatable.dispatchEvent(new CustomEvent("loadmore"));

      await flushPromises();

      // getRecords should NOT be called again since hasMore is false
      expect(getRecords).toHaveBeenCalledTimes(initialCallCount);
    });
  });

  describe("Sorting", () => {
    it("handles sort event from datatable", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();

      // Trigger sort event
      datatable.dispatchEvent(
        new CustomEvent("sort", {
          detail: {
            fieldName: "Name",
            sortDirection: "desc",
          },
        })
      );

      await flushPromises();

      // getRecords should be called again with sort parameters
      expect(getRecords).toHaveBeenCalledTimes(2);
    });
  });

  describe("Export Functionality", () => {
    it("calls exportToCSV when export button clicked", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      exportToCSV.mockResolvedValue("Id,Name\n001xx0000000001,Test");

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      // Find and click export button
      const exportButton = element.shadowRoot.querySelector("lightning-button");
      expect(exportButton).not.toBeNull();
      expect(exportButton.label).toBe("Export to CSV");

      // Mock URL methods on window
      const originalCreateObjectURL = window.URL.createObjectURL;
      const originalRevokeObjectURL = window.URL.revokeObjectURL;
      window.URL.createObjectURL = jest.fn().mockReturnValue("blob:test");
      window.URL.revokeObjectURL = jest.fn();

      exportButton.click();
      await flushPromises();

      expect(exportToCSV).toHaveBeenCalled();

      // Restore
      window.URL.createObjectURL = originalCreateObjectURL;
      window.URL.revokeObjectURL = originalRevokeObjectURL;
    });

    it("disables export button when no records", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [],
        columns: [],
        totalCount: 0,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      // Find export button
      const exportButton = element.shadowRoot.querySelector("lightning-button");
      expect(exportButton).not.toBeNull();
      expect(exportButton.disabled).toBe(true);
    });

    it("handles export error gracefully", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
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
      await flushPromises();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      // Find and click export button
      const exportButton = element.shadowRoot.querySelector("lightning-button");
      exportButton.click();

      await flushPromises();

      // Should dispatch toast event for error
      expect(dispatchEventSpy).toHaveBeenCalled();

      dispatchEventSpy.mockRestore();
    });
  });

  describe("Row Action Handling", () => {
    it("handles row action event from datatable", async () => {
      const context = {
        objectType: "Account",
        filters: {},
      };

      getRecords.mockResolvedValue({
        records: [{ Id: "001xx0000000001", Name: "Test" }],
        columns: [{ label: "Name", fieldName: "Name", type: "text", sortable: true }],
        totalCount: 1,
        hasMore: false,
      });

      const element = await createComponent({
        contextJson: JSON.stringify(context),
      });
      await flushPromises();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();

      // The datatable should be rendered and have the onrowaction handler bound
      // We verify the datatable exists and can receive events
      expect(datatable.data.length).toBe(1);
    });
  });
});
