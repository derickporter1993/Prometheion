/**
 * Jest tests for prometheionReadinessScore LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Score loading via wire adapter
 * - Sub-score calculation
 * - Score status determination
 * - Progress step tracking
 * - Generate pack buttons
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionReadinessScore from "c/prometheionReadinessScore";
import calculateReadinessScore from "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore";
import generateEvidencePack from "@salesforce/apex/PrometheionLegalDocumentGenerator.generateLegalAttestation";

// Wire adapter callbacks
let mockScoreCallbacks = new Set();

// Mock wire adapter
jest.mock(
  "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore",
  () => ({
    default: function MockScoreAdapter(callback) {
      if (new.target) {
        this.callback = callback;
        mockScoreCallbacks.add(callback);
        this.connect = () => {};
        this.disconnect = () => {
          mockScoreCallbacks.delete(this.callback);
        };
        this.update = () => {};
        return this;
      }
      return Promise.resolve(null);
    },
  }),
  { virtual: true }
);

// Mock generate evidence pack
jest.mock(
  "@salesforce/apex/PrometheionLegalDocumentGenerator.generateLegalAttestation",
  () => ({ default: jest.fn() }),
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

// Wire adapter emit helpers
const emitScore = (data) => {
  mockScoreCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitScoreError = (error) => {
  mockScoreCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

const resetWireCallbacks = () => {
  mockScoreCallbacks = new Set();
};

describe("c-prometheion-readiness-score", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    resetWireCallbacks();
    jest.clearAllMocks();
  });

  // Helper function to create element
  function createComponent() {
    const element = createElement("c-prometheion-readiness-score", {
      is: PrometheionReadinessScore,
    });
    document.body.appendChild(element);
    return element;
  }

  describe("Component Rendering", () => {
    it("should render lightning-card", async () => {
      const element = createComponent();
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Compliance Readiness Score");
      expect(card.iconName).toBe("custom:custom61");
    });

    it("should show spinner while loading", async () => {
      const element = createComponent();
      await Promise.resolve();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
      expect(spinner.alternativeText).toBe("Loading readiness score");
    });

    it("should display score when loaded", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const formattedNumber = element.shadowRoot.querySelector(
        "lightning-formatted-number"
      );
      expect(formattedNumber).not.toBeNull();
    });
  });

  describe("Score Status", () => {
    it("should show Audit Ready for score >= 80", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Audit Ready");
    });

    it("should show Action Required for score >= 60 and < 80", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(70);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Action Required");
    });

    it("should show Critical Risks for score < 60", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(45);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Critical Risks");
    });
  });

  describe("Sub-Scores Calculation", () => {
    it("should calculate sub-scores correctly", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(100);
      await Promise.resolve();

      // Each sub-score should be 25% of total
      const scoreLabels = element.shadowRoot.querySelectorAll("dd");
      expect(scoreLabels[0].textContent).toBe("25%");
      expect(scoreLabels[1].textContent).toBe("25%");
      expect(scoreLabels[2].textContent).toBe("25%");
      expect(scoreLabels[3].textContent).toBe("25%");
    });

    it("should handle score of 0 without crashing", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(0);
      await Promise.resolve();

      // Score of 0 should not cause errors - component should still be rendered
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Progress Indicator", () => {
    it("should render progress indicator", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const progressIndicator = element.shadowRoot.querySelector(
        "lightning-progress-indicator"
      );
      expect(progressIndicator).not.toBeNull();
      expect(progressIndicator.type).toBe("path");
    });

    it("should have four progress steps", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const steps = element.shadowRoot.querySelectorAll(
        "lightning-progress-step"
      );
      expect(steps).toHaveLength(4);
      expect(steps[0].label).toBe("Access");
      expect(steps[1].label).toBe("Config");
      expect(steps[2].label).toBe("Automation");
      expect(steps[3].label).toBe("Evidence");
    });
  });

  describe("Score Class Assignment", () => {
    // Note: Sub-scores are calculated as 25% of total score
    // So for total=100, sub-score=25, which is < 60 (error class)
    // The class thresholds (80, 60) apply to sub-scores, not total score

    it("should apply error class when sub-score < 60", async () => {
      const element = createComponent();
      await Promise.resolve();

      // Total score 100 -> sub-scores are 25 each, which is < 60
      emitScore(100);
      await Promise.resolve();

      const scoreLabels = element.shadowRoot.querySelectorAll("dd");
      expect(scoreLabels[0].className).toContain("slds-text-color_error");
    });

    it("should include heading_medium class in sub-score labels", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(80);
      await Promise.resolve();

      const scoreLabels = element.shadowRoot.querySelectorAll("dd");
      expect(scoreLabels[0].className).toContain("slds-text-heading_medium");
    });

    it("should apply consistent error class for all sub-scores", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(40);
      await Promise.resolve();

      const scoreLabels = element.shadowRoot.querySelectorAll("dd");
      // All sub-scores should have error class since they are < 60
      expect(scoreLabels[0].className).toContain("slds-text-color_error");
      expect(scoreLabels[1].className).toContain("slds-text-color_error");
      expect(scoreLabels[2].className).toContain("slds-text-color_error");
      expect(scoreLabels[3].className).toContain("slds-text-color_error");
    });
  });

  describe("Generate Pack Buttons", () => {
    it("should render SOC2 button", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const soc2Button = Array.from(buttons).find(
        (btn) => btn.label === "Generate SOC2 Pack"
      );
      expect(soc2Button).not.toBeNull();
      expect(soc2Button.variant).toBe("brand");
    });

    it("should render HIPAA button", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const hipaaButton = Array.from(buttons).find(
        (btn) => btn.label === "Generate HIPAA Pack"
      );
      expect(hipaaButton).not.toBeNull();
      expect(hipaaButton.variant).toBe("neutral");
    });

    it("should call generateEvidencePack when SOC2 button clicked", async () => {
      generateEvidencePack.mockResolvedValue("contentDocId123");
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const soc2Button = Array.from(buttons).find(
        (btn) => btn.label === "Generate SOC2 Pack"
      );
      soc2Button.click();
      await Promise.resolve();

      expect(generateEvidencePack).toHaveBeenCalled();
      const callArgs = generateEvidencePack.mock.calls[0][0];
      expect(callArgs.framework).toBe("SOC2");
    });

    it("should call generateEvidencePack when HIPAA button clicked", async () => {
      generateEvidencePack.mockResolvedValue("contentDocId456");
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const hipaaButton = Array.from(buttons).find(
        (btn) => btn.label === "Generate HIPAA Pack"
      );
      hipaaButton.click();
      await Promise.resolve();

      expect(generateEvidencePack).toHaveBeenCalled();
      const callArgs = generateEvidencePack.mock.calls[0][0];
      expect(callArgs.framework).toBe("HIPAA");
    });
  });

  describe("Error Handling", () => {
    it("should display error message on wire error", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScoreError({ message: "Failed to load" });
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("should hide progress indicator on error", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScoreError({ message: "Failed to load" });
      await Promise.resolve();

      const progressIndicator = element.shadowRoot.querySelector(
        "lightning-progress-indicator"
      );
      expect(progressIndicator).toBeNull();
    });

    it("should handle error with body.message format", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScoreError({ body: { message: "Server error" } });
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });
  });

  describe("Normalized Score", () => {
    it("should display formatted percentage", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const formattedNumber = element.shadowRoot.querySelector(
        "lightning-formatted-number"
      );
      expect(formattedNumber).not.toBeNull();
      expect(formattedNumber.formatStyle).toBe("percent");
    });
  });

  describe("Edge Cases", () => {
    it("should handle score of 100", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(100);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Audit Ready");
    });

    it("should handle score at boundary 80", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(80);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Audit Ready");
    });

    it("should handle score at boundary 60", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(60);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Action Required");
    });

    it("should handle score at boundary 59", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(59);
      await Promise.resolve();

      const statusText = element.shadowRoot.querySelector(
        ".slds-text-heading_small"
      );
      expect(statusText.textContent).toBe("Critical Risks");
    });
  });

  describe("Button Group", () => {
    it("should render button group", async () => {
      const element = createComponent();
      await Promise.resolve();

      emitScore(85);
      await Promise.resolve();

      const buttonGroup = element.shadowRoot.querySelector(
        "lightning-button-group"
      );
      expect(buttonGroup).not.toBeNull();
    });
  });
});
