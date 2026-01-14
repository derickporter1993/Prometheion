import { describe, it, expect } from "vitest";
import { statusCommand } from "../commands/status.js";
import { scanCommand } from "../commands/scan.js";
import { deployCommand } from "../commands/deploy.js";
import { testCommand } from "../commands/test.js";
import { orgCommand } from "../commands/org.js";
import { configCommand } from "../commands/config.js";

describe("CLI Commands", () => {
  describe("Command Exports", () => {
    it("should export statusCommand", () => {
      expect(statusCommand).toBeDefined();
      expect(statusCommand.name()).toBe("status");
    });

    it("should export scanCommand", () => {
      expect(scanCommand).toBeDefined();
      expect(scanCommand.name()).toBe("scan");
    });

    it("should export deployCommand", () => {
      expect(deployCommand).toBeDefined();
      expect(deployCommand.name()).toBe("deploy");
    });

    it("should export testCommand", () => {
      expect(testCommand).toBeDefined();
      expect(testCommand.name()).toBe("test");
    });

    it("should export orgCommand", () => {
      expect(orgCommand).toBeDefined();
      expect(orgCommand.name()).toBe("org");
    });

    it("should export configCommand", () => {
      expect(configCommand).toBeDefined();
      expect(configCommand.name()).toBe("config");
    });
  });

  describe("Command Descriptions", () => {
    it("statusCommand should have a description", () => {
      expect(statusCommand.description()).toBeTruthy();
    });

    it("scanCommand should have a description", () => {
      expect(scanCommand.description()).toBeTruthy();
    });

    it("deployCommand should have a description", () => {
      expect(deployCommand.description()).toBeTruthy();
    });
  });
});
