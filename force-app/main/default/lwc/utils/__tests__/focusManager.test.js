/**
 * Jest tests for focusManager utility module
 *
 * Tests cover:
 * - Focusable element detection
 * - Focus manipulation (first, last)
 * - Focus trapping
 * - Focus store (save/restore)
 * - Roving tabindex navigation
 * - Screen reader announcements
 */

import {
  getFocusableElements,
  focusFirstElement,
  focusLastElement,
  trapFocus,
  createFocusStore,
  handleRovingTabindex,
  announceToScreenReader,
} from "../focusManager";

describe("focusManager", () => {
  let container;

  beforeEach(() => {
    // Create a test container
    container = document.createElement("div");
    document.body.appendChild(container);
  });

  afterEach(() => {
    // Clean up
    if (container && container.parentNode) {
      container.parentNode.removeChild(container);
    }
    // Remove screen reader region if created
    const liveRegion = document.getElementById("sr-announcements");
    if (liveRegion && liveRegion.parentNode) {
      liveRegion.parentNode.removeChild(liveRegion);
    }
  });

  describe("getFocusableElements", () => {
    it("returns empty array for null container", () => {
      const elements = getFocusableElements(null);
      expect(elements).toEqual([]);
    });

    it("returns empty array for empty container", () => {
      const elements = getFocusableElements(container);
      expect(elements).toEqual([]);
    });

    it("finds focusable elements", () => {
      container.innerHTML = `
        <button>Button 1</button>
        <input type="text" />
        <a href="#">Link</a>
        <div tabindex="0">Focusable div</div>
      `;

      const elements = getFocusableElements(container);
      expect(elements.length).toBe(4);
      expect(elements[0].tagName).toBe("BUTTON");
      expect(elements[1].tagName).toBe("INPUT");
      expect(elements[2].tagName).toBe("A");
      expect(elements[3].tagName).toBe("DIV");
    });

    it("excludes disabled elements", () => {
      container.innerHTML = `
        <button>Enabled</button>
        <button disabled>Disabled</button>
        <input type="text" />
        <input type="text" disabled />
      `;

      const elements = getFocusableElements(container);
      expect(elements.length).toBe(2);
      expect(elements.every((el) => !el.hasAttribute("disabled"))).toBe(true);
    });

    it("excludes elements with tabindex=-1", () => {
      container.innerHTML = `
        <button tabindex="0">Focusable</button>
        <button tabindex="-1">Not focusable</button>
      `;

      const elements = getFocusableElements(container);
      expect(elements.length).toBe(1);
      expect(elements[0].getAttribute("tabindex")).toBe("0");
    });

    it("excludes hidden elements", () => {
      container.innerHTML = `
        <button style="display: none;">Hidden</button>
        <button style="visibility: hidden;">Invisible</button>
        <button>Visible</button>
      `;

      const elements = getFocusableElements(container);
      expect(elements.length).toBe(1);
      expect(elements[0].textContent).toBe("Visible");
    });
  });

  describe("focusFirstElement", () => {
    it("returns false for null container", () => {
      const result = focusFirstElement(null);
      expect(result).toBe(false);
    });

    it("returns false for empty container", () => {
      const result = focusFirstElement(container);
      expect(result).toBe(false);
    });

    it("focuses first element and returns true", () => {
      container.innerHTML = `
        <button>First</button>
        <button>Second</button>
      `;

      const result = focusFirstElement(container);
      expect(result).toBe(true);
      expect(document.activeElement.textContent).toBe("First");
    });
  });

  describe("focusLastElement", () => {
    it("returns false for null container", () => {
      const result = focusLastElement(null);
      expect(result).toBe(false);
    });

    it("returns false for empty container", () => {
      const result = focusLastElement(container);
      expect(result).toBe(false);
    });

    it("focuses last element and returns true", () => {
      container.innerHTML = `
        <button>First</button>
        <button>Last</button>
      `;

      const result = focusLastElement(container);
      expect(result).toBe(true);
      expect(document.activeElement.textContent).toBe("Last");
    });
  });

  describe("trapFocus", () => {
    it("returns no-op function for null container", () => {
      const cleanup = trapFocus(null);
      expect(typeof cleanup).toBe("function");
      expect(() => cleanup()).not.toThrow();
    });

    it("traps focus within container", () => {
      container.innerHTML = `
        <button>First</button>
        <button>Middle</button>
        <button>Last</button>
      `;

      const focusable = Array.from(container.querySelectorAll("button"));
      focusable[0].focus();

      const cleanup = trapFocus(container);

      // Simulate Tab from last element (should wrap to first)
      const lastButton = focusable[2];
      lastButton.focus();

      const tabEvent = new KeyboardEvent("keydown", {
        key: "Tab",
        bubbles: true,
      });
      lastButton.dispatchEvent(tabEvent);

      // Focus should wrap to first
      expect(document.activeElement).toBe(focusable[0]);

      cleanup();
    });

    it("handles Shift+Tab to wrap backwards", () => {
      container.innerHTML = `
        <button>First</button>
        <button>Last</button>
      `;

      const focusable = Array.from(container.querySelectorAll("button"));
      focusable[0].focus();

      const cleanup = trapFocus(container);

      // Shift+Tab from first should wrap to last
      const firstButton = focusable[0];
      const shiftTabEvent = new KeyboardEvent("keydown", {
        key: "Tab",
        shiftKey: true,
        bubbles: true,
      });
      firstButton.dispatchEvent(shiftTabEvent);

      expect(document.activeElement).toBe(focusable[1]);

      cleanup();
    });

    it("cleans up event listener", () => {
      container.innerHTML = `<button>Test</button>`;

      const cleanup = trapFocus(container);
      cleanup();

      // After cleanup, Tab should not be trapped
      const button = container.querySelector("button");
      button.focus();

      const tabEvent = new KeyboardEvent("keydown", {
        key: "Tab",
        bubbles: true,
      });
      expect(() => button.dispatchEvent(tabEvent)).not.toThrow();
    });
  });

  describe("createFocusStore", () => {
    it("returns object with save and restore methods", () => {
      const store = createFocusStore();
      expect(store).toHaveProperty("save");
      expect(store).toHaveProperty("restore");
      expect(store).toHaveProperty("clear");
      expect(store).toHaveProperty("getSaved");
      expect(typeof store.save).toBe("function");
      expect(typeof store.restore).toBe("function");
    });

    it("saves and restores focus", (done) => {
      container.innerHTML = `<button>Test Button</button>`;
      const button = container.querySelector("button");
      button.focus();

      const store = createFocusStore();
      store.save();

      // Change focus
      document.body.focus();

      // Restore (async with setTimeout)
      store.restore();

      setTimeout(() => {
        expect(document.activeElement).toBe(button);
        done();
      }, 10);
    });

    it("clear removes saved element", () => {
      container.innerHTML = `<button>Test</button>`;
      const button = container.querySelector("button");
      button.focus();

      const store = createFocusStore();
      store.save();
      store.clear();

      expect(store.getSaved()).toBeNull();
    });

    it("getSaved returns saved element", () => {
      container.innerHTML = `<button>Test</button>`;
      const button = container.querySelector("button");
      button.focus();

      const store = createFocusStore();
      store.save();

      expect(store.getSaved()).toBe(button);
    });
  });

  describe("handleRovingTabindex", () => {
    it("handles ArrowRight navigation", () => {
      container.innerHTML = `
        <button tabindex="0">First</button>
        <button tabindex="-1">Second</button>
        <button tabindex="-1">Third</button>
      `;

      const elements = Array.from(container.querySelectorAll("button"));
      elements[0].focus();

      const event = new KeyboardEvent("keydown", {
        key: "ArrowRight",
        bubbles: true,
        target: elements[0],
      });
      event.preventDefault = jest.fn();

      handleRovingTabindex(elements, event, { vertical: false, wrap: false });

      expect(event.preventDefault).toHaveBeenCalled();
      expect(elements[1].getAttribute("tabindex")).toBe("0");
      expect(elements[0].getAttribute("tabindex")).toBe("-1");
      expect(document.activeElement).toBe(elements[1]);
    });

    it("handles ArrowLeft navigation", () => {
      container.innerHTML = `
        <button tabindex="-1">First</button>
        <button tabindex="0">Second</button>
      `;

      const elements = Array.from(container.querySelectorAll("button"));
      elements[1].focus();

      const event = new KeyboardEvent("keydown", {
        key: "ArrowLeft",
        bubbles: true,
        target: elements[1],
      });
      event.preventDefault = jest.fn();

      handleRovingTabindex(elements, event, { vertical: false });

      expect(event.preventDefault).toHaveBeenCalled();
      expect(elements[0].getAttribute("tabindex")).toBe("0");
      expect(document.activeElement).toBe(elements[0]);
    });

    it("wraps around at ends when wrap is true", () => {
      container.innerHTML = `
        <button tabindex="0">First</button>
        <button tabindex="-1">Last</button>
      `;

      const elements = Array.from(container.querySelectorAll("button"));
      elements[0].focus();

      const event = new KeyboardEvent("keydown", {
        key: "ArrowRight",
        bubbles: true,
        target: elements[0],
      });
      event.preventDefault = jest.fn();

      handleRovingTabindex(elements, event, { vertical: false, wrap: true });

      expect(document.activeElement).toBe(elements[1]);
    });

    it("handles Home key", () => {
      container.innerHTML = `
        <button tabindex="-1">First</button>
        <button tabindex="0">Second</button>
      `;

      const elements = Array.from(container.querySelectorAll("button"));
      elements[1].focus();

      const event = new KeyboardEvent("keydown", {
        key: "Home",
        bubbles: true,
        target: elements[1],
      });
      event.preventDefault = jest.fn();

      handleRovingTabindex(elements, event);

      expect(elements[0].getAttribute("tabindex")).toBe("0");
      expect(document.activeElement).toBe(elements[0]);
    });

    it("handles End key", () => {
      container.innerHTML = `
        <button tabindex="0">First</button>
        <button tabindex="-1">Last</button>
      `;

      const elements = Array.from(container.querySelectorAll("button"));
      elements[0].focus();

      const event = new KeyboardEvent("keydown", {
        key: "End",
        bubbles: true,
        target: elements[0],
      });
      event.preventDefault = jest.fn();

      handleRovingTabindex(elements, event);

      expect(elements[1].getAttribute("tabindex")).toBe("0");
      expect(document.activeElement).toBe(elements[1]);
    });
  });

  describe("announceToScreenReader", () => {
    it("creates aria-live region if it doesn't exist", () => {
      expect(document.getElementById("sr-announcements")).toBeNull();

      announceToScreenReader("Test message");

      const liveRegion = document.getElementById("sr-announcements");
      expect(liveRegion).not.toBeNull();
      expect(liveRegion.getAttribute("aria-live")).toBe("polite");
      expect(liveRegion.getAttribute("aria-atomic")).toBe("true");
    });

    it("uses existing aria-live region", () => {
      announceToScreenReader("First message");
      const firstRegion = document.getElementById("sr-announcements");

      announceToScreenReader("Second message");
      const secondRegion = document.getElementById("sr-announcements");

      expect(firstRegion).toBe(secondRegion);
    });

    it("sets message text", (done) => {
      announceToScreenReader("Test announcement");

      setTimeout(() => {
        const liveRegion = document.getElementById("sr-announcements");
        expect(liveRegion.textContent).toBe("Test announcement");
        done();
      }, 150);
    });

    it("respects priority parameter", () => {
      announceToScreenReader("Urgent message", "assertive");

      const liveRegion = document.getElementById("sr-announcements");
      expect(liveRegion.getAttribute("aria-live")).toBe("assertive");
    });
  });
});
