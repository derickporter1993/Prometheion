/**
 * Jest tests for complianceGapList LWC component
 *
 * Tests cover:
 * - Component rendering states
 * - Gap list display
 * - Empty state handling
 * - Gap data formatting
 */

import { createElement } from "lwc";
import ComplianceGapList from "c/complianceGapList";

describe("c-compliance-gap-list", () => {
  afterEach(() => {
    // Clean up DOM
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  // Helper function to create element
  function createComponent(gaps = []) {
    const element = createElement("c-compliance-gap-list", {
      is: ComplianceGapList,
    });
    element.gaps = gaps;
    document.body.appendChild(element);
    return element;
  }

  // Test data
  const mockGaps = [
    {
      Id: "gap001",
      Policy_Reference__c: "AC-1: Access Control Policy",
      Severity__c: "CRITICAL",
      Status__c: "Open",
      Risk_Score__c: 95,
    },
    {
      Id: "gap002",
      Policy_Reference__c: "AU-2: Audit Events",
      Severity__c: "HIGH",
      Status__c: "In Progress",
      Risk_Score__c: 75,
    },
    {
      Id: "gap003",
      Policy_Reference__c: "CM-1: Configuration Management",
      Severity__c: "MEDIUM",
      Status__c: "Mitigated",
      Risk_Score__c: 45,
    },
  ];

  describe("Component Rendering", () => {
    it("should render lightning-card", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
      expect(card.title).toBe("Compliance Gaps");
    });

    it("should display gap items when gaps provided", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(3);
    });

    it("should display policy reference for each gap", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const headings = element.shadowRoot.querySelectorAll(
        ".slds-text-heading_small"
      );
      expect(headings).toHaveLength(3);
      expect(headings[0].textContent).toBe("AC-1: Access Control Policy");
      expect(headings[1].textContent).toBe("AU-2: Audit Events");
      expect(headings[2].textContent).toBe("CM-1: Configuration Management");
    });

    it("should display severity for each gap", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const severityDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_2-of-3 .slds-text-body_small"
      );
      expect(severityDivs[0].textContent).toBe("CRITICAL");
      expect(severityDivs[1].textContent).toBe("HIGH");
      expect(severityDivs[2].textContent).toBe("MEDIUM");
    });

    it("should display status for each gap", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const statusDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_1-of-3 .slds-text-body_small"
      );
      expect(statusDivs[0].textContent).toBe("Status: Open");
      expect(statusDivs[2].textContent).toBe("Status: In Progress");
      expect(statusDivs[4].textContent).toBe("Status: Mitigated");
    });

    it("should display risk score for each gap", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      const riskDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_1-of-3 .slds-text-body_small"
      );
      expect(riskDivs[1].textContent).toBe("Risk: 95");
      expect(riskDivs[3].textContent).toBe("Risk: 75");
      expect(riskDivs[5].textContent).toBe("Risk: 45");
    });
  });

  describe("Empty State", () => {
    it("should show empty message when no gaps", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No compliance gaps found");
    });

    it("should not show gap items when no gaps", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(0);
    });

    it("should show info icon in empty state", async () => {
      const element = createComponent([]);
      await Promise.resolve();

      const icon = element.shadowRoot.querySelector(
        ".slds-text-color_weak lightning-icon"
      );
      expect(icon).not.toBeNull();
      expect(icon.iconName).toBe("utility:info");
    });
  });

  describe("Single Gap", () => {
    it("should display single gap correctly", async () => {
      const singleGap = [mockGaps[0]];
      const element = createComponent(singleGap);
      await Promise.resolve();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(1);

      const heading = element.shadowRoot.querySelector(".slds-text-heading_small");
      expect(heading.textContent).toBe("AC-1: Access Control Policy");
    });
  });

  describe("Multiple Gaps", () => {
    it("should handle many gaps", async () => {
      const manyGaps = [];
      for (let i = 0; i < 10; i++) {
        manyGaps.push({
          Id: `gap${i}`,
          Policy_Reference__c: `Policy ${i}`,
          Severity__c: "MEDIUM",
          Status__c: "Open",
          Risk_Score__c: i * 10,
        });
      }
      const element = createComponent(manyGaps);
      await Promise.resolve();

      const gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(10);
    });
  });

  describe("Gap Data Variations", () => {
    it("should handle gaps with zero risk score", async () => {
      const zeroRiskGap = [
        {
          Id: "gap001",
          Policy_Reference__c: "Test Policy",
          Severity__c: "LOW",
          Status__c: "Closed",
          Risk_Score__c: 0,
        },
      ];
      const element = createComponent(zeroRiskGap);
      await Promise.resolve();

      const riskDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_1-of-3 .slds-text-body_small"
      );
      expect(riskDivs[1].textContent).toBe("Risk: 0");
    });

    it("should handle gaps with high risk score", async () => {
      const highRiskGap = [
        {
          Id: "gap001",
          Policy_Reference__c: "Critical Policy",
          Severity__c: "CRITICAL",
          Status__c: "Open",
          Risk_Score__c: 100,
        },
      ];
      const element = createComponent(highRiskGap);
      await Promise.resolve();

      const riskDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_1-of-3 .slds-text-body_small"
      );
      expect(riskDivs[1].textContent).toBe("Risk: 100");
    });

    it("should handle different severity values", async () => {
      const severityGaps = [
        {
          Id: "gap001",
          Policy_Reference__c: "Policy A",
          Severity__c: "CRITICAL",
          Status__c: "Open",
          Risk_Score__c: 90,
        },
        {
          Id: "gap002",
          Policy_Reference__c: "Policy B",
          Severity__c: "HIGH",
          Status__c: "Open",
          Risk_Score__c: 70,
        },
        {
          Id: "gap003",
          Policy_Reference__c: "Policy C",
          Severity__c: "MEDIUM",
          Status__c: "Open",
          Risk_Score__c: 50,
        },
        {
          Id: "gap004",
          Policy_Reference__c: "Policy D",
          Severity__c: "LOW",
          Status__c: "Open",
          Risk_Score__c: 30,
        },
      ];
      const element = createComponent(severityGaps);
      await Promise.resolve();

      const severityDivs = element.shadowRoot.querySelectorAll(
        ".slds-col.slds-size_2-of-3 .slds-text-body_small"
      );
      expect(severityDivs[0].textContent).toBe("CRITICAL");
      expect(severityDivs[1].textContent).toBe("HIGH");
      expect(severityDivs[2].textContent).toBe("MEDIUM");
      expect(severityDivs[3].textContent).toBe("LOW");
    });
  });

  describe("Dynamic Updates", () => {
    it("should update when gaps are changed", async () => {
      const element = createComponent([mockGaps[0]]);
      await Promise.resolve();

      let gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(1);

      // Update gaps
      element.gaps = mockGaps;
      await Promise.resolve();

      gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(3);
    });

    it("should show empty state when gaps are cleared", async () => {
      const element = createComponent(mockGaps);
      await Promise.resolve();

      let gapItems = element.shadowRoot.querySelectorAll(".slds-border_bottom");
      expect(gapItems).toHaveLength(3);

      // Clear gaps
      element.gaps = [];
      await Promise.resolve();

      const emptyDiv = element.shadowRoot.querySelector(".slds-text-color_weak");
      expect(emptyDiv).not.toBeNull();
      expect(emptyDiv.textContent).toContain("No compliance gaps found");
    });
  });
});
