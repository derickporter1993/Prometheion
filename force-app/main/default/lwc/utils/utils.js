/**
 * Utility module for shared LWC helper functions.
 * Re-exports focusManager utilities for component consumption.
 *
 * @module utils
 */
export {
  getFocusableElements,
  focusFirstElement,
  focusLastElement,
  trapFocus,
  createFocusStore,
  handleRovingTabindex,
  setupSkipLink,
  announceToScreenReader,
} from "./focusManager";
