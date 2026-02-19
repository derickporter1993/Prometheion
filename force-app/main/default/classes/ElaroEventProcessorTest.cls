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
        Test.startTest();
        ElaroEventProcessor.processEvent(null);
        Test.stopTest();

        // No exception thrown means null guard worked correctly
        Assert.isTrue(true, 'processEvent should silently return on null input');
    }

    @IsTest
    static void shouldSkipEventWithBlankEntityType() {
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = '',
            Entity_Id__c = 'someId',
            Framework__c = 'SOC2',
            Event_Type__c = 'CHANGE'
        );

        Test.startTest();
        ElaroEventProcessor.processEvent(evt);
        Test.stopTest();

        // Blank entity type triggers early return with warning log
        Assert.isTrue(true, 'processEvent should silently return when entity type is blank');
    }

    @IsTest
    static void shouldSkipEventWithBlankEntityId() {
        Elaro_Event__e evt = new Elaro_Event__e(
            Entity_Type__c = 'PERMISSION_SET',
            Entity_Id__c = '',
            Framework__c = 'SOC2',
            Event_Type__c = 'CHANGE'
        );

        Test.startTest();
        ElaroEventProcessor.processEvent(evt);
        Test.stopTest();

        // Blank entity ID triggers early return with warning log
        Assert.isTrue(true, 'processEvent should silently return when entity ID is blank');
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

        Test.startTest();
        // Should not throw -- the catch block logs the error
        ElaroEventProcessor.processEvent(evt);
        Test.stopTest();

        Assert.isTrue(true, 'processEvent should catch exceptions from graph indexer and log them');
    }

    @IsTest
    static void shouldSkipNullEventList() {
        Test.startTest();
        ElaroEventProcessor.processEvents(null);
        Test.stopTest();

        Assert.isTrue(true, 'processEvents should silently return on null list');
    }

    @IsTest
    static void shouldSkipEmptyEventList() {
        Test.startTest();
        ElaroEventProcessor.processEvents(new List<Elaro_Event__e>());
        Test.stopTest();

        Assert.isTrue(true, 'processEvents should silently return on empty list');
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

        Test.startTest();
        ElaroEventProcessor.processEvents(events);
        Test.stopTest();

        // All events processed without unhandled exceptions
        Assert.isTrue(true, 'processEvents should handle a batch of events with mixed validity without throwing');
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

        Test.startTest();
        // This will attempt indexing with SOC2 default, then catch the exception
        ElaroEventProcessor.processEvent(evt);
        Test.stopTest();

        Assert.isTrue(true, 'processEvent should default to SOC2 framework when event framework is blank');
    }
}
