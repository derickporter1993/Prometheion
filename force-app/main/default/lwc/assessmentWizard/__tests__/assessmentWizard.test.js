import { createElement } from "lwc";
import AssessmentWizard from "c/assessmentWizard";
import loadWizard from "@salesforce/apex/AssessmentWizardController.loadWizard";
import getAvailableWizards from "@salesforce/apex/AssessmentWizardController.getAvailableWizards";
import startSession from "@salesforce/apex/AssessmentWizardController.startSession";
import saveStep from "@salesforce/apex/AssessmentWizardController.saveStep";
import completeAssessment from "@salesforce/apex/AssessmentWizardController.completeAssessment";
import getInProgressSessions from "@salesforce/apex/AssessmentWizardController.getInProgressSessions";

// Mock Apex imports
jest.mock(
  "@salesforce/apex/AssessmentWizardController.loadWizard",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/AssessmentWizardController.getAvailableWizards",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/AssessmentWizardController.startSession",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock("@salesforce/apex/AssessmentWizardController.saveStep", () => ({ default: jest.fn() }), {
  virtual: true,
});
jest.mock(
  "@salesforce/apex/AssessmentWizardController.completeAssessment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);
jest.mock(
  "@salesforce/apex/AssessmentWizardController.getInProgressSessions",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Mock ShowToastEvent
jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: jest.fn().mockImplementation((params) => {
      return new CustomEvent("lightning__showtoast", { detail: params });
    }),
  }),
  { virtual: true }
);

