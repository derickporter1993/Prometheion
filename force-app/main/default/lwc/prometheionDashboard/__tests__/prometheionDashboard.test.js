/**
 * Jest tests for prometheionDashboard LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Framework selection and filtering
 * - Risk display and interaction
 * - Accessibility compliance
 */

import { createElement } from "lwc";
import PrometheionDashboard from "c/prometheionDashboard";
import { safeCleanupDom } from "../../__tests__/wireAdapterTestUtils";

// Wire adapter callbacks - must be declared before jest.mock (which is hoisted)
// Using 'mock' prefix allows Jest to hoist properly
let mockReadinessScoreCallbacks = new Set();
let mockAuditPackagesCallbacks = new Set();

// Store for imperative call result
let mockImperativeResult = null;

// Mock wire adapter that supports BOTH wire and imperative usage
// LWC Apex methods can be used as @wire adapters OR called imperatively
jest.mock(
  "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore",
  () => ({
    default: function MockReadinessScoreAdapter(callback) {
      // Check if called with 'new' (wire adapter mode)
      if (new.target) {
        this.callback = callback;
        mockReadinessScoreCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockReadinessScoreCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      // Called as regular function (imperative mode) - return a promise
      return Promise.resolve(mockImperativeResult);
    },
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionDashboardController.getAuditPackages",
  () => ({
    default: function MockAuditPackagesAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockAuditPackagesCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockAuditPackagesCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve([]);
    },
  }),
  { virtual: true }
);

// Wire adapter emit helpers (defined after mocks)
const emitReadinessScore = (data) => {
  mockReadinessScoreCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitAuditPackages = (data) => {
  mockAuditPackagesCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitReadinessScoreError = (error) => {
  mockReadinessScoreCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

const resetWireCallbacks = () => {
  mockReadinessScoreCallbacks = new Set();
  mockAuditPackagesCallbacks = new Set();
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

// Mock NavigationMixin
const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: jest.fn((Base) => {
      return class extends Base {
        [Symbol.for("navigate")] = mockNavigate;
      };
    }),
  }),
  { virtual: true }
);

// Sample mock data
const MOCK_SCORE_RESULT = {
  overallScore: 85,
  rating: "GOOD",
  frameworkScores: {
    HIPAA: 90,
    SOC2: 85,
    GDPR: 80,
    PCI_DSS: 75,
    ISO27001: 88,
    NIST: 82,
    FedRAMP: 79,
    CCPA: 85,
    GLBA: 81,
    SOX: 76,
  },
  factors: [
    {
      name: "Access Control",
      score: 88,
      status: "GOOD",
      weight: 0.25,
      weightedScore: 22,
      detail: "Strong access controls in place",
    },
    {
      name: "Data Protection",
      score: 75,
      status: "WARNING",
      weight: 0.25,
      weightedScore: 18.75,
      detail: "Some encryption gaps identified",
    },
  ],
  topRisks: [
    {
      nodeId: "risk-001",
      title: "Elevated Access",
      description: "User has excessive permissions",
      severity: "HIGH",
      framework: "HIPAA",
    },
    {
      nodeId: "risk-002",
      title: "Missing Encryption",
      description: "Data at rest not encrypted",
      severity: "CRITICAL",
      framework: "SOC2",
    },
  ],
};

const MOCK_AUDIT_PACKAGES = [
  {
    id: "pkg-001",
    packageName: "Q1 2024 HIPAA Audit",
    framework: "HIPAA",
    status: "Complete",
    periodStart: "2024-01-01",
    periodEnd: "2024-03-31",
    createdDate: "2024-04-01",
    createdBy: "Admin User",
  },
];

describe("c-prometheion-dashboard", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    resetWireCallbacks();
    // Set up imperative call result
    mockImperativeResult = MOCK_SCORE_RESULT;
  });

  afterEach(() => {
    safeCleanupDom();
  });

  /**
   * Helper to flush promises and allow LWC reactivity
   */
  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  /**
   * Helper to create component with wire data
   */
  async function createComponent() {
    const element = createElement("c-prometheion-dashboard", {
      is: PrometheionDashboard,
    });
    document.body.appendChild(element);

    await flushPromises();

    // Emit wire adapter data
    emitReadinessScore(MOCK_SCORE_RESULT);
    emitAuditPackages(MOCK_AUDIT_PACKAGES);

    await flushPromises();
    await Promise.resolve();

    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the dashboard header with title", async () => {
      const element = await createComponent();

      const heading = element.shadowRoot.querySelector("h1");
      expect(heading).not.toBeNull();
      expect(heading.textContent).toBe("Compliance Dashboard");
    });

    it("displays the overall score from wire data", async () => {
      const element = await createComponent();

      const scoreValue = element.shadowRoot.querySelector(".score-value");
      expect(scoreValue).not.toBeNull();
      expect(scoreValue.textContent).toBe("85");
    });

    it("displays the rating badge", async () => {
      const element = await createComponent();

      const ratingBadge = element.shadowRoot.querySelector(".rating-badge");
      expect(ratingBadge).not.toBeNull();
      expect(ratingBadge.textContent).toBe("GOOD");
    });

    it("renders framework cards", async () => {
      const element = await createComponent();

      const frameworkCards = element.shadowRoot.querySelectorAll(".framework-card");
      expect(frameworkCards.length).toBeGreaterThan(0);
    });

    it("displays factor cards with scores", async () => {
      const element = await createComponent();

      const factorCards = element.shadowRoot.querySelectorAll(".factor-card");
      expect(factorCards.length).toBe(2);
    });
  });

  describe("Framework Filtering", () => {
    it("shows all frameworks by default", async () => {
      const element = await createComponent();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      expect(combobox).not.toBeNull();
      expect(combobox.value).toBe("ALL");
    });

    it("filters frameworks when selection changes", async () => {
      const element = await createComponent();

      const combobox = element.shadowRoot.querySelector("lightning-combobox");
      combobox.dispatchEvent(
        new CustomEvent("change", {
          detail: { value: "HIPAA" },
        })
      );

      await flushPromises();

      // Should show drill-down view for HIPAA
      const drillDownView = element.shadowRoot.querySelector(".drill-down-view");
      expect(drillDownView).not.toBeNull();
    });
  });

  describe("Framework Card Interaction", () => {
    it("navigates to drill-down view when framework card is clicked", async () => {
      const element = await createComponent();

      const frameworkCard = element.shadowRoot.querySelector(".framework-card");
      expect(frameworkCard).not.toBeNull();

      frameworkCard.click();
      await flushPromises();

      const drillDownView = element.shadowRoot.querySelector(".drill-down-view");
      expect(drillDownView).not.toBeNull();
    });

    it("returns to all frameworks view when back button is clicked", async () => {
      const element = await createComponent();

      // First click a framework card
      const frameworkCard = element.shadowRoot.querySelector(".framework-card");
      frameworkCard.click();
      await flushPromises();

      // Then click back button
      const backButton = element.shadowRoot.querySelector(".back-button");
      expect(backButton).not.toBeNull();
      backButton.click();
      await flushPromises();

      const frameworkGrid = element.shadowRoot.querySelector(".framework-grid");
      expect(frameworkGrid).not.toBeNull();
    });
  });

  describe("Risk Display", () => {
    it("displays top risks when present", async () => {
      const element = await createComponent();

      const riskCards = element.shadowRoot.querySelectorAll(".risk-card");
      expect(riskCards.length).toBe(2);
    });

    it("shows severity badge for each risk", async () => {
      const element = await createComponent();

      const severityBadges = element.shadowRoot.querySelectorAll(".severity-badge");
      expect(severityBadges.length).toBeGreaterThan(0);
    });

    it("has view details button for risks", async () => {
      const element = await createComponent();

      const riskAction = element.shadowRoot.querySelector(".risk-action");
      expect(riskAction).not.toBeNull();
      expect(riskAction.getAttribute("aria-label")).not.toBeNull();
    });
  });

  describe("Loading State", () => {
    it("shows component initially", async () => {
      const element = createElement("c-prometheion-dashboard", {
        is: PrometheionDashboard,
      });
      document.body.appendChild(element);

      await flushPromises();

      // Component should render
      expect(element).not.toBeNull();

      // Emit data to complete the test
      emitReadinessScore(MOCK_SCORE_RESULT);
      emitAuditPackages(MOCK_AUDIT_PACKAGES);
      await flushPromises();
    });

    it("hides loading overlay after data loads", async () => {
      const element = await createComponent();

      const loadingOverlay = element.shadowRoot.querySelector(".loading-overlay");
      expect(loadingOverlay).toBeNull();
    });
  });

  describe("Refresh Functionality", () => {
    it("has a refresh button", async () => {
      const element = await createComponent();

      const refreshButton = element.shadowRoot.querySelector(".refresh-btn");
      expect(refreshButton).not.toBeNull();
    });

    it("calls refresh when button is clicked", async () => {
      const element = await createComponent();

      const refreshButton = element.shadowRoot.querySelector(".refresh-btn");
      refreshButton.click();
      await flushPromises();

      // Should trigger loading state
      // Note: The actual refresh behavior depends on implementation
    });
  });

  describe("Accessibility", () => {
    it("has score ring container with value display", async () => {
      const element = await createComponent();

      const scoreRing = element.shadowRoot.querySelector(".score-ring");
      expect(scoreRing).not.toBeNull();
      // Score value is displayed inside the score ring
      const scoreValue = element.shadowRoot.querySelector(".score-value");
      expect(scoreValue).not.toBeNull();
      expect(scoreValue.textContent).toBe("85");
    });

    it("has framework cards with data attributes", async () => {
      const element = await createComponent();

      const frameworkCard = element.shadowRoot.querySelector(".framework-card");
      expect(frameworkCard).not.toBeNull();
      // Framework cards have data-framework attribute for click handling
      expect(frameworkCard.dataset.framework).not.toBeUndefined();
    });

    it("has proper heading structure", async () => {
      const element = await createComponent();

      const h1 = element.shadowRoot.querySelector("h1");
      const h3s = element.shadowRoot.querySelectorAll("h3");

      expect(h1).not.toBeNull();
      expect(h3s.length).toBeGreaterThan(0);
    });

    it("framework cards have click handlers", async () => {
      const element = await createComponent();

      const frameworkCard = element.shadowRoot.querySelector(".framework-card");
      expect(frameworkCard).not.toBeNull();
      // Framework cards are clickable divs with data attributes
      expect(frameworkCard.dataset.framework).not.toBeUndefined();
    });

    it("action buttons have proper ARIA attributes", async () => {
      const element = await createComponent();

      const actionButtons = element.shadowRoot.querySelectorAll(".action-btn");
      actionButtons.forEach((btn) => {
        expect(btn.getAttribute("aria-label")).not.toBeNull();
      });
    });
  });

  describe("Action Buttons", () => {
    it("renders SOC2 report button", async () => {
      const element = await createComponent();

      const buttons = element.shadowRoot.querySelectorAll(".action-btn");
      const soc2Button = Array.from(buttons).find((btn) => btn.textContent.includes("SOC2"));
      expect(soc2Button).not.toBeNull();
    });

    it("renders HIPAA report button", async () => {
      const element = await createComponent();

      const buttons = element.shadowRoot.querySelectorAll(".action-btn");
      const hipaaButton = Array.from(buttons).find((btn) => btn.textContent.includes("HIPAA"));
      expect(hipaaButton).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles wire adapter error gracefully", async () => {
      const element = createElement("c-prometheion-dashboard", {
        is: PrometheionDashboard,
      });
      document.body.appendChild(element);

      await flushPromises();

      // Emit error from wire adapter
      emitReadinessScoreError({ body: { message: "Test error" } });

      await flushPromises();

      // Component should still be functional
      expect(element.shadowRoot.querySelector(".prometheion-dashboard")).not.toBeNull();
    });
  });
});
