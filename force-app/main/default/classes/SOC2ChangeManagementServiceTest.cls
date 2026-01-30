/**
 * SOC2ChangeManagementServiceTest
 *
 * Test class for SOC2ChangeManagementService
 *
 * @author Elaro
 * @version 1.0
 */
@isTest
public class SOC2ChangeManagementServiceTest {

    @TestSetup
    static void setup() {
        // Create test metadata change records
        List<Metadata_Change__c> changes = new List<Metadata_Change__c>();
        for (Integer i = 0; i < 10; i++) {
            changes.add(new Metadata_Change__c(
                Entity_Type__c = 'PermissionSet',
                Entity_Name__c = 'TestPermSet_' + i,
                Change_Type__c = 'Modified',
                Changed_By__c = UserInfo.getUserId(),
                Changed_Date__c = DateTime.now().addDays(-i),
                Risk_Score__c = i < 3 ? 8.0 : 4.0,
                Ticket_Reference__c = i < 5 ? 'JIRA-' + i : null
            ));
        }
        insert changes;
    }

    @isTest
    static void testGetFrameworkName() {
        SOC2ChangeManagementService service = new SOC2ChangeManagementService();

        Test.startTest();
        String frameworkName = service.getFrameworkName();
        Test.stopTest();

        System.assertEquals('SOC2', frameworkName, 'Framework name should be SOC2');
    }

    @isTest
    static void testEvaluateChangeControls() {
        Test.startTest();
        SOC2ChangeManagementService.ChangeControlResult result =
            SOC2ChangeManagementService.evaluateChangeControls();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertNotEquals(null, result.evaluationDate, 'Evaluation date should be set');
        System.assertNotEquals(null, result.controlResults, 'Control results should not be null');
        System.assert(result.controlResults.size() > 0, 'Should have control results');
    }

    @isTest
    static void testGetUnauthorizedChanges() {
        Test.startTest();
        List<SOC2ChangeManagementService.UnauthorizedChange> changes =
            SOC2ChangeManagementService.getUnauthorizedChanges(30);
        Test.stopTest();

        System.assertNotEquals(null, changes, 'Changes list should not be null');
        System.assert(changes.size() > 0, 'Should find unauthorized changes from test data');
    }

    @isTest
    static void testGetUnauthorizedChangesDefaultDays() {
        Test.startTest();
        List<SOC2ChangeManagementService.UnauthorizedChange> changes =
            SOC2ChangeManagementService.getUnauthorizedChanges(null);
        Test.stopTest();

        System.assertNotEquals(null, changes, 'Changes list should not be null with null days');
    }

    @isTest
    static void testLinkChangeToTicket() {
        Metadata_Change__c change = [
            SELECT Id, Ticket_Reference__c
            FROM Metadata_Change__c
            WHERE Ticket_Reference__c = null
            LIMIT 1
        ];

        Test.startTest();
        SOC2ChangeManagementService.linkChangeToTicket(change.Id, 'JIRA-999');
        Test.stopTest();

        change = [SELECT Ticket_Reference__c FROM Metadata_Change__c WHERE Id = :change.Id];
        System.assertEquals('JIRA-999', change.Ticket_Reference__c, 'Ticket should be linked');
    }

    @isTest
    static void testLinkChangeToTicketBlankTicket() {
        Metadata_Change__c change = [SELECT Id FROM Metadata_Change__c LIMIT 1];

        Test.startTest();
        try {
            SOC2ChangeManagementService.linkChangeToTicket(change.Id, '');
            System.assert(false, 'Should have thrown exception');
        } catch (ComplianceServiceBase.ComplianceServiceException e) {
            System.assert(e.getMessage().contains('blank'), 'Should mention blank ticket');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetChangesRequiringApproval() {
        Test.startTest();
        List<Metadata_Change__c> changes = SOC2ChangeManagementService.getChangesRequiringApproval();
        Test.stopTest();

        System.assertNotEquals(null, changes, 'Changes list should not be null');
    }

    @isTest
    static void testGenerateChangeReport() {
        Test.startTest();
        Id docId = SOC2ChangeManagementService.generateChangeReport(
            Date.today().addDays(-30),
            Date.today()
        );
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should not be null');

        // Verify document was created
        ContentDocument doc = [SELECT Title FROM ContentDocument WHERE Id = :docId];
        System.assert(doc.Title.contains('SOC2_Change_Report'), 'Title should contain SOC2_Change_Report');
    }

    @isTest
    static void testGenerateChangeReportDefaultDates() {
        Test.startTest();
        Id docId = SOC2ChangeManagementService.generateChangeReport(null, null);
        Test.stopTest();

        System.assertNotEquals(null, docId, 'Document ID should not be null with default dates');
    }

    @isTest
    static void testGetViolations() {
        SOC2ChangeManagementService service = new SOC2ChangeManagementService();

        Test.startTest();
        List<ComplianceServiceBase.Violation> violations = service.getViolations();
        Test.stopTest();

        System.assertNotEquals(null, violations, 'Violations should not be null');
    }

    @isTest
    static void testGetComplianceScore() {
        SOC2ChangeManagementService service = new SOC2ChangeManagementService();

        Test.startTest();
        Decimal score = service.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testBulkChangeEvaluation() {
        // Create bulk metadata changes
        List<Metadata_Change__c> bulkChanges = new List<Metadata_Change__c>();
        for (Integer i = 0; i < 200; i++) {
            bulkChanges.add(new Metadata_Change__c(
                Entity_Type__c = 'ApexClass',
                Entity_Name__c = 'TestClass_' + i,
                Change_Type__c = 'Created',
                Changed_By__c = UserInfo.getUserId(),
                Changed_Date__c = DateTime.now().addDays(-1),
                Risk_Score__c = 5.0
            ));
        }
        insert bulkChanges;

        Test.startTest();
        SOC2ChangeManagementService.ChangeControlResult result =
            SOC2ChangeManagementService.evaluateChangeControls();
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null for bulk test');
    }
}
