/**
 * Jest tests for PollingManager utility class
 *
 * Tests cover:
 * - Constructor initialization
 * - Start/stop/pause/resume functionality
 * - Visibility change handling (document.hidden)
 * - Interval updates
 * - Cleanup and resource management
 * - Immediate polling (pollNow)
 */

import PollingManager from "../pollingManager";

// Use fake timers for testing timeouts
jest.useFakeTimers();

describe("PollingManager", () => {
  let mockCallback;

  beforeEach(() => {
    mockCallback = jest.fn();
    jest.clearAllTimers();
    jest.clearAllMocks();
  });

  afterEach(() => {
    jest.clearAllTimers();
    // Reset document.hidden
    Object.defineProperty(document, "hidden", {
      configurable: true,
      writable: true,
      value: false,
    });
  });

  afterAll(() => {
    jest.useRealTimers();
  });

  describe("Constructor", () => {
    it("creates instance with callback and default interval", () => {
      const manager = new PollingManager(mockCallback);
      expect(manager.callback).toBe(mockCallback);
      expect(manager.interval).toBe(60000);
      expect(manager.isRunning).toBe(false);
    });

    it("creates instance with custom interval", () => {
      const manager = new PollingManager(mockCallback, 30000);
      expect(manager.interval).toBe(30000);
    });

    it("initializes with stopped state", () => {
      const manager = new PollingManager(mockCallback);
      expect(manager.isRunning).toBe(false);
      expect(manager.timerId).toBeNull();
    });
  });

  describe("start", () => {
    it("starts polling and schedules callback", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      expect(manager.isRunning).toBe(true);

      // Advance timer by less than interval - callback should not be called
      jest.advanceTimersByTime(500);
      expect(mockCallback).not.toHaveBeenCalled();

      // Advance to interval - callback should be called
      jest.advanceTimersByTime(500);
      expect(mockCallback).toHaveBeenCalledTimes(1);

      manager.stop();
    });

    it("does not start if already running", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      const timerId1 = manager.timerId;
      manager.start(); // Call start again

      expect(manager.timerId).toBe(timerId1); // Should not change

      manager.stop();
    });

    it("continues polling after first execution", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      // First call
      jest.advanceTimersByTime(1000);
      expect(mockCallback).toHaveBeenCalledTimes(1);

      // Second call
      jest.advanceTimersByTime(1000);
      expect(mockCallback).toHaveBeenCalledTimes(2);

      manager.stop();
    });
  });

  describe("stop", () => {
    it("stops polling and clears timer", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      expect(manager.isRunning).toBe(true);
      expect(manager.timerId).not.toBeNull();

      manager.stop();

      expect(manager.isRunning).toBe(false);
      expect(manager.timerId).toBeNull();

      // Advance timer - callback should not be called
      jest.advanceTimersByTime(2000);
      expect(mockCallback).not.toHaveBeenCalled();
    });

    it("can be called when not running without error", () => {
      const manager = new PollingManager(mockCallback);
      expect(() => manager.stop()).not.toThrow();
    });
  });

  describe("pause", () => {
    it("pauses polling without stopping", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      manager.pause();

      expect(manager.isRunning).toBe(true); // Still running
      expect(manager.timerId).toBeNull(); // But timer cleared

      // Advance timer - callback should not be called
      jest.advanceTimersByTime(2000);
      expect(mockCallback).not.toHaveBeenCalled();

      manager.stop();
    });
  });

  describe("resume", () => {
    it("resumes polling and executes callback immediately", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      manager.pause();
      expect(mockCallback).not.toHaveBeenCalled();

      manager.resume();
      expect(mockCallback).toHaveBeenCalledTimes(1); // Immediate execution

      // Continue polling
      jest.advanceTimersByTime(1000);
      expect(mockCallback).toHaveBeenCalledTimes(2);

      manager.stop();
    });

    it("does not resume if not running", () => {
      const manager = new PollingManager(mockCallback);
      manager.start();
      manager.stop();

      manager.resume();
      expect(mockCallback).not.toHaveBeenCalled();
    });
  });

  describe("updateInterval", () => {
    it("updates interval when not running", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.updateInterval(2000);

      expect(manager.interval).toBe(2000);
    });

    it("updates interval and restarts when running", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      jest.advanceTimersByTime(500);
      manager.updateInterval(2000);

      // Old interval should not fire
      jest.advanceTimersByTime(500);
      expect(mockCallback).not.toHaveBeenCalled();

      // New interval should fire
      jest.advanceTimersByTime(1500);
      expect(mockCallback).toHaveBeenCalledTimes(1);

      manager.stop();
    });
  });

  describe("setupVisibilityHandling", () => {
    it("sets up visibility change handler", () => {
      const addEventListenerSpy = jest.spyOn(document, "addEventListener");
      const manager = new PollingManager(mockCallback, 1000);

      manager.setupVisibilityHandling();

      expect(addEventListenerSpy).toHaveBeenCalledWith("visibilitychange", expect.any(Function));

      addEventListenerSpy.mockRestore();
    });

    it("pauses when tab becomes hidden", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();
      manager.setupVisibilityHandling();

      // Simulate tab becoming hidden
      Object.defineProperty(document, "hidden", {
        configurable: true,
        writable: true,
        value: true,
      });

      const visibilityEvent = new Event("visibilitychange");
      document.dispatchEvent(visibilityEvent);

      expect(manager.timerId).toBeNull(); // Should be paused

      manager.cleanup();
    });

    it("resumes when tab becomes visible", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();
      manager.setupVisibilityHandling();

      // Hide tab
      Object.defineProperty(document, "hidden", {
        configurable: true,
        writable: true,
        value: true,
      });
      document.dispatchEvent(new Event("visibilitychange"));

      // Show tab
      Object.defineProperty(document, "hidden", {
        configurable: true,
        writable: true,
        value: false,
      });
      document.dispatchEvent(new Event("visibilitychange"));

      // Should have called callback immediately on resume
      expect(mockCallback).toHaveBeenCalled();

      manager.cleanup();
    });
  });

  describe("cleanup", () => {
    it("stops polling and removes event listeners", () => {
      const removeEventListenerSpy = jest.spyOn(document, "removeEventListener");
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();
      manager.setupVisibilityHandling();

      manager.cleanup();

      expect(manager.isRunning).toBe(false);
      expect(manager.timerId).toBeNull();
      expect(removeEventListenerSpy).toHaveBeenCalledWith("visibilitychange", expect.any(Function));
      expect(manager.visibilityHandler).toBeNull();

      removeEventListenerSpy.mockRestore();
    });

    it("can be called multiple times safely", () => {
      const manager = new PollingManager(mockCallback);
      manager.setupVisibilityHandling();

      expect(() => {
        manager.cleanup();
        manager.cleanup();
      }).not.toThrow();
    });
  });

  describe("pollNow", () => {
    it("executes callback immediately", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      manager.pollNow();

      expect(mockCallback).toHaveBeenCalledTimes(1);

      manager.stop();
    });

    it("can be called when not running", () => {
      const manager = new PollingManager(mockCallback);
      manager.pollNow();

      expect(mockCallback).toHaveBeenCalledTimes(1);
    });

    it("does not interfere with scheduled polling", () => {
      const manager = new PollingManager(mockCallback, 1000);
      manager.start();

      manager.pollNow();
      expect(mockCallback).toHaveBeenCalledTimes(1);

      jest.advanceTimersByTime(1000);
      expect(mockCallback).toHaveBeenCalledTimes(2);

      manager.stop();
    });
  });

  describe("Error handling", () => {
    it("handles callback errors gracefully", () => {
      const errorCallback = jest.fn(() => {
        throw new Error("Callback error");
      });
      const manager = new PollingManager(errorCallback, 1000);

      expect(() => {
        manager.start();
        jest.advanceTimersByTime(1000);
      }).not.toThrow();

      manager.stop();
    });
  });
});
