/**
 * Tests for EventWindowService covering window creation, event management,
 * expiration eviction, filtering, and correlation.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see EventWindowService
 */
@IsTest(testFor=EventWindowService.class)
private class EventWindowServiceTest {

    @IsTest
    static void shouldCreateWindowWithValidDuration() {
        Test.startTest();
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test-window', 30);
        Test.stopTest();

        Assert.isNotNull(window, 'Window should not be null');
        Assert.areEqual('test-window', window.windowId, 'Window Id should match');
        Assert.areEqual(30, window.windowMinutes, 'Window duration should be 30 minutes');
        Assert.isNotNull(window.windowStart, 'Window start should be set');
        Assert.isNotNull(window.windowEnd, 'Window end should be set');
        Assert.areEqual(0, window.size(), 'Window should start empty');
        Assert.isFalse(window.isFull(), 'New window should not be full');
    }

    @IsTest
    static void shouldClampWindowToMaxDuration() {
        Test.startTest();
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('max-window', 9999);
        Test.stopTest();

        Assert.areEqual(EventWindowService.MAX_WINDOW_MINUTES, window.windowMinutes,
            'Window should be clamped to max duration');
    }

    @IsTest
    static void shouldUseDefaultForZeroDuration() {
        Test.startTest();
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('default-window', 0);
        Test.stopTest();

        Assert.areEqual(EventWindowService.DEFAULT_WINDOW_MINUTES, window.windowMinutes,
            'Zero duration should use default');
    }

    @IsTest
    static void shouldUseDefaultForNegativeDuration() {
        Test.startTest();
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('neg-window', -10);
        Test.stopTest();

        Assert.areEqual(EventWindowService.DEFAULT_WINDOW_MINUTES, window.windowMinutes,
            'Negative duration should use default');
    }

    @IsTest
    static void shouldAddEventWithinWindow() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        EventCorrelationEngine.SecurityEvent event =
            new EventCorrelationEngine.SecurityEvent(
                'LOGIN', 'user1', System.now().addMinutes(-5)
            );

        Test.startTest();
        Boolean added = EventWindowService.addEvent(window, event);
        Test.stopTest();

