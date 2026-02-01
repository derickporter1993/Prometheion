/**
 * Jest Setup File for LWC Testing
 *
 * This file runs before each test file and configures:
 * - Custom Jest matchers for accessibility testing
 * - Global test utilities
 * - Mock configurations
 */

import { toHaveNoViolations } from "jest-axe";

// Extend Jest expect with axe accessibility matchers
expect.extend(toHaveNoViolations);

// Silence console.warn during tests unless debugging
const originalWarn = console.warn;
global.console.warn = (...args) => {
  // Allow accessibility warnings through
  if (
    args[0]?.includes?.("Accessibility") ||
    args[0]?.includes?.("a11y") ||
    process.env.DEBUG_TESTS
  ) {
    originalWarn.apply(console, args);
  }
};

// Global test timeout for async operations
jest.setTimeout(10000);

// Mock ResizeObserver which isn't available in jsdom
global.ResizeObserver = class ResizeObserver {
  observe() {}
  unobserve() {}
  disconnect() {}
};

// Mock IntersectionObserver which isn't available in jsdom
global.IntersectionObserver = class IntersectionObserver {
  constructor() {
    this.root = null;
    this.rootMargin = "";
    this.thresholds = [];
  }
  observe() {}
  unobserve() {}
  disconnect() {}
  takeRecords() {
    return [];
  }
};

// Mock window.matchMedia
Object.defineProperty(window, "matchMedia", {
  writable: true,
  value: jest.fn().mockImplementation((query) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: jest.fn(), // deprecated
    removeListener: jest.fn(), // deprecated
    addEventListener: jest.fn(),
    removeEventListener: jest.fn(),
    dispatchEvent: jest.fn(),
  })),
});

// Mock scrollIntoView which isn't available in jsdom
Element.prototype.scrollIntoView = jest.fn();

// Mock HTMLAnchorElement.click() to prevent JSDOM navigation errors
// This is needed for components that programmatically download files
HTMLAnchorElement.prototype.click = jest.fn();

// Helper function to flush all pending promises
global.flushPromises = () => new Promise((resolve) => setTimeout(resolve, 0));

// Clean up after each test
afterEach(() => {
  // Clear any lingering timers
  jest.clearAllTimers();

  // Clear all mocks
  jest.clearAllMocks();

  // Remove all child elements from body (clean slate for each test)
  while (document.body.firstChild) {
    document.body.removeChild(document.body.firstChild);
  }
});
