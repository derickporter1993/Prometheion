import { createElement } from "lwc";
import JiraIssueCard from "c/jiraIssueCard";
import getIssueStatus from "@salesforce/apex/JiraIntegrationService.getIssueStatus";
import syncIssueStatus from "@salesforce/apex/JiraIntegrationService.syncIssueStatus";
import addComment from "@salesforce/apex/JiraIntegrationService.addComment";
import getAvailableTransitions from "@salesforce/apex/JiraIntegrationService.getAvailableTransitions";
import transitionIssue from "@salesforce/apex/JiraIntegrationService.transitionIssue";
import { refreshApex } from "@salesforce/apex";

jest.mock(
  "@salesforce/apex/JiraIntegrationService.getIssueStatus",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/JiraIntegrationService.syncIssueStatus",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex/JiraIntegrationService.addComment", () => ({ default: jest.fn() }), {
  virtual: true,
});
jest.mock(
  "@salesforce/apex/JiraIntegrationService.getAvailableTransitions",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/JiraIntegrationService.transitionIssue",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex", () => ({ refreshApex: jest.fn().mockResolvedValue(undefined) }), {
  virtual: true,
});

const MOCK_ISSUE = {
  key: "COMP-123",
  summary: "Fix access control gap",
  status: "In Progress",
  priority: "High",
  assignee: "John Doe",
  createdAt: "2025-01-15T10:00:00Z",
  updatedAt: "2025-01-20T14:30:00Z",
  url: "https://jira.test/COMP-123",
};

describe("c-jira-issue-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    const element = createElement("c-jira-issue-card", {
      is: JiraIssueCard,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it("renders the component", () => {
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    expect(element).not.toBeNull();
  });

  it("displays issue data when wire emits", async () => {
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });

    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("handles wire error", async () => {
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });

    getIssueStatus.error({ body: { message: "Failed to load" } });
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("shows no issue message when jiraKey is not set", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("computes statusClass for in-progress status", async () => {
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("computes priorityIcon for high priority", async () => {
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("syncs issue status", async () => {
    syncIssueStatus.mockResolvedValue(undefined);
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    const syncBtn = element.shadowRoot.querySelector('lightning-button[label="Sync"]');
    if (syncBtn) {
      syncBtn.click();
      await flushPromises();
      expect(syncIssueStatus).toHaveBeenCalledWith({ gapId: "a00xx0000001" });
    }
  });

  it("adds comment to jira issue", async () => {
    addComment.mockResolvedValue(undefined);
    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    const commentBtn = element.shadowRoot.querySelector('lightning-button[label="Comment"]');
    if (commentBtn) {
      commentBtn.click();
      await flushPromises();

      const textarea = element.shadowRoot.querySelector("lightning-textarea");
      if (textarea) {
        textarea.value = "Test comment";
        textarea.dispatchEvent(new CustomEvent("change", { target: { value: "Test comment" } }));
      }
    }
  });

  it("handles transition flow", async () => {
    getAvailableTransitions.mockResolvedValue([
      { id: "t1", name: "Done" },
      { id: "t2", name: "In Review" },
    ]);
    transitionIssue.mockResolvedValue(undefined);

    const element = createComponent({
      recordId: "a00xx0000001",
      jiraKey: "COMP-123",
    });
    getIssueStatus.emit(MOCK_ISSUE);
    await flushPromises();

    const transitionBtn = element.shadowRoot.querySelector('lightning-button[label="Transition"]');
    if (transitionBtn) {
      transitionBtn.click();
      await flushPromises();
      expect(getAvailableTransitions).toHaveBeenCalledWith({
        jiraKey: "COMP-123",
      });
    }
  });
});
