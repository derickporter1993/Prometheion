/**
 * PollingManager - A utility class for managing periodic polling with visibility handling
 *
 * This class encapsulates polling logic with support for:
 * - Starting and stopping periodic callbacks
 * - Dynamic interval adjustment via updateInterval()
 * - Automatic pause/resume based on browser tab visibility
 * - Memory leak prevention through proper cleanup
 *
 * Usage:
 *   const manager = new PollingManager(60000, () => this.fetchData());
 *   manager.setupVisibilityHandling();
 *   manager.start();
 *   // Later, to adjust interval:
 *   manager.updateInterval(120000);
 *   // Cleanup:
 *   manager.cleanup();
 */
export class PollingManager {
  /**
   * Creates a new PollingManager instance
   * @param {number} intervalMs - Initial polling interval in milliseconds
   * @param {Function} callback - Function to call on each poll
   */
  constructor(intervalMs, callback) {
    this.intervalMs = intervalMs;
    this.callback = callback;
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
   * Starts the polling timer if not already running and tab is visible
   * Note: This method checks document visibility to avoid polling on hidden tabs.
   * If called while tab is hidden, the timer will not start until visibility changes.
   */
  start() {
    if (!this.timer && document.visibilityState === "visible") {
      this.timer = setInterval(this.callback, this.intervalMs);
    }
  }

  /**
   * Stops the polling timer and clears it
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
   * Updates the polling interval and restarts the timer if currently running
   * This method allows dynamic adjustment of polling frequency without
   * recreating the PollingManager instance.
   *
   * @param {number} newIntervalMs - New polling interval in milliseconds
   * Updates the polling interval and restarts the timer if currently running.
   * Ensures old timers are cleared to prevent memory leaks.
   * @param {number} newIntervalMs - The new polling interval in milliseconds
   */
  updateInterval(newIntervalMs) {
    this.intervalMs = newIntervalMs;

    // If timer is running, restart it with the new interval
    // If currently running, restart with new interval
    if (this.timer) {
      this.stop();
      this.start();
    }
  }

  /**
   * Sets up automatic pause/resume of polling based on tab visibility
   * Call this once during component initialization.
   * The visibility handler will be stored and can be removed via cleanup().
   */
  setupVisibilityHandling() {
    // Store bound handler for later removal
    this.visibilityHandler = () => {
      if (document.visibilityState === "visible") {
        // Resume polling when tab becomes visible
        this.start();
        // Execute callback immediately when becoming visible
        this.callback();
      } else {
        // Pause polling when tab is hidden
        this.stop();
      }
    };

    document.addEventListener("visibilitychange", this.visibilityHandler);
  }

  /**
   * Cleanup method to stop polling and remove event listeners
   * Call this during component disconnection to prevent memory leaks
   */
  cleanup() {
    this.stop();

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
