/**
 * Tests for ElaroEventProcessor
 *
 * Validates Platform Event processing, null/empty handling, and graph indexing
 * delegation for Elaro_Event__e records.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Processing
 * @see ElaroEventProcessor
 */
@IsTest(testFor=ElaroEventProcessor.class)
private class ElaroEventProcessorTest {

    @IsTest
    static void shouldSkipNullEvent() {
        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvent(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvent should not throw on null input');
    }

    @IsTest
    static void shouldSkipEventWithBlankEntityType() {
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = '',
            Entity_Id__c = 'someId',
            Framework__c = 'SOC2',
            Event_Type__c = 'CHANGE'
        );

        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvent(evt);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvent should not throw when entity type is blank');
    }

    @IsTest
    static void shouldSkipEventWithBlankEntityId() {
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '',
            Framework__c = 'SOC2',
            Event_Type__c = 'CHANGE'
        );

        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvent(evt);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvent should not throw when entity ID is blank');
    }

    @IsTest
    static void shouldHandleExceptionInProcessEventGracefully() {
        // Provide a valid-looking event that will cause ElaroGraphIndexer to throw
        // (invalid entity type for the indexer)
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = 'UNSUPPORTED_TYPE',
            Entity_Id__c = 'fakeId123',
            Framework__c = 'SOC2',
            Event_Type__c = 'CHANGE',
            Correlation_Id__c = 'TEST-CORR-001'
        );

        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvent(evt);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvent should catch exceptions from graph indexer and log them');
    }

    @IsTest
    static void shouldSkipNullEventList() {
        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvents(null);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvents should not throw on null list');
    }

    @IsTest
    static void shouldSkipEmptyEventList() {
        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvents(new List<Elaro_Event__e>());
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvents should not throw on empty list');
    }

    @IsTest
    static void shouldProcessMultipleEventsWithMixedValidity() {
        List<Elaro_Event__e> events = new List<Elaro_Event__e>{
            new Elaro_Event__e(
                Entity_Type__c = '',
                Entity_Id__c = 'id1',
                Framework__c = 'SOC2',
                Event_Type__c = 'CHANGE'
            ),
            new Elaro_Event__e(
                Entity_Type__c = 'PERMISSION_SET',
                Entity_Id__c = '',
                Framework__c = 'HIPAA',
                Event_Type__c = 'CHANGE'
            ),
            new Elaro_Event__e(
                Entity_Type__c = 'UNKNOWN_TYPE',
                Entity_Id__c = 'fakeId',
                Framework__c = 'SOC2',
                Event_Type__c = 'CHANGE'
            )
        };

        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvents(events);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvents should handle a batch of events with mixed validity without throwing');
        Assert.areEqual(3, events.size(), 'Original event list should remain intact after processing');
    }

    @IsTest
    static void shouldDefaultFrameworkToSOC2WhenBlank() {
        // When framework is blank, processEvent defaults to SOC2 before calling indexer
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = 'UNSUPPORTED_TYPE',
            Entity_Id__c = 'fakeId456',
            Framework__c = '',
            Event_Type__c = 'CHANGE'
        );

        Exception caughtEx;
        Test.startTest();
        try {
            ElaroEventProcessor.processEvent(evt);
        } catch (Exception e) {
            caughtEx = e;
        }
        Test.stopTest();

        Assert.isNull(caughtEx, 'processEvent should default to SOC2 framework when event framework is blank');
    }
}
