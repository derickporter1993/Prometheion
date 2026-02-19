import { createElement } from "lwc";
import SecDisclosureDashboard from "c/secDisclosureDashboard";
import getOpenAssessments from "@salesforce/apex/SECDisclosureController.getOpenAssessments";
import { refreshApex } from "@salesforce/apex";

// Mock Apex wire adapter
jest.mock(
  "@salesforce/apex/SECDisclosureController.getOpenAssessments",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock("@salesforce/apex", () => ({ refreshApex: jest.fn() }), {
  virtual: true,
});

// Mock custom labels
jest.mock("@salesforce/label/c.SEC_DashboardTitle", () => ({ default: "SEC Dashboard" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_OpenAssessments", () => ({ default: "Open Assessments" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_NoOpenAssessments", () => ({ default: "No open assessments" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_Loading", () => ({ default: "Loading" }), { virtual: true });
jest.mock("@salesforce/label/c.SEC_ErrorTitle", () => ({ default: "Error" }), { virtual: true });
jest.mock("@salesforce/label/c.SEC_AtRisk", () => ({ default: "At Risk" }), { virtual: true });
jest.mock("@salesforce/label/c.SEC_OnTrack", () => ({ default: "On Track" }), { virtual: true });

// Mock NavigationMixin
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: (Base) => Base,
  }),
  { virtual: true }
);

const MOCK_ASSESSMENTS = [
  {
    Id: "a01000000000001",
    Name: "Assessment 1",
    Filing_Deadline__c: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000).toISOString(),
    Discovery_Date__c: "2026-01-15T00:00:00.000Z",
    Determination_Result__c: "Material",
  },
  {
    Id: "a01000000000002",
    Name: "Assessment 2",
    Filing_Deadline__c: new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString(),
    Discovery_Date__c: "2026-02-01T00:00:00.000Z",
    Determination_Result__c: "Under Review",
  },
];

describe("c-sec-disclosure-dashboard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-sec-disclosure-dashboard", {
      is: SecDisclosureDashboard,
    });
    document.body.appendChild(element);
    return element;
  }

  it("renders dashboard card on init", async () => {
    const element = createComponent();
    await Promise.resolve();
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("SEC Dashboard");
  });

  it("displays assessments when data is returned", async () => {
    const element = createComponent();

    getOpenAssessments.emit(MOCK_ASSESSMENTS);
    await Promise.resolve();

    const metricValues = element.shadowRoot.querySelectorAll(".metric-value");
    expect(metricValues.length).toBeGreaterThan(0);
    expect(metricValues[0].textContent).toBe("2");
  });

  it("renders error state when wire returns error", async () => {
    const element = createComponent();

    getOpenAssessments.error({ body: { message: "Server error" } });
    await Promise.resolve();

    const errorAlert = element.shadowRoot.querySelector('[role="alert"]');
    expect(errorAlert).not.toBeNull();
  });

  it("renders empty state when no assessments exist", async () => {
    const element = createComponent();

    getOpenAssessments.emit([]);
    await Promise.resolve();

    const emptyIllustration = element.shadowRoot.querySelector(".slds-illustration");
    expect(emptyIllustration).not.toBeNull();
  });

  it("contains New Assessment button", () => {
    const element = createComponent();
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const newBtn = Array.from(buttons).find((b) => b.label === "New Assessment");
    expect(newBtn).not.toBeNull();
    expect(newBtn.variant).toBe("brand");
  });

  it("contains refresh button", () => {
    const element = createComponent();
    const refreshBtn = element.shadowRoot.querySelector("lightning-button-icon");
    expect(refreshBtn).not.toBeNull();
    expect(refreshBtn.iconName).toBe("utility:refresh");
  });

  it("renders materiality cards for each assessment", async () => {
    const element = createComponent();

    getOpenAssessments.emit(MOCK_ASSESSMENTS);
    await Promise.resolve();

    const cards = element.shadowRoot.querySelectorAll("c-sec-materiality-card");
    expect(cards.length).toBe(2);
  });
});
