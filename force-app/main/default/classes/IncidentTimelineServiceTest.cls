/**
 * Test class for {@link IncidentTimelineService}. Validates timeline event
 * creation, chronological ordering, and SLA status evaluation for incident
 * response phases.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see IncidentTimelineService
 */
@IsTest
private class IncidentTimelineServiceTest {

    @TestSetup
    static void makeData() {
        Materiality_Assessment__c ma = new Materiality_Assessment__c(
            Incident_Description__c = 'Test incident for timeline',
            Discovery_Date__c = DateTime.now().addDays(-5),
            Status__c = 'Draft'
        );
        insert as user ma;
    }

    /**
     * Verify addTimelineEvent creates a record with correct field values.
     */
    @IsTest
    static void testAddTimelineEvent_createsRecord() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];
        DateTime eventDate = DateTime.now().addHours(-2);

        Test.startTest();
        Incident_Timeline__c evt = IncidentTimelineService.addTimelineEvent(
            ma.Id,
            eventDate,
            'Detection',
            'Unauthorized access detected by IDS',
            'SOC Analyst'
        );
        Test.stopTest();

        Assert.isNotNull(evt.Id, 'Timeline event should have been inserted');

        Incident_Timeline__c queried = [
            SELECT Materiality_Assessment__c, Event_Date__c, Event_Type__c,
                Event_Description__c, Performed_By__c
            FROM Incident_Timeline__c
            WHERE Id = :evt.Id
            WITH USER_MODE
        ];

        Assert.areEqual(ma.Id, queried.Materiality_Assessment__c, 'Assessment link should match');
        Assert.areEqual('Detection', queried.Event_Type__c, 'Event type should be Detection');
        Assert.areEqual('SOC Analyst', queried.Performed_By__c, 'Performed by should match');
        Assert.isTrue(
            queried.Event_Description__c.contains('IDS'),
            'Description should be preserved'
        );
    }

    /**
     * Verify getTimeline returns events ordered by date ascending.
     */
    @IsTest
    static void testGetTimeline_orderedByDate() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        // Insert events in reverse chronological order
        DateTime now = DateTime.now();
        Incident_Timeline__c evt3 = new Incident_Timeline__c(
            Materiality_Assessment__c = ma.Id,
            Event_Date__c = now,
            Event_Type__c = 'Investigation_Start',
            Event_Description__c = 'Forensic investigation initiated',
            Performed_By__c = 'IR Lead'
        );
        Incident_Timeline__c evt1 = new Incident_Timeline__c(
            Materiality_Assessment__c = ma.Id,
            Event_Date__c = now.addHours(-10),
            Event_Type__c = 'Detection',
            Event_Description__c = 'Initial detection',
            Performed_By__c = 'SOC'
        );
        Incident_Timeline__c evt2 = new Incident_Timeline__c(
            Materiality_Assessment__c = ma.Id,
            Event_Date__c = now.addHours(-6),
            Event_Type__c = 'Containment',
            Event_Description__c = 'Affected systems isolated',
            Performed_By__c = 'IR Team'
        );
        insert as user new List<Incident_Timeline__c>{ evt3, evt1, evt2 };

        Test.startTest();
        List<Incident_Timeline__c> timeline = IncidentTimelineService.getTimeline(ma.Id);
        Test.stopTest();

        Assert.areEqual(3, timeline.size(), 'Should return all 3 events');
        Assert.areEqual('Detection', timeline[0].Event_Type__c, 'First event should be Detection (earliest)');
        Assert.areEqual('Containment', timeline[1].Event_Type__c, 'Second event should be Containment');
        Assert.areEqual('Investigation_Start', timeline[2].Event_Type__c, 'Third event should be Investigation_Start (latest)');
    }

    /**
     * Verify SLA status is On_Track when containment is within 4 hours of detection.
     */
    @IsTest
    static void testEvaluateSLAStatus_onTrack() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        DateTime detectionTime = DateTime.now().addHours(-5);
        // Containment within 4 hours of detection (3 hours after)
        DateTime containmentTime = detectionTime.addHours(3);

        // Create detection event first
        IncidentTimelineService.addTimelineEvent(
            ma.Id, detectionTime, 'Detection', 'Threat detected', 'SOC'
        );

        Test.startTest();
        // Create containment event within SLA
        Incident_Timeline__c containment = IncidentTimelineService.addTimelineEvent(
            ma.Id, containmentTime, 'Containment', 'Threat contained', 'IR Team'
        );
        Test.stopTest();

        Incident_Timeline__c queried = [
            SELECT SLA_Status__c, SLA_Deadline__c
            FROM Incident_Timeline__c
            WHERE Id = :containment.Id
            WITH USER_MODE
        ];

        Assert.areEqual(
            IncidentTimelineService.SLA_ON_TRACK,
            queried.SLA_Status__c,
            'SLA should be On_Track when containment is within 4 hours of detection'
        );
        Assert.isNotNull(queried.SLA_Deadline__c, 'SLA deadline should be set');
    }

    /**
     * Verify SLA status is Breached when containment exceeds 4 hours after detection.
     */
    @IsTest
    static void testEvaluateSLAStatus_breached() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        DateTime detectionTime = DateTime.now().addHours(-10);
        // Containment 6 hours after detection (exceeds 4-hour SLA)
        DateTime containmentTime = detectionTime.addHours(6);

        // Create detection event first
        IncidentTimelineService.addTimelineEvent(
            ma.Id, detectionTime, 'Detection', 'Threat detected late', 'SOC'
        );

        Test.startTest();
        Incident_Timeline__c containment = IncidentTimelineService.addTimelineEvent(
            ma.Id, containmentTime, 'Containment', 'Late containment', 'IR Team'
        );
        Test.stopTest();

        Incident_Timeline__c queried = [
            SELECT SLA_Status__c, SLA_Deadline__c
            FROM Incident_Timeline__c
            WHERE Id = :containment.Id
            WITH USER_MODE
        ];

        Assert.areEqual(
            IncidentTimelineService.SLA_BREACHED,
            queried.SLA_Status__c,
            'SLA should be Breached when containment exceeds 4 hours after detection'
        );
    }

    /**
     * Verify evaluateSLAStatus re-evaluates and updates all events in bulk.
     */
    @IsTest
    static void testEvaluateSLAStatus_bulkReevaluation() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        DateTime detectionTime = DateTime.now().addHours(-10);
        DateTime containmentTime = detectionTime.addHours(3); // Within SLA
        DateTime investigationTime = detectionTime.addHours(20); // Within 24h SLA

        // Insert events directly (bypassing SLA calc for initial state)
        List<Incident_Timeline__c> events = new List<Incident_Timeline__c>{
            new Incident_Timeline__c(
                Materiality_Assessment__c = ma.Id,
                Event_Date__c = detectionTime,
                Event_Type__c = 'Detection',
                Event_Description__c = 'Detection event',
                Performed_By__c = 'SOC'
            ),
            new Incident_Timeline__c(
                Materiality_Assessment__c = ma.Id,
                Event_Date__c = containmentTime,
                Event_Type__c = 'Containment',
                Event_Description__c = 'Containment event',
                Performed_By__c = 'IR Team'
            ),
            new Incident_Timeline__c(
                Materiality_Assessment__c = ma.Id,
                Event_Date__c = investigationTime,
                Event_Type__c = 'Investigation_Start',
                Event_Description__c = 'Investigation started',
                Performed_By__c = 'Forensics'
            )
        };
        insert as user events;

        Test.startTest();
        IncidentTimelineService.evaluateSLAStatus(ma.Id);
        Test.stopTest();

        Map<String, Incident_Timeline__c> eventsByType = new Map<String, Incident_Timeline__c>();
        for (Incident_Timeline__c evt : [
            SELECT Event_Type__c, SLA_Status__c, SLA_Deadline__c
            FROM Incident_Timeline__c
            WHERE Materiality_Assessment__c = :ma.Id
            WITH USER_MODE
        ]) {
            eventsByType.put(evt.Event_Type__c, evt);
        }

        Assert.areEqual(
            'N/A',
            eventsByType.get('Detection').SLA_Status__c,
            'Detection event should have N/A SLA (no prior event to measure against)'
        );
        Assert.areEqual(
            IncidentTimelineService.SLA_ON_TRACK,
            eventsByType.get('Containment').SLA_Status__c,
            'Containment within 4h should be On_Track'
        );
        Assert.areEqual(
            IncidentTimelineService.SLA_ON_TRACK,
            eventsByType.get('Investigation_Start').SLA_Status__c,
            'Investigation within 24h should be On_Track'
        );
    }

    /**
     * Verify events without SLA requirements get N/A status.
     */
    @IsTest
    static void testAddTimelineEvent_noSLA_setsNA() {
        Materiality_Assessment__c ma = [SELECT Id FROM Materiality_Assessment__c LIMIT 1];

        Test.startTest();
        Incident_Timeline__c evt = IncidentTimelineService.addTimelineEvent(
            ma.Id,
            DateTime.now(),
            'Remediation',
            'Systems patched and restored',
            'IT Ops'
        );
        Test.stopTest();

        Incident_Timeline__c queried = [
            SELECT SLA_Status__c
            FROM Incident_Timeline__c
            WHERE Id = :evt.Id
            WITH USER_MODE
        ];

        Assert.areEqual(
            IncidentTimelineService.SLA_NOT_APPLICABLE,
            queried.SLA_Status__c,
            'Remediation events should have N/A SLA status'
        );
    }
}
