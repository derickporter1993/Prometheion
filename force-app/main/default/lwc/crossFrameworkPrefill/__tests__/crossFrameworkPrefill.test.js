import { createElement } from "lwc";
import CrossFrameworkPrefill from "c/crossFrameworkPrefill";
import getPrefillData from "@salesforce/apex/AssessmentWizardController.getPrefillData";

// Mock Apex
jest.mock(
  "@salesforce/apex/AssessmentWizardController.getPrefillData",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

// Mock labels
jest.mock(
  "@salesforce/label/c.AW_PrefillAvailable",
  () => ({ default: "Pre-fill data available from prior assessments" }),
  { virtual: true }
);
jest.mock("@salesforce/label/c.AW_ApplyPrefill", () => ({ default: "Apply Pre-fill" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.AW_SkipPrefill", () => ({ default: "Skip" }), { virtual: true });

const MOCK_PREFILL = {
  SOC2_Security_Scan: "passed",
  SOC2_Availability_Scan: "passed",
  SOC2_Confidentiality_Scan: "needs_review",
};

const flushPromises = () => new Promise(process.nextTick);

describe("c-cross-framework-prefill", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent(props = {}) {
    const element = createElement("c-cross-framework-prefill", {
      is: CrossFrameworkPrefill,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    return element;
  }

  it("renders loading spinner initially", () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    const spinner = element.shadowRoot.querySelector("lightning-spinner");
    expect(spinner).not.toBeNull();
  });

  it("shows banner when prefill data exists", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).not.toBeNull();
  });

  it("hides banner when no prefill data", async () => {
    getPrefillData.mockResolvedValue({});
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).toBeNull();
  });

  it("hides banner when wizardName is not provided", async () => {
    const element = createComponent();
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).toBeNull();
    expect(getPrefillData).not.toHaveBeenCalled();
  });

  it("calls getPrefillData with correct params", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    createComponent({ wizardName: "HIPAA_Assessment", framework: "HIPAA" });
    await flushPromises();

    expect(getPrefillData).toHaveBeenCalledWith({
      currentWizardName: "HIPAA_Assessment",
      framework: "HIPAA",
    });
  });

  it("passes null framework when not provided", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    expect(getPrefillData).toHaveBeenCalledWith({
      currentWizardName: "HIPAA_Assessment",
      framework: null,
    });
  });

  it("fires applyprefill event on apply click", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const handler = jest.fn();
    element.addEventListener("applyprefill", handler);

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const applyBtn = Array.from(buttons).find((b) => b.variant === "brand");
    applyBtn.click();
    await flushPromises();

    expect(handler).toHaveBeenCalled();
    expect(handler.mock.calls[0][0].detail.prefillData).toEqual(MOCK_PREFILL);
  });

  it("dismisses banner after apply", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const applyBtn = Array.from(buttons).find((b) => b.variant === "brand");
    applyBtn.click();
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).toBeNull();
  });

  it("fires skipprefill event on skip click", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const handler = jest.fn();
    element.addEventListener("skipprefill", handler);

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const skipBtn = Array.from(buttons).find((b) => b.label === "Skip");
    skipBtn.click();
    await flushPromises();

    expect(handler).toHaveBeenCalled();
  });

  it("dismisses banner after skip", async () => {
    getPrefillData.mockResolvedValue(MOCK_PREFILL);
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const buttons = element.shadowRoot.querySelectorAll("lightning-button");
    const skipBtn = Array.from(buttons).find((b) => b.label === "Skip");
    skipBtn.click();
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).toBeNull();
  });

  it("handles API error gracefully", async () => {
    getPrefillData.mockRejectedValue(new Error("Server error"));
    const element = createComponent({ wizardName: "HIPAA_Assessment" });
    await flushPromises();

    const banner = element.shadowRoot.querySelector(".slds-notify_toast");
    expect(banner).toBeNull();
  });
});
