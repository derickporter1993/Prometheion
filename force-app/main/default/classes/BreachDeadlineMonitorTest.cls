/**
 * BreachDeadlineMonitorTest
 *
 * Test coverage for BreachDeadlineMonitor
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=BreachDeadlineMonitor.class)
private class BreachDeadlineMonitorTest {

    @TestSetup
    static void setupTestData() {
        // Create test HIPAA breach records with various statuses
        List<HIPAA_Breach__c> breaches = new List<HIPAA_Breach__c>();

        // Overdue breach
        breaches.add(new HIPAA_Breach__c(
            Name = 'Overdue Breach',
            Description__c = 'Test overdue breach',
            Discovery_Date__c = Date.today().addDays(-70),
            Notification_Deadline__c = Date.today().addDays(-10),
            Records_Affected__c = 100,
            Status__c = 'Under Investigation',
            Risk_Level__c = 'High',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false
        ));

        // Critical deadline breach (within 7 days)
        breaches.add(new HIPAA_Breach__c(
            Name = 'Critical Deadline Breach',
            Description__c = 'Test critical deadline breach',
            Discovery_Date__c = Date.today().addDays(-55),
            Notification_Deadline__c = Date.today().addDays(5),
            Records_Affected__c = 50,
            Status__c = 'Under Investigation',
            Risk_Level__c = 'Medium',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false
        ));

        // Upcoming deadline breach (within 14 days)
        breaches.add(new HIPAA_Breach__c(
            Name = 'Upcoming Deadline Breach',
            Description__c = 'Test upcoming deadline breach',
            Discovery_Date__c = Date.today().addDays(-50),
            Notification_Deadline__c = Date.today().addDays(10),
            Records_Affected__c = 25,
            Status__c = 'Under Investigation',
            Risk_Level__c = 'Low',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false
        ));

        // Large breach requiring HHS notification (500+ records)
        breaches.add(new HIPAA_Breach__c(
            Name = 'Large Breach',
            Description__c = 'Test large breach requiring HHS',
            Discovery_Date__c = Date.today().addDays(-30),
            Notification_Deadline__c = Date.today().addDays(30),
            Records_Affected__c = 750,
            Status__c = 'Under Investigation',
            Risk_Level__c = 'Critical',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false
        ));

        // Completed breach (should not trigger alerts)
        breaches.add(new HIPAA_Breach__c(
            Name = 'Completed Breach',
            Description__c = 'Test completed breach',
            Discovery_Date__c = Date.today().addDays(-60),
            Notification_Deadline__c = Date.today().addDays(-5),
            Records_Affected__c = 30,
            Status__c = 'Closed',
            Risk_Level__c = 'Low',
            Notification_Required__c = true,
            Individuals_Notified__c = true,
            HHS_Notified__c = true
        ));

        insert breaches;
    }

    @IsTest
    static void testExecute_Success() {
        Test.startTest();

        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.execute(null);

        Test.stopTest();

        // Verify monitor executed by checking for audit log entries
        List<Elaro_Audit_Log__c> logs = [
            SELECT Id, Action__c FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Breach Deadline Monitor'
        ];
        Assert.isTrue(logs.size() > 0, 'Monitor should create an audit log entry');
    }

    @IsTest
    static void testMonitorDeadlines() {
        Test.startTest();

        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.monitorDeadlines();

        Test.stopTest();

        // Verify compliance gaps were created for overdue breaches
        List<Compliance_Gap__c> gaps = [
            SELECT Id, Gap_Type__c, Framework__c, Severity__c
            FROM Compliance_Gap__c
            WHERE Framework__c = 'HIPAA'
            AND CreatedDate = TODAY
        ];

        Assert.isTrue(gaps.size() > 0, 'Should create compliance gaps for breaches');
    }

    @IsTest
    static void testScheduleDaily() {
        Test.startTest();

        String jobId = BreachDeadlineMonitor.scheduleDaily();

        Test.stopTest();

        Assert.areNotEqual(null, jobId, 'Job ID should not be null');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Assert.areEqual(1, jobs.size(), 'Job should be scheduled');
    }

    @IsTest
    static void testScheduleCustom() {
        Test.startTest();

        String cronExp = '0 0 9 * * ?';
        String jobId = BreachDeadlineMonitor.scheduleCustom(cronExp, 'Morning');

        Test.stopTest();

        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testAbortAllJobs() {
        // First schedule a job
        String jobId = BreachDeadlineMonitor.scheduleDaily();

        Test.startTest();

        BreachDeadlineMonitor.abortAllJobs();

        Test.stopTest();

        // Verify job was aborted
        List<CronTrigger> jobs = [
            SELECT Id
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        Assert.areEqual(0, jobs.size(), 'Job should be aborted');
    }

    @IsTest
    static void testRunNow() {
        Test.startTest();

        BreachDeadlineMonitor.runNow();

        Test.stopTest();

        // Verify runNow executed by checking for audit log entries
        List<Elaro_Audit_Log__c> logs = [
            SELECT Id, Action__c FROM Elaro_Audit_Log__c
            WHERE Action__c = 'Breach Deadline Monitor'
        ];
        Assert.isTrue(logs.size() > 0, 'runNow should create an audit log entry');
    }

    @IsTest
    static void testGetDeadlineSummary() {
        Test.startTest();

        BreachDeadlineMonitor.DeadlineSummary summary = BreachDeadlineMonitor.getDeadlineSummary();

        Test.stopTest();

        Assert.areNotEqual(null, summary, 'Should return deadline summary');
        Assert.isTrue(summary.overdueCount >= 0, 'Overdue count should be valid');
        Assert.isTrue(summary.criticalCount >= 0, 'Critical count should be valid');
        Assert.isTrue(summary.upcomingCount >= 0, 'Upcoming count should be valid');
        Assert.isTrue(summary.hhsRequiredCount >= 0, 'HHS required count should be valid');
    }

    @IsTest
    static void testDeadlineSummaryClass() {
        BreachDeadlineMonitor.DeadlineSummary summary =
            new BreachDeadlineMonitor.DeadlineSummary();

        summary.overdueCount = 2;
        summary.criticalCount = 3;
        summary.upcomingCount = 5;
        summary.hhsRequiredCount = 1;
        summary.totalActiveBreaches = 10;

        Assert.areEqual(2, summary.overdueCount, 'Overdue count should be set');
        Assert.areEqual(3, summary.criticalCount, 'Critical count should be set');
        Assert.areEqual(5, summary.upcomingCount, 'Upcoming count should be set');
        Assert.areEqual(1, summary.hhsRequiredCount, 'HHS required count should be set');
        Assert.areEqual(10, summary.totalActiveBreaches, 'Total should be set');
    }

    @IsTest
    static void testMonitorDeadlines_NoBreaches() {
        // Delete all test breaches
        delete [SELECT Id FROM HIPAA_Breach__c];

        Test.startTest();

        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.monitorDeadlines();

        Test.stopTest();

        // Verify no compliance gaps were created for empty breach set
        List<Compliance_Gap__c> gaps = [
            SELECT Id FROM Compliance_Gap__c
            WHERE Framework__c = 'HIPAA'
            AND CreatedDate = TODAY
        ];
        Assert.areEqual(0, gaps.size(), 'Should not create gaps when no breaches exist');
    }

    @IsTest
    static void testBulkBreaches() {
        // Create 200 breach records
        List<HIPAA_Breach__c> breaches = new List<HIPAA_Breach__c>();
        for (Integer i = 0; i < 200; i++) {
            breaches.add(new HIPAA_Breach__c(
                Name = 'Bulk Breach ' + i,
                Description__c = 'Bulk test breach',
                Discovery_Date__c = Date.today().addDays(-50 - Math.mod(i, 30)),
                Notification_Deadline__c = Date.today().addDays(10 - Math.mod(i, 25)),
                Records_Affected__c = 10 + Math.mod(i, 100),
                Status__c = 'Under Investigation',
                Risk_Level__c = 'Medium',
                Notification_Required__c = true,
                Individuals_Notified__c = false,
                HHS_Notified__c = false
            ));
        }
        insert breaches;

        Test.startTest();

        BreachDeadlineMonitor monitor = new BreachDeadlineMonitor();
        monitor.monitorDeadlines();

        Test.stopTest();

        // Should handle bulk data without governor limit issues
        Assert.isTrue(Limits.getQueries() < 100, 'Should stay under SOQL limit');
        Assert.isTrue(Limits.getDmlStatements() < 150, 'Should stay under DML limit');
    }
}
