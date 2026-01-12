/**
 * SOC2DataRetentionServiceTest
 *
 * Test class for SOC2DataRetentionService
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
public class SOC2DataRetentionServiceTest {

    @TestSetup
    static void setup() {
        // Create test compliance evidence records
        List<Compliance_Evidence__c> evidenceRecords = new List<Compliance_Evidence__c>();
        for (Integer i = 0; i < 5; i++) {
            evidenceRecords.add(new Compliance_Evidence__c(
                Framework__c = 'SOC2',
                Evidence_Type__c = 'SETUP_AUDIT_TRAIL',
                Description__c = 'Test evidence ' + i,
                Evidence_Date__c = DateTime.now().addDays(-i * 30),
                Status__c = 'COLLECTED'
            ));
        }
        insert evidenceRecords;
    }

    @isTest
    static void testGetFrameworkName() {
        SOC2DataRetentionService service = new SOC2DataRetentionService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('SOC2', frameworkName, 'Framework name should be SOC2');
    }

    @isTest
    static void testEvaluateRetentionPolicies() {
        Test.startTest();
        SOC2DataRetentionService.RetentionEvaluationResult result =
            SOC2DataRetentionService.evaluateRetentionPolicies();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.evaluationDate, 'Evaluation date should be set');
        System.assertNotEquals(null, result.objectResults, 'Object results should not be null');
        System.assert(result.totalObjects > 0, 'Should evaluate at least one object');
    }

    @isTest
    static void testGetObjectsWithoutRetention() {
        Test.startTest();
        List<String> objectsWithoutRetention = SOC2DataRetentionService.getObjectsWithoutRetention();
        Test.stopTest();

        System.assertNotEquals(null, objectsWithoutRetention, 'Result should not be null');
        // The result depends on org configuration
    }

    @isTest
    static void testGetRetentionViolations() {
        Test.startTest();
        List<SOC2DataRetentionService.RetentionViolation> violations =
            SOC2DataRetentionService.getRetentionViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations list should not be null');
    }

    @isTest
    static void testGetViolations() {
        SOC2DataRetentionService service = new SOC2DataRetentionService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testGetComplianceScore() {
        SOC2DataRetentionService service = new SOC2DataRetentionService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testCalculateRiskScore() {
        SOC2DataRetentionService service = new SOC2DataRetentionService();

        Map<String, Object> metadata = new Map<String, Object>{
            'hasModifyAll' => true,
            'hasViewAll' => false
        };

        Test.startTest();
        Decimal riskScore = service.calculateRiskScore('PERMISSION_SET', 'TestId', metadata);
        Test.stopTest();

        System.assert(riskScore > 0, 'Risk score should be greater than 0');
        System.assert(riskScore <= 10, 'Risk score should not exceed 10');
    }

    @isTest
    static void testScheduleRetentionCheck() {
        Test.startTest();
        Id jobId = SOC2DataRetentionService.scheduleRetentionCheck(null);
        Test.stopTest();

        // Currently returns null as placeholder
        System.assertEquals(null, jobId, 'Job ID should be null (placeholder implementation)');
    }

    @isTest
    static void testBulkRetentionEvaluation() {
        // Create bulk test data
        List<Compliance_Evidence__c> bulkEvidence = new List<Compliance_Evidence__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkEvidence.add(new Compliance_Evidence__c(
                Framework__c = 'SOC2',
                Evidence_Type__c = 'FIELD_HISTORY',
                Description__c = 'Bulk test evidence ' + i,
                Evidence_Date__c = DateTime.now().addDays(-i),
                Status__c = 'COLLECTED'
            ));
        }
        insert bulkEvidence;

        Test.startTest();
        SOC2DataRetentionService.RetentionEvaluationResult result =
            SOC2DataRetentionService.evaluateRetentionPolicies();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for bulk test');
    }
}
