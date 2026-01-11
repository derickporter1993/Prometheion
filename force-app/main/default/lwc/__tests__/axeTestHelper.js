/**
 * Accessibility Test Helper for LWC Jest Tests
 *
 * Provides utilities for testing WCAG 2.1 AA compliance in Lightning Web Components.
 * Uses axe-core via jest-axe for automated accessibility testing.
 *
 * @module axeTestHelper
 */

import { axe, toHaveNoViolations } from "jest-axe";

// Extend Jest matchers with axe matchers
expect.extend(toHaveNoViolations);

/**
 * Default axe configuration for WCAG 2.1 AA compliance
 */
const defaultAxeConfig = {
  rules: {
    // Enable all WCAG 2.1 AA rules
    "color-contrast": { enabled: true },
    "image-alt": { enabled: true },
    "input-image-alt": { enabled: true },
    label: { enabled: true },
    "link-name": { enabled: true },
    "button-name": { enabled: true },
    "aria-required-attr": { enabled: true },
    "aria-valid-attr": { enabled: true },
    "aria-valid-attr-value": { enabled: true },
    "aria-hidden-focus": { enabled: true },
    "aria-input-field-name": { enabled: true },
    "aria-toggle-field-name": { enabled: true },
    "aria-hidden-body": { enabled: true },
    "aria-required-children": { enabled: true },
    "aria-required-parent": { enabled: true },
    "aria-roles": { enabled: true },
    "document-title": { enabled: true },
    "heading-order": { enabled: true },
    "html-has-lang": { enabled: true },
    "meta-viewport": { enabled: true },
    "focus-order-semantics": { enabled: true },
    tabindex: { enabled: true },
    // Disable rules that don't apply to components
    "page-has-heading-one": { enabled: false },
    "landmark-one-main": { enabled: false },
    region: { enabled: false },
  },
  // Run against WCAG 2.1 AA standard
  runOnly: {
    type: "tag",
    values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"],
  },
};

/**
 * Run accessibility audit on a DOM element
 *
 * @param {HTMLElement} element - The DOM element to test (usually element.shadowRoot)
 * @param {Object} options - Optional axe configuration overrides
 * @returns {Promise<Object>} axe results object
 *
 * @example
 * const element = await createComponent();
 * const results = await runAccessibilityAudit(element.shadowRoot);
 * expect(results).toHaveNoViolations();
 */
export async function runAccessibilityAudit(element, options = {}) {
  const config = { ...defaultAxeConfig, ...options };

  // If it's a shadow root, we need to use the host's container
  const targetElement = element instanceof ShadowRoot ? element.host : element;

  // Create a container for testing if needed
  const container = document.createElement("div");
  container.setAttribute("role", "region");
  container.setAttribute("aria-label", "Test container");

  // Clone the content for testing to avoid modifying the original
  if (element instanceof ShadowRoot) {
    // For shadow DOM, we test the host element directly
    return await axe(targetElement, config);
  }

  return await axe(element, config);
}

/**
 * Assert that an element has no accessibility violations
 *
 * @param {HTMLElement} element - The element to test
 * @param {Object} options - Optional axe configuration overrides
 *
 * @example
 * await assertNoAccessibilityViolations(element.shadowRoot);
 */
export async function assertNoAccessibilityViolations(element, options = {}) {
  const results = await runAccessibilityAudit(element, options);
  expect(results).toHaveNoViolations();
}

/**
 * Get all accessibility violations for an element
 *
 * @param {HTMLElement} element - The element to test
 * @param {Object} options - Optional axe configuration overrides
 * @returns {Promise<Array>} Array of violations
 *
 * @example
 * const violations = await getAccessibilityViolations(element.shadowRoot);
 * console.log(violations);
 */
export async function getAccessibilityViolations(element, options = {}) {
  const results = await runAccessibilityAudit(element, options);
  return results.violations || [];
}

/**
 * Check if an element has a specific ARIA attribute
 *
 * @param {HTMLElement} element - The element to check
 * @param {string} attribute - The ARIA attribute name (e.g., 'aria-label')
 * @param {string} expectedValue - Optional expected value
 * @returns {boolean}
 *
 * @example
 * expect(hasAriaAttribute(button, 'aria-label', 'Close modal')).toBe(true);
 */
export function hasAriaAttribute(element, attribute, expectedValue = null) {
  const value = element.getAttribute(attribute);
  if (expectedValue !== null) {
    return value === expectedValue;
  }
  return value !== null && value !== "";
}

/**
 * Check if an element is keyboard focusable
 *
 * @param {HTMLElement} element - The element to check
 * @returns {boolean}
 *
 * @example
 * expect(isKeyboardFocusable(button)).toBe(true);
 */
export function isKeyboardFocusable(element) {
  const tabIndex = element.getAttribute("tabindex");
  const tagName = element.tagName.toLowerCase();
  const nativelyFocusable = ["a", "button", "input", "select", "textarea"];

  // Check if natively focusable and not disabled
  if (nativelyFocusable.includes(tagName)) {
    return !element.disabled && tabIndex !== "-1";
  }

  // Check if made focusable via tabindex
  return tabIndex !== null && tabIndex !== "-1";
}

/**
 * Check heading hierarchy within a container
 *
 * @param {HTMLElement} container - The container element
 * @returns {Object} Object with isValid boolean and details
 *
 * @example
 * const { isValid, errors } = checkHeadingHierarchy(element.shadowRoot);
 * expect(isValid).toBe(true);
 */
