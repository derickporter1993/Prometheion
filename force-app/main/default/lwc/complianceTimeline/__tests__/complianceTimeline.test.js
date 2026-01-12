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

  describe("Rendering", () => {
    it("renders the component", async () => {
      const element = await createComponent({ events: [] });
      await Promise.resolve();

      expect(element).not.toBeNull();
    });
  });

  describe("Event Sorting", () => {
    it("sorts events by date (most recent first)", async () => {
      const events = [
        { type: "GAP_DETECTED", date: "2025-01-01", title: "Event 1" },
        { type: "EVIDENCE_COLLECTED", date: "2025-03-01", title: "Event 2" },
        { type: "GAP_REMEDIATED", date: "2025-02-01", title: "Event 3" },
      ];

      const element = await createComponent({ events });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted.length).toBe(3);
      expect(sorted[0].title).toBe("Event 2"); // Most recent
      expect(sorted[1].title).toBe("Event 3");
      expect(sorted[2].title).toBe("Event 1"); // Oldest
    });

    it("handles empty events array", async () => {
      const element = await createComponent({ events: [] });
      await Promise.resolve();

      expect(element.sortedEvents).toEqual([]);
    });

    it("handles null events", async () => {
      const element = await createComponent({ events: null });
      await Promise.resolve();

      expect(element.sortedEvents).toEqual([]);
    });
  });

  describe("Icon Assignment", () => {
    it("assigns correct icon for GAP_DETECTED", async () => {
      const element = await createComponent({
        events: [{ type: "GAP_DETECTED", date: "2025-01-01" }],
      });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted[0].iconName).toBe("utility:error");
    });

    it("assigns correct icon for GAP_REMEDIATED", async () => {
      const element = await createComponent({
        events: [{ type: "GAP_REMEDIATED", date: "2025-01-01" }],
      });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted[0].iconName).toBe("utility:success");
    });

    it("assigns correct icon for EVIDENCE_COLLECTED", async () => {
      const element = await createComponent({
        events: [{ type: "EVIDENCE_COLLECTED", date: "2025-01-01" }],
      });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted[0].iconName).toBe("utility:file");
    });

    it("assigns correct icon for ASSESSMENT_COMPLETE", async () => {
      const element = await createComponent({
        events: [{ type: "ASSESSMENT_COMPLETE", date: "2025-01-01" }],
      });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted[0].iconName).toBe("utility:check");
    });

    it("assigns default icon for unknown event types", async () => {
      const element = await createComponent({
        events: [{ type: "UNKNOWN_TYPE", date: "2025-01-01" }],
      });
      await Promise.resolve();

      const sorted = element.sortedEvents;
      expect(sorted[0].iconName).toBe("utility:info");
    });
  });

  describe("State Management", () => {
    it("hasEvents returns true when events exist", async () => {
      const element = await createComponent({
        events: [{ type: "GAP_DETECTED", date: "2025-01-01" }],
      });
      await Promise.resolve();

      expect(element.hasEvents).toBe(true);
    });

    it("hasEvents returns false when events are empty", async () => {
      const element = await createComponent({ events: [] });
      await Promise.resolve();

      expect(element.hasEvents).toBe(false);
    });

    it("isEmpty returns true when no events and not loading", async () => {
      const element = await createComponent({
        events: [],
        isLoading: false,
        hasError: false,
      });
      await Promise.resolve();

      expect(element.isEmpty).toBe(true);
    });
  });
});
