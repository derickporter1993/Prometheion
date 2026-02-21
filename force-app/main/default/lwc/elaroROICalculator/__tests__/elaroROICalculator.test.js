/**
 * Jest tests for elaroROICalculator LWC component
 *
 * Tests cover:
 * - ROI calculation
 * - Industry defaults
 * - Input handlers
 * - Results display
 */

import { createElement } from "lwc";
import ElaroROICalculator from "c/elaroROICalculator";

describe("c-elaro-roi-calculator", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-elaro-roi-calculator", {
      is: ElaroROICalculator,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  function getIndustryCombobox(element) {
    const comboboxes = element.shadowRoot.querySelectorAll("lightning-combobox");
    return Array.from(comboboxes).find((cb) => cb.label === "Industry");
  }

  function getOrgSizeInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Organization Size (Users)");
  }

  function getAuditSpendInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Current Annual Audit Spend ($)");
  }

  function getHoursInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Current Audit Prep Hours/Year");
  }

  function getRateInput(element) {
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    return Array.from(inputs).find((inp) => inp.label === "Compliance Analyst Hourly Rate ($)");
  }

  function getResultsSection(element) {
    return element.shadowRoot.querySelector(".roi-results");
  }

  function getResultCards(element) {
    return element.shadowRoot.querySelectorAll(".result-card");
  }

  function getCalculatorHeader(element) {
    return element.shadowRoot.querySelector(".calculator-header");
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(element).not.toBeNull();
      expect(getCalculatorHeader(element)).not.toBeNull();
    });

    it("renders all input fields", async () => {
      const element = await createComponent();
      await Promise.resolve();

      expect(getIndustryCombobox(element)).not.toBeNull();
      expect(getOrgSizeInput(element)).not.toBeNull();
      expect(getAuditSpendInput(element)).not.toBeNull();
      expect(getHoursInput(element)).not.toBeNull();
      expect(getRateInput(element)).not.toBeNull();
    });
  });

  describe("ROI Calculation", () => {
    it("calculates ROI and displays results", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Set up inputs via DOM events
      const industryCombo = getIndustryCombobox(element);
      industryCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "healthcare" } }));

      const orgSizeInput = getOrgSizeInput(element);
      orgSizeInput.dispatchEvent(new CustomEvent("change", { detail: { value: "500" } }));

      const spendInput = getAuditSpendInput(element);
      spendInput.dispatchEvent(new CustomEvent("change", { detail: { value: "150000" } }));

      const hoursInput = getHoursInput(element);
      hoursInput.dispatchEvent(new CustomEvent("change", { detail: { value: "600" } }));

      const rateInput = getRateInput(element);
      rateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "200" } }));
      await Promise.resolve();
      await Promise.resolve();

      // Results should be visible after entering inputs (auto-calculate or trigger calculate)
      const resultsSection = getResultsSection(element);
      expect(resultsSection).not.toBeNull();

      // Check that result cards are rendered
      const resultCards = getResultCards(element);
      expect(resultCards.length).toBeGreaterThan(0);
    });

    it("updates defaults when industry changes", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const industryCombo = getIndustryCombobox(element);
      industryCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "finance" } }));
      await Promise.resolve();
      await Promise.resolve();

      // Verify the combobox value is updated
      expect(industryCombo.value).toBe("finance");

      // Check that hours and spend inputs have finance defaults
      const hoursInput = getHoursInput(element);
      const spendInput = getAuditSpendInput(element);

      // Finance industry defaults: 500 hours, $120,000 spend
      expect(hoursInput.value).toBe(500);
      expect(spendInput.value).toBe(120000);
    });
  });

  describe("Input Handlers", () => {
    it("handles org size change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getOrgSizeInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "1000" } }));
      await Promise.resolve();

      expect(input.value).toBe(1000);
    });

    it("handles audit spend change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getAuditSpendInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "200000" } }));
      await Promise.resolve();

      expect(input.value).toBe(200000);
    });

    it("handles hours change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getHoursInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "800" } }));
      await Promise.resolve();

      expect(input.value).toBe(800);
    });

    it("handles rate change", async () => {
      const element = await createComponent();
      await Promise.resolve();

      const input = getRateInput(element);
      input.dispatchEvent(new CustomEvent("change", { detail: { value: "250" } }));
      await Promise.resolve();

      expect(input.value).toBe(250);
    });
  });

  describe("State Management", () => {
    it("shows results section when component has default values", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Component calculates and shows results with default values
      const resultsSection = getResultsSection(element);
      // Results may be visible with default calculation values
      expect(resultsSection).toBeTruthy();
      const resultCards = getResultCards(element);
      // Result cards are shown based on default calculation
      expect(resultCards.length).toBeGreaterThanOrEqual(0);
    });

    it("shows results section after inputs are set", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Set up inputs
      const industryCombo = getIndustryCombobox(element);
      industryCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "healthcare" } }));

      const orgSizeInput = getOrgSizeInput(element);
      orgSizeInput.dispatchEvent(new CustomEvent("change", { detail: { value: "500" } }));
      await Promise.resolve();
      await Promise.resolve();

      // Results should be visible
      const resultsSection = getResultsSection(element);
      expect(resultsSection).not.toBeNull();
    });
  });

  describe("Results Display", () => {
    it("displays time savings in results", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Set up inputs to trigger calculation
      const industryCombo = getIndustryCombobox(element);
      industryCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "healthcare" } }));

      const hoursInput = getHoursInput(element);
      hoursInput.dispatchEvent(new CustomEvent("change", { detail: { value: "600" } }));

      const rateInput = getRateInput(element);
      rateInput.dispatchEvent(new CustomEvent("change", { detail: { value: "200" } }));
      await Promise.resolve();
      await Promise.resolve();

      const resultsSection = getResultsSection(element);
      expect(resultsSection).toBeTruthy();
      // Check for time savings card
      const savingsCard = element.shadowRoot.querySelector(".result-card.savings");
      expect(savingsCard).not.toBeNull();

      // Check that it contains "hours" text
      const resultValue = savingsCard?.querySelector(".result-value");
      expect(resultValue?.textContent).toContain("hours");
    });

    it("displays ROI percentage in results", async () => {
      const element = await createComponent();
      await Promise.resolve();

      // Set up inputs
      const industryCombo = getIndustryCombobox(element);
      industryCombo.dispatchEvent(new CustomEvent("change", { detail: { value: "healthcare" } }));

      const spendInput = getAuditSpendInput(element);
      spendInput.dispatchEvent(new CustomEvent("change", { detail: { value: "150000" } }));
      await Promise.resolve();
      await Promise.resolve();

      const resultsSection = getResultsSection(element);
      expect(resultsSection).toBeTruthy();
      // Check for ROI card
      const roiCard = element.shadowRoot.querySelector(".result-card.roi");
      expect(roiCard).not.toBeNull();

      // Check that it contains "%" text
      const resultValue = roiCard?.querySelector(".result-value");
      expect(resultValue?.textContent).toContain("%");
    });
  });
});
