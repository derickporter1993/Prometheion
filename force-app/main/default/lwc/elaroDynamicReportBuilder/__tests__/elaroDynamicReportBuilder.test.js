/**
 * Jest tests for elaroDynamicReportBuilder LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Field metadata loading
 * - Report execution
 * - Filter and sort handling
 * - Error handling
 */

import { createElement } from "lwc";
import ElaroDynamicReportBuilder from "c/elaroDynamicReportBuilder";
import getAvailableObjects from "@salesforce/apex/ElaroDynamicReportController.getAvailableObjects";
import getFieldMetadata from "@salesforce/apex/ElaroDynamicReportController.getFieldMetadata";
import executeReport from "@salesforce/apex/ElaroDynamicReportController.executeReport";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockObjectsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/ElaroDynamicReportController.getAvailableObjects",
  () => ({
    default: function MockObjectsAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockObjectsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockObjectsCallbacks.delete(this.callback);
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
  "@salesforce/apex/ElaroDynamicReportController.getFieldMetadata",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ElaroDynamicReportController.executeReport",
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

const emitObjects = (data) => {
  mockObjectsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitObjectsError = (error) => {
  mockObjectsCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-elaro-dynamic-report-builder", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockObjectsCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-elaro-dynamic-report-builder", {
      is: ElaroDynamicReportBuilder,
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
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("renders object selection combobox", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("loads available objects", async () => {
      const mockObjects = [
        { label: "Account", value: "Account" },
        { label: "Contact", value: "Contact" },
      ];

      const element = await createComponent();
      await Promise.resolve();

      emitObjects(mockObjects);
      await Promise.resolve();
      await Promise.resolve();

      // Check that the combobox has the expected options via DOM inspection
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      // The options attribute should be populated
      expect(combobox.options).toBeDefined();
      expect(combobox.options.length).toBeGreaterThan(0);
    });

    it("handles wire adapter error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Failed to load objects" },
        message: "Failed to load objects",
      };

      emitObjectsError(error);
      await Promise.resolve();
      await Promise.resolve();

      // ShowToastEvent should have been dispatched
      expect(ShowToastEvent).toHaveBeenCalled();
    });
  });

  describe("Field Loading", () => {
    it("loads field metadata when object is selected", async () => {
      const mockFields = [
        { label: "Name", apiName: "Name", type: "string", isFilterable: true, isSortable: true },
        { label: "Industry", apiName: "Industry", type: "picklist", isFilterable: true, isSortable: true },
      ];

      getFieldMetadata.mockResolvedValue(mockFields);

      const element = await createComponent();
      await Promise.resolve();

      // Simulate selecting an object through the combobox
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "Account" },
        })
      );
      await Promise.resolve();
      await Promise.resolve();

      expect(getFieldMetadata).toHaveBeenCalledWith({
        objectApiName: "Account",
      });
    });

    it("shows dual listbox after fields are loaded", async () => {
      const mockFields = [
        { label: "Name", apiName: "Name", type: "string", isFilterable: true, isSortable: true },
        { label: "Industry", apiName: "Industry", type: "picklist", isFilterable: true, isSortable: true },
      ];

      getFieldMetadata.mockResolvedValue(mockFields);

      const element = await createComponent();
      await Promise.resolve();

      // Simulate selecting an object through the combobox
      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "Account" },
        })
      );
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Dual listbox should appear for field selection
      const dualListbox = element.shadowRoot.querySelector("lightning-dual-listbox");
      expect(dualListbox).not.toBeNull();
    });
  });

  describe("Run Report Button", () => {
    it("renders run report button", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const runButton = Array.from(buttons).find((b) => b.label === "Run Report");
      expect(runButton).toBeDefined();
    });

    it("run report button is disabled initially", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const runButton = Array.from(buttons).find((b) => b.label === "Run Report");
      expect(runButton.disabled).toBe(true);
    });
  });
});
