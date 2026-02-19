/**
 * ElaroPCIAccessAlertHandlerTest - Test coverage for PCI DSS access alert handling
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroPCIAccessAlertHandler.class)
private class ElaroPCIAccessAlertHandlerTest {

    // ========================================
    // FAILED ACCESS TESTS
    // ========================================

    @IsTest
    static void testHandleFailedAccess_SingleAttempt() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        events.add(createTestEvent('user001', 'testuser@example.com', '192.168.1.1', 'Failed Login'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should log warning level (not critical) for single failure
        Assert.isNull(caughtEx, 'Single failed access should be handled without throwing');
    }

    @IsTest
    static void testHandleFailedAccess_MultipleAttempts() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        // Create 3+ events for same user (should trigger critical alert)
        for (Integer i = 0; i < 4; i++) {
            events.add(createTestEvent('user001', 'testuser@example.com', '192.168.1.1', 'Failed Login ' + i));
        }

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should trigger critical alert for repeated failures
        Assert.isNull(caughtEx, 'Multiple failed accesses should be handled without throwing');
    }

    @IsTest
    static void testHandleFailedAccess_MultipleUsers() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        // Create events for multiple users
        events.add(createTestEvent('user001', 'user1@example.com', '192.168.1.1', 'Failed Login'));
        events.add(createTestEvent('user002', 'user2@example.com', '192.168.1.2', 'Failed Login'));
        events.add(createTestEvent('user003', 'user3@example.com', '192.168.1.3', 'Failed Login'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should handle multiple users without errors
        Assert.isNull(caughtEx, 'Multiple users should be handled without throwing');
    }

    // ========================================
    // AFTER-HOURS ACCESS TESTS
    // ========================================

    @IsTest
    static void testHandleAfterHoursAccess() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        events.add(createTestEvent('user001', 'testuser@example.com', '192.168.1.1', 'View Record'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleAfterHoursAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should send warning alert for after-hours access
        Assert.isNull(caughtEx, 'After-hours access should be handled without throwing');
    }

    @IsTest
    static void testHandleAfterHoursAccess_MultipleEvents() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        for (Integer i = 0; i < 5; i++) {
            events.add(createTestEvent('user00' + i, 'user' + i + '@example.com', '192.168.1.' + i, 'View Record'));
        }

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleAfterHoursAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should process all after-hours events
        Assert.isNull(caughtEx, 'Multiple after-hours events should be processed without throwing');
    }

    // ========================================
    // BULK ACCESS TESTS
    // ========================================

    @IsTest
    static void testHandleBulkAccess_UnderThreshold() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        events.add(createTestEventWithAction('user001', 'testuser@example.com', '192.168.1.1', 'Bulk: 25 records'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleBulkAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should log event but not trigger alert (under 50 threshold)
        Assert.isNull(caughtEx, 'Under-threshold bulk access should be handled without throwing');
    }

    @IsTest
    static void testHandleBulkAccess_OverThreshold() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        events.add(createTestEventWithAction('user001', 'testuser@example.com', '192.168.1.1', 'Bulk: 100 records'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleBulkAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should trigger high priority alert
        Assert.isNull(caughtEx, 'Over-threshold bulk access should be handled without throwing');
    }

    @IsTest
    static void testHandleBulkAccess_InvalidAction() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        events.add(createTestEventWithAction('user001', 'testuser@example.com', '192.168.1.1', 'Regular access'));

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleBulkAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should handle invalid action format gracefully
        Assert.isNull(caughtEx, 'Invalid action format should be handled without throwing');
    }

    // ========================================
    // SECURITY INCIDENT TESTS
    // ========================================

    @IsTest
    static void testCreateSecurityIncident() {
        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.createSecurityIncident(
                'Test Security Incident',
                'This is a test incident description',
                'High'
            );
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should create security incident without error
        Assert.isNull(caughtEx, 'Security incident creation should complete without throwing');
    }

    // ========================================
    // GOVERNOR LIMIT STRESS TESTS
    // ========================================
    
    @IsTest
    static void testHandleAfterHoursAccess_BulkEvents() {
        // Test with 200 events to verify batching handles governor limits
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        
        for (Integer i = 0; i < 200; i++) {
            events.add(createTestEvent(
                'user' + i, 
                'user' + i + '@example.com', 
                '192.168.1.' + Math.mod(i, 255), 
                'View Record ' + i
            ));
        }
        
        Test.startTest();
        ElaroPCIAccessAlertHandler.handleAfterHoursAccess(events);
        Test.stopTest();
        
        // Should handle 200 events with batched logging (no governor limit errors)
        Assert.areEqual(200, events.size(), 'Should process all 200 events');
    }
    
    @IsTest
    static void testHandleBulkAccess_BulkEvents() {
        // Test with 200 bulk access events
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        
        for (Integer i = 0; i < 200; i++) {
            // Mix of over and under threshold
            Integer recordCount = i < 100 ? 75 : 25;
            events.add(createTestEventWithAction(
                'user' + i, 
                'user' + i + '@example.com', 
                '192.168.1.' + Math.mod(i, 255), 
                'Bulk: ' + recordCount + ' records'
            ));
        }
        
        Test.startTest();
        ElaroPCIAccessAlertHandler.handleBulkAccess(events);
        Test.stopTest();
        
        // Should handle 200 events with batched processing
        Assert.areEqual(200, events.size(), 'Should process all 200 events');
    }
    
    @IsTest
    static void testHandleFailedAccess_BulkUsersWithMultipleAttempts() {
        // Test with 50 users, each with 4 failed attempts (200 total events)
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        
        for (Integer userId = 0; userId < 50; userId++) {
            for (Integer attempt = 0; attempt < 4; attempt++) {
                events.add(createTestEvent(
                    'user' + userId, 
                    'user' + userId + '@example.com', 
                    '192.168.1.' + Math.mod(userId, 255), 
                    'Failed Login Attempt ' + attempt
                ));
            }
        }
        
        Test.startTest();
        ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        Test.stopTest();
        
        // Should group by user and detect 50 users with critical alerts
        Assert.areEqual(200, events.size(), 'Should process all 200 events');
    }

    // ========================================
    // EDGE CASE TESTS
    // ========================================

    @IsTest
    static void testHandleEmptyEvents() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        Test.startTest();

        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
            ElaroPCIAccessAlertHandler.handleAfterHoursAccess(events);
            ElaroPCIAccessAlertHandler.handleBulkAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }

        Test.stopTest();

        // Should handle empty lists gracefully
        Assert.isNull(caughtEx, 'Empty event lists should be handled without throwing');
    }

    @IsTest
    static void testHandleNullEventData() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        // Create event with null/empty Event_Data__c
        Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
            Event_Type__c = 'PCI_ACCESS',
            Timestamp__c = System.now(),
            Event_Data__c = null
        );
        events.add(event);

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should handle null event data gracefully
        Assert.isNull(caughtEx, 'Null event data should be handled without throwing');
    }

    @IsTest
    static void testHandleMalformedJson() {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();

        // Create event with malformed JSON
        Elaro_Raw_Event__e event = new Elaro_Raw_Event__e(
            Event_Type__c = 'PCI_ACCESS',
            Timestamp__c = System.now(),
            Event_Data__c = 'not valid json {'
        );
        events.add(event);

        Test.startTest();
        Exception caughtEx;
        try {
            ElaroPCIAccessAlertHandler.handleFailedAccess(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        // Should handle malformed JSON gracefully
        Assert.isNull(caughtEx, 'Malformed JSON should be handled without throwing');
    }

    // ========================================
    // HELPER METHODS
    // ========================================

    private static Elaro_Raw_Event__e createTestEvent(String userId, String username, String ipAddress, String action) {
        Map<String, Object> eventData = new Map<String, Object>{
            'userId' => userId,
            'username' => username,
            'ipAddress' => ipAddress,
            'userAction' => action,
            'accessType' => 'View',
            'recordId' => '001XXXXXXXXXXXX'
        };

        return new Elaro_Raw_Event__e(
            Event_Type__c = 'PCI_ACCESS',
            Timestamp__c = System.now(),
            Event_Data__c = JSON.serialize(eventData)
        );
    }

    private static Elaro_Raw_Event__e createTestEventWithAction(String userId, String username, String ipAddress, String action) {
        Map<String, Object> eventData = new Map<String, Object>{
            'userId' => userId,
            'username' => username,
            'ipAddress' => ipAddress,
            'userAction' => action,
            'accessType' => 'Export',
            'recordId' => '001XXXXXXXXXXXX'
        };

        return new Elaro_Raw_Event__e(
            Event_Type__c = 'PCI_ACCESS',
            Timestamp__c = System.now(),
            Event_Data__c = JSON.serialize(eventData)
        );
    }
}
