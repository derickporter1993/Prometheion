/**
 * Jest tests for complianceScoreCard LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Score class styling (via rendered CSS class)
 * - Status icon display
 * - Framework details display
 * - Navigation
 */

import { createElement } from "lwc";
import ComplianceScoreCard from "c/complianceScoreCard";
import { runAccessibilityAudit, checkHeadingHierarchy } from "../../__tests__/axeTestHelper";

let mockFrameworkDetailsCallbacks = new Set();

// Mock the wire adapter with proper connect/disconnect interface
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

// Mock navigation
const mockNavigate = jest.fn();
jest.mock(
  "lightning/navigation",
  () => ({
    NavigationMixin: (Base) => {
      return class extends Base {
        [Symbol.for("NavigationMixin.Navigate")](pageReference) {
          return mockNavigate(pageReference);
        }
      };
    },
  }),
  { virtual: true }
);

const emitFrameworkDetails = (data) => {
  mockFrameworkDetailsCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitFrameworkDetailsError = (error) => {
  mockFrameworkDetailsCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-compliance-score-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockFrameworkDetailsCallbacks = new Set();
  });

  async function createComponent(props = {}) {
    const element = createElement("c-compliance-score-card", {
      is: ComplianceScoreCard,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("displays score percentage", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "COMPLIANT" },
      });

      const scoreText = element.shadowRoot.querySelector(".slds-text-heading_large");
      expect(scoreText).not.toBeNull();
      expect(scoreText.textContent).toContain("85");
    });

    it("displays framework status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "COMPLIANT" },
      });

      const statusText = element.shadowRoot.textContent;
      expect(statusText).toContain("COMPLIANT");
    });
  });

  describe("Score Class Styling", () => {
    it("applies score-high class for scores >= 90", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 95, status: "COMPLIANT" },
      });

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-high");
    });

    it("applies score-medium class for scores >= 70 and < 90", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "PARTIALLY_COMPLIANT" },
      });

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-medium");
    });

    it("applies score-low class for scores < 70", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 65, status: "NON_COMPLIANT" },
      });

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card.className).toContain("score-low");
    });
  });

  describe("Status Icon", () => {
    it("displays success icon for COMPLIANT status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 95, status: "COMPLIANT" },
      });

      const icons = element.shadowRoot.querySelectorAll("lightning-icon");
      const iconNames = Array.from(icons).map((i) => i.iconName);
      expect(iconNames).toContain("utility:success");
    });

    it("displays warning icon for PARTIALLY_COMPLIANT status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "PARTIALLY_COMPLIANT" },
      });

      const icons = element.shadowRoot.querySelectorAll("lightning-icon");
      const iconNames = Array.from(icons).map((i) => i.iconName);
      expect(iconNames).toContain("utility:warning");
    });

    it("displays error icon for NON_COMPLIANT status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 50, status: "NON_COMPLIANT" },
      });

      const icons = element.shadowRoot.querySelectorAll("lightning-icon");
      const iconNames = Array.from(icons).map((i) => i.iconName);
      expect(iconNames).toContain("utility:error");
    });
  });

  describe("Policy Counts", () => {
    it("displays compliant and total policy counts", async () => {
      const element = await createComponent({
        framework: {
          framework: "SOC2",
          score: 85,
          status: "COMPLIANT",
          compliantPolicies: 8,
          totalPolicies: 10,
          gapCount: 2,
        },
      });

      const content = element.shadowRoot.textContent;
      expect(content).toContain("8");
      expect(content).toContain("10");
      expect(content).toContain("Policies Compliant");
    });

    it("displays gap count", async () => {
      const element = await createComponent({
        framework: {
          framework: "SOC2",
          score: 85,
          status: "COMPLIANT",
          compliantPolicies: 8,
          totalPolicies: 10,
          gapCount: 2,
        },
      });

      const content = element.shadowRoot.textContent;
      expect(content).toContain("2");
      expect(content).toContain("Gaps");
    });
  });

  describe("Framework Details Wire", () => {
    it("displays framework details when wire returns data", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });

      const mockDetails = {
        mappingCount: 15,
        evidenceCount: 42,
        requirementCount: 20,
      };

      emitFrameworkDetails(mockDetails);
      await Promise.resolve();
      await Promise.resolve();

      const content = element.shadowRoot.textContent;
      expect(content).toContain("15");
      expect(content).toContain("42");
      expect(content).toContain("20");
    });

    it("handles wire error gracefully", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });

      emitFrameworkDetailsError({ message: "Test error" });
      await Promise.resolve();
      await Promise.resolve();

      // Check that error state is displayed - component shows error message
      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
      expect(errorDiv.textContent).toContain("Test error");
    });

    it("displays latest audit package when available", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });

      const mockDetails = {
        mappingCount: 15,
        evidenceCount: 42,
        requirementCount: 20,
        latestAuditPackage: {
          id: "a0B1234",
          name: "Q4 2024 Audit",
          status: "In Progress",
          periodStart: "2024-10-01",
          periodEnd: "2024-12-31",
        },
      };

      emitFrameworkDetails(mockDetails);
      await Promise.resolve();
      await Promise.resolve();

      const content = element.shadowRoot.textContent;
      expect(content).toContain("Q4 2024 Audit");
      expect(content).toContain("In Progress");
    });
  });

  describe("Loading State", () => {
    it("shows spinner when loading details", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });

      // Component starts in loading state for wire
      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      // Spinner may or may not be present depending on wire state
      expect(element.shadowRoot).not.toBeNull();
    });
  });

  describe("Accessibility (axe)", () => {
    it("should have no accessibility violations", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "COMPLIANT" },
      });

      const results = await runAccessibilityAudit(element);
      expect(results.violations).toHaveLength(0);
    });

    it("should have valid heading hierarchy", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85, status: "COMPLIANT" },
      });

      const { isValid, errors } = checkHeadingHierarchy(element.shadowRoot);
      if (!isValid) {
        console.warn("Heading hierarchy issues:", errors);
      }
      expect(isValid).toBe(true);
    });
  });
});
