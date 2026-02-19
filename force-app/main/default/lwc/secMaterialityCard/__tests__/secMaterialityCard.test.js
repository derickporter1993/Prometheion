import { createElement } from "lwc";
import SecMaterialityCard from "c/secMaterialityCard";

// Mock custom labels
jest.mock(
  "@salesforce/label/c.SEC_IncidentDescription",
  () => ({ default: "Incident Description" }),
  { virtual: true }
);
jest.mock("@salesforce/label/c.SEC_DiscoveryDate", () => ({ default: "Discovery Date" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_FilingDeadline", () => ({ default: "Filing Deadline" }), {
  virtual: true,
});
jest.mock(
  "@salesforce/label/c.SEC_DeterminationResult",
  () => ({ default: "Determination Result" }),
  { virtual: true }
);
jest.mock("@salesforce/label/c.SEC_SLAStatus", () => ({ default: "SLA Status" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_OnTrack", () => ({ default: "On Track" }), { virtual: true });
jest.mock("@salesforce/label/c.SEC_AtRisk", () => ({ default: "At Risk" }), { virtual: true });
jest.mock("@salesforce/label/c.SEC_Breached", () => ({ default: "Breached" }), { virtual: true });

const FUTURE_DATE = new Date(Date.now() + 10 * 24 * 60 * 60 * 1000).toISOString();
const TOMORROW_DATE = new Date(Date.now() + 1 * 24 * 60 * 60 * 1000).toISOString();
const PAST_DATE = new Date(Date.now() - 3 * 24 * 60 * 60 * 1000).toISOString();

const MOCK_ON_TRACK_ASSESSMENT = {
  Id: "a01000000000001",
  Name: "Q1 2026 Incident Assessment",
  Filing_Deadline__c: FUTURE_DATE,
  Discovery_Date__c: "2026-01-15T00:00:00.000Z",
  Determination_Result__c: "Under Review",
};

const MOCK_AT_RISK_ASSESSMENT = {
  Id: "a01000000000002",
  Name: "Critical Data Breach",
  Filing_Deadline__c: TOMORROW_DATE,
  Discovery_Date__c: "2026-02-01T00:00:00.000Z",
  Determination_Result__c: "Material",
};

const MOCK_BREACHED_ASSESSMENT = {
  Id: "a01000000000003",
  Name: "Overdue Filing",
  Filing_Deadline__c: PAST_DATE,
  Discovery_Date__c: "2026-01-01T00:00:00.000Z",
  Determination_Result__c: "Material",
};

describe("c-sec-materiality-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function createComponent(assessment) {
    const element = createElement("c-sec-materiality-card", {
      is: SecMaterialityCard,
    });
    element.assessment = assessment;
    document.body.appendChild(element);
    return element;
  }

  it("renders assessment name in header", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const title = element.shadowRoot.querySelector(".slds-truncate");
    expect(title).not.toBeNull();
    expect(title.textContent).toBe("Q1 2026 Incident Assessment");
  });

  it("displays On Track SLA badge for future deadline", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const badge = element.shadowRoot.querySelector("lightning-badge");
    expect(badge).not.toBeNull();
    expect(badge.label).toBe("On Track");
  });

  it("displays At Risk SLA badge when deadline is within 1 day", async () => {
    const element = createComponent(MOCK_AT_RISK_ASSESSMENT);
    await Promise.resolve();

    const badge = element.shadowRoot.querySelector("lightning-badge");
    expect(badge).not.toBeNull();
    expect(badge.label).toBe("At Risk");
  });

  it("displays Breached SLA badge when deadline has passed", async () => {
    const element = createComponent(MOCK_BREACHED_ASSESSMENT);
    await Promise.resolve();

    const badge = element.shadowRoot.querySelector("lightning-badge");
    expect(badge).not.toBeNull();
    expect(badge.label).toBe("Breached");
  });

  it("displays On Track when no filing deadline exists", async () => {
    const assessmentNoDeadline = {
      Id: "a01000000000004",
      Name: "No Deadline Assessment",
      Discovery_Date__c: "2026-01-15T00:00:00.000Z",
      Determination_Result__c: "Not Material",
    };
    const element = createComponent(assessmentNoDeadline);
    await Promise.resolve();

    const badge = element.shadowRoot.querySelector("lightning-badge");
    expect(badge).not.toBeNull();
    expect(badge.label).toBe("On Track");
  });

  it("renders discovery date and filing deadline", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const labels = element.shadowRoot.querySelectorAll(".slds-dl_horizontal__label");
    const details = element.shadowRoot.querySelectorAll(".slds-dl_horizontal__detail");
    expect(labels.length).toBe(3);
    expect(details.length).toBe(3);
    // Discovery Date and Filing Deadline should have non-empty values
    expect(details[0].textContent).not.toBe("");
    expect(details[1].textContent).not.toBe("");
  });

  it("renders determination result with severity class", async () => {
    const element = createComponent(MOCK_AT_RISK_ASSESSMENT);
    await Promise.resolve();

    const severitySpan = element.shadowRoot.querySelector(".severity-high");
    expect(severitySpan).not.toBeNull();
    expect(severitySpan.textContent).toBe("Material");
  });

  it("applies medium severity class for Under Review", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const severitySpan = element.shadowRoot.querySelector(".severity-medium");
    expect(severitySpan).not.toBeNull();
    expect(severitySpan.textContent).toBe("Under Review");
  });

  it("dispatches viewassessment event on card click", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const handler = jest.fn();
    element.addEventListener("viewassessment", handler);

    const article = element.shadowRoot.querySelector("article");
    article.click();
    await Promise.resolve();

    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.assessmentId).toBe("a01000000000001");
  });

  it("renders as a clickable article with role button", async () => {
    const element = createComponent(MOCK_ON_TRACK_ASSESSMENT);
    await Promise.resolve();

    const article = element.shadowRoot.querySelector("article");
    expect(article).not.toBeNull();
    expect(article.getAttribute("role")).toBe("button");
    expect(article.getAttribute("tabindex")).toBe("0");
  });
});
