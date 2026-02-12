import { createElement } from "lwc";
import ComplianceActionCard from "c/complianceActionCard";

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

jest.mock("@salesforce/label/c.CC_PrioritizedActions", () => ({ default: "Prioritized Actions" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_NoActions", () => ({ default: "No actions" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_GoToSetup", () => ({ default: "Go to Setup" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_RemediationSteps", () => ({ default: "Remediation Steps" }), {
  virtual: true,
});

const MOCK_ACTIONS = [
  {
    title: "Enforce MFA",
    description: "Enable MFA for all users",
    severity: "CRITICAL",
    framework: "SOC2",
    category: "Access Control",
    setupPath: "SecurityMfa/home",
    remediationSteps: "Go to MFA settings and enable.",
    controlReference: "CC6.1",
  },
  {
    title: "Review Access Logs",
    description: "Check access logs weekly",
    severity: "HIGH",
    framework: "SOC2",
    category: "Audit",
    setupPath: "",
    remediationSteps: "",
    controlReference: "CC7.2",
  },
  {
    title: "Data Retention Policy",
    description: "Implement data retention",
    severity: "MEDIUM",
    framework: "GDPR",
    category: "Data Protection",
    setupPath: "",
    remediationSteps: "Create retention schedule.",
    controlReference: "Art.5",
  },
];

describe("c-compliance-action-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function createComponent(actions = MOCK_ACTIONS) {
    const element = createElement("c-compliance-action-card", {
      is: ComplianceActionCard,
    });
    element.actions = actions;
    document.body.appendChild(element);
    return element;
  }

  it("renders action cards for each action", async () => {
    const element = createComponent();
    await Promise.resolve();

    const cards = element.shadowRoot.querySelectorAll(".slds-box");
    expect(cards.length).toBe(3);
  });

  it("renders empty state when no actions", async () => {
    const element = createComponent([]);
    await Promise.resolve();

    const emptyState = element.shadowRoot.querySelector(".slds-illustration");
    expect(emptyState).not.toBeNull();
  });

  it("displays severity badges with correct classes", async () => {
    const element = createComponent();
    await Promise.resolve();

    const badges = element.shadowRoot.querySelectorAll(".slds-badge");
    expect(badges.length).toBe(3);
    expect(badges[0].classList.contains("slds-badge_inverse")).toBe(true);
    expect(badges[1].classList.contains("slds-theme_error")).toBe(true);
    expect(badges[2].classList.contains("slds-theme_warning")).toBe(true);
  });

  it("shows Go to Setup button only when setup path exists", async () => {
    const element = createComponent();
    await Promise.resolve();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons.length).toBe(1);
  });

  it("expands action on toggle click", async () => {
    const element = createComponent();
    await Promise.resolve();

    const toggleBtn = element.shadowRoot.querySelector("button[data-key='action-0']");
    expect(toggleBtn).not.toBeNull();

    toggleBtn.click();
    await Promise.resolve();

    const expandedContent = element.shadowRoot.querySelector(".slds-border_top");
    expect(expandedContent).not.toBeNull();
  });

  it("collapses action when toggled again", async () => {
    const element = createComponent();
    await Promise.resolve();

    const toggleBtn = element.shadowRoot.querySelector("button[data-key='action-0']");
    toggleBtn.click();
    await Promise.resolve();

    toggleBtn.click();
    await Promise.resolve();

    const expandedContent = element.shadowRoot.querySelector(".slds-border_top");
    expect(expandedContent).toBeNull();
  });

  it("shows remediation steps in expanded view", async () => {
    const element = createComponent();
    await Promise.resolve();

    const toggleBtn = element.shadowRoot.querySelector("button[data-key='action-0']");
    toggleBtn.click();
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Go to MFA settings and enable.");
  });

  it("shows control reference in expanded view", async () => {
    const element = createComponent();
    await Promise.resolve();

    const toggleBtn = element.shadowRoot.querySelector("button[data-key='action-0']");
    toggleBtn.click();
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("CC6.1");
  });

  it("handles null actions gracefully", async () => {
    const element = createElement("c-compliance-action-card", {
      is: ComplianceActionCard,
    });
    element.actions = null;
    document.body.appendChild(element);
    await Promise.resolve();

    const emptyState = element.shadowRoot.querySelector(".slds-illustration");
    expect(emptyState).not.toBeNull();
  });
});
