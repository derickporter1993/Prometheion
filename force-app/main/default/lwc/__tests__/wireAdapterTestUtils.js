/**
 * Wire Adapter Test Utilities
 *
 * Provides utilities for testing LWC components with @wire decorators
 * that are compatible with sfdx-lwc-jest 7.x and newer LWC versions
 */

/**
 * Creates a mock wire adapter class for Apex methods that properly implements
 * the LWC wire adapter protocol. LWC expects adapters to be instantiable with 'new'.
 *
 * Usage:
 * ```js
 * const { MockAdapter, emit, error, reset } = createApexWireAdapterMock();
 *
 * // In jest.mock at module level:
 * jest.mock('@salesforce/apex/MyClass.myMethod', () => ({
 *   default: MockAdapter
 * }), { virtual: true });
 *
 * // In beforeEach:
 * reset();
 *
 * // After component is mounted:
 * emit(mockData);
 * ```
 */
export function createApexWireAdapterMock() {
  const callbacks = new Set();

  // Create a class that LWC can instantiate with 'new'
  class MockAdapter {
    constructor(callback) {
      this.callback = callback;
      if (typeof callback === "function") {
        callbacks.add(callback);
      }
    }

    connect() {
      // Connection established - nothing special needed for tests
    }

    disconnect() {
      // Clean disconnect - remove the callback
      if (typeof this.callback === "function") {
        callbacks.delete(this.callback);
      }
    }

    update() {
      // Configuration updated - nothing special needed for tests
    }
  }

  // Emit data to all registered callbacks (simulates Apex returning data)
  const emit = (data) => {
    callbacks.forEach((callback) => {
      if (typeof callback === "function") {
        callback({ data, error: undefined });
      }
    });
  };

  // Emit error to all registered callbacks (simulates Apex throwing error)
  const error = (err) => {
    callbacks.forEach((callback) => {
      if (typeof callback === "function") {
        callback({ data: undefined, error: err });
      }
    });
  };

  // Clear all callbacks (useful in beforeEach)
  const reset = () => {
    callbacks.clear();
  };

  return { MockAdapter, emit, error, reset };
}

/**
 * Safely removes all child elements from document.body
 * Handles wire adapter disconnect errors gracefully
 */
export function safeCleanupDom() {
  while (document.body.firstChild) {
    try {
      document.body.removeChild(document.body.firstChild);
    } catch (e) {
      // Ignore wire adapter disconnect errors - these happen when
      // the component is removed from DOM while wire adapters are still connected
      if (e.message && (e.message.includes("disconnect") || e.message.includes("connect"))) {
        // Force remove the child
        try {
          document.body.firstChild.remove();
        } catch {
          // If even remove() fails, just continue
        }
      } else {
        throw e;
      }
    }
  }
}

export default {
  createApexWireAdapterMock,
  safeCleanupDom,
};