        Assert.isTrue(added, 'Event within window should be added');
        Assert.areEqual(1, window.size(), 'Window should have 1 event');
    }

    @IsTest
    static void shouldRejectEventOutsideWindow() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 30);
        EventCorrelationEngine.SecurityEvent event =
            new EventCorrelationEngine.SecurityEvent(
                'LOGIN', 'user1', System.now().addHours(-2)
            );

        Test.startTest();
        Boolean added = EventWindowService.addEvent(window, event);
        Test.stopTest();

        Assert.isFalse(added, 'Event outside window should be rejected');
        Assert.areEqual(0, window.size(), 'Window should remain empty');
    }

    @IsTest
    static void shouldRejectNullEvent() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);

        Test.startTest();
        Boolean added = EventWindowService.addEvent(window, null);
        Test.stopTest();

        Assert.isFalse(added, 'Null event should be rejected');
    }

    @IsTest
    static void shouldRejectEventWithNullTimestamp() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        EventCorrelationEngine.SecurityEvent event =
            new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', null);

        Test.startTest();
        Boolean added = EventWindowService.addEvent(window, event);
        Test.stopTest();

        Assert.isFalse(added, 'Event with null timestamp should be rejected');
    }

    @IsTest
    static void shouldHandleNullWindowInAddEvent() {
        EventCorrelationEngine.SecurityEvent event =
            new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', System.now());

        Test.startTest();
        Boolean added = EventWindowService.addEvent(null, event);
        Test.stopTest();

        Assert.isFalse(added, 'Null window should return false');
    }

    @IsTest
    static void shouldAddMultipleEvents() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events =
            new List<EventCorrelationEngine.SecurityEvent>{
                new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now.addMinutes(-5)),
                new EventCorrelationEngine.SecurityEvent('ACCESS', 'user1', now.addMinutes(-3)),
                new EventCorrelationEngine.SecurityEvent('OLD_EVENT', 'user1', now.addHours(-3))
            };

        Test.startTest();
        Integer added = EventWindowService.addEvents(window, events);
        Test.stopTest();

        Assert.areEqual(2, added, 'Should add 2 of 3 events (1 outside window)');
        Assert.areEqual(2, window.size(), 'Window should have 2 events');
    }

    @IsTest
    static void shouldReturnZeroForNullInputsInAddEvents() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);

        Assert.areEqual(0, EventWindowService.addEvents(null, new List<EventCorrelationEngine.SecurityEvent>()),
            'Null window should return 0');
        Assert.areEqual(0, EventWindowService.addEvents(window, null),
            'Null events should return 0');
    }

    @IsTest
    static void shouldEvictExpiredEvents() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 30);

        // Manually add an event that's now outside the window
        EventCorrelationEngine.SecurityEvent oldEvent =
            new EventCorrelationEngine.SecurityEvent(
                'OLD', 'user1', System.now().addHours(-2)
            );
        window.events.add(oldEvent);

        EventCorrelationEngine.SecurityEvent recentEvent =
            new EventCorrelationEngine.SecurityEvent(
                'RECENT', 'user1', System.now().addMinutes(-5)
            );
        window.events.add(recentEvent);

        Test.startTest();
        Integer evicted = EventWindowService.evictExpired(window);
        Test.stopTest();

        Assert.areEqual(1, evicted, 'Should evict 1 expired event');
        Assert.areEqual(1, window.size(), 'Window should have 1 remaining event');
    }

    @IsTest
    static void shouldReturnZeroEvictionForEmptyWindow() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);

        Test.startTest();
        Integer evicted = EventWindowService.evictExpired(window);
        Test.stopTest();

        Assert.areEqual(0, evicted, 'Empty window should evict 0');
    }

    @IsTest
    static void shouldReturnZeroEvictionForNullWindow() {
        Test.startTest();
        Integer evicted = EventWindowService.evictExpired(null);
        Test.stopTest();

        Assert.areEqual(0, evicted, 'Null window should evict 0');
    }

    @IsTest
    static void shouldGetEventsByUser() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Datetime now = System.now();
        window.events.add(new EventCorrelationEngine.SecurityEvent('A', 'user1', now.addMinutes(-5)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('B', 'user2', now.addMinutes(-3)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('C', 'user1', now.addMinutes(-1)));

        Test.startTest();
        List<EventCorrelationEngine.SecurityEvent> user1Events =
            EventWindowService.getEventsByUser(window, 'user1');
        Test.stopTest();

        Assert.areEqual(2, user1Events.size(), 'user1 should have 2 events');
    }

    @IsTest
    static void shouldReturnEmptyForUnknownUser() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);

        Test.startTest();
        List<EventCorrelationEngine.SecurityEvent> events =
            EventWindowService.getEventsByUser(window, 'nonexistent');
        Test.stopTest();

        Assert.isTrue(events.isEmpty(), 'Unknown user should return empty list');
    }

    @IsTest
    static void shouldHandleNullInputsInGetEventsByUser() {
        Assert.isTrue(
            EventWindowService.getEventsByUser(null, 'user1').isEmpty(),
            'Null window should return empty'
        );

        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Assert.isTrue(
            EventWindowService.getEventsByUser(window, null).isEmpty(),
            'Null userId should return empty'
        );
        Assert.isTrue(
            EventWindowService.getEventsByUser(window, '').isEmpty(),
            'Blank userId should return empty'
        );
    }

    @IsTest
    static void shouldGetEventsByType() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Datetime now = System.now();
        window.events.add(new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now.addMinutes(-5)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('LOGIN', 'user2', now.addMinutes(-3)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('ACCESS', 'user1', now.addMinutes(-1)));

        Test.startTest();
        List<EventCorrelationEngine.SecurityEvent> loginEvents =
            EventWindowService.getEventsByType(window, 'LOGIN');
        Test.stopTest();

        Assert.areEqual(2, loginEvents.size(), 'Should have 2 LOGIN events');
    }

    @IsTest
    static void shouldGetEventTypeSummary() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Datetime now = System.now();
        window.events.add(new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now.addMinutes(-5)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('LOGIN', 'user2', now.addMinutes(-4)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('ACCESS', 'user1', now.addMinutes(-3)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('EXPORT', 'user1', now.addMinutes(-1)));

        Test.startTest();
        Map<String, Integer> summary = EventWindowService.getEventTypeSummary(window);
        Test.stopTest();

        Assert.areEqual(3, summary.size(), 'Should have 3 event types');
        Assert.areEqual(2, summary.get('LOGIN'), 'LOGIN should have count 2');
        Assert.areEqual(1, summary.get('ACCESS'), 'ACCESS should have count 1');
        Assert.areEqual(1, summary.get('EXPORT'), 'EXPORT should have count 1');
    }

    @IsTest
    static void shouldReturnEmptySummaryForNullWindow() {
        Test.startTest();
        Map<String, Integer> summary = EventWindowService.getEventTypeSummary(null);
        Test.stopTest();

        Assert.isTrue(summary.isEmpty(), 'Null window should return empty summary');
    }

    @IsTest
    static void shouldCorrelateWindow() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);
        Datetime now = System.now();
        window.events.add(new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now.addMinutes(-5)));
        window.events.add(new EventCorrelationEngine.SecurityEvent('ACCESS', 'user1', now.addMinutes(-3)));

        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventWindowService.correlateWindow(window);
        Test.stopTest();

        Assert.isNotNull(results, 'Correlation results should not be null');
    }

    @IsTest
    static void shouldReturnEmptyCorrelationForEmptyWindow() {
        EventWindowService.EventWindow window =
            EventWindowService.createWindow('test', 60);

        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventWindowService.correlateWindow(window);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Empty window should return empty results');
    }

    @IsTest
    static void shouldReturnEmptyCorrelationForNullWindow() {
        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventWindowService.correlateWindow(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Null window should return empty results');
    }

    @IsTest
    static void shouldExposeConstants() {
        Assert.areEqual(60, EventWindowService.DEFAULT_WINDOW_MINUTES,
            'Default window should be 60 minutes');
        Assert.areEqual(1440, EventWindowService.MAX_WINDOW_MINUTES,
            'Max window should be 1440 minutes (24 hours)');
        Assert.areEqual(10000, EventWindowService.MAX_EVENTS_PER_WINDOW,
            'Max events should be 10000');
    }
}
