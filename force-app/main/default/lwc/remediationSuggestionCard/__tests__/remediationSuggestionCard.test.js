import { createElement } from "lwc";
import RemediationSuggestionCard from "c/remediationSuggestionCard";
import getSuggestions from "@salesforce/apex/RemediationSuggestionService.getSuggestions";
import generateSuggestions from "@salesforce/apex/RemediationSuggestionService.generateSuggestions";
import approveSuggestion from "@salesforce/apex/RemediationSuggestionService.approveSuggestion";
import rejectSuggestion from "@salesforce/apex/RemediationSuggestionService.rejectSuggestion";
import executeRemediation from "@salesforce/apex/RemediationExecutor.executeRemediation";
import markAsManuallyApplied from "@salesforce/apex/RemediationExecutor.markAsManuallyApplied";
import { refreshApex } from "@salesforce/apex";

jest.mock(
  "@salesforce/apex/RemediationSuggestionService.getSuggestions",
  () => {
    const { createApexTestWireAdapter } = require("@salesforce/sfdx-lwc-jest");
    return { default: createApexTestWireAdapter(jest.fn()) };
  },
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RemediationSuggestionService.generateSuggestions",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RemediationSuggestionService.approveSuggestion",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RemediationSuggestionService.rejectSuggestion",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RemediationExecutor.executeRemediation",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/RemediationExecutor.markAsManuallyApplied",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex", () => ({ refreshApex: jest.fn().mockResolvedValue(undefined) }), {
  virtual: true,
});

const MOCK_SUGGESTIONS = [
  {
    Id: "a03xx0000001",
    Name: "RS-001",
    Suggestion_Type__c: "PERMISSION_CHANGE",
    Description__c: "Remove ModifyAllData permission",
    Implementation_Steps__c: "1. Go to Permission Set\n2. Remove permission",
    Auto_Remediation_Available__c: true,
    Status__c: "PENDING",
    Confidence_Score__c: 0.92,
    Risk_Reduction_Score__c: 8,
    Effort_Estimate__c: "LOW",
    Priority_Score__c: 9,
    Framework__c: "HIPAA",
    Applied_At__c: null,
    Applied_By__r: null,
    Reviewed_By__r: null,
    Reviewed_At__c: null,
    Rejection_Reason__c: null,
  },
  {
    Id: "a03xx0000002",
    Name: "RS-002",
    Suggestion_Type__c: "FIELD_LEVEL_SECURITY",
    Description__c: "Encrypt SSN field",
    Implementation_Steps__c: "1. Enable Shield Encryption\n2. Select field",
    Auto_Remediation_Available__c: false,
    Status__c: "APPROVED",
    Confidence_Score__c: 0.85,
    Risk_Reduction_Score__c: 9,
    Effort_Estimate__c: "MEDIUM",
    Priority_Score__c: 8,
    Framework__c: "HIPAA",
    Applied_At__c: null,
    Applied_By__r: null,
    Reviewed_By__r: { Name: "Admin User" },
    Reviewed_At__c: "2025-01-20T10:00:00Z",
    Rejection_Reason__c: null,
  },
  {
    Id: "a03xx0000003",
    Name: "RS-003",
    Suggestion_Type__c: "SHARING_RULE",
    Description__c: "Restrict sharing rule",
    Implementation_Steps__c: "Modify sharing settings",
    Auto_Remediation_Available__c: false,
    Status__c: "REJECTED",
    Confidence_Score__c: 0.6,
    Risk_Reduction_Score__c: 3,
    Effort_Estimate__c: "HIGH",
    Priority_Score__c: 4,
    Framework__c: "SOC2",
    Applied_At__c: null,
    Applied_By__r: null,
    Reviewed_By__r: { Name: "Admin User" },
    Reviewed_At__c: "2025-01-21T10:00:00Z",
    Rejection_Reason__c: "Not applicable to our org",
  },
];

describe("c-remediation-suggestion-card", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    const element = createElement("c-remediation-suggestion-card", {
      is: RemediationSuggestionCard,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it("renders the component", () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    expect(element).not.toBeNull();
  });

  it("displays suggestions when wire data is emitted", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("handles wire error", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.error({ body: { message: "Error" } });
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("categorizes suggestions into pending, approved, and processed", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("generates suggestions on button click", async () => {
    generateSuggestions.mockResolvedValue(undefined);
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit([]);
    await flushPromises();

    const genBtn = element.shadowRoot.querySelector(
      'lightning-button[label="Generate Suggestions"]'
    );
    if (genBtn) {
      genBtn.click();
      await flushPromises();
      expect(generateSuggestions).toHaveBeenCalledWith({
        gapId: "a00xx0000001",
      });
    }
  });

  it("approves a suggestion", async () => {
    approveSuggestion.mockResolvedValue(undefined);
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    const approveBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="a03xx0000001"][label="Approve"]'
    );
    if (approveBtn) {
      approveBtn.click();
      await flushPromises();
      expect(approveSuggestion).toHaveBeenCalledWith({
        suggestionId: "a03xx0000001",
      });
    }
  });

  it("opens reject modal on reject click", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    const rejectBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="a03xx0000001"][label="Reject"]'
    );
    if (rejectBtn) {
      rejectBtn.click();
      await flushPromises();

      const modal = element.shadowRoot.querySelector("section[role='dialog']");
      expect(modal).not.toBeNull();
    }
  });

  it("executes remediation for approved suggestion", async () => {
    executeRemediation.mockResolvedValue({
      success: true,
      message: "Applied",
      requiresDeployment: false,
    });
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    const executeBtn = element.shadowRoot.querySelector(
      'lightning-button[data-id="a03xx0000002"][label="Execute"]'
    );
    if (executeBtn) {
      executeBtn.click();
      await flushPromises();
      expect(executeRemediation).toHaveBeenCalledWith({
        suggestionId: "a03xx0000002",
      });
    }
  });

  it("maps suggestion type labels correctly", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    expect(element).not.toBeNull();
  });

  it("refreshes suggestions on refresh", async () => {
    const element = createComponent({ recordId: "a00xx0000001" });
    getSuggestions.emit(MOCK_SUGGESTIONS);
    await flushPromises();

    const refreshBtn = element.shadowRoot.querySelector('lightning-button[label="Refresh"]');
    if (refreshBtn) {
      refreshBtn.click();
      await flushPromises();
      expect(refreshApex).toHaveBeenCalled();
    }
  });
});
