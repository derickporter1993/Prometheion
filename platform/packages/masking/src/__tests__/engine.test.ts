import { describe, it, expect } from "vitest";
import { MaskingEngine } from "../engine.js";
import { redact } from "../strategies/redact.js";
import { hash } from "../strategies/hash.js";
import type { MaskingPolicy } from "@platform/types";

// Test policy for MaskingEngine tests
const createTestPolicy = (): MaskingPolicy => ({
  id: "test-policy-1",
  workspaceId: "test-workspace",
  name: "Test Policy",
  version: 1,
  rules: [],
  isDefault: false,
  createdAt: new Date(),
  updatedAt: new Date(),
});

describe("Masking Engine", () => {
  describe("MaskingEngine", () => {
    it("should be constructable with a policy", () => {
      const policy = createTestPolicy();
      const engine = new MaskingEngine(policy);
      expect(engine).toBeDefined();
    });
  });

  describe("Redact Strategy", () => {
    it("should redact string values", () => {
      const result = redact("sensitive data", {});
      expect(result).not.toBe("sensitive data");
      expect(result).toBe("[REDACTED]");
    });

    it("should handle empty strings", () => {
      const result = redact("", {});
      expect(result).toBe("");
    });
  });

  describe("Hash Strategy", () => {
    it("should hash string values", () => {
      const result = hash("test value", { deterministic: true });
      expect(result).toBeDefined();
      expect(typeof result).toBe("string");
    });

    it("should produce consistent hashes", () => {
      const result1 = hash("same input", { deterministic: true });
      const result2 = hash("same input", { deterministic: true });
      expect(result1).toBe(result2);
    });

    it("should produce different hashes for different inputs", () => {
      const result1 = hash("input one", { deterministic: true });
      const result2 = hash("input two", { deterministic: true });
      expect(result1).not.toBe(result2);
    });
  });
});
