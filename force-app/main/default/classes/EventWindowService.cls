/**
 * Manages event windows for temporal correlation of security events.
 * Provides in-memory windowed event storage with time-based expiration,
 * enabling the correlation engine to evaluate event sequences within
 * configurable time boundaries.
 *
 * In a future iteration, this service will integrate with Big Objects
 * for persistent event storage across transactions.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see EventCorrelationEngine
 * @see BreachPatternMatcher
 */
public inherited sharing class EventWindowService {

    private static final String CLASS_NAME = 'EventWindowService';

    /**
     * Default window duration in minutes if not specified.
     */
    public static final Integer DEFAULT_WINDOW_MINUTES = 60;

    /**
     * Maximum allowed window duration in minutes.
     */
    public static final Integer MAX_WINDOW_MINUTES = 1440;

    /**
     * Maximum events retained per window to prevent memory issues.
     */
    public static final Integer MAX_EVENTS_PER_WINDOW = 10000;

    /**
     * Represents a time-bounded event window.
     */
    public class EventWindow {
        public String windowId;
        public Integer windowMinutes;
        public Datetime windowStart;
        public Datetime windowEnd;
        public List<EventCorrelationEngine.SecurityEvent> events;
        public Integer maxEvents;

        /**
         * Creates a new event window with the specified duration.
         *
         * @param windowId Unique identifier for this window
         * @param windowMinutes Duration of the window in minutes
         */
        public EventWindow(String windowId, Integer windowMinutes) {
            this.windowId = windowId;
            this.windowMinutes = Math.min(
                windowMinutes > 0 ? windowMinutes : DEFAULT_WINDOW_MINUTES,
                MAX_WINDOW_MINUTES
            );
            this.windowEnd = System.now();
            this.windowStart = this.windowEnd.addMinutes(-this.windowMinutes);
            this.events = new List<EventCorrelationEngine.SecurityEvent>();
            this.maxEvents = MAX_EVENTS_PER_WINDOW;
        }

        /**
         * Returns the number of events currently in the window.
         *
         * @return Event count
         */
        public Integer size() {
            return events.size();
        }

        /**
         * Checks if the window has reached its maximum event capacity.
         *
         * @return True if the window is full
         */
        public Boolean isFull() {
            return events.size() >= maxEvents;
        }
    }

    /**
     * Creates a new event window for the specified duration.
     *
     * @param windowId Unique identifier for the window
     * @param windowMinutes Duration in minutes
     * @return A new EventWindow instance
     */
    public static EventWindow createWindow(String windowId, Integer windowMinutes) {
        EventWindow window = new EventWindow(windowId, windowMinutes);

        ElaroLogger.info(CLASS_NAME + '.createWindow: Window created', new Map<String, Object>{
            'windowId' => windowId,
            'windowMinutes' => window.windowMinutes,
            'windowStart' => window.windowStart,
            'windowEnd' => window.windowEnd
        });

        return window;
    }

    /**
     * Adds an event to the window if it falls within the time boundary
     * and the window is not at capacity.
     *
     * @param window The event window to add to
     * @param event The security event to add
     * @return True if the event was added, false if rejected
     */
    public static Boolean addEvent(EventWindow window, EventCorrelationEngine.SecurityEvent event) {
        if (window == null || event == null) {
            return false;
        }

        if (window.isFull()) {
            ElaroLogger.warn(CLASS_NAME + '.addEvent: Window full', new Map<String, Object>{
                'windowId' => window.windowId,
                'maxEvents' => window.maxEvents
            });
            return false;
        }

        if (event.eventTimestamp == null) {
            return false;
        }

        if (event.eventTimestamp >= window.windowStart && event.eventTimestamp <= window.windowEnd) {
            window.events.add(event);
            return true;
        }

        return false;
    }

    /**
     * Adds multiple events to the window, filtering by time boundary.
     *
     * @param window The event window to add to
     * @param events List of security events to add
     * @return Number of events successfully added
     */
    public static Integer addEvents(
        EventWindow window,
        List<EventCorrelationEngine.SecurityEvent> events
    ) {
        if (window == null || events == null) {
            return 0;
        }

        Integer added = 0;
        for (EventCorrelationEngine.SecurityEvent event : events) {
            if (addEvent(window, event)) {
                added++;
            }
        }

        return added;
    }

    /**
     * Removes expired events from the window based on the current time.
     * Slides the window forward to the current time.
     *
     * @param window The event window to clean
     * @return Number of events removed
     */
    public static Integer evictExpired(EventWindow window) {
        if (window == null || window.events.isEmpty()) {
            return 0;
        }

        window.windowEnd = System.now();
        window.windowStart = window.windowEnd.addMinutes(-window.windowMinutes);

        List<EventCorrelationEngine.SecurityEvent> retained =
            new List<EventCorrelationEngine.SecurityEvent>();
        Integer removedCount = 0;

        for (EventCorrelationEngine.SecurityEvent evt : window.events) {
            if (evt.eventTimestamp >= window.windowStart) {
                retained.add(evt);
            } else {
                removedCount++;
            }
        }

        window.events = retained;

        if (removedCount > 0) {
            ElaroLogger.info(CLASS_NAME + '.evictExpired: Evicted events', new Map<String, Object>{
                'windowId' => window.windowId,
                'evicted' => removedCount,
                'remaining' => retained.size()
            });
        }

        return removedCount;
    }

    /**
     * Retrieves all events in the window for a specific user.
     *
     * @param window The event window to query
     * @param userId The user Id to filter by
     * @return List of events for the specified user
     */
    public static List<EventCorrelationEngine.SecurityEvent> getEventsByUser(
        EventWindow window,
        String userId
    ) {
        List<EventCorrelationEngine.SecurityEvent> userEvents =
            new List<EventCorrelationEngine.SecurityEvent>();

        if (window == null || String.isBlank(userId)) {
            return userEvents;
        }

        for (EventCorrelationEngine.SecurityEvent evt : window.events) {
            if (evt.userId == userId) {
                userEvents.add(evt);
            }
        }

        return userEvents;
    }

    /**
     * Retrieves all events in the window matching a specific event type.
     *
     * @param window The event window to query
     * @param eventType The event type to filter by
     * @return List of matching events
     */
    public static List<EventCorrelationEngine.SecurityEvent> getEventsByType(
        EventWindow window,
        String eventType
    ) {
        List<EventCorrelationEngine.SecurityEvent> filtered =
            new List<EventCorrelationEngine.SecurityEvent>();

        if (window == null || String.isBlank(eventType)) {
            return filtered;
        }

        for (EventCorrelationEngine.SecurityEvent evt : window.events) {
            if (evt.eventType == eventType) {
                filtered.add(evt);
            }
        }

        return filtered;
    }

    /**
     * Runs correlation analysis on all events currently in the window.
     *
     * @param window The event window to analyze
     * @return List of CorrelationResult for any pattern matches found
     */
    public static List<EventCorrelationEngine.CorrelationResult> correlateWindow(
        EventWindow window
    ) {
        if (window == null || window.events.isEmpty()) {
            return new List<EventCorrelationEngine.CorrelationResult>();
        }

        return EventCorrelationEngine.correlateEvents(window.events);
    }

    /**
     * Returns a summary of event counts grouped by event type within the window.
     *
     * @param window The event window to summarize
     * @return Map of event type to count
     */
    public static Map<String, Integer> getEventTypeSummary(EventWindow window) {
        Map<String, Integer> summary = new Map<String, Integer>();

        if (window == null) {
            return summary;
        }

        for (EventCorrelationEngine.SecurityEvent evt : window.events) {
            String eventType = evt.eventType ?? 'UNKNOWN';
            Integer count = summary.get(eventType) ?? 0;
            summary.put(eventType, count + 1);
        }

        return summary;
    }
}
