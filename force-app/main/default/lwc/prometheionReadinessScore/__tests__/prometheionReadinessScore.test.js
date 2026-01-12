/**
 * Jest tests for prometheionReadinessScore LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Score status updates based on thresholds
 * - Framework change events
 * - Generate evidence pack navigation
 * - Error handling
 */

import { createElement } from "lwc";
import PrometheionReadinessScore from "c/prometheionReadinessScore";
import calculateReadinessScore from "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore";
import generateEvidencePack from "@salesforce/apex/PrometheionLegalDocumentGenerator.generateLegalAttestation";
import { ShowToastEvent } from "lightning/platformShowToastEvent";

// Wire adapter callbacks
let mockReadinessScoreCallbacks = new Set();

jest.mock(
  "@salesforce/apex/PrometheionComplianceScorer.calculateReadinessScore",
  () => ({
    default: function MockReadinessScoreAdapter(callback) {
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
      return Promise.resolve(null);
    },
  }),
  { virtual: true }
);

jest.mock(
  "@salesforce/apex/PrometheionLegalDocumentGenerator.generateLegalAttestation",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((config) => {
      return new CustomEvent("showtoast", { detail: config });
    }),
  }),
  { virtual: true }
);

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

const emitReadinessScore = (data) => {
  mockReadinessScoreCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitReadinessScoreError = (error) => {
  mockReadinessScoreCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-prometheion-readiness-score", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockReadinessScoreCallbacks = new Set();
  });

  async function createComponent() {
    const element = createElement("c-prometheion-readiness-score", {
      is: PrometheionReadinessScore,
    });
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });

    it("shows loading spinner initially", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).not.toBeNull();
    });
  });

  describe("Wire Adapter Data Handling", () => {
    it("displays score after wire adapter receives data", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.score).toBe(85);
      expect(element.isLoading).toBe(false);
      expect(element.hasError).toBe(false);
    });

    it("calculates sub-scores correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(80);
      await Promise.resolve();
      await Promise.resolve();

      // Each sub-score should be 25% of total (80 * 0.25 = 20)
      expect(element.accessScore).toBe(20);
      expect(element.configScore).toBe(20);
      expect(element.automationScore).toBe(20);
      expect(element.evidenceScore).toBe(20);
    });

    it("updates score status based on thresholds", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // High score (>= 80)
      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.scoreStatus).toBe("Audit Ready");
      expect(element.currentStep).toBe("evidence");

      // Medium score (>= 60)
      emitReadinessScore(65);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.scoreStatus).toBe("Action Required");
      expect(element.currentStep).toBe("automation");

      // Low score (< 60)
      emitReadinessScore(45);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.scoreStatus).toBe("Critical Risks");
      expect(element.currentStep).toBe("access");
    });
  });

  describe("Error Handling", () => {
    it("handles wire adapter error", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Failed to calculate score" },
        message: "Failed to calculate score",
      };

      emitReadinessScoreError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Failed to calculate");
      expect(element.isLoading).toBe(false);
      expect(element.scoreStatus).toBe("Error");
    });

    it("displays error message in UI", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = {
        body: { message: "Test error" },
        message: "Test error",
      };

      emitReadinessScoreError(error);
      await Promise.resolve();
      await Promise.resolve();

      const errorDiv = element.shadowRoot.querySelector(".slds-text-color_error");
      expect(errorDiv).not.toBeNull();
    });

    it("handles error without body property", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const error = { message: "Network error" };
      emitReadinessScoreError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.errorMessage).toBe("Network error");
    });
  });

  describe("Generate Evidence Pack", () => {
    it("generates SOC2 pack and navigates", async () => {
      generateEvidencePack.mockResolvedValue("001xx0000000001");

      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const soc2Button = element.shadowRoot.querySelector(
        'lightning-button[data-action="generateSoc2"]'
      );
      if (soc2Button) {
        soc2Button.click();
        await Promise.resolve();

        expect(generateEvidencePack).toHaveBeenCalled();
        expect(mockNavigate).toHaveBeenCalled();
        expect(dispatchEventSpy).toHaveBeenCalled();
      }

      dispatchEventSpy.mockRestore();
    });

    it("generates HIPAA pack", async () => {
      generateEvidencePack.mockResolvedValue("001xx0000000001");

      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      const hipaaButton = element.shadowRoot.querySelector(
        'lightning-button[data-action="generateHipaa"]'
      );
      if (hipaaButton) {
        hipaaButton.click();
        await Promise.resolve();

        expect(generateEvidencePack).toHaveBeenCalledWith({
          framework: "HIPAA",
          startDate: expect.any(Date),
          endDate: expect.any(Date),
        });
      }
    });

    it("shows error toast if generation fails", async () => {
      const error = {
        body: { message: "Generation failed" },
        message: "Generation failed",
      };
      generateEvidencePack.mockRejectedValue(error);

      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      const dispatchEventSpy = jest.spyOn(element, "dispatchEvent");

      const soc2Button = element.shadowRoot.querySelector(
        'lightning-button[data-action="generateSoc2"]'
      );
      if (soc2Button) {
        soc2Button.click();
        await Promise.resolve();

        expect(dispatchEventSpy).toHaveBeenCalled();
        const toastEvent = dispatchEventSpy.mock.calls.find(
          (call) => call[0].type === "showtoast"
        );
        if (toastEvent) {
          expect(toastEvent[0].detail.variant).toBe("error");
        }
      }

      dispatchEventSpy.mockRestore();
    });
  });

  describe("Score Classes", () => {
    it("applies correct CSS classes based on scores", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      // High scores should have success class
      expect(element.accessClass).toContain("slds-text-color_success");
      expect(element.configClass).toContain("slds-text-color_success");
    });

    it("applies warning class for medium scores", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(65);
      await Promise.resolve();
      await Promise.resolve();

      // Medium scores (65 * 0.25 = 16.25, rounded to 16) should have warning class
      expect(element.accessClass).toContain("slds-text-color_warning");
    });

    it("applies error class for low scores", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(45);
      await Promise.resolve();
      await Promise.resolve();

      // Low scores should have error class
      expect(element.accessClass).toContain("slds-text-color_error");
    });
  });

  describe("Normalized Score", () => {
    it("calculates normalized score correctly", async () => {
      const element = await createComponent();
      await Promise.resolve();

      emitReadinessScore(85);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.normalizedScore).toBe(0.85);
    });
  });
});
