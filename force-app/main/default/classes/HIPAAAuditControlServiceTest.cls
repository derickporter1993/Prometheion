/**
 * HIPAAAuditControlServiceTest
 *
 * Test class for HIPAAAuditControlService
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
public class HIPAAAuditControlServiceTest {

    @TestSetup
    static void setup() {
        // Create test contacts (PHI objects for audit testing)
        List<Contact> contacts = new List<Contact>();
        for (Integer i = 0; i < 10; i++) {
            contacts.add(new Contact(
                FirstName = 'Test',
                LastName = 'Patient ' + i,
                Email = 'patient' + i + '@test.com'
            ));
        }
        insert contacts;
    }

    @isTest
    static void testGetFrameworkName() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('HIPAA', frameworkName, 'Framework name should be HIPAA');
    }

    @isTest
    static void testGetViolations() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testGetComplianceScore() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testEvaluateAuditCompliance() {
        Test.startTest();
        HIPAAAuditControlService.AuditComplianceResult result =
            HIPAAAuditControlService.evaluateAuditCompliance();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.evaluationDate, 'Evaluation date should be set');
        System.assertNotEquals(null, result.coverageResult, 'Coverage result should not be null');
        System.assertNotEquals(null, result.accessPatternResult, 'Access pattern result should not be null');
        System.assertNotEquals(null, result.overallScore, 'Overall score should be set');
    }

    @isTest
    static void testGetPHIAccessLogs() {
        Test.startTest();
        List<HIPAAAuditControlService.PHIAccessLog> logs =
            HIPAAAuditControlService.getPHIAccessLogs(
                Date.today().addDays(-30),
                Date.today()
            );
        Test.stopTest();

        System.assertNotEquals(null, logs, 'Logs should not be null');
    }

    @isTest
    static void testGetUserAccessStats() {
        Test.startTest();
        List<HIPAAAuditControlService.UserAccessStats> stats =
            HIPAAAuditControlService.getUserAccessStats(30);
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Stats should not be null');
    }

    @isTest
    static void testGetUserAccessStatsDefaultDays() {
        Test.startTest();
        List<HIPAAAuditControlService.UserAccessStats> stats =
            HIPAAAuditControlService.getUserAccessStats(null);
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Stats should not be null with null days');
    }

    @isTest
    static void testGetUserAccessStatsInvalidDays() {
        Test.startTest();
        List<HIPAAAuditControlService.UserAccessStats> stats =
            HIPAAAuditControlService.getUserAccessStats(-5);
        Test.stopTest();

        System.assertNotEquals(null, stats, 'Stats should not be null with negative days');
    }

    @isTest
    static void testDetectSuspiciousAccessPatterns() {
        Test.startTest();
        List<HIPAAAuditControlService.SuspiciousAccess> suspicious =
            HIPAAAuditControlService.detectSuspiciousAccessPatterns();
        Test.stopTest();

        System.assertNotEquals(null, suspicious, 'Suspicious list should not be null');
    }

    @isTest
    static void testGenerateAuditReport() {
        Test.startTest();
        Id docId = HIPAAAuditControlService.generateAuditReport(
            Date.today().addDays(-30),
            Date.today()
        );
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should not be null');

        ContentDocument doc = [SELECT Title FROM ContentDocument WHERE Id = :docId];
        System.assert(doc.Title.contains('HIPAA_Audit_Report'), 'Title should contain HIPAA_Audit_Report');
    }

    @isTest
    static void testGenerateAuditReportDefaultDates() {
        Test.startTest();
        Id docId = HIPAAAuditControlService.generateAuditReport(null, null);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should not be null with default dates');
    }

    @isTest
    static void testGetRetentionStatus() {
        Test.startTest();
        HIPAAAuditControlService.RetentionStatus status =
            HIPAAAuditControlService.getRetentionStatus();
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(6, status.requiredYears, 'Required years should be 6');
        System.assertNotEquals(null, status.recommendation, 'Recommendation should be set');
    }

    @isTest
    static void testAuditCoverageResult() {
        Test.startTest();
        HIPAAAuditControlService.AuditComplianceResult result =
            HIPAAAuditControlService.evaluateAuditCompliance();
        Test.stopTest();

        HIPAAAuditControlService.AuditCoverageResult coverage = result.coverageResult;
        System.assertNotEquals(null, coverage, 'Coverage should not be null');
        System.assertNotEquals(null, coverage.totalPHIObjects, 'Total PHI objects should be set');
        System.assertNotEquals(null, coverage.objectsWithTracking, 'Objects with tracking should be set');
        System.assertNotEquals(null, coverage.gaps, 'Gaps should not be null');
    }

    @isTest
    static void testAccessPatternResult() {
        Test.startTest();
        HIPAAAuditControlService.AuditComplianceResult result =
            HIPAAAuditControlService.evaluateAuditCompliance();
        Test.stopTest();

        HIPAAAuditControlService.AccessPatternResult patterns = result.accessPatternResult;
        System.assertNotEquals(null, patterns, 'Patterns should not be null');
        System.assertNotEquals(null, patterns.totalAccessEvents, 'Total access events should be set');
        System.assertNotEquals(null, patterns.suspiciousCount, 'Suspicious count should be set');
    }

    @isTest
    static void testBulkProcessing() {
        // Create bulk contacts for audit
        List<Contact> bulkContacts = new List<Contact>();
        for (Integer i = 0; i < 200; i++) {
            bulkContacts.add(new Contact(
                FirstName = 'Bulk',
                LastName = 'Patient ' + i,
                Email = 'bulk' + i + '@test.com'
            ));
        }
        insert bulkContacts;

        Test.startTest();
        HIPAAAuditControlService.AuditComplianceResult result =
            HIPAAAuditControlService.evaluateAuditCompliance();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should handle bulk data');
    }

    @isTest
    static void testFullComplianceEvaluation() {
        HIPAAAuditControlService service = new HIPAAAuditControlService();

        Test.startTest();
        // Test full evaluation
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Decimal score = service.getComplianceScore();

        // Test static methods
        HIPAAAuditControlService.AuditComplianceResult result =
            HIPAAAuditControlService.evaluateAuditCompliance();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
        System.assert(score >= 0, 'Score should be non-negative');
        System.assertNotEquals(null, result, 'Result should not be null');
    }
}
