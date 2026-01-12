/**
 * HIPAABreachNotificationServiceTest
 *
 * Test class for HIPAABreachNotificationService
 *
 * @author Prometheion
 * @version 1.0
 */
@isTest
public class HIPAABreachNotificationServiceTest {

    @TestSetup
    static void setup() {
        // Create test breach records
        List<HIPAA_Breach__c> breaches = new List<HIPAA_Breach__c>();

        // Open breach with pending notification
        breaches.add(new HIPAA_Breach__c(
            Description__c = 'Test breach - unauthorized access',
            Discovery_Date__c = Date.today().addDays(-30),
            Notification_Deadline__c = Date.today().addDays(30),
            Records_Affected__c = 100,
            Breach_Type__c = 'Unauthorized Access',
            Status__c = 'Open',
            Risk_Level__c = 'High',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false,
            Media_Notified__c = false
        ));

        // Overdue breach
        breaches.add(new HIPAA_Breach__c(
            Description__c = 'Test breach - overdue notification',
            Discovery_Date__c = Date.today().addDays(-90),
            Notification_Deadline__c = Date.today().addDays(-30),
            Records_Affected__c = 600,
            Breach_Type__c = 'Hacking/IT Incident',
            Status__c = 'Notification In Progress',
            Risk_Level__c = 'High',
            Notification_Required__c = true,
            Individuals_Notified__c = false,
            HHS_Notified__c = false,
            Media_Notified__c = false
        ));

        // Pending assessment breach
        breaches.add(new HIPAA_Breach__c(
            Description__c = 'Test breach - pending assessment',
            Discovery_Date__c = Date.today().addDays(-5),
            Notification_Deadline__c = Date.today().addDays(55),
            Records_Affected__c = 50,
            Breach_Type__c = 'Loss',
            Status__c = 'Pending Assessment',
            Notification_Required__c = false,
            Individuals_Notified__c = false,
            HHS_Notified__c = false,
            Media_Notified__c = false
        ));

        // Closed breach
        breaches.add(new HIPAA_Breach__c(
            Description__c = 'Test breach - closed',
            Discovery_Date__c = Date.today().addDays(-120),
            Notification_Deadline__c = Date.today().addDays(-60),
            Records_Affected__c = 25,
            Breach_Type__c = 'Theft',
            Status__c = 'Closed',
            Risk_Level__c = 'Low',
            Notification_Required__c = true,
            Individuals_Notified__c = true,
            Individual_Notification_Date__c = Date.today().addDays(-70),
            HHS_Notified__c = true,
            HHS_Notification_Date__c = Date.today().addDays(-70),
            Media_Notified__c = false
        ));

        insert breaches;
    }