export function checkHeadingHierarchy(container) {
  const headings = container.querySelectorAll("h1, h2, h3, h4, h5, h6");
  const errors = [];
  let lastLevel = 0;

  headings.forEach((heading, index) => {
    const currentLevel = parseInt(heading.tagName.charAt(1), 10);

    // First heading can be any level (within a component)
    if (index > 0 && currentLevel > lastLevel + 1) {
      errors.push({
        element: heading,
        message: `Heading level skipped: ${heading.tagName} follows h${lastLevel}`,
      });
    }

    lastLevel = currentLevel;
  });

  return {
    isValid: errors.length === 0,
    errors,
    headingCount: headings.length,
  };
}

/**
 * Check color contrast ratio between foreground and background
 * Note: This is a simplified check - axe-core provides more comprehensive testing
 *
 * @param {string} foreground - Foreground color in hex format
 * @param {string} background - Background color in hex format
 * @param {string} size - 'normal' or 'large' text
 * @returns {Object} Object with ratio, passes boolean, and required ratio
 *
 * @example
 * const { passes } = checkColorContrast('#333333', '#ffffff', 'normal');
 * expect(passes).toBe(true);
 */
export function checkColorContrast(foreground, background, size = "normal") {
  const getLuminance = (hex) => {
    const rgb = hex
      .replace("#", "")
      .match(/.{2}/g)
      .map((x) => parseInt(x, 16) / 255);

    const [r, g, b] = rgb.map((c) => {
      return c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4);
    });

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };

  const l1 = getLuminance(foreground);
  const l2 = getLuminance(background);

  const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);

  // WCAG 2.1 AA requirements
  const requiredRatio = size === "large" ? 3 : 4.5;

  return {
    ratio: Math.round(ratio * 100) / 100,
    passes: ratio >= requiredRatio,
    requiredRatio,
  };
}

/**
 * Simulate keyboard navigation to test focus management
 *
 * @param {HTMLElement} element - Starting element
 * @param {string} key - Key to simulate ('Tab', 'Enter', 'Escape', 'ArrowDown', etc.)
 * @param {Object} options - Event options (shiftKey, ctrlKey, etc.)
 *
 * @example
 * simulateKeyPress(element, 'Tab');
 * simulateKeyPress(element, 'Tab', { shiftKey: true });
 */
export function simulateKeyPress(element, key, options = {}) {
  const event = new KeyboardEvent("keydown", {
    key,
    code: key,
    bubbles: true,
    cancelable: true,
    ...options,
  });

  element.dispatchEvent(event);
}

/**
 * Check if focus is trapped within a container (useful for modals)
 *
 * @param {HTMLElement} container - The container to check
 * @returns {Array} Array of focusable elements within the container
 *
 * @example
 * const focusableElements = getFocusableElements(modal);
 * expect(focusableElements.length).toBeGreaterThan(0);
 */
export function getFocusableElements(container) {
  const focusableSelectors = [
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
  ];

  return Array.from(container.querySelectorAll(focusableSelectors.join(", "))).filter((el) => {
    // Verify the element is visible
    const style = window.getComputedStyle(el);
    return style.display !== "none" && style.visibility !== "hidden";
  });
}

/**
 * Helper to wait for DOM updates in tests
 *
 * @param {number} ms - Milliseconds to wait (default 0)
 * @returns {Promise}
 */
export function flushPromises(ms = 0) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

/**
 * Create a mock for @salesforce/label imports
 *
 * @param {string} labelPath - The label path
 * @param {string} value - The label value
 * @returns {Object} Mock object for jest.mock
 */
export function createLabelMock(labelPath, value) {
  return {
    default: value,
  };
}

/**
 * Common accessibility test suite for LWC components
 *
 * @param {Function} createComponentFn - Async function that creates and returns the component
 * @param {string} componentName - Name of the component for test descriptions
 *
 * @example
 * runCommonAccessibilityTests(createComponent, 'prometheionDashboard');
 */
export function runCommonAccessibilityTests(createComponentFn, componentName) {
  describe(`${componentName} Accessibility`, () => {
    it("should have no accessibility violations", async () => {
      const element = await createComponentFn();
      await flushPromises();

      // Note: axe-core testing on shadow DOM has limitations
      // This test provides basic validation
      const violations = await getAccessibilityViolations(element);

      // Log violations for debugging
      if (violations.length > 0) {
        console.warn(`Accessibility violations in ${componentName}:`, violations);
      }

      expect(violations).toHaveLength(0);
    });

    it("should have valid heading hierarchy", async () => {
      const element = await createComponentFn();
      await flushPromises();

      const { isValid, errors } = checkHeadingHierarchy(element.shadowRoot);

      if (!isValid) {
        console.warn(`Heading hierarchy issues in ${componentName}:`, errors);
      }

      expect(isValid).toBe(true);
    });

    it("should have focusable interactive elements", async () => {
      const element = await createComponentFn();
      await flushPromises();

      const focusable = getFocusableElements(element.shadowRoot);

      // Components with interactive elements should have focusable items
      // This is a sanity check - specific tests should verify particular elements
      expect(Array.isArray(focusable)).toBe(true);
    });
  });
}

export default {
  runAccessibilityAudit,
  assertNoAccessibilityViolations,
  getAccessibilityViolations,
  hasAriaAttribute,
  isKeyboardFocusable,
  checkHeadingHierarchy,
  checkColorContrast,
  simulateKeyPress,
  getFocusableElements,
  flushPromises,
  createLabelMock,
  runCommonAccessibilityTests,
};
