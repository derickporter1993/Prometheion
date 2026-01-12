/**
 * Jest tests for complianceGapList LWC component
 *
 * Tests cover:
 * - Gap list display
 * - Severity class assignment
 * - State management
 */

import { createElement } from "lwc";
import ComplianceGapList from "c/complianceGapList";

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
    await Promise.resolve();
    return element;
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ gaps: [] });
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("State Management", () => {
    it("hasGaps returns true when gaps exist", async () => {
      const gaps = [
        { Id: "gap1", Severity__c: "HIGH", Title__c: "Test Gap" },
      ];

      const element = await createComponent({ gaps });
      await Promise.resolve();

      expect(element.hasGaps).toBe(true);
    });

    it("hasGaps returns false when gaps empty", async () => {
      const element = await createComponent({ gaps: [] });
      await Promise.resolve();

      expect(element.hasGaps).toBe(false);
    });

    it("isEmpty returns true when no gaps and not loading", async () => {
      const element = await createComponent({
        gaps: [],
        isLoading: false,
        hasError: false,
      });
      await Promise.resolve();

      expect(element.isEmpty).toBe(true);
    });

    it("notLoading returns true when not loading", async () => {
      const element = await createComponent({ isLoading: false });
      await Promise.resolve();

      expect(element.notLoading).toBe(true);
    });

    it("notError returns true when no error", async () => {
      const element = await createComponent({ hasError: false });
      await Promise.resolve();

      expect(element.notError).toBe(true);
    });
  });

  describe("Severity Classes", () => {
    it("returns error class for CRITICAL severity", async () => {
      const element = await createComponent({ gaps: [] });
      await Promise.resolve();

      const gap = { Severity__c: "CRITICAL" };
      const severityClassFn = element.severityClass;
      const severityClass = severityClassFn(gap);

      expect(severityClass).toContain("slds-text-color_error");
    });

    it("returns warning class for HIGH severity", async () => {
      const element = await createComponent({ gaps: [] });
      await Promise.resolve();

      const gap = { Severity__c: "HIGH" };
      const severityClassFn = element.severityClass;
      const severityClass = severityClassFn(gap);

      expect(severityClass).toContain("slds-text-color_warning");
    });

    it("returns default class for other severities", async () => {
      const element = await createComponent({ gaps: [] });
      await Promise.resolve();

      const gap = { Severity__c: "MEDIUM" };
      const severityClassFn = element.severityClass;
      const severityClass = severityClassFn(gap);

      expect(severityClass).toContain("slds-text-color_default");
    });
  });
});
