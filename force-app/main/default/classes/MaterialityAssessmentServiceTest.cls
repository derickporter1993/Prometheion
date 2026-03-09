/**
 * Test class for {@link MaterialityAssessmentService}. Validates assessment
 * lifecycle: creation, determination, AG delay, timeline retrieval,
 * and open assessment queries.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group SEC Cybersecurity
 * @see MaterialityAssessmentService
 */
@IsTest
private class MaterialityAssessmentServiceTest {

    @TestSetup
    static void makeData() {
        Materiality_Assessment__c ma = new Materiality_Assessment__c(
            Incident_Description__c = 'Test cybersecurity incident - unauthorized access detected',
            Discovery_Date__c = DateTime.now().addDays(-5),
            Status__c = 'Draft'
        );
        insert as user ma;

        // Create a second assessment that is Closed for filtering tests
        Materiality_Assessment__c closedMa = new Materiality_Assessment__c(
            Incident_Description__c = 'Resolved incident - phishing attempt contained',
            Discovery_Date__c = DateTime.now().addDays(-30),
            Status__c = 'Closed'
        );
        insert as user closedMa;
    }

    /**
     * Verify createAssessment produces a record with correct default values.
     */
    @IsTest
    static void testCreateAssessment_success() {
        String description = 'New ransomware incident detected in production environment';
        DateTime discoveryDate = DateTime.now();

        Test.startTest();
        Materiality_Assessment__c result = MaterialityAssessmentService.createAssessment(
            description, discoveryDate
        );
        Test.stopTest();

        Assert.isNotNull(result.Id, 'Assessment should have been inserted with an Id');

        Materiality_Assessment__c queried = [
            SELECT Incident_Description__c, Discovery_Date__c, Status__c
            FROM Materiality_Assessment__c
            WHERE Id = :result.Id
            WITH USER_MODE
        ];
        Assert.areEqual(description, queried.Incident_Description__c, 'Description should match');
        Assert.areEqual('Draft', queried.Status__c, 'Initial status should be Draft');
    }

    /**
     * Verify submitDetermination sets Filing_Deadline__c and status correctly.
     */
    @IsTest
    static void testSubmitDetermination_calculatesFiling() {
        Materiality_Assessment__c ma = [
            SELECT Id FROM Materiality_Assessment__c WHERE Status__c = 'Draft' LIMIT 1
        ];

        // Use a Monday so deadline calculation is straightforward
        DateTime determinationDate = DateTime.newInstance(2026, 1, 5, 10, 0, 0);

        Test.startTest();
        MaterialityAssessmentService.submitDetermination(ma.Id, 'Material', determinationDate);
        Test.stopTest();

        Materiality_Assessment__c updated = [
            SELECT Determination_Result__c, Determination_Date__c, Filing_Deadline__c, Status__c
            FROM Materiality_Assessment__c
            WHERE Id = :ma.Id
            WITH USER_MODE
        ];

        Assert.areEqual('Material', updated.Determination_Result__c, 'Determination result should be Material');
        Assert.areEqual(determinationDate, updated.Determination_Date__c, 'Determination date should be set');
        Assert.isNotNull(updated.Filing_Deadline__c, 'Filing deadline should be calculated');
        Assert.areEqual('Determined', updated.Status__c, 'Status should transition to Determined');

        // 4 business days from Monday Jan 5 = Friday Jan 9
        Assert.areEqual(
            Date.newInstance(2026, 1, 9),
            updated.Filing_Deadline__c.date(),
            'Filing deadline should be 4 business days from determination'
        );
    }

