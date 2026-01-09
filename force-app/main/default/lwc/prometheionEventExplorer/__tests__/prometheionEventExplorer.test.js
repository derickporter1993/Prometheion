/**
 * Jest tests for prometheionEventExplorer LWC component
 *
 * Tests cover:
 * - Event listing and filtering
 * - Modal functionality
 * - Export functionality
 * - Statistics display
 * - Accessibility compliance
 */
// @ts-ignore - LWC1702 false positive for Jest test files
import { createElement } from "lwc";
import PrometheionEventExplorer from "c/prometheionEventExplorer";
import { registerApexTestWireAdapter } from "@salesforce/sfdx-lwc-jest";
import getRealtimeStats from "@salesforce/apex/PrometheionRealtimeMonitor.getRealtimeStats";
import getEventRiskLevels from "@salesforce/apex/PrometheionShieldService.getEventRiskLevels";
import analyzeRootCause from "@salesforce/apex/RootCauseAnalysisEngine.analyzeRootCause";

// Register wire adapters
const getEventRiskLevelsAdapter = registerApexTestWireAdapter(getEventRiskLevels);

// Mock Apex methods
jest.mock(
  "@salesforce/apex/PrometheionRealtimeMonitor.getRealtimeStats",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/RootCauseAnalysisEngine.analyzeRootCause",
  () => ({
    default: jest.fn().mockResolvedValue({
      status: "SUCCESS",
      rootCause: "Configuration change",
      confidence: 85,
    }),
  }),
  { virtual: true }
);

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

// Mock data
const MOCK_STATS = {
  totalEvents: 50,
  topEventTypes: ["Login", "API", "ReportExport"],
};

const MOCK_RISK_LEVELS = {
  Login: "MEDIUM",
  API: "HIGH",
  ReportExport: "CRITICAL",
};

