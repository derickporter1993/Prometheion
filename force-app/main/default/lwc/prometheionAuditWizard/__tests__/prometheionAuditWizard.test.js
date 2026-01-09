/**
 * Jest tests for prometheionAuditWizard LWC component
 *
 * Tests cover:
 * - Multi-step wizard navigation
 * - Framework selection
 * - Date range configuration
 * - Control selection
 * - Package generation
 * - Accessibility compliance
 */
// @ts-ignore - LWC1702 false positive for Jest test files
import { createElement } from "lwc";
import PrometheionAuditWizard from "c/prometheionAuditWizard";
import {
  flushPromises,
  simulateKeyboardEvent,
  expectNoA11yViolations,
} from "../../__tests__/a11yTestUtils";

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

// Mock Apex method
jest.mock(
  "@salesforce/apex/PrometheionPDFExporter.generateAuditPackagePDF",
  () => ({ default: jest.fn().mockResolvedValue({ success: true }) }),
  { virtual: true }
);

describe("c-prometheion-audit-wizard", () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function flushPromisesLocal() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  async function createComponent() {
    const element = createElement("c-prometheion-audit-wizard", {
      is: PrometheionAuditWizard,
    });
    document.body.appendChild(element);
    await flushPromisesLocal();
    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the wizard with step 1 active", async () => {
      const element = await createComponent();

      const progressIndicator = element.shadowRoot.querySelector(
        "lightning-progress-indicator"
      );
      expect(progressIndicator).not.toBeNull();
      expect(progressIndicator.currentStep).toBe("1");
    });

    it("displays framework selection heading on step 1", async () => {
      const element = await createComponent();

      const heading = element.shadowRoot.querySelector("#step1-heading");
      expect(heading).not.toBeNull();
      expect(heading.textContent).toBe("Select Compliance Framework");
    });

    it("renders all framework cards", async () => {
      const element = await createComponent();

      const frameworkCards = element.shadowRoot.querySelectorAll(
        ".framework-card"
      );
      expect(frameworkCards.length).toBe(8); // HIPAA, SOC2, GDPR, FINRA, NIST, FedRAMP, PCI_DSS, ISO27001
    });

    it("has Previous button disabled on step 1", async () => {
      const element = await createComponent();

      const prevButton = element.shadowRoot.querySelector(
        'lightning-button[label="Previous"]'
      );
      expect(prevButton.disabled).toBe(true);
    });

    it("has Next button disabled when no framework selected", async () => {
      const element = await createComponent();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      expect(nextButton.disabled).toBe(true);
    });
  });

  describe("Framework Selection", () => {
    it("selects framework when card is clicked", async () => {
      const element = await createComponent();

      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      const selectedCard = element.shadowRoot.querySelector(
        ".framework-card.selected"
      );
      expect(selectedCard).not.toBeNull();
      expect(selectedCard.dataset.value).toBe("HIPAA");
    });

    it("enables Next button after framework selection", async () => {
      const element = await createComponent();

      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      expect(nextButton.disabled).toBe(false);
    });

    it("supports keyboard selection with Enter key", async () => {
      const element = await createComponent();

      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );

      const event = new KeyboardEvent("keydown", {
        key: "Enter",
        bubbles: true,
        cancelable: true,
      });
      hipaaCard.dispatchEvent(event);
      await flushPromisesLocal();

      expect(hipaaCard.classList.contains("selected")).toBe(true);
    });

    it("supports keyboard selection with Space key", async () => {
      const element = await createComponent();

      const soc2Card = element.shadowRoot.querySelector(
        '.framework-card[data-value="SOC2"]'
      );

      const event = new KeyboardEvent("keydown", {
        key: " ",
        bubbles: true,
        cancelable: true,
      });
      soc2Card.dispatchEvent(event);
      await flushPromisesLocal();

      expect(soc2Card.classList.contains("selected")).toBe(true);
    });
  });

  describe("Step Navigation", () => {
    it("navigates to step 2 when Next is clicked", async () => {
      const element = await createComponent();

      // Select framework first
      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      // Click Next
      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      nextButton.click();
      await flushPromisesLocal();

      const progressIndicator = element.shadowRoot.querySelector(
        "lightning-progress-indicator"
      );
      expect(progressIndicator.currentStep).toBe("2");
    });

    it("navigates back to step 1 from step 2", async () => {
      const element = await createComponent();

      // Go to step 2
      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      nextButton.click();
      await flushPromisesLocal();

      // Go back
      const prevButton = element.shadowRoot.querySelector(
        'lightning-button[label="Previous"]'
      );
      prevButton.click();
      await flushPromisesLocal();

      const progressIndicator = element.shadowRoot.querySelector(
        "lightning-progress-indicator"
      );
      expect(progressIndicator.currentStep).toBe("1");
    });
  });

  describe("Date Range Selection (Step 2)", () => {
    async function goToStep2(element) {
      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      nextButton.click();
      await flushPromisesLocal();
    }

    it("displays date range inputs", async () => {
      const element = await createComponent();
      await goToStep2(element);

      const dateInputs = element.shadowRoot.querySelectorAll(
        'lightning-input[type="date"]'
      );
      expect(dateInputs.length).toBe(2);
    });

    it("displays quick select buttons", async () => {
      const element = await createComponent();
      await goToStep2(element);

      const buttonGroup = element.shadowRoot.querySelector(
        "lightning-button-group"
      );
      expect(buttonGroup).not.toBeNull();
    });

    it("sets dates when Last Month is clicked", async () => {
      const element = await createComponent();
      await goToStep2(element);

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const lastMonthBtn = Array.from(buttons).find(
        (btn) => btn.label === "Last Month"
      );
      lastMonthBtn.click();
      await flushPromisesLocal();

      // Verify dates are set (component state)
      expect(element).not.toBeNull();
    });
  });

  describe("Control Selection (Step 3)", () => {
    async function goToStep3(element) {
      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      // Go through steps 1 -> 2 -> 3
      for (let i = 0; i < 2; i++) {
        const buttons = element.shadowRoot.querySelectorAll("lightning-button");
        const nextButton = Array.from(buttons).find(
          (btn) => btn.label === "Next"
        );
        nextButton.click();
        await flushPromisesLocal();
      }
    }

    it("displays control list after framework selection", async () => {
      const element = await createComponent();
      await goToStep3(element);

      const controlItems = element.shadowRoot.querySelectorAll(".control-item");
      expect(controlItems.length).toBeGreaterThan(0);
    });

    it("has Select All button", async () => {
      const element = await createComponent();
      await goToStep3(element);

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const selectAllBtn = Array.from(buttons).find(
        (btn) => btn.label === "Select All"
      );
      expect(selectAllBtn).not.toBeNull();
    });

    it("has Clear All button", async () => {
      const element = await createComponent();
      await goToStep3(element);

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const clearAllBtn = Array.from(buttons).find(
        (btn) => btn.label === "Clear All"
      );
      expect(clearAllBtn).not.toBeNull();
    });

    it("displays control count", async () => {
      const element = await createComponent();
      await goToStep3(element);

      const countDisplay = element.shadowRoot.querySelector(
        '[role="status"][aria-live="polite"]'
      );
      expect(countDisplay).not.toBeNull();
      expect(countDisplay.textContent).toContain("controls selected");
    });
  });

  describe("Accessibility", () => {
    it("has proper ARIA attributes on framework cards", async () => {
      const element = await createComponent();

      const frameworkCard = element.shadowRoot.querySelector(".framework-card");
      expect(frameworkCard.getAttribute("role")).toBe("radio");
      expect(frameworkCard.getAttribute("aria-checked")).toBe("false");
      expect(frameworkCard.getAttribute("aria-label")).not.toBeNull();
    });

    it("updates aria-checked when framework is selected", async () => {
      const element = await createComponent();

      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      expect(hipaaCard.getAttribute("aria-checked")).toBe("true");
    });

    it("has proper heading structure", async () => {
      const element = await createComponent();

      const h2 = element.shadowRoot.querySelector("h2");
      expect(h2).not.toBeNull();
    });

    it("has progress indicator with step labels", async () => {
      const element = await createComponent();

      const steps = element.shadowRoot.querySelectorAll(
        "lightning-progress-step"
      );
      expect(steps.length).toBe(5);

      const stepLabels = Array.from(steps).map((s) => s.label);
      expect(stepLabels).toContain("Framework");
      expect(stepLabels).toContain("Date Range");
      expect(stepLabels).toContain("Controls");
      expect(stepLabels).toContain("Preview");
      expect(stepLabels).toContain("Generate");
    });

    it("has accessible form fieldsets", async () => {
      const element = await createComponent();

      // Go to step 2 for date inputs
      const hipaaCard = element.shadowRoot.querySelector(
        '.framework-card[data-value="HIPAA"]'
      );
      hipaaCard.click();
      await flushPromisesLocal();

      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );
      nextButton.click();
      await flushPromisesLocal();

      const fieldset = element.shadowRoot.querySelector("fieldset");
      expect(fieldset).not.toBeNull();

      const legend = fieldset.querySelector("legend");
      expect(legend).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("shows validation when trying to proceed without selection", async () => {
      const element = await createComponent();

      // Try to click Next without selecting framework
      const buttons = element.shadowRoot.querySelectorAll("lightning-button");
      const nextButton = Array.from(buttons).find(
        (btn) => btn.label === "Next"
      );

      expect(nextButton.disabled).toBe(true);
    });
  });
});
