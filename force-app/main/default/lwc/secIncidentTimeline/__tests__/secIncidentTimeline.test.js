import { createElement } from "lwc";
import SecIncidentTimeline from "c/secIncidentTimeline";

// Mock custom labels
jest.mock("@salesforce/label/c.SEC_IncidentTimeline", () => ({ default: "Incident Timeline" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_EventType", () => ({ default: "Event Type" }), {
  virtual: true,
});
jest.mock("@salesforce/label/c.SEC_NoEvents", () => ({ default: "No events recorded" }), {
  virtual: true,
});

const MOCK_EVENTS = [
  {
    Id: "evt001",
    Event_Type__c: "Discovery",
    Description__c: "Incident discovered by SOC team",
    Event_Date__c: "2026-02-10T14:00:00.000Z",
    SLA_Status__c: "On Track",
    iconName: "utility:warning",
    formattedDate: "2/10/2026",
  },
  {
    Id: "evt002",
    Event_Type__c: "Determination",
    Description__c: "Materiality determination completed",
    Event_Date__c: "2026-02-12T10:00:00.000Z",
    SLA_Status__c: "At Risk",
    iconName: "utility:check",
    formattedDate: "2/12/2026",
  },
  {
    Id: "evt003",
    Event_Type__c: "Filing",
    Description__c: "8-K filed with SEC",
    Event_Date__c: "2026-02-14T16:00:00.000Z",
    SLA_Status__c: null,
    iconName: "utility:email",
    formattedDate: "2/14/2026",
  },
];

describe("c-sec-incident-timeline", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  function createComponent(events = []) {
    const element = createElement("c-sec-incident-timeline", {
      is: SecIncidentTimeline,
    });
    element.events = events;
    document.body.appendChild(element);
    return element;
  }

  it("renders empty state when no events provided", async () => {
    const element = createComponent([]);
    await Promise.resolve();

    const emptyText = element.shadowRoot.querySelector(".slds-text-color_weak");
    expect(emptyText).not.toBeNull();
    expect(emptyText.textContent).toBe("No events recorded");
  });

  it("renders empty state when events is null-like default", async () => {
    const element = createElement("c-sec-incident-timeline", {
      is: SecIncidentTimeline,
    });
    document.body.appendChild(element);
    await Promise.resolve();

    const timeline = element.shadowRoot.querySelector(".slds-timeline");
    // With empty default, timeline should not render
    expect(timeline).toBeNull();
  });

  it("renders timeline items when events are provided", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const items = element.shadowRoot.querySelectorAll(".slds-timeline__item");
    expect(items.length).toBe(3);
  });

  it("sorts events in reverse chronological order", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const headings = element.shadowRoot.querySelectorAll(".slds-text-heading_small");
    // Most recent first: Filing (Feb 14), Determination (Feb 12), Discovery (Feb 10)
    expect(headings.length).toBe(3);
    expect(headings[0].textContent).toBe("Filing");
    expect(headings[1].textContent).toBe("Determination");
    expect(headings[2].textContent).toBe("Discovery");
  });

  it("renders event descriptions", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const descriptions = element.shadowRoot.querySelectorAll(".slds-text-body_small");
    expect(descriptions.length).toBe(3);
    expect(descriptions[0].textContent).toBe("8-K filed with SEC");
  });

  it("renders SLA badges only when SLA_Status__c is present", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const badges = element.shadowRoot.querySelectorAll("lightning-badge");
    // evt001 has "On Track", evt002 has "At Risk", evt003 has null SLA
    expect(badges.length).toBe(2);
  });

  it("renders within a lightning-card with correct title", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const card = element.shadowRoot.querySelector("lightning-card");
    expect(card).not.toBeNull();
    expect(card.title).toBe("Incident Timeline");
    expect(card.iconName).toBe("standard:timeline");
  });

  it("renders lightning-icon for each event", async () => {
    const element = createComponent(MOCK_EVENTS);
    await Promise.resolve();

    const icons = element.shadowRoot.querySelectorAll("lightning-icon");
    expect(icons.length).toBe(3);
  });
});
