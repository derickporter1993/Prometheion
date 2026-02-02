/**
 * Jest tests for complianceGapList LWC component
 *
 * Tests cover:
 * - Gap list display
 * - Severity class assignment
 * - State management via DOM
 */

import { createElement } from "lwc";
import ComplianceGapList from "c/complianceGapList";

// Helper to wait for multiple microtasks
const flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

describe("c-compliance-gap-list", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-compliance-gap-list", {
      is: ComplianceGapList,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await flushPromises();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ gaps: [] });
      await flushPromises();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("State Management via DOM", () => {
    it("shows gap items when gaps exist", async () => {
      const gaps = [
        {
          Id: "gap1",
          Severity__c: "HIGH",
          Policy_Reference__c: "Test Policy",
          Status__c: "Open",
          Risk_Score__c: 75,
        },
      ];

      const element = await createComponent({ gaps });
      await flushPromises();

      // Check that gap items are rendered
      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems.length).toBe(1);

      // Verify the policy reference is displayed
      const policyText = element.shadowRoot.querySelector(".slds-text-heading_small");
      expect(policyText).not.toBeNull();
      expect(policyText.textContent).toBe("Test Policy");
    });

    it("shows empty message when gaps array is empty and not loading", async () => {
      const element = await createComponent({
        gaps: [],
        isLoading: false,
        hasError: false,
      });
      await flushPromises();

      // Check for empty state message
      const emptyMessage = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(emptyMessage).not.toBeNull();
      expect(emptyMessage.textContent).toContain("No compliance gaps found");
    });

    it("does not show loading spinner in default state", async () => {
      // Note: isLoading is @track (private), defaults to false
      const element = await createComponent({
        gaps: [],
      });
      await flushPromises();

      const spinner = element.shadowRoot.querySelector("lightning-spinner");
      expect(spinner).toBeNull();
    });

    it("does not show error message in default state", async () => {
      // Note: hasError is @track (private), defaults to false
      const element = await createComponent({
        gaps: [],
      });
      await flushPromises();

      // Error messages should not appear in default state
      const errorIcon = element.shadowRoot.querySelector(
        "lightning-icon[icon-name='utility:error']"
      );
      expect(errorIcon).toBeNull();
    });
  });

  describe("Gap List Display", () => {
    it("displays multiple gaps correctly", async () => {
      const gaps = [
        {
          Id: "gap1",
          Severity__c: "CRITICAL",
          Policy_Reference__c: "Policy 1",
          Status__c: "Open",
          Risk_Score__c: 95,
        },
        {
          Id: "gap2",
          Severity__c: "HIGH",
          Policy_Reference__c: "Policy 2",
          Status__c: "In Progress",
          Risk_Score__c: 75,
        },
        {
          Id: "gap3",
          Severity__c: "MEDIUM",
          Policy_Reference__c: "Policy 3",
          Status__c: "Closed",
          Risk_Score__c: 50,
        },
      ];

      const element = await createComponent({ gaps });
      await flushPromises();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems.length).toBe(3);

      // Check policy references
      const policyTexts = element.shadowRoot.querySelectorAll(".slds-text-heading_small");
      expect(policyTexts.length).toBe(3);
      expect(policyTexts[0].textContent).toBe("Policy 1");
      expect(policyTexts[1].textContent).toBe("Policy 2");
      expect(policyTexts[2].textContent).toBe("Policy 3");
    });

    it("displays gap severity", async () => {
      const gaps = [
        {
          Id: "gap1",
          Severity__c: "CRITICAL",
          Policy_Reference__c: "Critical Policy",
          Status__c: "Open",
          Risk_Score__c: 95,
        },
      ];

      const element = await createComponent({ gaps });
      await flushPromises();

      // Check severity text is displayed
      const severityText = element.shadowRoot.querySelector(".slds-text-body_small");
      expect(severityText).not.toBeNull();
      expect(severityText.textContent).toBe("CRITICAL");
    });

    it("displays gap status and risk score", async () => {
      const gaps = [
        {
          Id: "gap1",
          Severity__c: "HIGH",
          Policy_Reference__c: "Test Policy",
          Status__c: "In Progress",
          Risk_Score__c: 80,
        },
      ];

      const element = await createComponent({ gaps });
      await flushPromises();

      // Find status and risk elements in the right column
      const rightCol = element.shadowRoot.querySelector(".slds-size_1-of-3");
      expect(rightCol).not.toBeNull();

      const bodySmallTexts = rightCol.querySelectorAll(".slds-text-body_small");
      expect(bodySmallTexts.length).toBe(2);
      expect(bodySmallTexts[0].textContent).toContain("Status:");
      expect(bodySmallTexts[1].textContent).toContain("Risk:");
    });
  });
});
