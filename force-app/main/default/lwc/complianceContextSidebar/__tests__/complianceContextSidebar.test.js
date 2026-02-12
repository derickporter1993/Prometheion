import { createElement } from "lwc";
import ComplianceContextSidebar from "c/complianceContextSidebar";

jest.mock(
  "lightning/navigation",
  () => {
    const Navigate = Symbol("Navigate");
    const mixin = (Base) => Base;
    mixin.Navigate = Navigate;
    return { NavigationMixin: mixin };
  },
  { virtual: true }
);

jest.mock("@salesforce/label/c.CC_FrameworkSummary", () => ({ default: "Framework Summary" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_RecentGaps", () => ({ default: "Recent Gaps" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_NoGaps", () => ({ default: "No gaps" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_ViewDetails", () => ({ default: "View Details" }), {
  virtual: true,
});

const MOCK_FRAMEWORKS = [
  { framework: "SOC2", score: 85, gapCount: 4 },
  { framework: "HIPAA", score: 55, gapCount: 12 },
  { framework: "GDPR", score: 92, gapCount: 1 },
];

const MOCK_GAPS = [
  {
    gapId: "a0B000000000001",
    framework: "SOC2",
    severity: "CRITICAL",
    description: "Missing encryption at rest",
  },
  {
    gapId: "a0B000000000002",
    framework: "HIPAA",
    severity: "HIGH",
    description: "Audit trail not enabled",
  },
  {
    gapId: "a0B000000000003",
    framework: "GDPR",
    severity: "MEDIUM",
    description: "Consent tracking incomplete",
  },
];

describe("c-compliance-context-sidebar", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function createComponent(frameworks = MOCK_FRAMEWORKS, gaps = MOCK_GAPS) {
    const element = createElement("c-compliance-context-sidebar", {
      is: ComplianceContextSidebar,
    });
    element.frameworkSummaries = frameworks;
    element.recentGaps = gaps;
    document.body.appendChild(element);
    return element;
  }

  it("renders framework summary cards", async () => {
    const element = createComponent();
    await Promise.resolve();

    const cards = element.shadowRoot.querySelectorAll(".slds-col.slds-size_1-of-3");
    expect(cards.length).toBe(3);
  });

  it("displays framework names", async () => {
    const element = createComponent();
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("SOC2");
    expect(text).toContain("HIPAA");
    expect(text).toContain("GDPR");
  });

  it("displays framework scores", async () => {
    const element = createComponent();
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("85");
    expect(text).toContain("55");
    expect(text).toContain("92");
  });

  it("applies correct score color classes", async () => {
    const element = createComponent();
    await Promise.resolve();

    const successScores = element.shadowRoot.querySelectorAll(".slds-text-color_success");
    const errorScores = element.shadowRoot.querySelectorAll(".slds-text-color_error");
    expect(successScores.length).toBe(2);
    expect(errorScores.length).toBe(1);
  });

  it("renders gap list items", async () => {
    const element = createComponent();
    await Promise.resolve();

    const gapBoxes = element.shadowRoot.querySelectorAll(
      ".slds-box.slds-box_x-small.slds-var-m-bottom_xx-small"
    );
    expect(gapBoxes.length).toBe(3);
  });

  it("displays gap severity badges", async () => {
    const element = createComponent();
    await Promise.resolve();

    const badges = element.shadowRoot.querySelectorAll(".slds-badge");
    expect(badges.length).toBe(3);
  });

  it("renders no gaps empty state", async () => {
    const element = createComponent(MOCK_FRAMEWORKS, []);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("No gaps");
  });

  it("renders view gap navigation buttons", async () => {
    const element = createComponent();
    await Promise.resolve();

    const navButtons = element.shadowRoot.querySelectorAll("lightning-button-icon");
    expect(navButtons.length).toBe(3);
  });

  it("handles empty frameworks gracefully", async () => {
    const element = createComponent([], MOCK_GAPS);
    await Promise.resolve();

    const frameworkCards = element.shadowRoot.querySelectorAll(".slds-col.slds-size_1-of-3");
    expect(frameworkCards.length).toBe(0);
  });

  it("handles null props gracefully", async () => {
    const element = createElement("c-compliance-context-sidebar", {
      is: ComplianceContextSidebar,
    });
    element.frameworkSummaries = null;
    element.recentGaps = null;
    document.body.appendChild(element);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("No gaps");
  });
});
