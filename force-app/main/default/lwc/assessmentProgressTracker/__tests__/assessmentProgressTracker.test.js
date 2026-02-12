import { createElement } from "lwc";
import AssessmentProgressTracker from "c/assessmentProgressTracker";

// Mock labels
jest.mock("@salesforce/label/c.AW_PercentComplete", () => ({ default: "% Complete" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_StagePrefix", () => ({ default: "Stage" }), { virtual: true });

const MOCK_STAGES = [
  {
    stageOrder: 1,
    isComplete: true,
    steps: [
      { stepId: "step1", stepOrder: 1 },
      { stepId: "step2", stepOrder: 2 },
    ],
  },
  {
    stageOrder: 2,
    isComplete: false,
    steps: [{ stepId: "step3", stepOrder: 1 }],
  },
  {
    stageOrder: 3,
    isComplete: false,
    steps: [{ stepId: "step4", stepOrder: 1 }],
  },
];

describe("c-assessment-progress-tracker", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function createComponent(props = {}) {
    const element = createElement("c-assessment-progress-tracker", {
      is: AssessmentProgressTracker,
    });
    element.stages = props.stages || MOCK_STAGES;
    element.currentStage = props.currentStage || 2;
    element.currentStep = props.currentStep || 1;
    element.percentComplete = props.percentComplete || 40;
    document.body.appendChild(element);
    return element;
  }

  it("renders progress bar", () => {
    const element = createComponent();
    const progressBar = element.shadowRoot.querySelector("lightning-progress-bar");
    expect(progressBar).not.toBeNull();
    expect(progressBar.value).toBe(40);
  });

  it("displays percent label", () => {
    const element = createComponent({ percentComplete: 75 });
    const text = element.shadowRoot.textContent;
    expect(text).toContain("75%");
  });

  it("renders stage markers for all stages", () => {
    const element = createComponent();
    const items = element.shadowRoot.querySelectorAll("li");
    expect(items.length).toBe(3);
  });

  it("marks completed stages with check icon", () => {
    const element = createComponent();
    const icons = element.shadowRoot.querySelectorAll("lightning-icon");
    const checkIcons = Array.from(icons).filter((i) => i.iconName === "utility:check");
    // Stage 1 is complete, and stage 1 < currentStage 2 (isPast)
    expect(checkIcons.length).toBeGreaterThanOrEqual(1);
  });

  it("applies active class to current stage", () => {
    const element = createComponent();
    const activeItem = element.shadowRoot.querySelector(".slds-is-active");
    expect(activeItem).not.toBeNull();
  });

  it("applies completed class to past stages", () => {
    const element = createComponent();
    const completedItems = element.shadowRoot.querySelectorAll(".slds-is-completed");
    expect(completedItems.length).toBeGreaterThanOrEqual(1);
  });

  it("returns warning variant for 50% progress", () => {
    const element = createComponent({ percentComplete: 60 });
    const progressBar = element.shadowRoot.querySelector("lightning-progress-bar");
    expect(progressBar.variant).toBe("warning");
  });

  it("returns expired variant for 100% progress", () => {
    const element = createComponent({ percentComplete: 100 });
    const progressBar = element.shadowRoot.querySelector("lightning-progress-bar");
    expect(progressBar.variant).toBe("expired");
  });

  it("returns base variant for low progress", () => {
    const element = createComponent({ percentComplete: 20 });
    const progressBar = element.shadowRoot.querySelector("lightning-progress-bar");
    expect(progressBar.variant).toBe("base");
  });

  it("has progressbar role for accessibility", () => {
    const element = createComponent();
    const progressbar = element.shadowRoot.querySelector('[role="progressbar"]');
    expect(progressbar).not.toBeNull();
  });

  it("sets aria-valuenow on progress region", () => {
    const element = createComponent({ percentComplete: 55 });
    const progressbar = element.shadowRoot.querySelector('[role="progressbar"]');
    expect(progressbar.getAttribute("aria-valuenow")).toBe("55");
  });

  it("handles empty stages gracefully", () => {
    const element = createComponent({ stages: [] });
    const items = element.shadowRoot.querySelectorAll("li");
    expect(items.length).toBe(0);
  });
});