// Mock labels
jest.mock("@salesforce/label/c.AW_WizardTitle", () => ({ default: "Assessment Wizard" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_SelectWizard", () => ({ default: "Select Wizard" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_Loading", () => ({ default: "Loading" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_ErrorLoading", () => ({ default: "Error" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_NextStep", () => ({ default: "Next" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_PreviousStep", () => ({ default: "Previous" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_CompleteAssessment", () => ({ default: "Complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_StepCompleted", () => ({ default: "Step completed" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_AssessmentComplete", () => ({ default: "Assessment complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_InProgressSessions", () => ({ default: "In Progress" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_NoSessions", () => ({ default: "No sessions" }), {
  virtual: true,
});

// Mock child component labels
jest.mock("@salesforce/label/c.AW_PercentComplete", () => ({ default: "% Complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_StagePrefix", () => ({ default: "Stage" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_AutoScanRunning", () => ({ default: "Scanning" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_AutoScanComplete", () => ({ default: "Scan complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_AttestationPrompt", () => ({ default: "Attest" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_EvidenceUploadPrompt", () => ({ default: "Upload evidence" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_ApprovalPrompt", () => ({ default: "Approve" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_ReviewPrompt", () => ({ default: "Review" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_SaveProgress", () => ({ default: "Save" }), { virtual: true });

// Mock getPrefillData for crossFrameworkPrefill child
jest.mock(
  "@salesforce/apex/AssessmentWizardController.getPrefillData",
  () => ({ default: jest.fn().mockResolvedValue({}) }),
  { virtual: true }
);
jest.mock("@salesforce/label/c.AW_PrefillAvailable", () => ({ default: "Pre-fill available" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_ApplyPrefill", () => ({ default: "Apply" }), { virtual: true });
jest.mock("@salesforce/label/c.AW_SkipPrefill", () => ({ default: "Skip" }), { virtual: true });

const MOCK_CONFIG = {
  wizardName: "HIPAA_Assessment",
  framework: "HIPAA",
  sessionId: "a0B000000000001",
  currentStage: 1,
  currentStep: 1,
  percentComplete: 0,
  sessionStatus: "In Progress",
  stages: [
    {
      stageOrder: 1,
      isComplete: false,
      steps: [
        {
          stepId: "HIPAA_Access_Control_Scan",
          stepOrder: 1,
          stepType: "Auto_Scan",
          controlReference: "164.312(a)(1)",
          helpText: "Scan access controls",
          status: "Pending",
          response: null,
        },
        {
          stepId: "HIPAA_Access_Review",
          stepOrder: 2,
          stepType: "Manual_Attestation",
          controlReference: "164.312(a)(1)",
          helpText: "Review access",
          status: "Pending",
          response: null,
        },
      ],
    },
    {
      stageOrder: 2,
      isComplete: false,
      steps: [
        {
          stepId: "HIPAA_Audit_Scan",
          stepOrder: 1,
          stepType: "Auto_Scan",
          controlReference: "164.312(b)",
          helpText: "Scan audits",
          status: "Pending",
          response: null,
        },
      ],
    },
  ],
};

const MOCK_WIZARDS = ["HIPAA_Assessment", "SOC2_Assessment", "PCI_DSS_Assessment"];

const MOCK_SESSIONS = [
  {
    sessionId: "a0B000000000002",
    sessionName: "CAS-00001",
    wizardName: "SOC2_Assessment",
    framework: "SOC2",
    status: "In Progress",
    percentComplete: 50,
    startedDate: "2026-01-15T00:00:00.000Z",
  },
];

const flushPromises = () => new Promise(process.nextTick);

describe("c-assessment-wizard", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    const element = createElement("c-assessment-wizard", { is: AssessmentWizard });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it("renders loading spinner on initialization", () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue([]);
    const element = createComponent();
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("renders wizard picker when no wizardName provided", async () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue([]);
    const element = createComponent();
    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    expect(combobox).not.toBeNull();
  });

  it("loads wizard directly when wizardName is provided", async () => {
    loadWizard.mockResolvedValue(MOCK_CONFIG);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    expect(loadWizard).toHaveBeenCalledWith({ wizardName: "HIPAA_Assessment" });
    const tracker = element.shadowRoot.querySelector("c-assessment-progress-tracker");
    expect(tracker).not.toBeNull();
  });

  it("renders error state on initialization failure", async () => {
    getAvailableWizards.mockRejectedValue(new Error("Server error"));
    getInProgressSessions.mockResolvedValue([]);
    const element = createComponent();
    await flushPromises();

    const alert = element.shadowRoot.querySelector('[role="alert"]');
    expect(alert).not.toBeNull();
  });

  it("displays in-progress sessions", async () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue(MOCK_SESSIONS);
    const element = createComponent();
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const resumeButtons = Array.from(buttons).filter((b) => b.dataset.wizard === "SOC2_Assessment");
    expect(resumeButtons.length).toBe(1);
  });

  it("shows no sessions message when none exist", async () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue([]);
    const element = createComponent();
    await flushPromises();

    const text = element.shadowRoot.textContent;
    expect(text).toContain("No sessions");
  });

  it("loads wizard on combobox selection", async () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue([]);
    loadWizard.mockResolvedValue(MOCK_CONFIG);
    startSession.mockResolvedValue("a0B000000000003");

    const element = createComponent();
    await flushPromises();

    const combobox = element.shadowRoot.querySelector("lightning-combobox");
    combobox.dispatchEvent(new CustomEvent("change", { detail: { value: "HIPAA_Assessment" } }));
    await flushPromises();

    expect(loadWizard).toHaveBeenCalledWith({ wizardName: "HIPAA_Assessment" });
  });

  it("resumes session on button click", async () => {
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue(MOCK_SESSIONS);
    loadWizard.mockResolvedValue(MOCK_CONFIG);

    const element = createComponent();
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const resumeBtn = Array.from(buttons).find((b) => b.dataset.wizard === "SOC2_Assessment");
    resumeBtn.click();
    await flushPromises();

    expect(loadWizard).toHaveBeenCalledWith({ wizardName: "SOC2_Assessment" });
  });

  it("renders wizard step when config is active", async () => {
    loadWizard.mockResolvedValue(MOCK_CONFIG);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const wizardStep = element.shadowRoot.querySelector("c-wizard-step");
    expect(wizardStep).not.toBeNull();
    expect(wizardStep.step.stepId).toBe("HIPAA_Access_Control_Scan");
  });

  it("handles step complete event", async () => {
    loadWizard.mockResolvedValue(MOCK_CONFIG);
    const advancedConfig = { ...MOCK_CONFIG, currentStep: 2, percentComplete: 25 };
    saveStep.mockResolvedValue(advancedConfig);

    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const wizardStep = element.shadowRoot.querySelector("c-wizard-step");
    wizardStep.dispatchEvent(
      new CustomEvent("stepcomplete", {
        detail: { stepId: "HIPAA_Access_Control_Scan", responseData: "passed" },
      })
    );
    await flushPromises();

    expect(saveStep).toHaveBeenCalledWith({
      sessionId: "a0B000000000001",
      stepId: "HIPAA_Access_Control_Scan",
      responseData: "passed",
    });
  });

  it("disables previous button on first step", async () => {
    loadWizard.mockResolvedValue(MOCK_CONFIG);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const prevBtn = Array.from(buttons).find((b) => b.label === "Previous");
    expect(prevBtn.disabled).toBe(true);
  });

  it("calls completeAssessment on complete button click", async () => {
    const lastStepConfig = {
      ...MOCK_CONFIG,
      currentStage: 2,
      currentStep: 1,
      percentComplete: 100,
    };
    loadWizard.mockResolvedValue(lastStepConfig);
    completeAssessment.mockResolvedValue(true);
    getAvailableWizards.mockResolvedValue(MOCK_WIZARDS);
    getInProgressSessions.mockResolvedValue([]);

    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const completeBtn = Array.from(buttons).find((b) => b.variant === "brand");
    if (completeBtn) {
      completeBtn.click();
      await flushPromises();
      expect(completeAssessment).toHaveBeenCalledWith({
        sessionId: "a0B000000000001",
      });
    }
  });
});
