/**
 * Focus Management Utility for LWC Components
 *
 * Provides utilities for managing focus in modals, dialogs, and
 * other accessible interactive components.
 *
 * @module focusManager
 */

/**
 * Selectors for focusable elements
 */
const FOCUSABLE_SELECTORS = [
  "a[href]",
  "button:not([disabled])",
  "input:not([disabled])",
  "select:not([disabled])",
  "textarea:not([disabled])",
  "[tabindex]:not([tabindex='-1'])",
  "lightning-button",
  "lightning-input",
  "lightning-combobox",
  "lightning-textarea",
  "lightning-checkbox-group",
  "lightning-radio-group",
  "lightning-button-icon",
].join(", ");

/**
 * Get all focusable elements within a container
 *
 * @param {HTMLElement} container - The container element
 * @returns {HTMLElement[]} Array of focusable elements
 */
export function getFocusableElements(container) {
  if (!container) return [];

  return Array.from(container.querySelectorAll(FOCUSABLE_SELECTORS)).filter((element) => {
    // Verify element is visible
    const style = window.getComputedStyle(element);
    return (
      style.display !== "none" && style.visibility !== "hidden" && element.offsetParent !== null
    );
  });
}

/**
 * Focus the first focusable element in a container
 *
 * @param {HTMLElement} container - The container element
 * @returns {boolean} True if an element was focused
 */
export function focusFirstElement(container) {
  const focusable = getFocusableElements(container);
  if (focusable.length > 0) {
    focusable[0].focus();
    return true;
  }
  return false;
}

/**
 * Focus the last focusable element in a container
 *
 * @param {HTMLElement} container - The container element
 * @returns {boolean} True if an element was focused
 */
export function focusLastElement(container) {
  const focusable = getFocusableElements(container);
  if (focusable.length > 0) {
    focusable[focusable.length - 1].focus();
    return true;
  }
  return false;
}

/**
 * Create a focus trap within a container
 *
 * Returns a cleanup function to remove the trap.
 *
 * @param {HTMLElement} container - The container to trap focus within
 * @returns {Function} Cleanup function to remove the focus trap
 *
 * @example
 * const cleanup = trapFocus(modal);
 * // Later, to remove:
 * cleanup();
 */
export function trapFocus(container) {
  if (!container) return () => {};

  const handleKeydown = (event) => {
    if (event.key !== "Tab") return;

    const focusable = getFocusableElements(container);
    if (focusable.length === 0) return;

    const firstElement = focusable[0];
    const lastElement = focusable[focusable.length - 1];
    const activeElement = document.activeElement;

    if (event.shiftKey) {
      // Shift + Tab: going backwards
      if (activeElement === firstElement) {
        event.preventDefault();
        lastElement.focus();
      }
    } else {
      // Tab: going forwards
      if (activeElement === lastElement) {
        event.preventDefault();
        firstElement.focus();
      }
    }
  };

  container.addEventListener("keydown", handleKeydown);

  // Return cleanup function
  return () => {
    container.removeEventListener("keydown", handleKeydown);
  };
}

/**
 * Store and restore focus for modal operations
 *
 * @returns {Object} Object with save and restore methods
 *
 * @example
 * const focusStore = createFocusStore();
 * focusStore.save(); // Save current focus
 * // ... open modal ...
 * focusStore.restore(); // Restore focus when modal closes
 */
export function createFocusStore() {
  let savedElement = null;

  return {
    /**
     * Save the currently focused element
     */
    save() {
      savedElement = document.activeElement;
    },

    /**
     * Restore focus to the previously saved element
     */
    restore() {
      if (savedElement && typeof savedElement.focus === "function") {
        // Use setTimeout to ensure restore happens after any DOM updates
        setTimeout(() => {
          savedElement.focus();
          savedElement = null;
        }, 0);
      }
    },

    /**
     * Clear the saved element without restoring focus
     */
    clear() {
      savedElement = null;
    },

    /**
     * Get the currently saved element
     */
    getSaved() {
      return savedElement;
    },
  };
}

/**
 * Handle keyboard navigation in a roving tabindex pattern
 *
 * Useful for toolbars, menus, and radio groups.
 *
 * @param {HTMLElement[]} elements - Array of elements to navigate
 * @param {KeyboardEvent} event - The keyboard event
 * @param {Object} options - Configuration options
 * @param {boolean} options.vertical - True for up/down, false for left/right
 * @param {boolean} options.wrap - Whether to wrap around at ends
 */
export function handleRovingTabindex(elements, event, options = {}) {
  const { vertical = false, wrap = true } = options;

  const forwardKey = vertical ? "ArrowDown" : "ArrowRight";
  const backwardKey = vertical ? "ArrowUp" : "ArrowLeft";

  const currentIndex = elements.indexOf(event.target);
  if (currentIndex === -1) return;

  let nextIndex;

  if (event.key === forwardKey) {
    event.preventDefault();
    nextIndex = currentIndex + 1;
    if (nextIndex >= elements.length) {
      nextIndex = wrap ? 0 : elements.length - 1;
    }
  } else if (event.key === backwardKey) {
    event.preventDefault();
    nextIndex = currentIndex - 1;
    if (nextIndex < 0) {
      nextIndex = wrap ? elements.length - 1 : 0;
    }
  } else if (event.key === "Home") {
    event.preventDefault();
    nextIndex = 0;
  } else if (event.key === "End") {
    event.preventDefault();
    nextIndex = elements.length - 1;
  } else {
    return;
  }

  // Update tabindex values
  elements.forEach((el, index) => {
    el.setAttribute("tabindex", index === nextIndex ? "0" : "-1");
  });

  // Focus the new element
  elements[nextIndex].focus();
}

/**
 * Manage skip links for page navigation
 *
 * @param {HTMLElement} skipLink - The skip link element
 * @param {string} targetId - ID of the target element
 */
export function setupSkipLink(skipLink, targetId) {
  if (!skipLink) return;

  skipLink.addEventListener("click", (event) => {
    event.preventDefault();
    const target = document.getElementById(targetId);
    if (target) {
      target.setAttribute("tabindex", "-1");
      target.focus();
      // Remove tabindex after blur to maintain natural tab order
      target.addEventListener(
        "blur",
        () => {
          target.removeAttribute("tabindex");
        },
        { once: true }
      );
    }
  });
}

/**
 * Announce a message to screen readers using an aria-live region
 *
 * @param {string} message - The message to announce
 * @param {string} priority - 'polite' or 'assertive'
 */
export function announceToScreenReader(message, priority = "polite") {
  // Look for existing live region or create one
  let liveRegion = document.getElementById("sr-announcements");

  if (!liveRegion) {
    liveRegion = document.createElement("div");
    liveRegion.id = "sr-announcements";
    liveRegion.setAttribute("aria-live", priority);
    liveRegion.setAttribute("aria-atomic", "true");
    liveRegion.className = "slds-assistive-text";
    document.body.appendChild(liveRegion);
  } else {
    liveRegion.setAttribute("aria-live", priority);
  }

  // Clear and set new message
  liveRegion.textContent = "";
  // Use setTimeout to ensure the DOM update triggers the announcement
  setTimeout(() => {
    liveRegion.textContent = message;
  }, 100);
}

export default {
  getFocusableElements,
  focusFirstElement,
  focusLastElement,
  trapFocus,
  createFocusStore,
  handleRovingTabindex,
  setupSkipLink,
  announceToScreenReader,
};
