import { createElement } from "lwc";
import ComplianceCommandCenter from "c/complianceCommandCenter";
import getComplianceContext from "@salesforce/apex/CommandCenterController.getComplianceContext";

jest.mock(
  "@salesforce/apex/CommandCenterController.getComplianceContext",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);

// Child component mocks — complianceNotificationFeed uses getRecentActivity wire
jest.mock(
  "@salesforce/apex/CommandCenterController.getRecentActivity",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
jest.mock("@salesforce/label/c.CC_ActivityFeed", () => ({ default: "Activity" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_NoActivity", () => ({ default: "No activity" }), {
  virtual: true,
});

// Child component mocks — complianceActionCard labels
jest.mock("@salesforce/label/c.CC_PrioritizedActions", () => ({ default: "Actions" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_NoActions", () => ({ default: "No actions" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_GoToSetup", () => ({ default: "Setup" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_RemediationSteps", () => ({ default: "Steps" }), {
  virtual: true,
});

// Child component mocks — complianceContextSidebar labels
jest.mock("@salesforce/label/c.CC_FrameworkSummary", () => ({ default: "Frameworks" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_RecentGaps", () => ({ default: "Gaps" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_NoGaps", () => ({ default: "No gaps" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_ViewDetails", () => ({ default: "View" }), { virtual: true });

// Child component mocks — NavigationMixin for action card and sidebar
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

jest.mock("@salesforce/label/c.CC_DashboardTitle", () => ({ default: "Dashboard" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_Loading", () => ({ default: "Loading..." }), { virtual: true });
jest.mock("@salesforce/label/c.CC_ErrorLoading", () => ({ default: "Error loading" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_OverviewTitle", () => ({ default: "Overview" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_OverallScore", () => ({ default: "Overall Score" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_OpenGaps", () => ({ default: "Open Gaps" }), { virtual: true });
jest.mock("@salesforce/label/c.CC_CriticalGaps", () => ({ default: "Critical" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.CC_Remediated", () => ({ default: "Remediated" }), {
  virtual: true,
});

const MOCK_CONTEXT = {
  overview: {
    overallScore: 78,
    openGaps: 12,
    criticalGaps: 3,
    remediatedGaps: 45,
    riskRating: "Medium",
  },
  frameworkSummaries: [
    { framework: "SOC2", score: 85, gapCount: 4 },
    { framework: "HIPAA", score: 72, gapCount: 8 },
  ],
  prioritizedActions: [
    {
      title: "Enforce MFA",
      severity: "CRITICAL",
      framework: "SOC2",
      category: "Access Control",
    },
  ],
  recentGaps: [
    {
      gapId: "a0B000000000001",
      framework: "SOC2",
      severity: "HIGH",
      description: "Missing encryption",
    },
  ],
};

describe("c-compliance-command-center", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-compliance-command-center", {
      is: ComplianceCommandCenter,
    });
    document.body.appendChild(element);
    return element;
  }

  it("renders loading spinner initially", () => {
    const element = createComponent();
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("renders data after wire emits", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).toBeNull();

    const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_large");
    expect(headings.length).toBeGreaterThanOrEqual(1);
  });

  it("renders error state on wire error", async () => {
    const element = createComponent();
    getComplianceContext.error({ message: "Server error" });
    await Promise.resolve();

    const alert = element.shadowRoot.querySelector('[role="alert"]');
    expect(alert).not.toBeNull();
  });

  it("displays correct overview metrics", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const boxes = element.shadowRoot.querySelectorAll(".slds-box");
    expect(boxes.length).toBe(4);
  });

  it("passes actions to action card child", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const actionCard = element.shadowRoot.querySelector("c-compliance-action-card");
    expect(actionCard).not.toBeNull();
    expect(actionCard.actions).toEqual(MOCK_CONTEXT.prioritizedActions);
  });

  it("passes framework summaries to sidebar child", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const sidebar = element.shadowRoot.querySelector("c-compliance-context-sidebar");
    expect(sidebar).not.toBeNull();
    expect(sidebar.frameworkSummaries).toEqual(MOCK_CONTEXT.frameworkSummaries);
  });

  it("passes recent gaps to sidebar child", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const sidebar = element.shadowRoot.querySelector("c-compliance-context-sidebar");
    expect(sidebar.recentGaps).toEqual(MOCK_CONTEXT.recentGaps);
  });

  it("renders notification feed child", async () => {
    const element = createComponent();
    getComplianceContext.emit(MOCK_CONTEXT);
    await Promise.resolve();

    const feed = element.shadowRoot.querySelector("c-compliance-notification-feed");
    expect(feed).not.toBeNull();
  });

  it("applies success class for high score", async () => {
    const highScoreCtx = {
      ...MOCK_CONTEXT,
      overview: { ...MOCK_CONTEXT.overview, overallScore: 90 },
    };
    const element = createComponent();
    getComplianceContext.emit(highScoreCtx);
    await Promise.resolve();

    const scoreEl = element.shadowRoot.querySelector(".slds-text-color_success");
    expect(scoreEl).not.toBeNull();
  });

  it("applies error class for low score", async () => {
    const lowScoreCtx = {
      ...MOCK_CONTEXT,
      overview: { ...MOCK_CONTEXT.overview, overallScore: 40 },
    };
    const element = createComponent();
    getComplianceContext.emit(lowScoreCtx);
    await Promise.resolve();

    const scoreEl = element.shadowRoot.querySelector(".slds-text-color_error");
    expect(scoreEl).not.toBeNull();
  });
});
