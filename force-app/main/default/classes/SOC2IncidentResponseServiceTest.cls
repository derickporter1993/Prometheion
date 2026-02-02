/**
 * SOC2IncidentResponseServiceTest
 *
 * Test class for SOC2IncidentResponseService
 *
 * @author Elaro
 * @version 1.0
 */
@isTest
public class SOC2IncidentResponseServiceTest {

    @TestSetup
    static void setup() {
        // Create test security incidents
        List<Security_Incident__c> incidents = new List<Security_Incident__c>();
        incidents.add(new Security_Incident__c(
            Incident_Type__c = 'DATA_BREACH',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Detected_Date__c = DateTime.now().addDays(-1),
            Description__c = 'Test critical incident',
            Affected_Records__c = 1000,
            Framework__c = 'SOC2'
        ));
        incidents.add(new Security_Incident__c(
            Incident_Type__c = 'UNAUTHORIZED_ACCESS',
            Severity__c = 'HIGH',
            Status__c = 'INVESTIGATING',
            Detected_Date__c = DateTime.now().addDays(-3),
            Description__c = 'Test high incident',
            Affected_Records__c = 100,
            Framework__c = 'SOC2'
        ));
        incidents.add(new Security_Incident__c(
            Incident_Type__c = 'POLICY_VIOLATION',
            Severity__c = 'MEDIUM',
            Status__c = 'RESOLVED',
            Detected_Date__c = DateTime.now().addDays(-10),
            Resolved_Date__c = DateTime.now().addDays(-5),
            Description__c = 'Test resolved incident',
            Resolution__c = 'Resolved by retraining user',
            Root_Cause__c = 'User error',
            Framework__c = 'SOC2'
        ));
        insert incidents;
    }

