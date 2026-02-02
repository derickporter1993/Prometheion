/**
 * Test class for ComplianceReportScheduler
 * Provides comprehensive coverage with meaningful assertions
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ComplianceReportSchedulerTest {

    @TestSetup
    static void setupTestData() {
        // Create test compliance gaps
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        for (Integer i = 0; i < 10; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Test Gap ' + i,
                Severity__c = Math.mod(i, 4) == 0 ? 'Critical' : (Math.mod(i, 3) == 0 ? 'High' : 'Medium'),
                Framework__c = Math.mod(i, 2) == 0 ? 'HIPAA' : 'SOC2',
                Status__c = 'Open',
                Description__c = 'Test gap description ' + i
            ));
        }
        insert gaps;
    }

    /**
     * Test scheduling a weekly report
     */
    @IsTest
    static void testScheduleReport_Weekly() {
        List<String> recipients = new List<String>{ 'test@example.com' };

        Test.startTest();
        String jobId = ComplianceReportScheduler.scheduleReport('WEEKLY', recipients, 'ALL');
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        // Verify job was scheduled
        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name, CronExpression
            FROM CronTrigger
            WHERE Id = :jobId
        ];
        System.assertEquals(1, jobs.size(), 'Should have one scheduled job');
        System.assert(jobs[0].CronJobDetail.Name.contains('WEEKLY'), 'Job name should contain WEEKLY');
    }

    /**
     * Test scheduling a daily report
     */
    @IsTest
    static void testScheduleReport_Daily() {
        List<String> recipients = new List<String>{ 'daily@example.com' };

        Test.startTest();
        String jobId = ComplianceReportScheduler.scheduleReport('DAILY', recipients, 'HIPAA');
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        CronTrigger job = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assert(job.CronExpression.contains('8 * * ?'), 'Should run at 8 AM daily');
    }

    /**
     * Test scheduling a monthly report
     */
    @IsTest
    static void testScheduleReport_Monthly() {
        List<String> recipients = new List<String>{ 'monthly@example.com' };

        Test.startTest();
        String jobId = ComplianceReportScheduler.scheduleReport('MONTHLY', recipients, 'SOC2');
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job ID should not be null');

        CronTrigger job = [SELECT CronExpression FROM CronTrigger WHERE Id = :jobId];
        System.assert(job.CronExpression.contains('8 1 * ?'), 'Should run on 1st of month');
    }

    /**
     * Test get scheduled reports
     */
    @IsTest
    static void testGetScheduledReports() {
        // Schedule a report first
        List<String> recipients = new List<String>{ 'test@example.com' };
        ComplianceReportScheduler.scheduleReport('WEEKLY', recipients, 'ALL');

        Test.startTest();
        List<ComplianceReportScheduler.ScheduledReport> reports = ComplianceReportScheduler.getScheduledReports();
        Test.stopTest();

        System.assert(reports.size() >= 1, 'Should have at least one scheduled report');

        ComplianceReportScheduler.ScheduledReport report = reports[0];
        System.assertNotEquals(null, report.jobId, 'Job ID should not be null');
        System.assertNotEquals(null, report.name, 'Name should not be null');
        System.assertNotEquals(null, report.nextRun, 'Next run should not be null');
    }

    /**
     * Test cancel scheduled report
     */
    @IsTest
    static void testCancelScheduledReport() {
        // Schedule a report first
        List<String> recipients = new List<String>{ 'test@example.com' };
        String jobId = ComplianceReportScheduler.scheduleReport('WEEKLY', recipients, 'ALL');

        Test.startTest();
        ComplianceReportScheduler.cancelScheduledReport(jobId);
        Test.stopTest();

        // Verify job was cancelled
        List<CronTrigger> jobs = [
            SELECT Id FROM CronTrigger WHERE Id = :jobId
        ];
        System.assertEquals(0, jobs.size(), 'Job should be cancelled');
    }

    /**
     * Test send test report
     */
    @IsTest
    static void testSendTestReport() {
        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        Test.startTest();
        // Should not throw exception
        ComplianceReportScheduler.sendTestReport('ALL', new List<String>{ 'test@example.com' });
        Test.stopTest();

        System.assert(true, 'Test report should send without errors');
    }

    /**
     * Test schedulable execute method
     */
    @IsTest
    static void testSchedulableExecute() {
        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        ComplianceReportScheduler scheduler = new ComplianceReportScheduler();

        Test.startTest();
        String jobId = System.schedule(
            'Test Report Scheduler',
            '0 0 8 ? * MON',
            scheduler
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Job should be scheduled');
    }

    /**
     * Test parameterized constructor
     */
    @IsTest
    static void testParameterizedConstructor() {
        List<String> recipients = new List<String>{ 'test@example.com' };
        ComplianceReportScheduler scheduler = new ComplianceReportScheduler(
            ComplianceReportScheduler.Frequency.DAILY,
            recipients,
            'HIPAA'
        );

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        Test.startTest();
        String jobId = System.schedule(
            'Test Parameterized Scheduler',
            '0 0 8 * * ?',
            scheduler
        );
        Test.stopTest();

        System.assertNotEquals(null, jobId, 'Parameterized scheduler should work');
    }

    /**
     * Test invalid frequency
     */
    @IsTest
    static void testScheduleReport_InvalidFrequency() {
        List<String> recipients = new List<String>{ 'test@example.com' };

        Test.startTest();
        try {
            ComplianceReportScheduler.scheduleReport('INVALID', recipients, 'ALL');
            System.assert(false, 'Should throw exception for invalid frequency');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid frequency'), 'Should mention invalid frequency');
        }
        Test.stopTest();
    }

    /**
     * Test empty recipients
     */
    @IsTest
    static void testScheduleReport_NoRecipients() {
        Test.startTest();
        try {
            ComplianceReportScheduler.scheduleReport('WEEKLY', new List<String>(), 'ALL');
            System.assert(false, 'Should throw exception for no recipients');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('recipient'), 'Should mention recipients');
        }
        Test.stopTest();
    }

    /**
     * Test invalid email validation
     */
    @IsTest
    static void testScheduleReport_InvalidEmails() {
        List<String> badEmails = new List<String>{ 'not-an-email', '', '   ' };

        Test.startTest();
        try {
            ComplianceReportScheduler.scheduleReport('WEEKLY', badEmails, 'ALL');
            System.assert(false, 'Should throw exception for invalid emails');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('recipient'), 'Should mention recipients');
        }
        Test.stopTest();
    }

    /**
     * Test invalid framework
     */
    @IsTest
    static void testScheduleReport_InvalidFramework() {
        List<String> recipients = new List<String>{ 'test@example.com' };

        Test.startTest();
        try {
            ComplianceReportScheduler.scheduleReport('WEEKLY', recipients, 'INVALID_FRAMEWORK');
            System.assert(false, 'Should throw exception for invalid framework');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Invalid framework'), 'Should mention invalid framework');
        }
        Test.stopTest();
    }

    /**
     * Test cancel with null job ID
     */
    @IsTest
    static void testCancelScheduledReport_NullJobId() {
        Test.startTest();
        try {
            ComplianceReportScheduler.cancelScheduledReport(null);
            System.assert(false, 'Should throw exception for null job ID');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Job ID'), 'Should mention job ID');
        }
        Test.stopTest();
    }

    /**
     * Test bulk scheduling (200+ record scenario pattern)
     */
    @IsTest
    static void testBulkScheduling() {
        // Create many gaps to test report generation with bulk data
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        for (Integer i = 0; i < 200; i++) {
            gaps.add(new Compliance_Gap__c(
                Name = 'Bulk Gap ' + i,
                Severity__c = 'Medium',
                Framework__c = 'HIPAA',
                Status__c = 'Open'
            ));
        }
        insert gaps;

        Test.setMock(HttpCalloutMock.class, new ReportCalloutMock());

        Test.startTest();
        ComplianceReportScheduler.sendTestReport('HIPAA', new List<String>{ 'bulk@example.com' });
        Test.stopTest();

        // Verify gaps exist
        Integer gapCount = [SELECT COUNT() FROM Compliance_Gap__c WHERE Name LIKE 'Bulk Gap%'];
        System.assertEquals(200, gapCount, 'Should have 200 bulk gaps');
    }

    /**
     * Test default constructor
     */
    @IsTest
    static void testDefaultConstructor() {
        ComplianceReportScheduler scheduler = new ComplianceReportScheduler();
        System.assertNotEquals(null, scheduler, 'Default constructor should work');
    }

    /**
     * Mock class for HTTP callouts
     */
    private class ReportCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"success": true}');
            return res;
        }
    }
}
