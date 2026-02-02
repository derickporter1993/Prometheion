/**
 * Jest tests for complianceTimeline LWC component
 *
 * Tests cover:
 * - Event sorting
 * - Icon assignment
 * - State management
 */

import { createElement } from "lwc";
import ComplianceTimeline from "c/complianceTimeline";

describe("c-compliance-timeline", () => {
  afterEach(() => {
    while (document.body.firstChild) {
      document.body.removeChild(document.body.firstChild);
    }
  });

  async function createComponent(props = {}) {
    const element = createElement("c-compliance-timeline", {
      is: ComplianceTimeline,
    });
    Object.assign(element, props);
    document.body.appendChild(element);
    await Promise.resolve();
    return element;
  }

  function getTimelineItems(element) {
    return element.shadowRoot.querySelectorAll(".slds-timeline__item");
  }

  function getEmptyMessage(element) {
    return element.shadowRoot.querySelector(".slds-text-color_weak");
  }

  function getSpinner(element) {
    return element.shadowRoot.querySelector("lightning-spinner");
  }

  function getErrorContainer(element) {
    return element.shadowRoot.querySelector(".slds-text-color_error");
  }

  function getTimelineList(element) {
    return element.shadowRoot.querySelector(".slds-timeline");
  }

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ events: [] });
      await Promise.resolve();

      expect(element).not.toBeNull();
      expect(element.shadowRoot.querySelector("lightning-card")).not.toBeNull();
    });
  });

  describe("Event Sorting", () => {
    it("sorts events by date (most recent first)", async () => {
      const events = [
        {
          id: "1",
          type: "GAP_DETECTED",
          date: "2025-01-01",
          title: "Event 1",
          description: "Desc 1",
        },
        {
          id: "2",
          type: "EVIDENCE_COLLECTED",
          date: "2025-03-01",
          title: "Event 2",
          description: "Desc 2",
        },
        {
          id: "3",
          type: "GAP_REMEDIATED",
          date: "2025-02-01",
          title: "Event 3",
          description: "Desc 3",
        },
      ];

      const element = await createComponent({ events });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      expect(timelineItems.length).toBe(3);

      // Check the order by examining titles - most recent first
      const titles = Array.from(timelineItems).map(
        (item) => item.querySelector(".slds-text-heading_small")?.textContent
      );
      expect(titles[0]).toBe("Event 2"); // Most recent (March)
      expect(titles[1]).toBe("Event 3"); // February
      expect(titles[2]).toBe("Event 1"); // Oldest (January)
    });

    it("handles empty events array", async () => {
      const element = await createComponent({ events: [] });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      expect(timelineItems.length).toBe(0);

      // Should show empty message
      const emptyMessage = getEmptyMessage(element);
      expect(emptyMessage).not.toBeNull();
      expect(emptyMessage.textContent).toContain("No timeline events");
    });

    it("handles null events", async () => {
      const element = await createComponent({ events: null });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      expect(timelineItems.length).toBe(0);
    });
  });

  describe("Icon Assignment", () => {
    it("assigns correct icon for GAP_DETECTED", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "GAP_DETECTED",
            date: "2025-01-01",
            title: "Gap",
            description: "Gap detected",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      expect(timelineItems.length).toBe(1);

      const icon = timelineItems[0].querySelector("lightning-icon");
      expect(icon).not.toBeNull();
      expect(icon.iconName).toBe("utility:error");
    });

    it("assigns correct icon for GAP_REMEDIATED", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "GAP_REMEDIATED",
            date: "2025-01-01",
            title: "Remediated",
            description: "Gap fixed",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      const icon = timelineItems[0].querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:success");
    });

    it("assigns correct icon for EVIDENCE_COLLECTED", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "EVIDENCE_COLLECTED",
            date: "2025-01-01",
            title: "Evidence",
            description: "Evidence collected",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      const icon = timelineItems[0].querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:file");
    });

    it("assigns correct icon for ASSESSMENT_COMPLETE", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "ASSESSMENT_COMPLETE",
            date: "2025-01-01",
            title: "Complete",
            description: "Assessment done",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      const icon = timelineItems[0].querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:check");
    });

    it("assigns default icon for unknown event types", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "UNKNOWN_TYPE",
            date: "2025-01-01",
            title: "Unknown",
            description: "Unknown type",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timelineItems = getTimelineItems(element);
      const icon = timelineItems[0].querySelector("lightning-icon");
      expect(icon.iconName).toBe("utility:info");
    });
  });

  describe("State Management", () => {
    it("shows timeline when events exist", async () => {
      const element = await createComponent({
        events: [
          {
            id: "1",
            type: "GAP_DETECTED",
            date: "2025-01-01",
            title: "Event",
            description: "Desc",
          },
        ],
      });
      await Promise.resolve();
      await Promise.resolve();

      const timeline = getTimelineList(element);
      expect(timeline).not.toBeNull();
    });

    it("shows empty message when events are empty (default state)", async () => {
      // isLoading and hasError are @track (internal), not @api - they default to false
      const element = await createComponent({ events: [] });
      await Promise.resolve();
      await Promise.resolve();

      const emptyMessage = getEmptyMessage(element);
      expect(emptyMessage).not.toBeNull();
      expect(emptyMessage.textContent).toContain("No timeline events");
    });

    it("does not show spinner by default (isLoading is internal state)", async () => {
      // isLoading is @track, not @api - cannot be set externally
      // Component defaults to isLoading: false
      const element = await createComponent({ events: [] });
      await Promise.resolve();
      await Promise.resolve();

      const spinner = getSpinner(element);
      // Spinner should not be visible when isLoading defaults to false
      expect(spinner).toBeNull();
    });

    it("does not show error by default (hasError is internal state)", async () => {
      // hasError is @track, not @api - cannot be set externally
      // Component defaults to hasError: false
      const element = await createComponent({ events: [] });
      await Promise.resolve();
      await Promise.resolve();

      const errorContainer = getErrorContainer(element);
      // Error should not be visible when hasError defaults to false
      expect(errorContainer).toBeNull();
    });
  });
});
