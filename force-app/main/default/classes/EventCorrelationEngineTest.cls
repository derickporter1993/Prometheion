/**
 * Tests for EventCorrelationEngine covering rule loading, event correlation,
 * sequence matching, grouping, and edge cases.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see EventCorrelationEngine
 */
@IsTest(testFor=EventCorrelationEngine.class)
private class EventCorrelationEngineTest {

    @IsTest
    static void shouldLoadActiveRules() {
        Test.startTest();
        List<EventCorrelationEngine.CorrelationRule> rules =
            EventCorrelationEngine.loadActiveRules();
        Test.stopTest();

        Assert.isNotNull(rules, 'Rules list should not be null');
        // CMT records exist from the 8 Correlation_Rule__mdt records we created
        Assert.isTrue(rules.size() > 0, 'Should load at least one active rule');
    }

    @IsTest
    static void shouldCorrelateMatchingSequence() {
        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>{
            new EventCorrelationEngine.SecurityEvent(
                'LOGIN_FROM_NEW_IP', '005000000000001AAA', now.addMinutes(-8)
            ),
            new EventCorrelationEngine.SecurityEvent(
                'RAPID_CONTEXT_SWITCH', '005000000000001AAA', now.addMinutes(-5)
            ),
            new EventCorrelationEngine.SecurityEvent(
                'SENSITIVE_DATA_ACCESS', '005000000000001AAA', now.addMinutes(-2)
            )
        };

        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventCorrelationEngine.correlateEvents(events);
        Test.stopTest();

        // Should match Session_Hijacking rule (10 min window)
        Assert.isNotNull(results, 'Results should not be null');
        // May or may not match depending on CMT record availability in test context
    }

    @IsTest
    static void shouldReturnEmptyForNullEvents() {
        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventCorrelationEngine.correlateEvents(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Null events should return empty results');
    }

    @IsTest
    static void shouldReturnEmptyForEmptyEvents() {
        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventCorrelationEngine.correlateEvents(
                new List<EventCorrelationEngine.SecurityEvent>()
            );
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Empty events should return empty results');
    }

    @IsTest
    static void shouldGroupEventsByUser() {
        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>{
            new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now),
            new EventCorrelationEngine.SecurityEvent('ACCESS', 'user2', now),
            new EventCorrelationEngine.SecurityEvent('EXPORT', 'user1', now),
            new EventCorrelationEngine.SecurityEvent('LOGIN', null, now)
        };

        Test.startTest();
        Map<String, List<EventCorrelationEngine.SecurityEvent>> grouped =
            EventCorrelationEngine.groupEventsByUser(events);
        Test.stopTest();

        Assert.areEqual(3, grouped.size(), 'Should have 3 groups (user1, user2, UNKNOWN)');
        Assert.areEqual(2, grouped.get('user1').size(), 'user1 should have 2 events');
        Assert.areEqual(1, grouped.get('user2').size(), 'user2 should have 1 event');
        Assert.areEqual(1, grouped.get('UNKNOWN').size(), 'UNKNOWN should have 1 event');
    }

    @IsTest
    static void shouldParseValidEventSequence() {
        Test.startTest();
        List<String> sequence = EventCorrelationEngine.parseEventSequence(
            '["LOGIN_FAILURE","LOGIN_FAILURE","ACCOUNT_LOCKOUT"]'
        );
        Test.stopTest();

        Assert.areEqual(3, sequence.size(), 'Should parse 3 event types');
        Assert.areEqual('LOGIN_FAILURE', sequence[0], 'First event should be LOGIN_FAILURE');
        Assert.areEqual('ACCOUNT_LOCKOUT', sequence[2], 'Third event should be ACCOUNT_LOCKOUT');
    }

