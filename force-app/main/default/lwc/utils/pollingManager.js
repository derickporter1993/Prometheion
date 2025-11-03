/**
 * PollingManager - Manages periodic polling with visibility handling and dynamic interval updates.
 *
 * This utility class encapsulates the logic for polling operations, including:
 * - Starting and stopping polling
 * - Automatic pause/resume based on page visibility
 * - Dynamic interval updates without restarting visibility handlers
 * - Cleanup on component destruction
 */
export class PollingManager {
  /**
   * Creates a new PollingManager instance.
   * @param {Function} callback - The function to call on each poll interval
   * @param {number} intervalMs - The polling interval in milliseconds
   */
  constructor(callback, intervalMs) {
    this.callback = callback;
    this.intervalMs = intervalMs;
    this.timer = null;
    this.isRunning = false;
    this.visibilityHandler = null;
  }

  /**
   * Updates the polling interval. If the manager is currently running,
   * it will restart the timer with the new interval without duplicating
   * visibility handlers.
   *
   * @param {number} newIntervalMs - The new polling interval in milliseconds
   */
  updateInterval(newIntervalMs) {
    const wasRunning = this.isRunning;
    this.intervalMs = newIntervalMs;

    if (wasRunning) {
      // Clear existing timer and restart with new interval
      this._clearTimer();
      this._startTimer();
    }
  }

  /**
   * Starts polling if not already running and the page is visible.
   */
  start() {
    this.isRunning = true;
    this._startTimer();
  }

  /**
   * Internal method to start the timer if the page is visible.
   * @private
   */
  _startTimer() {
    if (!this.timer && this.isRunning && document.visibilityState === "visible") {
      this.timer = setInterval(() => this.callback(), this.intervalMs);
    }
  }

  /**
   * Stops polling by clearing the interval timer.
   */
  stop() {
    this.isRunning = false;
    this._clearTimer();
  }

  /**
   * Internal method to clear the timer.
   * @private
   */
  _clearTimer() {
    if (this.timer) {
      clearInterval(this.timer);
      this.timer = null;
    }
  }

  /**
   * Sets up visibility change handling to automatically pause/resume polling
   * when the page becomes hidden/visible. This method should be called once
   * during component initialization.
   */
  setupVisibilityHandling() {
    if (!this.visibilityHandler) {
      this.visibilityHandler = () => {
        if (document.visibilityState === "visible") {
          this._startTimer();
          // Trigger an immediate poll when becoming visible
          this.callback();
        } else {
          this._clearTimer();
        }
      };
      document.addEventListener("visibilitychange", this.visibilityHandler);
    }
  }

  /**
   * Cleans up the polling manager by stopping the timer and removing
   * visibility change listeners. Should be called when the component
   * is disconnected.
   */
  cleanup() {
    this.stop();
    if (this.visibilityHandler) {
      document.removeEventListener("visibilitychange", this.visibilityHandler);
      this.visibilityHandler = null;
    }
  }
}
