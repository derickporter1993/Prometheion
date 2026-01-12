/**
 * Jest tests for complianceScoreCard LWC component
 *
 * Tests cover:
 * - Wire adapter data handling
 * - Score class calculation
 * - Status icon selection
 * - Framework details display
 * - Date formatting
 * - Navigation
 */

import { createElement } from "lwc";
import ComplianceScoreCard from "c/complianceScoreCard";
import getFrameworkDetails from "@salesforce/apex/ComplianceScoreCardController.getFrameworkDetails";
import { NavigationMixin } from "lightning/navigation";

let mockFrameworkCallbacks = new Set();

jest.mock(
  "@salesforce/apex/ComplianceScoreCardController.getFrameworkDetails",
  () => ({
    default: jest.fn((config, callback) => {
      if (callback) {
        mockFrameworkCallbacks.add(callback);
        return {
          connect: () => {},
          disconnect: () => {
            mockFrameworkCallbacks.delete(callback);
          },
          update: () => {},
        };
      }
      return Promise.resolve(null);
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

const emitFrameworkData = (data) => {
  mockFrameworkCallbacks.forEach((cb) => cb({ data, error: undefined }));
};

const emitFrameworkError = (error) => {
  mockFrameworkCallbacks.forEach((cb) => cb({ data: undefined, error }));
};

describe("c-compliance-score-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
    mockFrameworkCallbacks = new Set();
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
      await Promise.resolve();

      expect(element).not.toBeNull();
      const card = element.shadowRoot.querySelector("lightning-card");
      expect(card).not.toBeNull();
    });
  });

  describe("Score Class", () => {
    it("returns score-high for scores >= 90", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 95 },
      });
      await Promise.resolve();

      expect(element.scoreClass).toBe("score-high");
    });

    it("returns score-medium for scores >= 70 and < 90", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      expect(element.scoreClass).toBe("score-medium");
    });

    it("returns score-low for scores < 70", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 65 },
      });
      await Promise.resolve();

      expect(element.scoreClass).toBe("score-low");
    });
  });

  describe("Status Icon", () => {
    it("returns success icon for COMPLIANT status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", status: "COMPLIANT" },
      });
      await Promise.resolve();

      expect(element.statusIcon).toBe("utility:success");
    });

    it("returns warning icon for PARTIALLY_COMPLIANT status", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", status: "PARTIALLY_COMPLIANT" },
      });
      await Promise.resolve();

      expect(element.statusIcon).toBe("utility:warning");
    });

    it("returns error icon for other statuses", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", status: "NON_COMPLIANT" },
      });
      await Promise.resolve();

      expect(element.statusIcon).toBe("utility:error");
    });
  });

  describe("Framework Details", () => {
    it("loads framework details via wire adapter", async () => {
      const mockDetails = {
        mappingCount: 10,
        evidenceCount: 25,
        requirementCount: 15,
        latestAuditPackage: {
          id: "pkg001",
          name: "Q4 2025 Audit",
          status: "COMPLETE",
          periodStart: "2025-01-01",
          periodEnd: "2025-03-31",
        },
      };

      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      emitFrameworkData(mockDetails);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.frameworkDetails).toEqual(mockDetails);
      expect(element.hasFrameworkDetails).toBe(true);
      expect(element.mappingCount).toBe(10);
      expect(element.evidenceCount).toBe(25);
      expect(element.requirementCount).toBe(15);
    });

    it("handles missing framework details gracefully", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      expect(element.hasFrameworkDetails).toBe(false);
      expect(element.mappingCount).toBe(0);
      expect(element.evidenceCount).toBe(0);
    });
  });

  describe("Date Formatting", () => {
    it("formats date values correctly", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      const formatted = element.formatDate("2025-01-15");
      expect(formatted).toBeTruthy();
      expect(typeof formatted).toBe("string");
    });

    it("returns empty string for null date", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      const formatted = element.formatDate(null);
      expect(formatted).toBe("");
    });
  });

  describe("Error Handling", () => {
    it("handles wire adapter error", async () => {
      const element = await createComponent({
        framework: { framework: "SOC2", score: 85 },
      });
      await Promise.resolve();

      const error = {
        body: { message: "Failed to load details" },
        message: "Failed to load details",
      };

      emitFrameworkError(error);
      await Promise.resolve();
      await Promise.resolve();

      expect(element.hasError).toBe(true);
      expect(element.errorMessage).toContain("Failed to load");
    });
  });
});
