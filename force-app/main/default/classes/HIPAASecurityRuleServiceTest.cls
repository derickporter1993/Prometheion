/**
 * HIPAASecurityRuleServiceTest
 *
 * Test class for HIPAASecurityRuleService
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
public class HIPAASecurityRuleServiceTest {

    @TestSetup
    static void setup() {
        // Create test contacts (PHI objects)
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
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('HIPAA', frameworkName, 'Framework name should be HIPAA');
    }

    @isTest
    static void testGetViolations() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testGetComplianceScore() {
        HIPAASecurityRuleService service = new HIPAASecurityRuleService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testEvaluateTechnicalSafeguards() {
        Test.startTest();
        HIPAASecurityRuleService.TechnicalSafeguardResult result =
            HIPAASecurityRuleService.evaluateTechnicalSafeguards();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.evaluationDate, 'Evaluation date should be set');
        System.assertNotEquals(null, result.accessControlResult, 'Access control result should not be null');
        System.assertNotEquals(null, result.auditControlResult, 'Audit control result should not be null');
        System.assertNotEquals(null, result.integrityControlResult, 'Integrity control result should not be null');
        System.assertNotEquals(null, result.transmissionResult, 'Transmission result should not be null');
    }

    @isTest
    static void testCheckAccessControls() {
        Test.startTest();
        HIPAASecurityRuleService.AccessControlResult result =
            HIPAASecurityRuleService.checkAccessControls();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.score, 'Score should be set');
        System.assertNotEquals(null, result.gaps, 'Gaps should not be null');
        System.assertNotEquals(null, result.violations, 'Violations should not be null');
    }

    @isTest
    static void testCheckAuditControls() {
        Test.startTest();
        HIPAASecurityRuleService.AuditControlResult result =
            HIPAASecurityRuleService.checkAuditControls();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.score, 'Score should be set');
        System.assertNotEquals(null, result.retentionPeriodDays, 'Retention period should be set');
    }

    @isTest
    static void testCheckIntegrityControls() {
        Test.startTest();
        HIPAASecurityRuleService.IntegrityControlResult result =
            HIPAASecurityRuleService.checkIntegrityControls();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.score, 'Score should be set');
    }

    @isTest
    static void testCheckTransmissionSecurity() {
        Test.startTest();
        HIPAASecurityRuleService.TransmissionResult result =
            HIPAASecurityRuleService.checkTransmissionSecurity();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('TLS 1.2+', result.tlsVersion, 'TLS version should be TLS 1.2+');
        System.assertEquals(true, result.tlsCompliant, 'Should be TLS compliant');
    }

    @isTest
    static void testGetEncryptionStatus() {
        Test.startTest();
        Map<String, HIPAASecurityRuleService.EncryptionInfo> status =
            HIPAASecurityRuleService.getEncryptionStatus();
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should not be null');
        System.assert(status.containsKey('Contact'), 'Should include Contact object');
        System.assert(status.containsKey('Lead'), 'Should include Lead object');
        System.assert(status.containsKey('Account'), 'Should include Account object');
        System.assert(status.containsKey('Case'), 'Should include Case object');
    }

    @isTest
    static void testEncryptionInfoDetails() {
        Test.startTest();
        Map<String, HIPAASecurityRuleService.EncryptionInfo> status =
            HIPAASecurityRuleService.getEncryptionStatus();
        Test.stopTest();

        HIPAASecurityRuleService.EncryptionInfo contactInfo = status.get('Contact');
        System.assertNotEquals(null, contactInfo, 'Contact encryption info should not be null');
        System.assertEquals('Contact', contactInfo.objectName, 'Object name should be Contact');
        System.assertNotEquals(null, contactInfo.encryptedFields, 'Encrypted fields list should not be null');
        System.assertNotEquals(null, contactInfo.unencryptedPHIFields, 'Unencrypted PHI fields list should not be null');
    }

    @isTest
    static void testOverallComplianceCalculation() {
        Test.startTest();
        HIPAASecurityRuleService.TechnicalSafeguardResult result =
            HIPAASecurityRuleService.evaluateTechnicalSafeguards();
        Test.stopTest();

        System.assertNotEquals(null, result.overallScore, 'Overall score should be set');
        System.assert(result.overallScore >= 0 && result.overallScore <= 100,
            'Overall score should be between 0 and 100');
        System.assertNotEquals(null, result.overallCompliant, 'Overall compliant flag should be set');
        System.assertNotEquals(null, result.gaps, 'Gaps list should not be null');
    }

    @isTest
    static void testBulkProcessing() {
        // Create bulk contacts
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
        HIPAASecurityRuleService.TechnicalSafeguardResult result =
            HIPAASecurityRuleService.evaluateTechnicalSafeguards();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Should handle bulk data');
    }
}
