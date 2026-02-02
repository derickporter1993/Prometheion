/**
 * Jest tests for reportSchedulerConfig LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Scheduled reports display
 */

import { createElement } from "lwc";
import ReportSchedulerConfig from "c/reportSchedulerConfig";
import { safeCleanupDom } from "../../__tests__/wireAdapterTestUtils";

// Wire adapter callbacks - must be declared before jest.mock (which is hoisted)
let mockScheduledReportsCallbacks = new Set();

// Mock wire adapter for getScheduledReports
jest.mock(
  "@salesforce/apex/ComplianceReportScheduler.getScheduledReports",
  () => ({
    default: function MockScheduledReportsAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockScheduledReportsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockScheduledReportsCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve([]);
    },
  }),
  { virtual: true }
);

// Mock imperative Apex methods
jest.mock(
  "@salesforce/apex/ComplianceReportScheduler.scheduleReport",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ComplianceReportScheduler.cancelScheduledReport",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/ComplianceReportScheduler.sendTestReport",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Wire adapter emit helper
const emitScheduledReports = (data) => {
  mockScheduledReportsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const resetWireCallbacks = () => {
  mockScheduledReportsCallbacks = new Set();
};

// Mock ShowToastEvent
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

const MOCK_SCHEDULED_REPORTS = [
  {
    jobId: "08e000000000001",
    name: "Prometheion WEEKLY Report - ALL - 20240115120000",
    frequency: "WEEKLY",
    framework: "ALL",
    nextRun: "2024-01-22T08:00:00.000Z",
    status: "WAITING",
    cronExpression: "0 0 8 ? * MON",
  },
  {
    jobId: "08e000000000002",
    name: "Prometheion DAILY Report - HIPAA - 20240110090000",
    frequency: "DAILY",
    framework: "HIPAA",
    nextRun: "2024-01-16T08:00:00.000Z",
    status: "WAITING",
    cronExpression: "0 0 8 * * ?",
  },
];

describe("c-report-scheduler-config", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    resetWireCallbacks();
  });

  afterEach(() => {
    safeCleanupDom();
  });

  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  async function createComponent(reports = []) {
    const element = createElement("c-report-scheduler-config", {
      is: ReportSchedulerConfig,
    });
    document.body.appendChild(element);
    await flushPromises();

    emitScheduledReports(reports);
    await flushPromises();

    return element;
  }

  describe("Initial Rendering", () => {
    it("renders lightning-card with correct title", async () => {
      const element = await createComponent([]);

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Compliance Report Scheduler");
    });

    it("displays empty state when no scheduled reports exist", async () => {
      const element = await createComponent([]);

      const heading = element.shadowRoot.querySelector(".slds-text-heading_medium");
      expect(heading).not.toBeNull();
      expect(heading.textContent).toBe("No Scheduled Reports");
    });

    it("displays scheduled reports in datatable", async () => {
      const element = await createComponent(MOCK_SCHEDULED_REPORTS);

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("shows info section about report delivery", async () => {
      const element = await createComponent([]);

      const infoBox = element.shadowRoot.querySelector(".slds-box.slds-theme_shade");
      expect(infoBox).not.toBeNull();
      expect(infoBox.textContent).toContain("Report Delivery");
    });

    it("renders button group in card actions", async () => {
      const element = await createComponent([]);

      const buttonGroup = element.shadowRoot.querySelector("lightning-button-group");
      expect(buttonGroup).not.toBeNull();
    });
  });

  describe("Data Display", () => {
    it("passes data to datatable when reports exist", async () => {
      const element = await createComponent(MOCK_SCHEDULED_REPORTS);

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
      expect(datatable.data).not.toBeNull();
    });

    it("hides empty state when reports exist", async () => {
      const element = await createComponent(MOCK_SCHEDULED_REPORTS);

      const emptyStateHeading = element.shadowRoot.querySelector(".slds-text-heading_medium");
      expect(emptyStateHeading).toBeNull();
    });

    it("shows empty state when no reports", async () => {
      const element = await createComponent([]);

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).toBeNull();

      const emptyStateHeading = element.shadowRoot.querySelector(".slds-text-heading_medium");
      expect(emptyStateHeading).not.toBeNull();
    });
  });
});
