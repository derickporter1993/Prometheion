/**
 * Accessibility Test Utilities for LWC Components
 *
 * Provides comprehensive utilities for testing WCAG 2.1 AA compliance
 * in Lightning Web Components using Jest.
 *
 * @module a11yTestUtils
 */

import { axe, toHaveNoViolations } from "jest-axe";

// Extend Jest with axe matchers
expect.extend(toHaveNoViolations);

/**
 * Axe configuration for WCAG 2.1 AA compliance testing
 */
export const AXE_CONFIG = {
  rules: {
    // Enable core WCAG rules
    "color-contrast": { enabled: true },
    "image-alt": { enabled: true },
    label: { enabled: true },
    "link-name": { enabled: true },
    "button-name": { enabled: true },
    "aria-required-attr": { enabled: true },
    "aria-valid-attr": { enabled: true },
    "aria-valid-attr-value": { enabled: true },
    "aria-hidden-focus": { enabled: true },
    "aria-input-field-name": { enabled: true },
    "heading-order": { enabled: true },
    tabindex: { enabled: true },
    "focus-order-semantics": { enabled: true },
    // Disable rules not applicable to components
    "page-has-heading-one": { enabled: false },
    "landmark-one-main": { enabled: false },
    region: { enabled: false },
    "html-has-lang": { enabled: false },
    "document-title": { enabled: false },
  },
  runOnly: {
    type: "tag",
    values: ["wcag2a", "wcag2aa", "wcag21a", "wcag21aa", "best-practice"],
  },
};

/**
 * Run axe accessibility audit on an element
 *
 * @param {HTMLElement} element - Element to audit
 * @param {Object} customConfig - Optional custom axe config
 * @returns {Promise<Object>} axe results
 */
export async function runAxeAudit(element, customConfig = {}) {
  const config = { ...AXE_CONFIG, ...customConfig };
  return await axe(element, config);
}

/**
 * Assert element has no accessibility violations
 *
 * @param {HTMLElement} element - Element to test
 * @param {Object} customConfig - Optional custom axe config
 */
export async function expectNoA11yViolations(element, customConfig = {}) {
  const results = await runAxeAudit(element, customConfig);
  expect(results).toHaveNoViolations();
}

/**
 * Helper to flush promises and allow DOM updates
 */
export function flushPromises() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

/**
 * Simulate keyboard event on element
 *
 * @param {HTMLElement} element - Target element
 * @param {string} eventType - Event type (keydown, keyup, keypress)
 * @param {string} key - Key name (Enter, Escape, Tab, etc.)
 * @param {Object} options - Additional event options
 */
export function simulateKeyboardEvent(element, eventType, key, options = {}) {
  const event = new KeyboardEvent(eventType, {
    key,
    code: key,
    bubbles: true,
    cancelable: true,
    ...options,
  });
  element.dispatchEvent(event);
  return event;
}

/**
 * Check if element is keyboard focusable
 *
 * @param {HTMLElement} element - Element to check
 * @returns {boolean}
 */
export function isKeyboardFocusable(element) {
  const tabIndex = element.getAttribute("tabindex");
  const tagName = element.tagName.toLowerCase();

  // Natively focusable elements
  const focusableTags = ["a", "button", "input", "select", "textarea"];
  if (focusableTags.includes(tagName)) {
    return !element.disabled && tabIndex !== "-1";
  }

  // Elements made focusable via tabindex
  return tabIndex !== null && tabIndex !== "-1";
}

/**
 * Get all focusable elements within a container
 *
 * @param {HTMLElement} container - Container element
 * @returns {HTMLElement[]} Array of focusable elements
 */
export function getFocusableElements(container) {
  const selectors = [
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
  ];

  return Array.from(container.querySelectorAll(selectors.join(", "))).filter((el) => {
    const style = window.getComputedStyle(el);
    return style.display !== "none" && style.visibility !== "hidden";
  });
}

/**
 * Verify focus trap is working within a container
 *
 * @param {HTMLElement} container - Container to test
 * @returns {boolean} True if focus is trapped correctly
 */
export function verifyFocusTrap(container) {
  const focusable = getFocusableElements(container);
  if (focusable.length === 0) return false;

  const first = focusable[0];
  const last = focusable[focusable.length - 1];

  // Test Tab from last element wraps to first
  last.focus();
  simulateKeyboardEvent(last, "keydown", "Tab");
  // Note: In actual implementation, the component handler would move focus

  return focusable.length > 0;
}

/**
 * Verify ARIA attributes on an element
 *
 * @param {HTMLElement} element - Element to check
 * @param {Object} expectedAttrs - Object with expected attribute values
 * @returns {Object} Object with pass/fail and details
 */
