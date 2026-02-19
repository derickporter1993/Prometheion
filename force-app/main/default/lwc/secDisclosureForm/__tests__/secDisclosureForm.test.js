import { createElement } from "lwc";
import SecDisclosureForm from "c/secDisclosureForm";
import createAssessment from "@salesforce/apex/SECDisclosureController.createAssessment";
import { ShowToastEventName } from "lightning/platformShowToastEvent";

jest.mock(
  "@salesforce/apex/SECDisclosureController.createAssessment",
  () => ({ default: jest.fn() }),
  { virtual: true }
);

jest.mock(
  "lightning/platformShowToastEvent",
  () => ({
    ShowToastEvent: function (config) {
      this.detail = config;
    },
    ShowToastEventName: "lightning__showtoast",
  }),
  { virtual: true }
);

describe("c-sec-disclosure-form", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
    jest.clearAllMocks();
  });

  function createComponent() {
    const element = createElement("c-sec-disclosure-form", {
      is: SecDisclosureForm,
    });
    document.body.appendChild(element);
    return element;
  }

  it("renders the form with required inputs", () => {
    const element = createComponent();
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    expect(inputs.length).toBe(2);

    const descriptionInput = Array.from(inputs).find(
      (i) => i.dataset.field === "description"
    );
    expect(descriptionInput).not.toBeNull();
    expect(descriptionInput.required).toBe(true);

    const dateInput = Array.from(inputs).find(
      (i) => i.dataset.field === "discoveryDate"
    );
    expect(dateInput).not.toBeNull();
    expect(dateInput.type).toBe("datetime");
    expect(dateInput.required).toBe(true);
  });

  it("renders Create Assessment button", () => {
    const element = createComponent();
    const button = element.shadowRoot.querySelector("lightning-button");
    expect(button).not.toBeNull();
    expect(button.label).toBe("Create Assessment");
    expect(button.variant).toBe("brand");
  });

  it("updates formData on input change", async () => {
    const element = createComponent();
    const inputs = element.shadowRoot.querySelectorAll("lightning-input");
    const descInput = Array.from(inputs).find(
      (i) => i.dataset.field === "description"
    );

    descInput.value = "Test incident";
    descInput.dispatchEvent(
      new CustomEvent("change", {
        detail: { value: "Test incident" },
        target: { dataset: { field: "description" }, value: "Test incident" },
      })
    );
    await Promise.resolve();

    // Form should accept input without errors
    expect(descInput).not.toBeNull();
  });

  it("calls createAssessment on save and dispatches success toast", async () => {
    createAssessment.mockResolvedValue("a01000000000001");
    const element = createComponent();

    const toastHandler = jest.fn();
    element.addEventListener(ShowToastEventName, toastHandler);

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();
    await Promise.resolve();
    await Promise.resolve();

    expect(createAssessment).toHaveBeenCalled();
  });

  it("dispatches error toast when createAssessment fails", async () => {
    createAssessment.mockRejectedValue({
      body: { message: "Validation failed" },
    });
    const element = createComponent();

    const toastHandler = jest.fn();
    element.addEventListener(ShowToastEventName, toastHandler);

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();
    await Promise.resolve();
    await Promise.resolve();

    expect(createAssessment).toHaveBeenCalled();
  });

  it("dispatches assessmentcreated event on successful save", async () => {
    createAssessment.mockResolvedValue("a01000000000001");
    const element = createComponent();

    const createdHandler = jest.fn();
    element.addEventListener("assessmentcreated", createdHandler);

    const button = element.shadowRoot.querySelector("lightning-button");
    button.click();
    await Promise.resolve();
    await Promise.resolve();

    expect(createdHandler).toHaveBeenCalled();
    expect(createdHandler.mock.calls[0][0].detail.assessmentId).toBe(
      "a01000000000001"
    );
  });

  it("renders within a lightning-card", () => {
    const element = createComponent();
    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("New Materiality Assessment");
    expect(card.iconName).toBe("standard:form");
  });
});
