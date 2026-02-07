/**
 * @description Test class for FINRAModule
 * Covers all IComplianceModule interface methods and internal evaluation logic
 * for FINRA Rules 3110 (Supervision), 4511 (Records), 4370 (BCP)
 * @group Tests
 * @author Elaro Team
 */
@IsTest
private class FINRAModuleTest {

    @TestSetup
    static void setupTestData() {
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('FINRA');

        List<Elaro_Evidence_Item__c> items = new List<Elaro_Evidence_Item__c>();

        // Supervision evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'Supervision',
            Evidence_Date__c = Date.today(),
            Description__c = 'Supervisory procedures review completed',
            Status__c = 'COLLECTED'
        ));

        // BCP evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'BCP',
            Evidence_Date__c = Date.today(),
            Description__c = 'Business continuity plan documented',
            Status__c = 'REVIEWED'
        ));

        // Generic evidence
        for (Integer i = 0; i < 8; i++) {
            items.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'Login',
                Evidence_Date__c = Date.today().addDays(-i),
                Description__c = 'General FINRA evidence item ' + i,
                Status__c = 'COLLECTED'
            ));
        }

        insert items;
    }

    @IsTest
    static void testGetFrameworkName() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        String name = module.getFrameworkName();
        Test.stopTest();

        System.assertEquals('FINRA', name, 'Framework name should be FINRA');
    }

    @IsTest
    static void testGetFrameworkVersion() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        String version = module.getFrameworkVersion();
        Test.stopTest();

        System.assertEquals('2024', version, 'Framework version should be 2024');
    }

    @IsTest
    static void testGetControls() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        List<IComplianceModule.Control> controls = module.getControls();
        Test.stopTest();

        System.assertNotEquals(null, controls, 'Controls list should not be null');
        System.assert(controls.size() > 0, 'Should have at least one control');

        Set<String> categories = new Set<String>();
        for (IComplianceModule.Control ctrl : controls) {
            categories.add(ctrl.category);
        }
        System.assert(categories.contains('Supervision'), 'Should include Supervision controls');
        System.assert(categories.contains('Records'), 'Should include Records controls');
        System.assert(categories.contains('BCP'), 'Should include BCP controls');
    }

    @IsTest
    static void testCalculateScore_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Decimal score = module.calculateScore(pkg.Id);
        Test.stopTest();

        System.assertNotEquals(null, score, 'Score should not be null');
        System.assert(score >= 0, 'Score should be >= 0');
    }

    @IsTest
    static void testCalculateScore_NullAuditPackageId() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Decimal score = module.calculateScore(null);
        Test.stopTest();

        System.assertEquals(0, score, 'Score should be 0 for null audit package');
    }

    @IsTest
    static void testIdentifyGaps_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
        Test.stopTest();

        System.assertNotEquals(null, gaps, 'Gaps list should not be null');
        for (IComplianceModule.Gap gap : gaps) {
            System.assert(gap.id.startsWith('GAP-FINRA-'), 'Gap ID should start with GAP-FINRA-');
            System.assertNotEquals(null, gap.recommendation, 'Gap recommendation should not be null');
        }
    }

    @IsTest
    static void testGenerateReport() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Blob report = module.generateReport(pkg.Id);
        Test.stopTest();

        System.assertNotEquals(null, report, 'Report should not be null');
        System.assertEquals('FINRA Report', report.toString(), 'Should return test report content');
    }

    @IsTest
    static void testGetControlById_Valid() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('3110(a)');
        Test.stopTest();

        System.assertNotEquals(null, ctrl, 'Should find Supervisory System control');
        System.assertEquals('3110(a)', ctrl.code, 'Control code should match');
    }

    @IsTest
    static void testGetControlById_Invalid() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('NONEXISTENT');
        Test.stopTest();

        System.assertEquals(null, ctrl, 'Should return null for nonexistent control');
    }

    @IsTest
    static void testEvaluateControl_Supervision() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '3110(a)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('3110(a)', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_CommunicationsReview() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '3110(d)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('3110(d)', result.controlId, 'Control ID should match');
        System.assertEquals(75, result.score, 'Score should be 75');
    }

    @IsTest
    static void testEvaluateControl_RecordKeeping() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '4511(a)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assert(result.passed, 'Record keeping should pass');
        System.assertEquals(90, result.score, 'Score should be 90');
    }

    @IsTest
    static void testEvaluateControl_BCP() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '4370(a)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals('4370(a)', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_DefaultEvaluation() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '3110(c)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        System.assertNotEquals(null, result, 'Result should not be null');
        System.assertEquals(70, result.score, 'Default score should be 70');
    }

    @IsTest
    static void testEvaluateControl_AllControlTypes() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();
        List<IComplianceModule.Control> controls = module.getControls();

        Test.startTest();
        for (IComplianceModule.Control ctrl : controls) {
            IComplianceModule.ControlResult result = module.evaluateControl(
                ctrl.code,
                new Map<String, Object>{ 'auditPackageId' => pkg.Id }
            );
            System.assertNotEquals(null, result, 'Result should not be null for: ' + ctrl.code);
        }
        Test.stopTest();
    }
}
