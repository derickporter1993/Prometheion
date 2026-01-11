/**
 * PollingManager - Utility class for managing periodic polling in LWC components
 *
 * Features:
 * - Automatic pause/resume based on tab visibility
 * - Configurable polling interval
 * - Clean resource management
 *
 * Usage:
 * import PollingManager from 'c/pollingManager';
 *
 * connectedCallback() {
 *   this.pollingManager = new PollingManager(() => this.load(), 60000);
 *   this.pollingManager.setupVisibilityHandling();
 *   this.pollingManager.start();
 * }
 *
 * disconnectedCallback() {
 *   this.pollingManager.cleanup();
 * }
 *
 * @author Prometheion
 * @version 1.0
 */
export default class PollingManager {
  callback = null;
  interval = 60000;
  timerId = null;
  isRunning = false;
  visibilityHandler = null;

  /**
   * Create a new PollingManager
   * @param {Function} callback - Function to call on each poll
   * @param {number} interval - Polling interval in milliseconds (default: 60000)
   */
  constructor(callback, interval = 60000) {
    this.callback = callback;
    this.interval = interval;
  }

  /**
   * Start polling
   */
  start() {
    if (this.isRunning) {
      return;
    }

    this.isRunning = true;
    this.scheduleNext();
  }

  /**
   * Stop polling
   */
  stop() {
    this.isRunning = false;
    this.clearTimer();
  }

  /**
   * Update the polling interval
   * @param {number} newInterval - New interval in milliseconds
   */
  updateInterval(newInterval) {
    this.interval = newInterval;

    // If currently running, restart with new interval
    if (this.isRunning) {
      this.clearTimer();
      this.scheduleNext();
    }
  }

  /**
   * Setup visibility change handling to pause/resume polling when tab is hidden/visible
   */
  setupVisibilityHandling() {
    this.visibilityHandler = () => {
      if (document.hidden) {
        this.pause();
      } else {
        this.resume();
      }
    };

    document.addEventListener("visibilitychange", this.visibilityHandler);
  }

  /**
   * Pause polling (keeps state, can resume)
   */
  pause() {
    this.clearTimer();
  }

  /**
   * Resume polling after pause
   */
  resume() {
    if (this.isRunning) {
      // Execute immediately when tab becomes visible again
      this.executeCallback();
      this.scheduleNext();
    }
  }

  /**
   * Cleanup all resources - call this in disconnectedCallback
   */
  cleanup() {
    this.stop();

    if (this.visibilityHandler) {
      document.removeEventListener("visibilitychange", this.visibilityHandler);
      this.visibilityHandler = null;
    }
  }

  /**
   * Force an immediate poll
   */
  pollNow() {
    this.executeCallback();
  }

  /**
   * Schedule the next poll
   * @private
   */
  scheduleNext() {
    this.timerId = setTimeout(() => {
      if (this.isRunning) {
        this.executeCallback();
        this.scheduleNext();
      }
    }, this.interval);
  }

  /**
   * Clear the current timer
   * @private
   */
  clearTimer() {
    if (this.timerId) {
      clearTimeout(this.timerId);
      this.timerId = null;
    }
  }

  /**
   * Execute the callback safely
   * @private
   */
  executeCallback() {
    if (this.callback && typeof this.callback === "function") {
      try {
        this.callback();
      } catch {
        // Silently handle callback errors
      }
    }
  }
}