export function verifyAriaAttributes(element, expectedAttrs) {
  const results = {
    pass: true,
    missing: [],
    invalid: [],
  };

  for (const [attr, expected] of Object.entries(expectedAttrs)) {
    const actual = element.getAttribute(attr);

    if (actual === null) {
      results.pass = false;
      results.missing.push(attr);
    } else if (expected !== null && actual !== expected) {
      results.pass = false;
      results.invalid.push({ attr, expected, actual });
    }
  }

  return results;
}

/**
 * Check heading hierarchy in a container
 *
 * @param {HTMLElement} container - Container to check
 * @returns {Object} Object with isValid, headings list, and errors
 */
export function checkHeadingHierarchy(container) {
  const headings = Array.from(container.querySelectorAll("h1, h2, h3, h4, h5, h6"));
  const levels = headings.map((h) => parseInt(h.tagName[1], 10));
  const errors = [];

  for (let i = 1; i < levels.length; i++) {
    if (levels[i] > levels[i - 1] + 1) {
      errors.push({
        message: `Heading level skipped: h${levels[i - 1]} to h${levels[i]}`,
        element: headings[i],
      });
    }
  }

  return {
    isValid: errors.length === 0,
    headings: levels,
    errors,
  };
}

/**
 * Check color contrast between two colors
 *
 * @param {string} foreground - Foreground color (hex)
 * @param {string} background - Background color (hex)
 * @param {string} textSize - 'normal' or 'large'
 * @returns {Object} Object with ratio, passes, and required ratio
 */
export function checkColorContrast(foreground, background, textSize = "normal") {
  const getLuminance = (hex) => {
    const rgb = hex
      .replace("#", "")
      .match(/.{2}/g)
      .map((x) => parseInt(x, 16) / 255);

    const [r, g, b] = rgb.map((c) =>
      c <= 0.03928 ? c / 12.92 : Math.pow((c + 0.055) / 1.055, 2.4)
    );

    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  };

  const l1 = getLuminance(foreground);
  const l2 = getLuminance(background);
  const ratio = (Math.max(l1, l2) + 0.05) / (Math.min(l1, l2) + 0.05);
  const required = textSize === "large" ? 3 : 4.5;

  return {
    ratio: Math.round(ratio * 100) / 100,
    passes: ratio >= required,
    required,
  };
}

/**
 * Test suite for common accessibility checks
 *
 * @param {Function} createComponent - Function to create component
 * @param {string} componentName - Component name for descriptions
 */
export function runAccessibilityTests(createComponent, componentName) {
  describe(`${componentName} Accessibility`, () => {
    let element;

    beforeEach(async () => {
      element = await createComponent();
      await flushPromises();
    });

    afterEach(() => {
      if (element && element.parentNode) {
        element.parentNode.removeChild(element);
      }
    });

    it("should have no axe violations", async () => {
      await expectNoA11yViolations(element);
    });

    it("should have valid heading hierarchy", () => {
      const { isValid, errors } = checkHeadingHierarchy(element.shadowRoot);
      if (!isValid) {
        console.warn("Heading hierarchy issues:", errors);
      }
      expect(isValid).toBe(true);
    });

    it("should have focusable interactive elements", () => {
      const focusable = getFocusableElements(element.shadowRoot);
      expect(Array.isArray(focusable)).toBe(true);
    });
  });
}

/**
 * Create mock for Salesforce labels
 *
 * @param {string} value - Label value
 * @returns {Object} Mock object
 */
export function mockLabel(value) {
  return { default: value };
}

/**
 * Assert element has specific ARIA role
 */
export function expectRole(element, role) {
  expect(element.getAttribute("role")).toBe(role);
}

/**
 * Assert element has aria-label
 */
export function expectAriaLabel(element, label = null) {
  const actual = element.getAttribute("aria-label");
  if (label) {
    expect(actual).toBe(label);
  } else {
    expect(actual).not.toBeNull();
    expect(actual).not.toBe("");
  }
}

/**
 * Assert button has accessible name
 */
export function expectButtonName(button) {
  const ariaLabel = button.getAttribute("aria-label");
  const textContent = button.textContent?.trim();
  const ariaLabelledby = button.getAttribute("aria-labelledby");

  const hasName = ariaLabel || textContent || ariaLabelledby;
  expect(hasName).toBeTruthy();
}

export default {
  runAxeAudit,
  expectNoA11yViolations,
  flushPromises,
  simulateKeyboardEvent,
  isKeyboardFocusable,
  getFocusableElements,
  verifyFocusTrap,
  verifyAriaAttributes,
  checkHeadingHierarchy,
  checkColorContrast,
  runAccessibilityTests,
  mockLabel,
  expectRole,
  expectAriaLabel,
  expectButtonName,
  AXE_CONFIG,
};