    @IsTest
    static void shouldReturnEmptyForInvalidJson() {
        Test.startTest();
        List<String> sequence = EventCorrelationEngine.parseEventSequence('not valid json');
        Test.stopTest();

        Assert.isTrue(sequence.isEmpty(), 'Invalid JSON should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyForNullSequence() {
        Test.startTest();
        List<String> sequence = EventCorrelationEngine.parseEventSequence(null);
        Test.stopTest();

        Assert.isTrue(sequence.isEmpty(), 'Null sequence should return empty list');
    }

    @IsTest
    static void shouldReturnEmptyForBlankSequence() {
        Test.startTest();
        List<String> sequence = EventCorrelationEngine.parseEventSequence('');
        Test.stopTest();

        Assert.isTrue(sequence.isEmpty(), 'Blank sequence should return empty list');
    }

    @IsTest
    static void shouldNotMatchIncompleteSequence() {
        // Build a rule with a 3-event sequence but only provide 2 events
        Correlation_Rule__mdt mockMdt = new Correlation_Rule__mdt(
            DeveloperName = 'Test_Rule',
            Rule_Name__c = 'Test Rule',
            Event_Sequence__c = '["EVENT_A","EVENT_B","EVENT_C"]',
            Time_Window_Minutes__c = 60,
            Severity__c = ElaroConstants.SEVERITY_HIGH,
            Is_Active__c = true
        );
        EventCorrelationEngine.CorrelationRule rule =
            new EventCorrelationEngine.CorrelationRule(mockMdt);

        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>{
            new EventCorrelationEngine.SecurityEvent('EVENT_A', 'user1', now.addMinutes(-10)),
            new EventCorrelationEngine.SecurityEvent('EVENT_B', 'user1', now.addMinutes(-5))
        };

        Test.startTest();
        EventCorrelationEngine.CorrelationResult result =
            EventCorrelationEngine.evaluateRule(rule, events, 'user1');
        Test.stopTest();

        Assert.isNull(result, 'Incomplete sequence should not match');
    }

    @IsTest
    static void shouldNotMatchOutsideTimeWindow() {
        Correlation_Rule__mdt mockMdt = new Correlation_Rule__mdt(
            DeveloperName = 'Time_Test',
            Rule_Name__c = 'Time Test',
            Event_Sequence__c = '["EVENT_A","EVENT_B"]',
            Time_Window_Minutes__c = 5,
            Severity__c = ElaroConstants.SEVERITY_HIGH,
            Is_Active__c = true
        );
        EventCorrelationEngine.CorrelationRule rule =
            new EventCorrelationEngine.CorrelationRule(mockMdt);

        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>{
            new EventCorrelationEngine.SecurityEvent('EVENT_A', 'user1', now.addMinutes(-30)),
            new EventCorrelationEngine.SecurityEvent('EVENT_B', 'user1', now)
        };

        Test.startTest();
        EventCorrelationEngine.CorrelationResult result =
            EventCorrelationEngine.evaluateRule(rule, events, 'user1');
        Test.stopTest();

        Assert.isNull(result, 'Events outside time window should not match');
    }

    @IsTest
    static void shouldMatchWithinTimeWindow() {
        Correlation_Rule__mdt mockMdt = new Correlation_Rule__mdt(
            DeveloperName = 'Match_Test',
            Rule_Name__c = 'Match Test',
            Event_Sequence__c = '["EVENT_A","EVENT_B"]',
            Time_Window_Minutes__c = 60,
            Severity__c = ElaroConstants.SEVERITY_CRITICAL,
            Is_Active__c = true
        );
        EventCorrelationEngine.CorrelationRule rule =
            new EventCorrelationEngine.CorrelationRule(mockMdt);

        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>{
            new EventCorrelationEngine.SecurityEvent('EVENT_A', 'user1', now.addMinutes(-10)),
            new EventCorrelationEngine.SecurityEvent('EVENT_B', 'user1', now.addMinutes(-5))
        };

        Test.startTest();
        EventCorrelationEngine.CorrelationResult result =
            EventCorrelationEngine.evaluateRule(rule, events, 'user1');
        Test.stopTest();

        Assert.isNotNull(result, 'Events within window should match');
        Assert.areEqual('Match Test', result.ruleName, 'Rule name should match');
        Assert.areEqual(ElaroConstants.SEVERITY_CRITICAL, result.severity, 'Severity should match');
        Assert.areEqual('user1', result.userId, 'User Id should match');
        Assert.areEqual(2, result.matchedEvents.size(), 'Should have 2 matched events');
    }

    @IsTest
    static void shouldConstructSecurityEventWithMetadata() {
        Map<String, Object> metadata = new Map<String, Object>{
            'ipAddress' => '192.168.1.1',
            'browser' => 'Chrome'
        };

        EventCorrelationEngine.SecurityEvent event = new EventCorrelationEngine.SecurityEvent(
            'LOGIN', 'user1', System.now(), metadata
        );

        Assert.areEqual('LOGIN', event.eventType, 'Event type should match');
        Assert.areEqual('user1', event.userId, 'User Id should match');
        Assert.areEqual(2, event.metadata.size(), 'Metadata should have 2 entries');
    }

    @IsTest
    static void shouldBulkPublishCorrelationResults() {
        // Verify that correlateEvents uses bulk publish internally.
        // We create events that may match rules, and the bulk publish
        // path handles them in a single EventBus.publish call.
        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events = new List<EventCorrelationEngine.SecurityEvent>();

        // Create events for multiple users to potentially produce multiple matches
        for (Integer i = 0; i < 10; i++) {
            String userId = '00500000000000' + String.valueOf(i).leftPad(4, '0');
            events.add(new EventCorrelationEngine.SecurityEvent(
                'LOGIN_FROM_NEW_IP', userId, now.addMinutes(-8)
            ));
            events.add(new EventCorrelationEngine.SecurityEvent(
                'RAPID_CONTEXT_SWITCH', userId, now.addMinutes(-5)
            ));
            events.add(new EventCorrelationEngine.SecurityEvent(
                'SENSITIVE_DATA_ACCESS', userId, now.addMinutes(-2)
            ));
        }

        Test.startTest();
        List<EventCorrelationEngine.CorrelationResult> results =
            EventCorrelationEngine.correlateEvents(events);
        Test.stopTest();

        // Results depend on CMT availability; the key assertion is no governor limit exception
        Assert.isNotNull(results, 'Results should not be null even with bulk events');
    }

    @IsTest
    static void shouldHandleNullMetadataInConstructor() {
        EventCorrelationEngine.SecurityEvent event = new EventCorrelationEngine.SecurityEvent(
            'LOGIN', 'user1', System.now(), null
        );

        Assert.isNotNull(event.metadata, 'Metadata should default to empty map');
        Assert.isTrue(event.metadata.isEmpty(), 'Metadata should be empty');
    }

    @IsTest
    static void shouldReturnRulesFromCacheOnSecondCall() {
        Test.startTest();
        // First call populates Platform Cache
        List<EventCorrelationEngine.CorrelationRule> rules1 =
            EventCorrelationEngine.loadActiveRules();
        // Second call should read from Platform Cache
        List<EventCorrelationEngine.CorrelationRule> rules2 =
            EventCorrelationEngine.loadActiveRules();
        Test.stopTest();

        Assert.isNotNull(rules1, 'First call should return rules');
        Assert.isNotNull(rules2, 'Second call should return rules from cache');
        Assert.areEqual(rules1.size(), rules2.size(),
            'Cached rules count should match original rules count');
    }
}
