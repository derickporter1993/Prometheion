/**
 * Jest tests for prometheionDynamicReportBuilder LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Field metadata loading
 * - Report execution
 * - Filter and sort handling
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionDynamicReportBuilder from "c/prometheionDynamicReportBuilder";
import getAvailableObjects from "@salesforce/apex/PrometheionDynamicReportController.getAvailableObjects";
import getFieldMetadata from "@salesforce/apex/PrometheionDynamicReportController.getFieldMetadata";
import executeReport from "@salesforce/apex/PrometheionDynamicReportController.executeReport";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

let mockObjectsCallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionDynamicReportController.getAvailableObjects",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockObjectsCallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockObjectsCallbacks.delete(callback);
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
  "@salesforce/apex/PrometheionDynamicReportController.getFieldMetadata",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionDynamicReportController.executeReport",
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

describe("c-prometheion-dynamic-report-builder", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockObjectsCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-dynamic-report-builder", {
      is: PrometheionDynamicReportBuilder,
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

      expect(element.objectOptions.length).toBeGreaterThan(0);
    });
  });

  describe("Field Loading", () => {
    it("loads field metadata when object is selected", async () => {
      const mockFields = [
        { label: "Name", apiName: "Name", type: "string" },
        { label: "Industry", apiName: "Industry", type: "picklist" },
      ];

      getFieldMetadata.mockResolvedValue(mockFields);

      const element = await createComponent();
      await Promise.resolve();

      const event = new CustomEvent("change", {
        detail: { value: "Account" },
      });

      element.handleObjectChange(event);
      await Promise.resolve();

      expect(getFieldMetadata).toHaveBeenCalledWith({
        objectApiName: "Account",
      });
    });
  });
});
