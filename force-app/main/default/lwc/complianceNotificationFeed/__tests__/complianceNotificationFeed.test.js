import { createElement } from "lwc";
import ComplianceNotificationFeed from "c/complianceNotificationFeed";
import getRecentActivity from "@salesforce/apex/CommandCenterController.getRecentActivity";

jest.mock(
  "@salesforce/apex/CommandCenterController.getRecentActivity",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

jest.mock("@salesforce/label/c.CC_ActivityFeed", () => ({ default: "Recent Activity" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_NoActivity", () => ({ default: "No activity" }), {
  virtual: true,
});

const MOCK_ACTIVITIES = [
  {
    activityId: "a0B000000000001",
    activityType: "GAP_UPDATE",
    title: "GAP-001 — SOC2",
    detail: "CRITICAL gap is OPEN",
    timestamp: new Date().toISOString(),
    modifiedBy: "Admin User",
    severity: "CRITICAL",
  },
  {
    activityId: "a0B000000000002",
    activityType: "SCORE_CHANGE",
    title: "Score Updated — HIPAA",
    detail: "Score changed to 72",
    timestamp: new Date(Date.now() - 3600000).toISOString(),
    modifiedBy: "System",
    severity: "HIGH",
  },
  {
    activityId: "a0B000000000003",
    activityType: "REMEDIATION",
    title: "GAP-003 — GDPR",
    detail: "MEDIUM gap is REMEDIATED",
    timestamp: new Date(Date.now() - 86400000 * 2).toISOString(),
    modifiedBy: "Jane Doe",
    severity: "MEDIUM",
  },
];

describe("c-compliance-notification-feed", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-compliance-notification-feed", {
      is: ComplianceNotificationFeed,
    });
    document.body.appendChild(element);
    return element;
  }

  it("renders empty state before wire emits", () => {
    const element = createComponent();
    const text = element.shadowRoot.textContent;
    expect(text).toContain("No activity");
  });

  it("renders activity items after wire emits", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const items = element.shadowRoot.querySelectorAll(".slds-timeline__item");
    expect(items.length).toBe(3);
  });

  it("displays activity titles", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("GAP-001 — SOC2");
    expect(text).toContain("Score Updated — HIPAA");
  });

  it("displays severity badges", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const badges = element.shadowRoot.querySelectorAll(".slds-badge");
    expect(badges.length).toBe(3);
  });

  it("applies correct severity classes", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const inverseBadge = element.shadowRoot.querySelector(".slds-badge_inverse");
    expect(inverseBadge).not.toBeNull();

    const errorBadge = element.shadowRoot.querySelector(".slds-theme_error");
    expect(errorBadge).not.toBeNull();

    const warningBadge = element.shadowRoot.querySelector(".slds-theme_warning");
    expect(warningBadge).not.toBeNull();
  });

  it("displays correct icons per activity type", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const icons = element.shadowRoot.querySelectorAll("lightning-icon");
    expect(icons.length).toBe(3);
  });

  it("displays modifier name", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Admin User");
    expect(text).toContain("Jane Doe");
  });

  it("shows relative time formatting", async () => {
    const element = createComponent();
    getRecentActivity.emit(MOCK_ACTIVITIES);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    // First item is "Just now" or "Xm ago" (within seconds)
    // Second is "1h ago"
    // Third is "2d ago"
    expect(text).toContain("ago");
  });

  it("renders empty state on empty array", async () => {
    const element = createComponent();
    getRecentActivity.emit([]);
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("No activity");
  });

  it("handles wire error gracefully", async () => {
    const element = createComponent();
    getRecentActivity.error({ message: "Error" });
    await Promise.resolve();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("No activity");
  });
});
