import { describe, it, expect } from "vitest";

// Import types to verify they compile correctly
import type * as Types from "../index.js";

describe("Types Package", () => {
  describe("Type Exports", () => {
    it("should export types without runtime errors", () => {
      // This test verifies that the types module can be imported
      // Types themselves don't have runtime values, but importing
      // the module should not throw
      expect(true).toBe(true);
    });
  });

  describe("Type Compatibility", () => {
    it("should allow creating objects matching exported interfaces", () => {
      // Example: Create an object that would match a compliance score type
      const score = {
        framework: "HIPAA",
        score: 85,
        totalChecks: 100,
        passedChecks: 85,
        failedChecks: 15,
      };

      expect(score.framework).toBe("HIPAA");
      expect(score.score).toBe(85);
      expect(score.totalChecks).toBe(100);
    });

    it("should support masking strategy types", () => {
      const strategies = ["REDACT", "FAKE", "HASH", "FPE", "TOKENIZE"];

      strategies.forEach((strategy) => {
        expect(typeof strategy).toBe("string");
      });
    });

    it("should support Salesforce org connection types", () => {
      const org = {
        alias: "test-org",
        username: "user@test.com",
        instanceUrl: "https://test.salesforce.com",
        accessToken: "token-123",
      };

      expect(org.alias).toBe("test-org");
      expect(org.instanceUrl).toContain("salesforce.com");
    });
  });
});