    @isTest
    static void testGetFrameworkName() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('SOC2', frameworkName, 'Framework name should be SOC2');
    }

    @isTest
    static void testAssessBreach() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        IBreachNotificationService.BreachAssessmentRequest request = new IBreachNotificationService.BreachAssessmentRequest();
        request.incidentType = 'DATA_BREACH';
        request.description = 'Test breach assessment';
        request.recordsAffected = 5000;
        request.dataTypesExposed = new List<String>{'PHI', 'SSN'};
        request.discoveryDate = DateTime.now();
        request.encryptionInPlace = false;

        Test.startTest();
        IBreachNotificationService.BreachAssessment assessment = service.assessBreach(request);
        Test.stopTest();

        System.assertNotEquals(null, assessment, 'Assessment should not be null');
        System.assertNotEquals(null, assessment.breachId, 'Breach ID should be set');
        System.assert(assessment.riskScore > 5.0, 'Risk score should be elevated for PHI breach');
        System.assertEquals(true, assessment.notificationRequired, 'Notification should be required');
    }

    @isTest
    static void testAssessBreachLowRisk() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        IBreachNotificationService.BreachAssessmentRequest request = new IBreachNotificationService.BreachAssessmentRequest();
        request.incidentType = 'POLICY_VIOLATION';
        request.description = 'Minor policy violation';
        request.recordsAffected = 10;
        request.encryptionInPlace = true;

        Test.startTest();
        IBreachNotificationService.BreachAssessment assessment = service.assessBreach(request);
        Test.stopTest();

        System.assertNotEquals(null, assessment, 'Assessment should not be null');
        System.assert(assessment.riskScore < 7.0, 'Risk score should be lower for minor incident');
    }

    @isTest
    static void testCreateNotification() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        Security_Incident__c incident = [SELECT Id FROM Security_Incident__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        Id evidenceId = service.createNotification(incident.Id, 'MANAGEMENT');
        Test.stopTest();

        System.assertNotEquals(null, evidenceId, 'Evidence ID should be created');
    }

    @isTest
    static void testGetNotificationDeadline() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        Security_Incident__c incident = [SELECT Id FROM Security_Incident__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        DateTime deadline = service.getNotificationDeadline(incident.Id);
        Test.stopTest();

        System.assertNotEquals(null, deadline, 'Deadline should not be null');
        // Critical incidents have 1-day deadline
        System.assert(deadline > DateTime.now(), 'Deadline should be in the future');
    }

    @isTest
    static void testGetNotificationStatus() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        Security_Incident__c incident = [SELECT Id FROM Security_Incident__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        IBreachNotificationService.NotificationStatus status = service.getNotificationStatus(incident.Id);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(incident.Id, status.breachId, 'Breach ID should match');
    }

    @isTest
    static void testGenerateBreachReport() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();
        Security_Incident__c incident = [SELECT Id FROM Security_Incident__c WHERE Severity__c = 'CRITICAL' LIMIT 1];

        Test.startTest();
        Id docId = service.generateBreachReport(incident.Id);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should not be null');
    }

    @isTest
    static void testGetOpenBreaches() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        Test.startTest();
        List<IBreachNotificationService.BreachSummary> breaches = service.getOpenBreaches();
        Test.stopTest();

        System.assertNotEquals(null, breaches, 'Breaches list should not be null');
        System.assert(breaches.size() >= 2, 'Should have at least 2 open breaches from test data');
    }

    @isTest
    static void testGetBreachMetrics() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        Test.startTest();
        IBreachNotificationService.BreachMetrics metrics = service.getBreachMetrics(30);
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.totalBreaches >= 3, 'Should have at least 3 breaches from test data');
    }

    @isTest
    static void testCreateIncident() {
        SOC2IncidentResponseService.IncidentRequest request = new SOC2IncidentResponseService.IncidentRequest();
        request.incidentType = 'MALWARE';
        request.description = 'Test malware detection';
        request.recordsAffected = 50;

        Test.startTest();
        Id incidentId = SOC2IncidentResponseService.createIncident(request);
        Test.stopTest();

        System.assertNotEquals(null, incidentId, 'Incident ID should be created');
    }

    @isTest
    static void testEscalateIncident() {
        Security_Incident__c incident = [SELECT Id, Severity__c FROM Security_Incident__c WHERE Severity__c = 'MEDIUM' LIMIT 1];

        Test.startTest();
        SOC2IncidentResponseService.escalateIncident(incident.Id, 'Increased impact discovered');
        Test.stopTest();

        incident = [SELECT Severity__c FROM Security_Incident__c WHERE Id = :incident.Id];
        System.assertEquals('HIGH', incident.Severity__c, 'Severity should be escalated to HIGH');
    }

    @isTest
    static void testResolveIncident() {
        Security_Incident__c incident = [SELECT Id FROM Security_Incident__c WHERE Status__c = 'OPEN' LIMIT 1];

        Test.startTest();
        SOC2IncidentResponseService.resolveIncident(incident.Id, 'Issue resolved through patching');
        Test.stopTest();

        incident = [SELECT Status__c, Resolution__c FROM Security_Incident__c WHERE Id = :incident.Id];
        System.assertEquals('RESOLVED', incident.Status__c, 'Status should be RESOLVED');
        System.assertNotEquals(null, incident.Resolution__c, 'Resolution should be set');
    }

    @isTest
    static void testGetOpenIncidents() {
        Test.startTest();
        List<Security_Incident__c> incidents = SOC2IncidentResponseService.getOpenIncidents(null);
        Test.stopTest();

        System.assertNotEquals(null, incidents, 'Incidents list should not be null');
    }

    @isTest
    static void testGetOpenIncidentsBySeverity() {
        Test.startTest();
        List<Security_Incident__c> incidents = SOC2IncidentResponseService.getOpenIncidents('CRITICAL');
        Test.stopTest();

        System.assertNotEquals(null, incidents, 'Incidents list should not be null');
        for (Security_Incident__c inc : incidents) {
            System.assertEquals('CRITICAL', inc.Severity__c, 'All incidents should be CRITICAL');
        }
    }

    @isTest
    static void testGetIncidentMetrics() {
        Test.startTest();
        SOC2IncidentResponseService.IncidentMetrics metrics = SOC2IncidentResponseService.getIncidentMetrics(30);
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.totalIncidents >= 3, 'Should have at least 3 incidents from test data');
    }

    @isTest
    static void testGetViolations() {
        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testBulkIncidentProcessing() {
        // Create bulk incidents
        List<Security_Incident__c> bulkIncidents = new List<Security_Incident__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkIncidents.add(new Security_Incident__c(
                Incident_Type__c = 'OTHER',
                Severity__c = 'LOW',
                Status__c = 'OPEN',
                Detected_Date__c = DateTime.now(),
                Description__c = 'Bulk test incident ' + i,
                Framework__c = 'SOC2'
            ));
        }
        insert bulkIncidents;

        SOC2IncidentResponseService service = new SOC2IncidentResponseService();

        Test.startTest();
        List<IBreachNotificationService.BreachSummary> breaches = service.getOpenBreaches();
        Test.stopTest();

        System.assert(breaches.size() >= 200, 'Should retrieve bulk incidents');
    }
}
