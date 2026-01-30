/**
 * @description Test class for ElaroPDFController
 * Tests Visualforce PDF controller for audit packages
 * @group Tests
 * @see ElaroPDFController
 */
@isTest
private class ElaroPDFControllerTest {

    @TestSetup
    static void setup() {
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'PDF Test Package',
            Framework__c = 'HIPAA',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert pkg;

        // Create evidence items with various types
        List<Elaro_Evidence_Item__c> items = new List<Elaro_Evidence_Item__c>();
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'LoginAs',
            Evidence_Date__c = Date.today(),
            Description__c = 'Critical impersonation event',
            Status__c = 'COLLECTED'
        ));
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'API',
            Evidence_Date__c = Date.today(),
            Description__c = 'High risk API access',
            Status__c = 'COLLECTED'
        ));
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'Login',
            Evidence_Date__c = Date.today(),
            Description__c = 'Standard login event',
            Status__c = 'COLLECTED'
        ));
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'Logout',
            Evidence_Date__c = Date.today(),
            Description__c = 'Low risk logout event',
            Status__c = 'COLLECTED'
        ));
        insert items;
    }

    @isTest
    static void testControllerInitialization() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);

        Test.startTest();
        ElaroPDFController controller = new ElaroPDFController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.auditPackage, 'Audit package should be loaded');
        System.assert(controller.evidenceCount > 0, 'Evidence should be loaded');
        System.assertNotEquals(null, controller.generatedAt, 'Generated timestamp should be set');
        System.assertNotEquals(null, controller.documentHash, 'Document hash should be generated');
    }

    @isTest
    static void testStatisticsCalculation() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);

        Test.startTest();
        ElaroPDFController controller = new ElaroPDFController(stdController);
        Test.stopTest();

        System.assertEquals(1, controller.criticalCount, 'Should have 1 critical event (LoginAs)');
        System.assertEquals(1, controller.highCount, 'Should have 1 high event (API)');
        System.assertEquals(1, controller.mediumCount, 'Should have 1 medium event (Login)');
        System.assertEquals(1, controller.lowCount, 'Should have 1 low event (Logout)');
    }

    @isTest
    static void testGetComplianceScore() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);
        ElaroPDFController controller = new ElaroPDFController(stdController);

        Test.startTest();
        Decimal score = controller.getComplianceScore();
        Test.stopTest();

        System.assert(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @isTest
    static void testGetDateRange() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);
        ElaroPDFController controller = new ElaroPDFController(stdController);

        Test.startTest();
        String dateRange = controller.getDateRange();
        Test.stopTest();

        System.assert(dateRange.contains(' - '), 'Date range should contain separator');
    }

    @isTest
    static void testGetRiskColorClass() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);
        ElaroPDFController controller = new ElaroPDFController(stdController);

        Test.startTest();
        System.assertEquals('risk-critical', controller.getRiskColorClass('CRITICAL'), 'Critical should map correctly');
        System.assertEquals('risk-high', controller.getRiskColorClass('HIGH'), 'High should map correctly');
        System.assertEquals('risk-medium', controller.getRiskColorClass('MEDIUM'), 'Medium should map correctly');
        System.assertEquals('risk-low', controller.getRiskColorClass('LOW'), 'Low should map correctly');
        System.assertEquals('risk-medium', controller.getRiskColorClass('UNKNOWN'), 'Unknown should default to medium');
        Test.stopTest();
    }

    @isTest
    static void testControlSummary() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];
        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);

        Test.startTest();
        ElaroPDFController controller = new ElaroPDFController(stdController);
        Test.stopTest();

        System.assert(controller.controlSummary.size() > 0, 'Control summary should be populated');
    }

    @isTest
    static void testControllerWithPageParameter() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c LIMIT 1];

        // Set page parameters
        PageReference pageRef = Page.ElaroAuditPackagePDF;
        pageRef.getParameters().put('id', pkg.Id);
        pageRef.getParameters().put('controls', 'Login,LoginAs');
        Test.setCurrentPage(pageRef);

        ApexPages.StandardController stdController = new ApexPages.StandardController(new Elaro_Audit_Package__c());

        Test.startTest();
        ElaroPDFController controller = new ElaroPDFController(stdController);
        Test.stopTest();

        System.assertNotEquals(null, controller.selectedControls, 'Selected controls should be set');
    }

    @isTest
    static void testControllerWithNullPackage() {
        ApexPages.StandardController stdController = new ApexPages.StandardController(new Elaro_Audit_Package__c());

        Test.startTest();
        ElaroPDFController controller = new ElaroPDFController(stdController);
        Test.stopTest();

        // Should handle gracefully without errors
        System.assert(true, 'Controller should handle null package');
    }

    @isTest
    static void testComplianceScoreNoEvidence() {
        Elaro_Audit_Package__c pkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Empty Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT'
        );
        insert pkg;

        ApexPages.StandardController stdController = new ApexPages.StandardController(pkg);
        ElaroPDFController controller = new ElaroPDFController(stdController);

        Test.startTest();
        Decimal score = controller.getComplianceScore();
        Test.stopTest();

        System.assertEquals(0, score, 'Score should be 0 with no evidence');
    }
}
