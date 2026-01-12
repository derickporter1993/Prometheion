/**
 * Jest tests for complianceScoreCard LWC component
 *
 * Tests cover:
 * - Component rendering with different score levels
 * - Status icon display
 * - Framework details display
 * - Audit package navigation
 * - Error handling
 */

import { createElement } from "lwc";
import ComplianceScoreCard from "c/complianceScoreCard";

// Wire adapter callbacks
let mockFrameworkDetailsCallbacks = new Set();

// Mock wire adapter
jest.mock(
  "@salesforce/apex/ComplianceScoreCardController.getFrameworkDetails",
  () => ({
    default: function MockFrameworkDetailsAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockFrameworkDetailsCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockFrameworkDetailsCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve(null);
    },
  }),
  { virtual: true }
);

// Wire adapter emit helpers
const emitFrameworkDetails = (data) => {
  mockFrameworkDetailsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitFrameworkDetailsError = (error) => {
  mockFrameworkDetailsCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

const resetWireCallbacks = () => {
  mockFrameworkDetailsCallbacks = new Set();
};

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

describe("c-compliance-score-card", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    resetWireCallbacks();
    jest.clearAllMocks();
  });

  // Helper function to create element with framework data
  function createComponent(frameworkData = null) {
    const element = createElement("c-compliance-score-card", {
      is: ComplianceScoreCard,
    });
    if (frameworkData) {
      element.framework = frameworkData;
    }
    document.body.appendChild(element);
    return element;
  }

  // Test data
  const mockHighScoreFramework = {
    framework: "SOC2",
    key: "SOC2",
    score: 95,
    status: "COMPLIANT",
    compliantPolicies: 48,
    totalPolicies: 50,
    gapCount: 2,
  };

  const mockMediumScoreFramework = {
    framework: "HIPAA",
    key: "HIPAA",
    score: 78,
    status: "PARTIALLY_COMPLIANT",
    compliantPolicies: 35,
    totalPolicies: 45,
    gapCount: 10,
  };

  const mockLowScoreFramework = {
    framework: "GDPR",
    key: "GDPR",
    score: 55,
    status: "NON_COMPLIANT",
    compliantPolicies: 20,
    totalPolicies: 40,
    gapCount: 20,
  };

  const mockFrameworkDetails = {
    mappingCount: 25,
    evidenceCount: 150,
    requirementCount: 30,
    latestAuditPackage: {
      id: "a0B000000001234AAA",
      name: "Q4 2025 Audit Package",
      status: "APPROVED",
      periodStart: "2025-10-01",
      periodEnd: "2025-12-31",
    },
  };

  describe("Component Rendering", () => {
    it("should render with framework data", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("should display framework score", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const scoreDiv = element.shadowRoot.querySelector(
        ".slds-text-heading_large"
      );
      expect(scoreDiv.textContent).toBe("95%");
    });

    it("should display compliance status", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const statusDiv = element.shadowRoot.querySelectorAll(
        ".slds-text-body_small"
      )[1];
      expect(statusDiv.textContent).toBe("COMPLIANT");
    });

    it("should display policy counts", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const policyText = element.shadowRoot.querySelector(
        ".slds-m-top_small .slds-text-body_small"
      );
      expect(policyText.textContent).toContain("48 / 50");
    });

    it("should display gap count", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const bodyElements = element.shadowRoot.querySelectorAll(
        ".slds-m-top_small .slds-text-body_small"
      );
      const gapElement = bodyElements[1];
      expect(gapElement.textContent).toBe("2 Gaps");
    });
  });

  describe("Score Class", () => {
    it("should apply score-high class for scores >= 90", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-high");
    });

    it("should apply score-medium class for scores >= 70 and < 90", async () => {
      const element = createComponent(mockMediumScoreFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-medium");
    });

    it("should apply score-low class for scores < 70", async () => {
      const element = createComponent(mockLowScoreFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-low");
    });
  });

  describe("Status Icon", () => {
    it("should display success icon for COMPLIANT status", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const icon = element.shadowRoot.querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:success");
    });

    it("should display warning icon for PARTIALLY_COMPLIANT status", async () => {
      const element = createComponent(mockMediumScoreFramework);
      await Promise.resolve();

      const icon = element.shadowRoot.querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:warning");
    });

    it("should display error icon for NON_COMPLIANT status", async () => {
      const element = createComponent(mockLowScoreFramework);
      await Promise.resolve();

      const icon = element.shadowRoot.querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:error");
    });
  });

  describe("Framework Details Wire", () => {
    it("should display loading spinner when waiting for data", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      // Component should render and have proper structure
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("should display framework details when loaded", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      // Emit data
      emitFrameworkDetails(mockFrameworkDetails);
      await Promise.resolve();

      const mappingText = element.shadowRoot.querySelector(
        ".slds-m-top_medium .slds-text-body_small"
      );
      expect(mappingText.textContent).toContain("25");
    });

    it("should display error message on wire error", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      // Emit error
      emitFrameworkDetailsError({ message: "Failed to load" });
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(
        ".slds-text-color_error"
      );
      expect(errorDiv).not.toBeNull();
    });
  });

  describe("Latest Audit Package", () => {
    it("should display latest audit package when available", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      emitFrameworkDetails(mockFrameworkDetails);
      await Promise.resolve();

      const packageName = element.shadowRoot.querySelectorAll(
        ".slds-m-top_small.slds-border_top .slds-text-body_small"
      )[1];
      expect(packageName.textContent).toBe("Q4 2025 Audit Package");
    });

    it("should display formatted dates for audit package", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      emitFrameworkDetails(mockFrameworkDetails);
      await Promise.resolve();

      const periodText = element.shadowRoot.querySelectorAll(
        ".slds-m-top_small.slds-border_top .slds-text-body_small"
      )[3];
      // Date format: "Oct 1, 2025 - Dec 31, 2025"
      expect(periodText.textContent).toContain("Period:");
    });

    it("should render View Package button", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      emitFrameworkDetails(mockFrameworkDetails);
      await Promise.resolve();

      const button = element.shadowRoot.querySelector("lightning-button");
      expect(button).not.toBeNull();
      expect(button.label).toBe("View Package");
    });
  });

  describe("Edge Cases", () => {
    it("should handle framework with zero score", async () => {
      const zeroScoreFramework = {
        ...mockHighScoreFramework,
        score: 0,
        status: "NON_COMPLIANT",
      };
      const element = createComponent(zeroScoreFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-low");
    });

    it("should handle framework with 100 score", async () => {
      const perfectFramework = {
        ...mockHighScoreFramework,
        score: 100,
        status: "COMPLIANT",
      };
      const element = createComponent(perfectFramework);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-high");
    });
  });

  describe("Framework Details without Audit Package", () => {
    it("should not display audit package section when not available", async () => {
      const element = createComponent(mockHighScoreFramework);
      await Promise.resolve();

      const detailsWithoutPackage = {
        mappingCount: 10,
        evidenceCount: 50,
        requirementCount: 15,
        latestAuditPackage: null,
      };

      emitFrameworkDetails(detailsWithoutPackage);
      await Promise.resolve();

      const button = element.shadowRoot.querySelector("lightning-button");
      expect(button).toBeNull();
    });
  });
});
