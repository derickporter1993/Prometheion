import { describe, it, expect } from "vitest";
import { RestClient, RestApiError } from "../rest/client.js";
import { ToolingClient, ToolingApiError } from "../tooling/client.js";
import { BulkClient, BulkApiError } from "../bulk/client.js";
import { validateJwtConfig, AuthenticationError } from "../auth/jwt.js";
import { OAuthError } from "../auth/oauth.js";

describe("Salesforce Client", () => {
  describe("RestClient", () => {
    it("should be constructable with config", () => {
      const client = new RestClient({
        instanceUrl: "https://test.salesforce.com",
        accessToken: "test-token",
      });
      expect(client).toBeDefined();
    });

    it("should use default API version", () => {
      const client = new RestClient({
        instanceUrl: "https://test.salesforce.com",
        accessToken: "test-token",
      });
      expect(client).toBeDefined();
    });
  });

  describe("ToolingClient", () => {
    it("should be constructable with config", () => {
      const client = new ToolingClient({
        instanceUrl: "https://test.salesforce.com",
        accessToken: "test-token",
      });
      expect(client).toBeDefined();
    });
  });

  describe("BulkClient", () => {
    it("should be constructable with config", () => {
      const client = new BulkClient({
        instanceUrl: "https://test.salesforce.com",
        accessToken: "test-token",
      });
      expect(client).toBeDefined();
    });
  });

  describe("JWT Validation", () => {
    it("should return errors for missing clientId", () => {
      const errors = validateJwtConfig({
        clientId: "",
        username: "user@test.com",
        privateKey: "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
      });
      expect(errors).toContain("clientId is required");
    });

    it("should return errors for missing username", () => {
      const errors = validateJwtConfig({
        clientId: "test-client",
        username: "",
        privateKey: "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
      });
      expect(errors).toContain("username is required");
    });

    it("should return errors for invalid privateKey format", () => {
      const errors = validateJwtConfig({
        clientId: "test-client",
        username: "user@test.com",
        privateKey: "not-a-valid-key",
      });
      expect(errors).toContain("privateKey must be a valid PEM-formatted RSA private key");
    });

    it("should return empty array for valid config", () => {
      const errors = validateJwtConfig({
        clientId: "test-client",
        username: "user@test.com",
        privateKey: "-----BEGIN RSA PRIVATE KEY-----\ntest\n-----END RSA PRIVATE KEY-----",
      });
      expect(errors).toHaveLength(0);
    });
  });

  describe("Error Classes", () => {
    it("RestApiError should have statusCode and body", () => {
      const error = new RestApiError("Test error", 401, "Unauthorized");
      expect(error.message).toBe("Test error");
      expect(error.statusCode).toBe(401);
      expect(error.body).toBe("Unauthorized");
      expect(error.name).toBe("RestApiError");
    });

    it("ToolingApiError should have statusCode and body", () => {
      const error = new ToolingApiError("Test error", 404, "Not found");
      expect(error.statusCode).toBe(404);
      expect(error.name).toBe("ToolingApiError");
    });

    it("BulkApiError should be an Error", () => {
      const error = new BulkApiError("Bulk error");
      expect(error).toBeInstanceOf(Error);
      expect(error.name).toBe("BulkApiError");
    });

    it("AuthenticationError should be an Error", () => {
      const error = new AuthenticationError("Auth failed");
      expect(error).toBeInstanceOf(Error);
      expect(error.name).toBe("AuthenticationError");
    });

    it("OAuthError should be an Error", () => {
      const error = new OAuthError("OAuth failed");
      expect(error).toBeInstanceOf(Error);
      expect(error.name).toBe("OAuthError");
    });
  });
});
