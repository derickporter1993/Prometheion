/**
 * Jest tests for aiGovernanceDashboard LWC component
 *
 * Tests cover:
 * - Loading state rendering
 * - Error state rendering
 * - Dashboard summary display with stat cards
 * - Wire adapter for registered systems
 * - Discovery flow (imperative call)
 * - Refresh and sort interactions
 * - Empty states for registry, gaps, and audit trail
 */

import { createElement } from "lwc";
import AiGovernanceDashboard from "c/aiGovernanceDashboard";
import getRegisteredSystems from "@salesforce/apex/AIGovernanceController.getRegisteredSystems";

// --- Mutable state for imperative mocks (read at call-time inside factory closures) ---
let mockSummaryResult = null;
let mockSummaryError = null;
let mockAuditResult = null;
let mockAuditError = null;
let mockDiscoverResult = null;
let mockDiscoverError = null;
let mockRegisterResult = null;
let mockRegisterError = null;

// --- Wire adapter mock for getRegisteredSystems (the only @wire) ---
jest.mock(
  "@salesforce/apex/AIGovernanceController.getRegisteredSystems",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// --- Imperative mocks using closure-captured let variables ---
jest.mock(
  "@salesforce/apex/AIGovernanceController.getGovernanceSummary",
  () => ({
    default: jest.fn(() => {
      if (mockSummaryError) return Promise.reject(mockSummaryError);
      return Promise.resolve(mockSummaryResult);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIGovernanceController.getAIAuditTrail",
  () => ({
    default: jest.fn(() => {
      if (mockAuditError) return Promise.reject(mockAuditError);
      return Promise.resolve(mockAuditResult);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIGovernanceController.discoverAISystems",
  () => ({
    default: jest.fn(() => {
      if (mockDiscoverError) return Promise.reject(mockDiscoverError);
      return Promise.resolve(mockDiscoverResult);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIGovernanceController.registerAISystem",
  () => ({
    default: jest.fn(() => {
      if (mockRegisterError) return Promise.reject(mockRegisterError);
      return Promise.resolve(mockRegisterResult);
    }),
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/AIGovernanceController.updateRiskLevel",
  () => ({ default: jest.fn(() => Promise.resolve()) }),
  { virtual: true }
);

// --- refreshApex mock ---
jest.mock("@salesforce/apex", () => ({ refreshApex: jest.fn().mockResolvedValue(undefined) }), {
  virtual: true,
});

// --- ShowToastEvent mock ---
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("lightning__showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

// --- Custom label mocks (inline to avoid jest.mock scoping restriction) ---
jest.mock(
  "@salesforce/label/c.AI_DiscoveryInProgress",
  () => ({ default: "AI_DiscoveryInProgress" }),
  { virtual: true }
);
jest.mock("@salesforce/label/c.AI_DiscoveryComplete", () => ({ default: "AI_DiscoveryComplete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_NoSystemsFound", () => ({ default: "AI_NoSystemsFound" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_RiskUnacceptable", () => ({ default: "AI_RiskUnacceptable" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_RiskHigh", () => ({ default: "AI_RiskHigh" }), { virtual: true });
jest.mock("@salesforce/label/c.AI_RiskLimited", () => ({ default: "AI_RiskLimited" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_RiskMinimal", () => ({ default: "AI_RiskMinimal" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_RegisterSystem", () => ({ default: "AI_RegisterSystem" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_ComplianceScore", () => ({ default: "AI_ComplianceScore" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_TotalSystems", () => ({ default: "AI_TotalSystems" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_HighRiskSystems", () => ({ default: "AI_HighRiskSystems" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_GapsIdentified", () => ({ default: "AI_GapsIdentified" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_EUAIAct", () => ({ default: "AI_EUAIAct" }), { virtual: true });
jest.mock("@salesforce/label/c.AI_NISTRMF", () => ({ default: "AI_NISTRMF" }), { virtual: true });
jest.mock("@salesforce/label/c.AI_RefreshData", () => ({ default: "AI_RefreshData" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_ErrorGeneric", () => ({ default: "AI_ErrorGeneric" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_DashboardTitle", () => ({ default: "AI_DashboardTitle" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_DiscoverSystems", () => ({ default: "AI_DiscoverSystems" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_SystemRegistry", () => ({ default: "AI_SystemRegistry" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_NoGaps", () => ({ default: "AI_NoGaps" }), { virtual: true });
jest.mock("@salesforce/label/c.AI_AuditTrail", () => ({ default: "AI_AuditTrail" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AI_NoAuditEntries", () => ({ default: "AI_NoAuditEntries" }), {
  virtual: true,
});

// --- Test data ---
const MOCK_SUMMARY = {
  complianceScore: 72,
  totalSystems: 5,
  highRiskCount: 2,
  lastScanDate: "2026-03-01T00:00:00.000Z",
  gaps: [
    {
      id: "gap1",
      severity: "High",
      controlName: "Bias Testing",
      description: "No bias testing performed",
      recommendation: "Implement bias testing framework",
    },
  ],
};

const MOCK_AUDIT_TRAIL = [
  {
    actionType: "Risk Update",
    section: "AI Registry",
    changedBy: "Admin User",
    severity: "HIGH",
    display: "Risk level changed to High",
    changeDate: "2026-03-10T12:00:00.000Z",
  },
];

const MOCK_REGISTERED_SYSTEMS = [
  {
    Id: "a01xx000000001",
    Name: "Einstein Bot",
    System_Type__c: "Chatbot",
    Risk_Level__c: "High",
    Status__c: "Active",
    Detection_Method__c: "Manual",
  },
  {
    Id: "a01xx000000002",
    Name: "Prediction Builder",
    System_Type__c: "ML Model",
    Risk_Level__c: "Minimal",
    Status__c: "Active",
    Detection_Method__c: "Auto-Discovery",
  },
];

// --- Utility ---
const flushPromises = () => new Promise(process.nextTick);

/**
 * Creates the component with default successful mock data,
 * waits for async connectedCallback, and emits wire data.
 */
async function createLoadedComponent(opts = {}) {
  const {
    summary = MOCK_SUMMARY,
    auditTrail = MOCK_AUDIT_TRAIL,
    systems = MOCK_REGISTERED_SYSTEMS,
  } = opts;

  mockSummaryResult = summary;
  mockSummaryError = null;
  mockAuditResult = auditTrail;
  mockAuditError = null;

  const element = createElement("c-ai-governance-dashboard", {
    is: AiGovernanceDashboard,
  });
  document.body.appendChild(element);

  // Wait for connectedCallback async work to resolve
  await flushPromises();

  // Emit wire adapter data for registered systems
  getRegisteredSystems.emit(systems);

  // Wait for re-render after state changes
  await flushPromises();

  return element;
}

function findButton(element, labelText) {
  const buttons = element.shadowRoot.querySelectorAll("lightning-button");
  return Array.from(buttons).find((b) => b.label === labelText);
}

describe("c-ai-governance-dashboard", () => {
  beforeEach(() => {
    // Reset mock state before each test
    mockSummaryResult = null;
    mockSummaryError = null;
    mockAuditResult = null;
    mockAuditError = null;
    mockDiscoverResult = null;
    mockDiscoverError = null;
    mockRegisterResult = null;
    mockRegisterError = null;
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  // ---------- Loading State ----------

  describe("Loading State", () => {
    it("shows a spinner while data is loading", async () => {
      // Leave mock results as null so the promise never resolves meaningfully
      // but the component is still in loading state initially
      mockSummaryResult = new Promise(() => {}); // never resolves
      mockAuditResult = [];

      const element = createElement("c-ai-governance-dashboard", {
        is: AiGovernanceDashboard,
      });
      document.body.appendChild(element);
      await Promise.resolve();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });

    it("hides spinner after data loads", async () => {
      const element = await createLoadedComponent();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();
    });
  });

  // ---------- Error State ----------

  describe("Error State", () => {
    it("displays error alert when imperative call fails", async () => {
      mockSummaryError = { body: { message: "Insufficient permissions" } };
      mockAuditResult = [];

      const element = createElement("c-ai-governance-dashboard", {
        is: AiGovernanceDashboard,
      });
      document.body.appendChild(element);
      await flushPromises();
      await flushPromises();

      const alert = element.shadowRoot.querySelector('[role="alert"]');
      expect(alert).not.toBeNull();
    });

    it("falls back to generic error label when body is missing", async () => {
      mockSummaryError = { message: "Unknown" };
      mockAuditResult = [];

      const element = createElement("c-ai-governance-dashboard", {
        is: AiGovernanceDashboard,
      });
      document.body.appendChild(element);
      await flushPromises();
      await flushPromises();

      const alert = element.shadowRoot.querySelector('[role="alert"]');
      expect(alert).not.toBeNull();
      expect(alert.textContent).toContain("AI_ErrorGeneric");
    });

    it("displays error from wire adapter", async () => {
      const element = await createLoadedComponent();

      getRegisteredSystems.error({ body: { message: "Wire error" } });
      await flushPromises();

      const alert = element.shadowRoot.querySelector('[role="alert"]');
      expect(alert).not.toBeNull();
    });
  });

  // ---------- Summary Cards ----------

  describe("Summary Cards", () => {
    it("renders four stat cards with correct values", async () => {
      const element = await createLoadedComponent();

      const statValues = element.shadowRoot.querySelectorAll(".stat-value");
      expect(statValues.length).toBe(4);

      // Compliance score, total systems, high risk, gap count
      expect(statValues[0].textContent).toContain("72");
      expect(statValues[1].textContent).toContain("5");
      expect(statValues[2].textContent).toContain("2");
      expect(statValues[3].textContent).toContain("1");
    });

    it("rounds compliance score to nearest integer", async () => {
      const element = await createLoadedComponent({
        summary: { ...MOCK_SUMMARY, complianceScore: 72.7 },
      });

      const statValues = element.shadowRoot.querySelectorAll(".stat-value");
      expect(statValues[0].textContent).toContain("73");
    });
  });

  // ---------- Page Header ----------

  describe("Page Header", () => {
    it("renders dashboard title and framework labels", async () => {
      const element = await createLoadedComponent();

      const header = element.shadowRoot.querySelector(".slds-page-header");
      expect(header).not.toBeNull();
      expect(header.textContent).toContain("AI_DashboardTitle");
      expect(header.textContent).toContain("AI_EUAIAct");
      expect(header.textContent).toContain("AI_NISTRMF");
    });

    it("renders Discover and Refresh buttons", async () => {
      const element = await createLoadedComponent();

      expect(findButton(element, "AI_DiscoverSystems")).toBeDefined();
      expect(findButton(element, "AI_RefreshData")).toBeDefined();
    });
  });

  // ---------- Registered Systems (Wire) ----------

  describe("Registered Systems", () => {
    it("renders datatable when systems exist", async () => {
      const element = await createLoadedComponent();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const registryTable = Array.from(datatables).find((dt) => dt.keyField === "Id");
      expect(registryTable).toBeDefined();
      expect(registryTable.data.length).toBe(2);
    });

    it("shows empty message when no registered systems", async () => {
      const element = await createLoadedComponent({ systems: [] });

      const weakTexts = element.shadowRoot.querySelectorAll(".slds-text-color_weak");
      const noSystemsMsg = Array.from(weakTexts).find((el) =>
        el.textContent.includes("AI_NoSystemsFound")
      );
      expect(noSystemsMsg).toBeDefined();
    });

    it("adds riskClass to each system record", async () => {
      const element = await createLoadedComponent();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const registryTable = Array.from(datatables).find((dt) => dt.keyField === "Id");
      expect(registryTable.data[0].riskClass).toBe("slds-text-color_error");
      expect(registryTable.data[1].riskClass).toBe("slds-text-color_success");
    });
  });

  // ---------- Gaps ----------

  describe("Compliance Gaps", () => {
    it("renders gap items when gaps exist", async () => {
      const element = await createLoadedComponent();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-item");
      expect(gapItems.length).toBe(1);
    });

    it("shows no-gaps message when gaps array is empty", async () => {
      const element = await createLoadedComponent({
        summary: { ...MOCK_SUMMARY, gaps: [] },
      });

      const weakTexts = element.shadowRoot.querySelectorAll(".slds-text-color_weak");
      const noGapsMsg = Array.from(weakTexts).find((el) => el.textContent.includes("AI_NoGaps"));
      expect(noGapsMsg).toBeDefined();
    });
  });

  // ---------- Audit Trail ----------

  describe("Audit Trail", () => {
    it("renders audit datatable when entries exist", async () => {
      const element = await createLoadedComponent();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const auditTable = Array.from(datatables).find((dt) => dt.keyField === "uniqueKey");
      expect(auditTable).toBeDefined();
      expect(auditTable.data.length).toBe(1);
    });

    it("shows empty message when no audit entries", async () => {
      const element = await createLoadedComponent({ auditTrail: [] });

      const weakTexts = element.shadowRoot.querySelectorAll(".slds-text-color_weak");
      const noAuditMsg = Array.from(weakTexts).find((el) =>
        el.textContent.includes("AI_NoAuditEntries")
      );
      expect(noAuditMsg).toBeDefined();
    });
  });

  // ---------- Discovery ----------

  describe("Discovery Flow", () => {
    it("calls discoverAISystems when Discover button is clicked", async () => {
      mockDiscoverResult = [
        { systemName: "Custom Bot", systemType: "Chatbot", detectionMethod: "API Scan" },
      ];

      const element = await createLoadedComponent();
      const discoverBtn = findButton(element, "AI_DiscoverSystems");

      discoverBtn.click();
      await flushPromises();
      await flushPromises();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const discoveredTable = Array.from(datatables).find((dt) => dt.keyField === "systemName");
      expect(discoveredTable).toBeDefined();
    });

    it("renders discovered systems datatable after discovery", async () => {
      mockDiscoverResult = [
        { systemName: "Custom Bot", systemType: "Chatbot", detectionMethod: "API Scan" },
      ];

      const element = await createLoadedComponent();
      const discoverBtn = findButton(element, "AI_DiscoverSystems");

      discoverBtn.click();
      await flushPromises();
      await flushPromises();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const discoveredTable = Array.from(datatables).find((dt) => dt.keyField === "systemName");
      expect(discoveredTable).toBeDefined();
      expect(discoveredTable.data.length).toBe(1);
    });

    it("handles discovery error gracefully without crashing", async () => {
      mockDiscoverError = { body: { message: "Discovery failed" } };

      const element = await createLoadedComponent();
      const discoverBtn = findButton(element, "AI_DiscoverSystems");

      discoverBtn.click();
      await flushPromises();
      await flushPromises();

      // Component should not crash; isDiscovering resets to false
      const discoveryBanner = element.shadowRoot.querySelector('[role="status"]');
      expect(discoveryBanner).toBeNull();
    });
  });

  // ---------- Sorting ----------

  describe("Sort Handling", () => {
    it("sorts registry data when onsort fires", async () => {
      const element = await createLoadedComponent();

      const datatables = element.shadowRoot.querySelectorAll("lightning-datatable");
      const registryTable = Array.from(datatables).find((dt) => dt.keyField === "Id");

      registryTable.dispatchEvent(
        new CustomEvent("sort", {
          detail: { fieldName: "Name", sortDirection: "desc" },
        })
      );
      await flushPromises();

      // After desc sort, "Prediction Builder" should come first
      expect(registryTable.data[0].Name).toBe("Prediction Builder");
    });
  });

  // ---------- Refresh ----------

  describe("Refresh", () => {
    it("reloads dashboard data on refresh click", async () => {
      const element = await createLoadedComponent();

      const refreshBtn = findButton(element, "AI_RefreshData");
      refreshBtn.click();
      await flushPromises();

      // Verify the component did not crash and main content still renders
      const header = element.shadowRoot.querySelector(".slds-page-header");
      expect(header).not.toBeNull();
    });
  });
});
