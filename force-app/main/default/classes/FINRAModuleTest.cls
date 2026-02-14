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

        insert as user items;
    }

    @IsTest
    static void testGetFrameworkName() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        String name = module.getFrameworkName();
        Test.stopTest();

        Assert.areEqual('FINRA', name, 'Framework name should be FINRA');
    }

    @IsTest
    static void testGetFrameworkVersion() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        String version = module.getFrameworkVersion();
        Test.stopTest();

        Assert.areEqual('2024', version, 'Framework version should be 2024');
    }

    @IsTest
    static void testGetControls() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        List<IComplianceModule.Control> controls = module.getControls();
        Test.stopTest();

        Assert.areNotEqual(null, controls, 'Controls list should not be null');
        Assert.isTrue(controls.size() > 0, 'Should have at least one control');

        Set<String> categories = new Set<String>();
        for (IComplianceModule.Control ctrl : controls) {
            categories.add(ctrl.category);
        }
        Assert.isTrue(categories.contains('Supervision'), 'Should include Supervision controls');
        Assert.isTrue(categories.contains('Records'), 'Should include Records controls');
        Assert.isTrue(categories.contains('BCP'), 'Should include BCP controls');
    }

    @IsTest
    static void testCalculateScore_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Decimal score = module.calculateScore(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null');
        Assert.isTrue(score >= 0, 'Score should be >= 0');
    }

    @IsTest
    static void testCalculateScore_NullAuditPackageId() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Decimal score = module.calculateScore(null);
        Test.stopTest();

        Assert.areEqual(0, score, 'Score should be 0 for null audit package');
    }

    @IsTest
    static void testIdentifyGaps_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');
        for (IComplianceModule.Gap gap : gaps) {
            Assert.isTrue(gap.id.startsWith('GAP-FINRA-'), 'Gap ID should start with GAP-FINRA-');
            Assert.areNotEqual(null, gap.recommendation, 'Gap recommendation should not be null');
        }
    }

    @IsTest
    static void testGenerateReport() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'FINRA' LIMIT 1];
        FINRAModule module = new FINRAModule();

        Test.startTest();
        Blob report = module.generateReport(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, report, 'Report should not be null');
        Assert.areEqual('FINRA Report', report.toString(), 'Should return test report content');
    }

    @IsTest
    static void testGetControlById_Valid() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('3110(a)');
        Test.stopTest();

        Assert.areNotEqual(null, ctrl, 'Should find Supervisory System control');
        Assert.areEqual('3110(a)', ctrl.code, 'Control code should match');
    }

    @IsTest
    static void testGetControlById_Invalid() {
        FINRAModule module = new FINRAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('NONEXISTENT');
        Test.stopTest();

        Assert.areEqual(null, ctrl, 'Should return null for nonexistent control');
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

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('3110(a)', result.controlId, 'Control ID should match');
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

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('3110(d)', result.controlId, 'Control ID should match');
        Assert.areEqual(75, result.score, 'Score should be 75');
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

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.isTrue(result.passed, 'Record keeping should pass');
        Assert.areEqual(90, result.score, 'Score should be 90');
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

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('4370(a)', result.controlId, 'Control ID should match');
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

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual(70, result.score, 'Default score should be 70');
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
            Assert.areNotEqual(null, result, 'Result should not be null for: ' + ctrl.code);
        }
        Test.stopTest();
    }
}
