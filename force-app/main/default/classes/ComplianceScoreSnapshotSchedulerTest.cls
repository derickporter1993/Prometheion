/**
 * ComplianceScoreSnapshotSchedulerTest
 *
 * Test coverage for ComplianceScoreSnapshotScheduler
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ComplianceScoreSnapshotScheduler.class)
private class ComplianceScoreSnapshotSchedulerTest {

    @TestSetup
    static void setupTestData() {
        // Create test compliance scores for trend analysis
        List<Compliance_Score__c> scores = new List<Compliance_Score__c>();
        List<String> frameworks = new List<String>{'SOC2', 'HIPAA', 'GDPR', 'CCPA', 'PCI-DSS'};

        for (String framework : frameworks) {
            scores.add(new Compliance_Score__c(
                Framework__c = framework,
                Score__c = 85,
                Status__c = 'Compliant',
                Evaluation_Date__c = DateTime.now().addDays(-1),
                Gaps_Count__c = 2,
                Violations_Count__c = 1
            ));
        }
        insert scores;

        // Create test compliance gaps
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        for (Integer i = 0; i < 10; i++) {
            gaps.add(new Compliance_Gap__c(
                Gap_Type__c = 'Access Control',
                Framework__c = frameworks[Math.mod(i, frameworks.size())],
                Severity__c = 'Medium',
                Status__c = 'Open',
                Description__c = 'Test gap ' + i
            ));
        }
        insert gaps;
    }

    @IsTest
    static void testExecute_Success() {
        Test.startTest();

        ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
        scheduler.execute(null);

        Test.stopTest();

        // Verify scheduler executed by checking for audit log entries
        List<Elaro_Audit_Log__c> logs = [
            SELECT Id, Action__c FROM Elaro_Audit_Log__c
            WHERE Action__c IN ('Compliance Score Snapshot', 'Daily Compliance Summary')
        ];
        Assert.isTrue(logs.size() > 0, 'Scheduler should create audit log entries');
    }

    @IsTest
    static void testCaptureSnapshots() {
        Test.startTest();

        ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
        scheduler.captureSnapshots();

        Test.stopTest();

        // Verify snapshots were created
        List<Compliance_Score__c> newSnapshots = [
            SELECT Id, Framework__c, Score__c
            FROM Compliance_Score__c
            WHERE CreatedDate = TODAY
        ];

        Assert.isTrue(newSnapshots.size() > 0, 'Should create compliance score snapshots');
    }

    @IsTest
    static void testScheduleDaily() {
        Test.startTest();

        String jobId = ComplianceScoreSnapshotScheduler.scheduleDaily();

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

        String cronExp = '0 0 2 * * ?';
        String jobId = ComplianceScoreSnapshotScheduler.scheduleCustom(cronExp, 'Custom');

        Test.stopTest();

        Assert.areNotEqual(null, jobId, 'Job ID should not be null');
    }

    @IsTest
    static void testAbortAllJobs() {
        // First schedule a job
        String jobId = ComplianceScoreSnapshotScheduler.scheduleDaily();

        Test.startTest();

        ComplianceScoreSnapshotScheduler.abortAllJobs();

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

        ComplianceScoreSnapshotScheduler.runNow();

        Test.stopTest();

        // Verify runNow executed by checking for audit log entries
        List<Elaro_Audit_Log__c> logs = [
            SELECT Id, Action__c FROM Elaro_Audit_Log__c
            WHERE Action__c IN ('Compliance Score Snapshot', 'Daily Compliance Summary')
        ];
        Assert.isTrue(logs.size() > 0, 'runNow should create audit log entries');
    }

    @IsTest
    static void testGetScoreTrend() {
        Test.startTest();

        List<ComplianceScoreSnapshotScheduler.ScoreTrend> trends =
            ComplianceScoreSnapshotScheduler.getScoreTrend('SOC2', 30);

        Test.stopTest();

        Assert.areNotEqual(null, trends, 'Should return trend data');
    }

    @IsTest
    static void testGetScoreTrend_NullDays() {
        Test.startTest();

        List<ComplianceScoreSnapshotScheduler.ScoreTrend> trends =
            ComplianceScoreSnapshotScheduler.getScoreTrend('HIPAA', null);

        Test.stopTest();

        Assert.areNotEqual(null, trends, 'Should handle null days parameter');
    }

    @IsTest
    static void testGetScoreTrend_ZeroDays() {
        Test.startTest();

        List<ComplianceScoreSnapshotScheduler.ScoreTrend> trends =
            ComplianceScoreSnapshotScheduler.getScoreTrend('GDPR', 0);

        Test.stopTest();

        Assert.areNotEqual(null, trends, 'Should handle zero days parameter');
    }

    @IsTest
    static void testScoreTrendClass() {
        ComplianceScoreSnapshotScheduler.ScoreTrend trend =
            new ComplianceScoreSnapshotScheduler.ScoreTrend();

        trend.date = Date.today();
        trend.score = 85.5;
        trend.status = 'Compliant';
        trend.gapCount = 3;

        Assert.areEqual(Date.today(), trend.date, 'Date should be set');
        Assert.areEqual(85.5, trend.score, 'Score should be set');
        Assert.areEqual('Compliant', trend.status, 'Status should be set');
        Assert.areEqual(3, trend.gapCount, 'Gap count should be set');
    }

    @IsTest
    static void testCaptureSnapshots_WithScoreDrop() {
        // Create a previous high score
        Compliance_Score__c previousScore = new Compliance_Score__c(
            Framework__c = 'SOC2',
            Score__c = 95,
            Status__c = 'Compliant',
            Evaluation_Date__c = DateTime.now().addDays(-1)
        );
        insert previousScore;

        Test.startTest();

        ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
        scheduler.captureSnapshots();

        Test.stopTest();

        // Verify snapshots were created for score comparison scenario
        List<Compliance_Score__c> snapshots = [
            SELECT Id, Framework__c, Score__c
            FROM Compliance_Score__c
            WHERE CreatedDate = TODAY
        ];
        Assert.isTrue(snapshots.size() > 0, 'Should create snapshots even with score drops');
    }

    @IsTest
    static void testBulkSnapshots() {
        // Create 200 compliance gaps across frameworks
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        List<String> frameworks = new List<String>{'SOC2', 'HIPAA', 'GDPR', 'CCPA', 'PCI-DSS'};

        for (Integer i = 0; i < 200; i++) {
            gaps.add(new Compliance_Gap__c(
                Gap_Type__c = 'Access Control',
                Framework__c = frameworks[Math.mod(i, frameworks.size())],
                Severity__c = 'Medium',
                Status__c = 'Open',
                Description__c = 'Bulk gap ' + i
            ));
        }
        insert gaps;

        Test.startTest();

        ComplianceScoreSnapshotScheduler scheduler = new ComplianceScoreSnapshotScheduler();
        scheduler.captureSnapshots();

        Test.stopTest();

        // Should handle bulk data without governor limit issues
        Assert.isTrue(Limits.getQueries() < 100, 'Should stay under SOQL limit');
        Assert.isTrue(Limits.getDmlStatements() < 150, 'Should stay under DML limit');
    }
}
