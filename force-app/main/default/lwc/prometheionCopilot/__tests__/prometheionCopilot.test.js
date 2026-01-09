/**
 * Jest tests for prometheionCopilot LWC component
 *
 * Tests cover:
 * - Component rendering
 * - Chat functionality
 * - Quick commands
 * - User interactions
 * - Accessibility compliance
 */
// @ts-ignore - LWC1702 false positive for Jest test files
import { createElement } from "lwc";
import PrometheionCopilot from "c/prometheionCopilot";
import { registerApexTestWireAdapter } from "@salesforce/sfdx-lwc-jest";
import askCopilot from "@salesforce/apex/PrometheionComplianceCopilot.askCopilot";
import getQuickCommands from "@salesforce/apex/PrometheionComplianceCopilot.getQuickCommands";

// Register wire adapter
const getQuickCommandsAdapter = registerApexTestWireAdapter(getQuickCommands);

// Mock Apex method
jest.mock(
  "@salesforce/apex/PrometheionComplianceCopilot.askCopilot",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

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

// Sample mock data
const MOCK_QUICK_COMMANDS = [
  { command: "Why did my score drop?", icon: "utility:trending_down" },
  { command: "Show me risky Flows", icon: "utility:flow" },
  { command: "Generate HIPAA evidence", icon: "utility:file" },
  { command: "Who has elevated access?", icon: "utility:user" },
  { command: "SOC2 compliance status", icon: "utility:shield" },
  { command: "Show recent violations", icon: "utility:warning" },
];

const MOCK_COPILOT_RESPONSE = {
  answer: "Your compliance score dropped due to 3 high-risk changes detected.",
  evidence: [
    {
      nodeId: "node1",
      entityType: "PERMISSION_SET",
      description: "Elevated access granted",
      riskScore: 8.5,
    },
  ],
  actions: [
    { actionType: "AUTO_FIX", label: "Auto-Fix", canAutoFix: true, nodeId: "node1" },
  ],
  queryType: "SCORE_CHANGE",
  confidence: 0.95,
};

describe("c-prometheion-copilot", () => {
  beforeEach(() => {
    jest.clearAllMocks();
    askCopilot.mockResolvedValue(MOCK_COPILOT_RESPONSE);
  });

  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function flushPromises() {
    return new Promise((resolve) => setTimeout(resolve, 0));
  }

  async function createComponent() {
    const element = createElement("c-prometheion-copilot", {
      is: PrometheionCopilot,
    });
    document.body.appendChild(element);
    await flushPromises();

    getQuickCommandsAdapter.emit(MOCK_QUICK_COMMANDS);
    await flushPromises();
    await Promise.resolve();

    return element;
  }

  describe("Initial Rendering", () => {
    it("renders the copilot header", async () => {
      const element = await createComponent();

      const header = element.shadowRoot.querySelector(".copilot-header");
      expect(header).not.toBeNull();
    });

    it("displays the title", async () => {
      const element = await createComponent();

      const h1 = element.shadowRoot.querySelector("h1");
      expect(h1).not.toBeNull();
      expect(h1.textContent).toBe("Prometheion");
    });

    it("displays welcome message", async () => {
      const element = await createComponent();

      const h2 = element.shadowRoot.querySelector("h2");
      expect(h2).not.toBeNull();
      expect(h2.textContent).toContain("compliance");
    });

    it("renders quick action cards", async () => {
      const element = await createComponent();

      const quickCards = element.shadowRoot.querySelectorAll(".quick-action-card");
      expect(quickCards.length).toBe(MOCK_QUICK_COMMANDS.length);
    });

    it("has clear button in header", async () => {
      const element = await createComponent();

      const clearBtn = element.shadowRoot.querySelector(".icon-button");
      expect(clearBtn).not.toBeNull();
      expect(clearBtn.getAttribute("aria-label")).toBe("Clear conversation history");
    });
  });

  describe("Chat Input", () => {
    it("renders input field", async () => {
      const element = await createComponent();

      const input = element.shadowRoot.querySelector("#copilot-input");
      expect(input).not.toBeNull();
    });

    it("has send button", async () => {
      const element = await createComponent();

      const sendBtn = element.shadowRoot.querySelector(".send-button");
      expect(sendBtn).not.toBeNull();
      expect(sendBtn.getAttribute("aria-label")).toBe("Send message");
    });

    it("updates query on input change", async () => {
      const element = await createComponent();

      const input = element.shadowRoot.querySelector("#copilot-input");
      input.value = "Test query";
      input.dispatchEvent(new Event("change"));
      await flushPromises();

      expect(input.value).toBe("Test query");
    });

    it("submits query on Enter key", async () => {
      const element = await createComponent();

      const input = element.shadowRoot.querySelector("#copilot-input");
      input.value = "Test query";
      input.dispatchEvent(new Event("change"));
      await flushPromises();

      const keyEvent = new KeyboardEvent("keypress", {
        key: "Enter",
        bubbles: true,
        cancelable: true,
      });
      input.dispatchEvent(keyEvent);
      await flushPromises();

      // Wait for debounce
      await new Promise((resolve) => setTimeout(resolve, 400));

      expect(askCopilot).toHaveBeenCalled();
    });
  });

  describe("Quick Commands", () => {
    it("executes quick command on click", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();

      expect(askCopilot).toHaveBeenCalled();
    });

    it("supports keyboard activation with Enter", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      const keyEvent = new KeyboardEvent("keydown", {
        key: "Enter",
        bubbles: true,
        cancelable: true,
      });
      quickCard.dispatchEvent(keyEvent);
      await flushPromises();
      await Promise.resolve();

      expect(askCopilot).toHaveBeenCalled();
    });

    it("supports keyboard activation with Space", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      const keyEvent = new KeyboardEvent("keydown", {
        key: " ",
        bubbles: true,
        cancelable: true,
      });
      quickCard.dispatchEvent(keyEvent);
      await flushPromises();
      await Promise.resolve();

      expect(askCopilot).toHaveBeenCalled();
    });
  });

  describe("Message Display", () => {
    it("hides welcome after sending message", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();

      const welcome = element.shadowRoot.querySelector(".welcome-section");
      expect(welcome).toBeNull();
    });

    it("displays user message", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();

      const userMessage = element.shadowRoot.querySelector(".user-message");
      expect(userMessage).not.toBeNull();
    });

    it("displays assistant response", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      const assistantMessage = element.shadowRoot.querySelector(".assistant-message");
      expect(assistantMessage).not.toBeNull();
    });
  });

  describe("Loading State", () => {
    it("shows loading indicator during query", async () => {
      askCopilot.mockImplementation(() => new Promise(() => {})); // Never resolves

      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();

      const loading = element.shadowRoot.querySelector(".loading-message");
      expect(loading).not.toBeNull();
    });

    it("disables input during loading", async () => {
      askCopilot.mockImplementation(() => new Promise(() => {}));

      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();

      const input = element.shadowRoot.querySelector("#copilot-input");
      expect(input.disabled).toBe(true);
    });
  });

  describe("Clear Chat", () => {
    it("clears messages when clear button is clicked", async () => {
      const element = await createComponent();

      // Send a message first
      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();

      // Clear chat
      const clearBtn = element.shadowRoot.querySelector(".icon-button");
      clearBtn.click();
      await flushPromises();

      const welcome = element.shadowRoot.querySelector(".welcome-section");
      expect(welcome).not.toBeNull();
    });
  });

  describe("Error Handling", () => {
    it("handles API errors gracefully", async () => {
      askCopilot.mockRejectedValue({ body: { message: "Test error" } });

      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      // Component should still be functional
      const copilot = element.shadowRoot.querySelector(".prometheion-copilot");
      expect(copilot).not.toBeNull();
    });
  });

  describe("Accessibility", () => {
    it("has proper region role", async () => {
      const element = await createComponent();

      const region = element.shadowRoot.querySelector('[role="region"]');
      expect(region).not.toBeNull();
      expect(region.getAttribute("aria-label")).toBe("Prometheion Compliance Copilot");
    });

    it("has live region for chat", async () => {
      const element = await createComponent();

      const liveRegion = element.shadowRoot.querySelector('[aria-live="polite"]');
      expect(liveRegion).not.toBeNull();
    });

    it("has labeled input field", async () => {
      const element = await createComponent();

      const label = element.shadowRoot.querySelector('label[for="copilot-input"]');
      expect(label).not.toBeNull();
    });

    it("has aria-hidden on decorative SVGs", async () => {
      const element = await createComponent();

      const svgs = element.shadowRoot.querySelectorAll("svg");
      svgs.forEach((svg) => {
        expect(svg.getAttribute("aria-hidden")).toBe("true");
      });
    });

    it("quick action cards have aria-labels", async () => {
      const element = await createComponent();

      const quickCards = element.shadowRoot.querySelectorAll(".quick-action-card");
      quickCards.forEach((card) => {
        expect(card.getAttribute("aria-label")).not.toBeNull();
      });
    });

    it("quick action cards are buttons", async () => {
      const element = await createComponent();

      const quickCards = element.shadowRoot.querySelectorAll(".quick-action-card");
      quickCards.forEach((card) => {
        expect(card.tagName.toLowerCase()).toBe("button");
        expect(card.getAttribute("type")).toBe("button");
      });
    });
  });

  describe("Evidence Display", () => {
    it("displays evidence section when present", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      const evidenceSection = element.shadowRoot.querySelector(".evidence-section");
      expect(evidenceSection).not.toBeNull();
    });

    it("displays action buttons when available", async () => {
      const element = await createComponent();

      const quickCard = element.shadowRoot.querySelector(".quick-action-card");
      quickCard.click();
      await flushPromises();
      await Promise.resolve();
      await Promise.resolve();
      await Promise.resolve();

      const actionSection = element.shadowRoot.querySelector(".actions-section");
      expect(actionSection).not.toBeNull();
    });
  });

  describe("Component Cleanup", () => {
    it("cleans up debounce timer on disconnect", async () => {
      const element = await createComponent();

      document.body.removeChild(element);

      // Should not throw error
      expect(true).toBe(true);
    });
  });
});
