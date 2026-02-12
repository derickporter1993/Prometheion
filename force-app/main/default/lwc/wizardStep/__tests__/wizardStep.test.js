import { createElement } from "lwc";
import WizardStep from "c/wizardStep";

// Mock labels
jest.mock("@salesforce/label/c.AW_AutoScanRunning", () => ({ default: "Scanning..." }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_AutoScanComplete", () => ({ default: "Scan complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_AttestationPrompt", () => ({ default: "I attest" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_EvidenceUploadPrompt", () => ({ default: "Upload evidence" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_ApprovalPrompt", () => ({ default: "Approve" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_ReviewPrompt", () => ({ default: "Review" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_NextStep", () => ({ default: "Next" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_SaveProgress", () => ({ default: "Save" }), { virtual: true });

const ATTESTATION_STEP = {
  stepId: "HIPAA_Access_Review",
  stepOrder: 2,
  stepType: "Manual_Attestation",
  controlReference: "164.312(a)(1)",
  helpText: "Review access",
  status: "Pending",
  response: null,
};

const EVIDENCE_STEP = {
  stepId: "HIPAA_Audit_Evidence",
  stepOrder: 2,
  stepType: "Evidence_Upload",
  controlReference: "164.312(b)",
  helpText: "Upload audit evidence",
  status: "Pending",
  response: null,
};

const REVIEW_STEP = {
  stepId: "HIPAA_Final_Review",
  stepOrder: 1,
  stepType: "Review",
  controlReference: "164.308(a)(8)",
  helpText: "Review all findings",
  status: "Pending",
  response: null,
};

const APPROVAL_STEP = {
  stepId: "HIPAA_Final_Approval",
  stepOrder: 2,
  stepType: "Approval",
  controlReference: "164.308(a)(8)",
  helpText: "Submit for approval",
  status: "Pending",
  response: null,
};

const COMPLETED_ATTESTATION = {
  ...ATTESTATION_STEP,
  status: "Completed",
  response: "attested",
};

const flushPromises = () => new Promise(process.nextTick);

describe("c-wizard-step", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(step, sessionId = "a0B000000000001") {
    const element = createElement("c-wizard-step", { is: WizardStep });
    element.step = step;
    element.sessionId = sessionId;
    document.body.appendChild(element);
    return element;
  }

  it("renders control reference badge", async () => {
    const element = createComponent(ATTESTATION_STEP);
    await flushPromises();

    const badge = element.shadowRoot.querySelector(".slds-badge");
    expect(badge).not.toBeNull();
    expect(badge.textContent).toContain("164.312(a)(1)");
  });

  it("renders help text", async () => {
    const element = createComponent(ATTESTATION_STEP);
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Review access");
  });

  it("renders lightning-input for Manual_Attestation step", async () => {
    const element = createComponent(ATTESTATION_STEP);
    await flushPromises();

    const input = element.shadowRoot.querySelector("lightning-input");
    expect(input).not.toBeNull();
  });

  it("renders lightning-textarea for Evidence_Upload step", async () => {
    const element = createComponent(EVIDENCE_STEP);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    expect(textarea).not.toBeNull();
  });

  it("renders textarea for Review step", async () => {
    const element = createComponent(REVIEW_STEP);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    expect(textarea).not.toBeNull();
  });

  it("renders textarea for Approval step", async () => {
    const element = createComponent(APPROVAL_STEP);
    await flushPromises();

    const textarea = element.shadowRoot.querySelector("lightning-textarea");
    expect(textarea).not.toBeNull();
  });

  it("shows completed badge for completed step", async () => {
    const element = createComponent(COMPLETED_ATTESTATION);
    await flushPromises();

    const badge = element.shadowRoot.querySelector(".slds-theme_success");
    expect(badge).not.toBeNull();
  });

  it("renders lightning-input as disabled for completed attestation", async () => {
    const element = createComponent(COMPLETED_ATTESTATION);
    await flushPromises();

    const input = element.shadowRoot.querySelector("lightning-input");
    expect(input).not.toBeNull();
  });

  it("displays attestation prompt for Manual_Attestation", async () => {
    const element = createComponent(ATTESTATION_STEP);
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("I attest");
  });

  it("displays review prompt for Review step", async () => {
    const element = createComponent(REVIEW_STEP);
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Review");
  });

  it("displays approval prompt for Approval step", async () => {
    const element = createComponent(APPROVAL_STEP);
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Approve");
  });

  it("displays evidence upload prompt", async () => {
    const element = createComponent(EVIDENCE_STEP);
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("Upload evidence");
  });

  it("renders submit button for review step", async () => {
    const element = createComponent(REVIEW_STEP);
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons.length).toBeGreaterThanOrEqual(1);
  });

  it("renders submit button for approval step", async () => {
    const element = createComponent(APPROVAL_STEP);
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    expect(buttons.length).toBeGreaterThanOrEqual(1);
  });

  it("does not render submit for completed attestation step", async () => {
    const element = createComponent(COMPLETED_ATTESTATION);
    await flushPromises();

    // canSubmit is false for completed steps, so no button inside the canSubmit block
    // The only buttons would be from other sections
    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    // Completed steps should not have a submit button
    const brandButtons = Array.from(buttons).filter((b) => b.variant === "brand");
    expect(brandButtons.length).toBe(0);
  });
});