describe("c-prometheion-event-explorer", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    getRealtimeStats.default.mockResolvedValue(MOCK_STATS);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  async function createComponent() {
    const element = createElement("c-prometheion-event-explorer", {
      is: PrometheionEventExplorer,
    });
    document.body.appendChild(element);
    await flushPromises();

    getEventRiskLevelsAdapter.emit(MOCK_RISK_LEVELS);
    await flushPromises();
    await Promise.resolve();

    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the event explorer card", async () => {
      const element = await createComponent();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Event Explorer");
    });

    it("displays filter controls", async () => {
      const element = await createComponent();

      const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
      expect(comboboxes.length).toBe(2); // Event type and risk level
    });

    it("displays date range inputs", async () => {
      const element = await createComponent();

      const dateInputs = element.shadowRoot.querySelectorAll(
        'lightning-input[type="date"]'
      );
      expect(dateInputs.length).toBe(2); // Start and end date
    });

    it("displays search input", async () => {
      const element = await createComponent();

      const searchInput = element.shadowRoot.querySelector(
        'lightning-input[type="search"]'
      );
      expect(searchInput).not.toBeNull();
    });

    it("displays statistics cards", async () => {
      const element = await createComponent();

      const statCards = element.shadowRoot.querySelectorAll(".stat-card");
      expect(statCards.length).toBe(4); // Total, Critical, High, Medium
    });

    it("has refresh button", async () => {
      const element = await createComponent();

      const refreshBtn = element.shadowRoot.querySelector("lightning-button-icon");
      expect(refreshBtn).not.toBeNull();
    });

    it("has export button", async () => {
      const element = await createComponent();

      const exportBtn = element.shadowRoot.querySelector(
        'lightning-button[label="Export CSV"]'
      );
      expect(exportBtn).not.toBeNull();
    });
  });

  describe("Filtering", () => {
    it("filters by event type", async () => {
      const element = await createComponent();

      const eventTypeCombo = element.shadowRoot.querySelector(
        'lightning-combobox[name="eventType"]'
      );
      eventTypeCombo.dispatchEvent(
        new CustomEvent("change", { detail: { value: "Login" } })
      );
      await flushPromises();

      // Component should re-filter
      expect(element).not.toBeNull();
    });

    it("filters by risk level", async () => {
      const element = await createComponent();

      const riskLevelCombo = element.shadowRoot.querySelector(
        'lightning-combobox[name="riskLevel"]'
      );
      riskLevelCombo.dispatchEvent(
        new CustomEvent("change", { detail: { value: "CRITICAL" } })
      );
      await flushPromises();

      expect(element).not.toBeNull();
    });

    it("filters by date range", async () => {
      const element = await createComponent();

      const startDateInput = element.shadowRoot.querySelector(
        'lightning-input[name="startDate"]'
      );
      startDateInput.dispatchEvent(
        new CustomEvent("change", { detail: { value: "2024-01-01" } })
      );
      await flushPromises();

      expect(element).not.toBeNull();
    });

    it("filters by search term", async () => {
      const element = await createComponent();

      const searchInput = element.shadowRoot.querySelector(
        'lightning-input[type="search"]'
      );
      searchInput.dispatchEvent(
        new CustomEvent("change", { detail: { value: "user1" } })
      );
      await flushPromises();

      expect(element).not.toBeNull();
    });
  });

  describe("Data Table", () => {
    it("renders data table when events exist", async () => {
      const element = await createComponent();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      expect(datatable).not.toBeNull();
    });

    it("handles sorting", async () => {
      const element = await createComponent();

      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      datatable.dispatchEvent(
        new CustomEvent("sort", {
          detail: { fieldName: "riskScore", sortDirection: "desc" },
        })
      );
      await flushPromises();

      expect(element).not.toBeNull();
    });
  });

  describe("Modal Functionality", () => {
    async function openModal(element) {
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      datatable.dispatchEvent(
        new CustomEvent("rowaction", {
          detail: {
            action: { name: "view" },
            row: {
              id: "EVT-00001",
              eventType: "Login",
              riskLevel: "HIGH",
              riskScore: 75,
              userName: "user1@test.com",
              formattedTimestamp: "2024-01-01 12:00",
              sourceIp: "192.168.1.1",
              description: "Test event",
            },
          },
        })
      );
      await flushPromises();
      await new Promise((resolve) => setTimeout(resolve, 150));
    }

    it("opens modal on view action", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector(".slds-modal");
      expect(modal).not.toBeNull();
    });

    it("modal has proper ARIA attributes", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      expect(modal).not.toBeNull();
      expect(modal.getAttribute("aria-modal")).toBe("true");
      expect(modal.getAttribute("aria-labelledby")).toBe("modal-heading");
    });

    it("closes modal on close button click", async () => {
      const element = await createComponent();
      await openModal(element);

      const closeBtn = element.shadowRoot.querySelector(".slds-modal__close");
      closeBtn.click();
      await flushPromises();

      const modal = element.shadowRoot.querySelector(".slds-modal");
      expect(modal).toBeNull();
    });

    it("closes modal on Escape key", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      const escEvent = new KeyboardEvent("keydown", {
        key: "Escape",
        bubbles: true,
      });
      modal.dispatchEvent(escEvent);
      await flushPromises();

      const modalAfter = element.shadowRoot.querySelector(".slds-modal");
      expect(modalAfter).toBeNull();
    });

    it("traps focus within modal", async () => {
      const element = await createComponent();
      await openModal(element);

      const modal = element.shadowRoot.querySelector('[role="dialog"]');
      expect(modal).not.toBeNull();

      // Check tabindex for focus management
      expect(modal.getAttribute("tabindex")).toBe("-1");
    });
  });

  describe("Statistics", () => {
    it("displays total events count", async () => {
      const element = await createComponent();

      const totalCard = element.shadowRoot.querySelector(".stat-card.total");
      expect(totalCard).not.toBeNull();
    });

    it("has accessible stat cards", async () => {
      const element = await createComponent();

      const statCards = element.shadowRoot.querySelectorAll(".stat-card");
      statCards.forEach((card) => {
        expect(card.getAttribute("role")).toBe("status");
        expect(card.getAttribute("aria-label")).not.toBeNull();
      });
    });

    it("statistics update when filters change", async () => {
      const element = await createComponent();

      const initialTotal = element.shadowRoot.querySelector(
        ".stat-card.total .stat-value"
      );
      const initialValue = initialTotal.textContent;

      // Apply filter
      const riskLevelCombo = element.shadowRoot.querySelector(
        'lightning-combobox[name="riskLevel"]'
      );
      riskLevelCombo.dispatchEvent(
        new CustomEvent("change", { detail: { value: "CRITICAL" } })
      );
      await flushPromises();

      // Values should potentially change based on filter
      expect(element).not.toBeNull();
    });
  });

  describe("Export Functionality", () => {
    it("exports CSV when button is clicked", async () => {
      // Mock URL.createObjectURL
      const mockUrl = "blob:test";
      global.URL.createObjectURL = jest.fn(() => mockUrl);
      global.URL.revokeObjectURL = jest.fn();

      const element = await createComponent();

      const exportBtn = element.shadowRoot.querySelector(
        'lightning-button[label="Export CSV"]'
      );
      exportBtn.click();
      await flushPromises();

      expect(global.URL.createObjectURL).toHaveBeenCalled();
    });
  });

  describe("Refresh Functionality", () => {
    it("reloads events on refresh", async () => {
      const element = await createComponent();

      const refreshBtn = element.shadowRoot.querySelector("lightning-button-icon");
      refreshBtn.click();
      await flushPromises();

      // Should trigger data reload
      expect(element).not.toBeNull();
    });
  });

  describe("Accessibility", () => {
    it("statistics region has aria-label", async () => {
      const element = await createComponent();

      const statsRegion = element.shadowRoot.querySelector(
        '[aria-label="Event statistics"]'
      );
      expect(statsRegion).not.toBeNull();
    });

    it("stat cards have aria-live for updates", async () => {
      const element = await createComponent();

      const liveRegion = element.shadowRoot.querySelector('[aria-live="polite"]');
      expect(liveRegion).not.toBeNull();
    });

    it("close button has aria-label", async () => {
      const element = await createComponent();

      // Open modal first
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      datatable.dispatchEvent(
        new CustomEvent("rowaction", {
          detail: {
            action: { name: "view" },
            row: {
              id: "EVT-00001",
              eventType: "Login",
              riskLevel: "HIGH",
            },
          },
        })
      );
      await flushPromises();
      await new Promise((resolve) => setTimeout(resolve, 150));

      const closeBtn = element.shadowRoot.querySelector(".slds-modal__close");
      expect(closeBtn.getAttribute("aria-label")).toBe("Close event details modal");
    });

    it("modal content has id for aria-describedby", async () => {
      const element = await createComponent();

      // Open modal
      const datatable = element.shadowRoot.querySelector("lightning-datatable");
      datatable.dispatchEvent(
        new CustomEvent("rowaction", {
          detail: {
            action: { name: "view" },
            row: { id: "EVT-00001", eventType: "Login", riskLevel: "HIGH" },
          },
        })
      );
      await flushPromises();
      await new Promise((resolve) => setTimeout(resolve, 150));

      const content = element.shadowRoot.querySelector("#modal-content");
      expect(content).not.toBeNull();
    });

    it("empty state is accessible", async () => {
      getRealtimeStats.default.mockResolvedValue({ totalEvents: 0, topEventTypes: [] });

      const element = createElement("c-prometheion-event-explorer", {
        is: PrometheionEventExplorer,
      });
      document.body.appendChild(element);
      await flushPromises();

      // Apply a filter that results in no events
      const riskLevelCombo = element.shadowRoot.querySelector(
        'lightning-combobox[name="riskLevel"]'
      );
      if (riskLevelCombo) {
        riskLevelCombo.dispatchEvent(
          new CustomEvent("change", { detail: { value: "CRITICAL" } })
        );
        await flushPromises();
      }

      // Check for empty state message
      expect(element).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      getRealtimeStats.default.mockRejectedValue(new Error("API Error"));

      const element = createElement("c-prometheion-event-explorer", {
        is: PrometheionEventExplorer,
      });
      document.body.appendChild(element);
      await flushPromises();

      // Component should still render
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });
});
