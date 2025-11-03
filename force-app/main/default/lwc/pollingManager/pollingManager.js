/**
 * PollingManager - A utility class for managing periodic polling operations
 * with support for visibility-based pause/resume and dynamic interval updates.
 */
export default class PollingManager {
  /**
   * Creates a new PollingManager instance.
   * @param {Function} callback - The function to call on each poll interval
   * @param {number} intervalMs - The initial polling interval in milliseconds
   */
  constructor(callback, intervalMs) {
    this.callback = callback;
    this.intervalMs = intervalMs;
    this.timer = null;
    this.visibilityHandler = null;
  }

  /**
   * Starts the polling timer if not already running and page is visible.
   * Safe to call multiple times - will not create duplicate timers.
   */
  start() {
    if (!this.timer && document.visibilityState === "visible") {
      this.timer = setInterval(() => this.callback(), this.intervalMs);
    }
  }

  /**
   * Stops the polling timer and clears any active intervals.
   * Safe to call multiple times.
   */
  stop() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * Updates the polling interval and restarts the timer if currently running.
   * Ensures old timers are cleared to prevent memory leaks.
   * @param {number} newIntervalMs - The new polling interval in milliseconds
   */
  updateInterval(newIntervalMs) {
    this.intervalMs = newIntervalMs;

    // If currently running, restart with new interval
    if (this.timer) {
      this.stop();
      this.start();
    }
  }

  /**
   * Sets up visibility change handlers to pause/resume polling when tab visibility changes.
   * Automatically pauses polling when tab is hidden and resumes when visible.
   * Safe to call multiple times - will not create duplicate handlers.
   */
  setupVisibilityHandling() {
    if (!this.visibilityHandler) {
      this.visibilityHandler = () => {
        if (document.visibilityState === "visible") {
          this.start();
        } else {
          this.stop();
        }
      };
      document.addEventListener("visibilitychange", this.visibilityHandler);
    }
  }

  /**
   * Cleans up all resources including timers and event listeners.
   * Should be called when the PollingManager is no longer needed.
   */
  cleanup() {
    this.stop();
    if (this.visibilityHandler) {
      document.removeEventListener("visibilitychange", this.visibilityHandler);
      this.visibilityHandler = null;
    }
  }
}