    /**
     * Verify requestAGDelay recalculates the filing deadline with extra days.
     */
    @IsTest
    static void testRequestAGDelay_recalculatesDeadline() {
        Materiality_Assessment__c ma = [
            SELECT Id FROM Materiality_Assessment__c WHERE Status__c = 'Draft' LIMIT 1
        ];

        // First submit determination
        DateTime determinationDate = DateTime.newInstance(2026, 1, 5, 10, 0, 0);
        MaterialityAssessmentService.submitDetermination(ma.Id, 'Material', determinationDate);

        Test.startTest();
        MaterialityAssessmentService.requestAGDelay(ma.Id, 3);
        Test.stopTest();

        Materiality_Assessment__c updated = [
            SELECT AG_Delay_Requested__c, AG_Delay_Duration_Days__c, Filing_Deadline__c, Status__c
            FROM Materiality_Assessment__c
            WHERE Id = :ma.Id
            WITH USER_MODE
        ];

        Assert.isTrue(updated.AG_Delay_Requested__c, 'AG delay should be flagged as requested');
        Assert.areEqual(3, updated.AG_Delay_Duration_Days__c, 'Delay duration should be 3 days');
        Assert.areEqual('AG_Delay_Requested', updated.Status__c, 'Status should be AG_Delay_Requested');
        // 4 base + 3 delay = 7 business days from Mon Jan 5 = Wed Jan 14
        Assert.areEqual(
            Date.newInstance(2026, 1, 14),
            updated.Filing_Deadline__c.date(),
            'Filing deadline should reflect 7 total business days (4 base + 3 delay)'
        );
    }

    /**
     * Verify getAssessmentWithTimeline includes child Incident_Timeline__c records.
     */
    @IsTest
    static void testGetAssessmentWithTimeline_includesEvents() {
        Materiality_Assessment__c ma = [
            SELECT Id FROM Materiality_Assessment__c WHERE Status__c = 'Draft' LIMIT 1
        ];

        // Create timeline events
        List<Incident_Timeline__c> events = new List<Incident_Timeline__c>{
            new Incident_Timeline__c(
                Materiality_Assessment__c = ma.Id,
                Event_Date__c = DateTime.now().addDays(-4),
                Event_Type__c = 'Detection',
                Event_Description__c = 'Anomaly detected by SIEM',
                Performed_By__c = 'SOC Team'
            ),
            new Incident_Timeline__c(
                Materiality_Assessment__c = ma.Id,
                Event_Date__c = DateTime.now().addDays(-3),
                Event_Type__c = 'Containment',
                Event_Description__c = 'Affected systems isolated',
                Performed_By__c = 'IR Team'
            )
        };
        insert as user events;

        Test.startTest();
        Materiality_Assessment__c result = MaterialityAssessmentService.getAssessmentWithTimeline(ma.Id);
        Test.stopTest();

        Assert.isNotNull(result, 'Assessment should be returned');
        Assert.areEqual(ma.Id, result.Id, 'Should return the requested assessment');
        Assert.areEqual(
            2,
            result.Incident_Timelines__r.size(),
            'Should include 2 timeline events'
        );
        // Verify ordering: Detection should come before Containment
        Assert.areEqual(
            'Detection',
            result.Incident_Timelines__r[0].Event_Type__c,
            'First event should be Detection (ordered by date)'
        );
    }

    /**
     * Verify getOpenAssessments excludes Closed records.
     */
    @IsTest
    static void testGetOpenAssessments_excludesClosed() {
        Test.startTest();
        List<Materiality_Assessment__c> openAssessments = MaterialityAssessmentService.getOpenAssessments();
        Test.stopTest();

        Assert.isFalse(openAssessments.isEmpty(), 'Should return at least one open assessment');

        for (Materiality_Assessment__c ma : openAssessments) {
            Assert.areNotEqual(
                'Closed',
                ma.Status__c,
                'Closed assessments should not appear in open list'
            );
        }
    }

    /**
     * Verify requestAGDelay fails when no determination exists.
     */
    @IsTest
    static void testRequestAGDelay_noDetermination_throwsException() {
        Materiality_Assessment__c ma = [
            SELECT Id FROM Materiality_Assessment__c WHERE Status__c = 'Draft' LIMIT 1
        ];

        Boolean exceptionThrown = false;
        Test.startTest();
        try {
            MaterialityAssessmentService.requestAGDelay(ma.Id, 3);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(
                e.getMessage().contains('determination'),
                'Exception message should mention determination requirement'
            );
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw exception when no determination date exists');
    }
}
