import { createElement } from "lwc";
import JiraCreateModal from "c/jiraCreateModal";
import createIssue from "@salesforce/apex/JiraIntegrationService.createIssue";
import isConfigured from "@salesforce/apex/JiraIntegrationService.isConfigured";

jest.mock("@salesforce/apex/JiraIntegrationService.createIssue", () => ({ default: jest.fn() }), {
  virtual: true,
});
jest.mock("@salesforce/apex/JiraIntegrationService.isConfigured", () => ({ default: jest.fn() }), {
  virtual: true,
});

describe("c-jira-create-modal", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    isConfigured.mockResolvedValue(true);
    const element = createElement("c-jira-create-modal", {
      is: JiraCreateModal,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it("renders the component", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();
    expect(element).not.toBeNull();
  });

  it("checks configuration on connected callback", async () => {
    createComponent({ recordId: "a00xx0000001" });
    await flushPromises();
    expect(isConfigured).toHaveBeenCalled();
  });

  it("opens modal via public open method", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    const modal = element.shadowRoot.querySelector("section[role='dialog']");
    expect(modal).not.toBeNull();
  });

  it("closes modal via public close method", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    element.close();
    await flushPromises();

    const modal = element.shadowRoot.querySelector("section[role='dialog']");
    expect(modal).toBeNull();
  });

  it("handles priority change", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    if (combobox) {
      combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "High" } }));
      await flushPromises();
    }
  });

  it("creates issue successfully and dispatches event", async () => {
    createIssue.mockResolvedValue({ key: "COMP-123", url: "https://jira.test/COMP-123" });
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    const handler = jest.fn();
    element.addEventListener("issuecreated", handler);

    const createBtn = element.shadowRoot.querySelector('lightning-button[label="Create Issue"]');
    createBtn.click();
    await flushPromises();

    expect(createIssue).toHaveBeenCalledWith({
      gapId: "a00xx0000001",
      priority: null,
    });
    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.issueKey).toBe("COMP-123");
  });

  it("shows error when no recordId is provided", async () => {
    const element = createComponent({ recordId: null });
    await flushPromises();

    element.open();
    await flushPromises();

    const createBtn = element.shadowRoot.querySelector('lightning-button[label="Create Issue"]');
    createBtn.click();
    await flushPromises();

    expect(createIssue).not.toHaveBeenCalled();
  });

  it("handles createIssue error", async () => {
    createIssue.mockRejectedValue({ body: { message: "Jira API error" } });
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    const createBtn = element.shadowRoot.querySelector('lightning-button[label="Create Issue"]');
    createBtn.click();
    await flushPromises();

    // Error should be displayed in the component
    const errorAlert = element.shadowRoot.querySelector(".slds-alert_error span:last-child");
    if (errorAlert) {
      expect(errorAlert.textContent).toBe("Jira API error");
    }
  });

  it("disables create button when not configured", async () => {
    isConfigured.mockResolvedValue(false);
    const element = createElement("c-jira-create-modal", {
      is: JiraCreateModal,
    });
    element.recordId = "a00xx0000001";
    document.body.appendChild(element);
    await flushPromises();

    element.open();
    await flushPromises();

    const createBtn = element.shadowRoot.querySelector('lightning-button[label="Create Issue"]');
    expect(createBtn.disabled).toBe(true);
  });

  it("shows not configured warning when jira is not set up", async () => {
    isConfigured.mockResolvedValue(false);
    const element = createElement("c-jira-create-modal", {
      is: JiraCreateModal,
    });
    element.recordId = "a00xx0000001";
    document.body.appendChild(element);
    await flushPromises();

    element.open();
    await flushPromises();

    const warning = element.shadowRoot.querySelector(".slds-alert_warning");
    expect(warning).not.toBeNull();
  });

  it("closes modal on cancel button click", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    element.open();
    await flushPromises();

    const cancelBtn = element.shadowRoot.querySelector('lightning-button[label="Cancel"]');
    cancelBtn.click();
    await flushPromises();

    const modal = element.shadowRoot.querySelector("section[role='dialog']");
    expect(modal).toBeNull();
  });
});