    @isTest
    static void testGetFrameworkName() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('HIPAA', frameworkName, 'Framework name should be HIPAA');
    }

    @isTest
    static void testGetViolations() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
        System.assert(violations.size() > 0, 'Should have violations for overdue breaches');
    }

    @isTest
    static void testGetComplianceScore() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testAssessBreach() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        IBreachNotificationService.BreachAssessmentRequest request =
            new IBreachNotificationService.BreachAssessmentRequest();
        request.dataTypesInvolved = new List<String>{'SSN', 'Medical Records'};
        request.recordsAffected = 100;
        request.recipientType = 'Unknown';
        request.recipientAuthorized = false;
        request.dataAcquired = true;
        request.dataViewed = true;
        request.mitigationsApplied = new List<String>{'Encryption enabled'};

        Test.startTest();
        IBreachNotificationService.BreachAssessment assessment = service.assessBreach(request);
        Test.stopTest();

        System.assertNotEquals(null, assessment, 'Assessment should not be null');
        System.assertNotEquals(null, assessment.assessmentDate, 'Assessment date should be set');
        System.assertNotEquals(null, assessment.overallRiskScore, 'Overall risk score should be set');
        System.assertNotEquals(null, assessment.notificationRequired, 'Notification required should be set');
        System.assertNotEquals(null, assessment.riskLevel, 'Risk level should be set');
    }

    @isTest
    static void testAssessBreachLowRisk() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        IBreachNotificationService.BreachAssessmentRequest request =
            new IBreachNotificationService.BreachAssessmentRequest();
        request.dataTypesInvolved = new List<String>{'Name'};
        request.recordsAffected = 5;
        request.recipientType = 'Business Associate';
        request.recipientAuthorized = true;
        request.dataAcquired = false;
        request.dataViewed = false;
        request.mitigationsApplied = new List<String>{'Data Destroyed', 'Confidentiality Agreement'};

        Test.startTest();
        IBreachNotificationService.BreachAssessment assessment = service.assessBreach(request);
        Test.stopTest();

        System.assert(assessment.overallRiskScore < 5, 'Low risk scenario should have low score');
    }

    @isTest
    static void testGetNotificationStatus() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        HIPAA_Breach__c breach = [
            SELECT Id FROM HIPAA_Breach__c
            WHERE Status__c = 'Open'
            LIMIT 1
        ];

        Test.startTest();
        IBreachNotificationService.NotificationStatus status =
            service.getNotificationStatus(breach.Id);
        Test.stopTest();

        System.assertNotEquals(null, status, 'Status should not be null');
        System.assertEquals(breach.Id, status.breachId, 'Breach ID should match');
        System.assertNotEquals(null, status.discoveryDate, 'Discovery date should be set');
        System.assertNotEquals(null, status.notificationDeadline, 'Notification deadline should be set');
    }

    @isTest
    static void testGetBreachSummary() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        IBreachNotificationService.BreachSummary summary = service.getBreachSummary();
        Test.stopTest();

        System.assertNotEquals(null, summary, 'Summary should not be null');
        System.assert(summary.totalBreaches >= 4, 'Should have at least 4 breaches from test data');
        System.assert(summary.openBreaches > 0, 'Should have open breaches');
    }

    @isTest
    static void testGetBreachMetrics() {
        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        IBreachNotificationService.BreachMetrics metrics = service.getBreachMetrics(365);
        Test.stopTest();

        System.assertNotEquals(null, metrics, 'Metrics should not be null');
        System.assert(metrics.totalBreaches >= 4, 'Should have at least 4 breaches');
        System.assertNotEquals(null, metrics.breachesByType, 'Breaches by type should not be null');
        System.assertNotEquals(null, metrics.breachesByRiskLevel, 'Breaches by risk level should not be null');
    }

    @isTest
    static void testCreateBreachRecord() {
        Map<String, Object> breachData = new Map<String, Object>{
            'description' => 'New test breach',
            'recordsAffected' => 50,
            'breachType' => 'Unauthorized Access'
        };

        Test.startTest();
        Id breachId = HIPAABreachNotificationService.createBreachRecord(breachData);
        Test.stopTest();

        System.assertNotEquals(null, breachId, 'Breach ID should not be null');

        HIPAA_Breach__c breach = [
            SELECT Description__c, Records_Affected__c, Status__c
            FROM HIPAA_Breach__c
            WHERE Id = :breachId
        ];
        System.assertEquals('New test breach', breach.Description__c, 'Description should match');
        System.assertEquals(50, breach.Records_Affected__c, 'Records affected should match');
        System.assertEquals('Open', breach.Status__c, 'Status should be Open');
    }

    @isTest
    static void testGetPendingBreaches() {
        Test.startTest();
        List<HIPAA_Breach__c> pending = HIPAABreachNotificationService.getPendingBreaches();
        Test.stopTest();

        System.assertNotEquals(null, pending, 'Pending list should not be null');
        System.assert(pending.size() > 0, 'Should have pending breaches');
    }

    @isTest
    static void testGetBreachesRequiringNotification() {
        Test.startTest();
        List<HIPAA_Breach__c> breaches =
            HIPAABreachNotificationService.getBreachesRequiringNotification();
        Test.stopTest();

        System.assertNotEquals(null, breaches, 'Breaches list should not be null');
    }

    @isTest
    static void testRecordIndividualNotification() {
        HIPAA_Breach__c breach = [
            SELECT Id FROM HIPAA_Breach__c
            WHERE Status__c = 'Open' AND Individuals_Notified__c = false
            LIMIT 1
        ];

        Test.startTest();
        HIPAABreachNotificationService.recordIndividualNotification(breach.Id, 100);
        Test.stopTest();

        breach = [
            SELECT Individuals_Notified__c, Individual_Notification_Date__c, Individuals_Notified_Count__c
            FROM HIPAA_Breach__c
            WHERE Id = :breach.Id
        ];
        System.assertEquals(true, breach.Individuals_Notified__c, 'Should be marked as notified');
        System.assertEquals(Date.today(), breach.Individual_Notification_Date__c, 'Date should be today');
        System.assertEquals(100, breach.Individuals_Notified_Count__c, 'Count should be 100');
    }

    @isTest
    static void testRecordHHSNotification() {
        HIPAA_Breach__c breach = [
            SELECT Id FROM HIPAA_Breach__c
            WHERE Status__c = 'Open' AND HHS_Notified__c = false
            LIMIT 1
        ];

        Test.startTest();
        HIPAABreachNotificationService.recordHHSNotification(breach.Id, 'HHS-CONFIRM-123');
        Test.stopTest();

        breach = [
            SELECT HHS_Notified__c, HHS_Notification_Date__c, HHS_Confirmation_Number__c
            FROM HIPAA_Breach__c
            WHERE Id = :breach.Id
        ];
        System.assertEquals(true, breach.HHS_Notified__c, 'Should be marked as HHS notified');
        System.assertEquals(Date.today(), breach.HHS_Notification_Date__c, 'Date should be today');
        System.assertEquals('HHS-CONFIRM-123', breach.HHS_Confirmation_Number__c, 'Confirmation should match');
    }

    @isTest
    static void testGetNotificationTimeline() {
        HIPAA_Breach__c breach = [SELECT Id FROM HIPAA_Breach__c LIMIT 1];

        Test.startTest();
        List<HIPAABreachNotificationService.NotificationEvent> timeline =
            HIPAABreachNotificationService.getNotificationTimeline(breach.Id);
        Test.stopTest();

        System.assertNotEquals(null, timeline, 'Timeline should not be null');
        System.assert(timeline.size() >= 3, 'Should have at least 3 events');
    }

    @isTest
    static void testBulkBreachProcessing() {
        // Create bulk breaches
        List<HIPAA_Breach__c> bulkBreaches = new List<HIPAA_Breach__c>();
        for (Integer i = 0; i < 100; i++) {
            bulkBreaches.add(new HIPAA_Breach__c(
                Description__c = 'Bulk breach ' + i,
                Discovery_Date__c = Date.today().addDays(-i),
                Notification_Deadline__c = Date.today().addDays(60 - i),
                Records_Affected__c = i * 10,
                Breach_Type__c = 'Other',
                Status__c = 'Open',
                Notification_Required__c = true
            ));
        }
        insert bulkBreaches;

        HIPAABreachNotificationService service = new HIPAABreachNotificationService();

        Test.startTest();
        IBreachNotificationService.BreachSummary summary = service.getBreachSummary();
        Test.stopTest();

        System.assert(summary.totalBreaches >= 100, 'Should handle bulk breaches');
    }
}
