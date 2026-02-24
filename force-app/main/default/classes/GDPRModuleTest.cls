/**
 * Test class for GDPRModule
 * Covers all IComplianceModule interface methods and internal evaluation logic
 * for GDPR Articles 5-37 including DSR, ROPA, and Breach Notification
 * @group Tests
 * @author Elaro Team
 */
@IsTest(testFor=GDPRModule.class)
private class GDPRModuleTest {

    @TestSetup
    static void setupTestData() {
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('GDPR');

        List<Elaro_Evidence_Item__c> items = new List<Elaro_Evidence_Item__c>();

        // DSR / Erasure evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'DSR',
            Evidence_Date__c = Date.today(),
            Description__c = 'Data subject access request handled',
            Status__c = 'COLLECTED'
        ));
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'Erasure',
            Evidence_Date__c = Date.today(),
            Description__c = 'Data deletion request completed',
            Status__c = 'COLLECTED'
        ));

        // ROPA evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'ROPA',
            Evidence_Date__c = Date.today(),
            Description__c = 'Record of processing activities maintained',
            Status__c = 'REVIEWED'
        ));

        // Breach procedure evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'BreachProcedure',
            Evidence_Date__c = Date.today(),
            Description__c = 'Breach notification procedure documented',
            Status__c = 'COLLECTED'
        ));

        // Generic evidence items
        for (Integer i = 0; i < 8; i++) {
            items.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'Login',
                Evidence_Date__c = Date.today().addDays(-i),
                Description__c = 'General GDPR evidence item ' + i,
                Status__c = 'COLLECTED'
            ));
        }

        insert as user items;
    }

    // =============================================
    // BASIC INTERFACE METHODS
    // =============================================

    @IsTest
    static void testGetFrameworkName() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        String name = module.getFrameworkName();
        Test.stopTest();

        Assert.areEqual('GDPR', name, 'Framework name should be GDPR');
    }

    @IsTest
    static void testGetFrameworkVersion() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        String version = module.getFrameworkVersion();
        Test.stopTest();

        Assert.areEqual('2018', version, 'Framework version should be 2018');
    }

    @IsTest
    static void testGetControls() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        List<IComplianceModule.Control> controls = module.getControls();
        Test.stopTest();

        Assert.areNotEqual(null, controls, 'Controls list should not be null');
        Assert.isTrue(controls.size() > 0, 'Should have at least one control');

        Set<String> families = new Set<String>();
        for (IComplianceModule.Control ctrl : controls) {
            families.add(ctrl.family);
            Assert.areNotEqual(null, ctrl.code, 'Control code should not be null');
            Assert.areNotEqual(null, ctrl.name, 'Control name should not be null');
        }
        Assert.isTrue(families.size() > 1, 'Should cover multiple GDPR families');
    }

    // =============================================
    // CALCULATE SCORE
    // =============================================

    @IsTest
    static void testCalculateScore_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        Decimal score = module.calculateScore(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null');
        Assert.isTrue(score >= 0, 'Score should be >= 0');
    }

    @IsTest
    static void testCalculateScore_NullAuditPackageId() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        Decimal score = module.calculateScore(null);
        Test.stopTest();

        Assert.areEqual(0, score, 'Score should be 0 for null audit package');
    }

    // =============================================
    // IDENTIFY GAPS
    // =============================================

    @IsTest
    static void testIdentifyGaps_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');
        for (IComplianceModule.Gap gap : gaps) {
            Assert.isTrue(gap.id.startsWith('GAP-GDPR-'), 'Gap ID should start with GAP-GDPR-');
            Assert.areNotEqual(null, gap.controlCode, 'Gap controlCode should not be null');
            Assert.areNotEqual(null, gap.recommendation, 'Gap recommendation should not be null');
        }
    }

    // =============================================
    // GENERATE REPORT
    // =============================================

    @IsTest
    static void testGenerateReport() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        Blob report = module.generateReport(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, report, 'Report should not be null');
        Assert.areEqual('GDPR Report', report.toString(), 'Should return test report content');
    }

    // =============================================
    // GET CONTROL BY ID
    // =============================================

    @IsTest
    static void testGetControlById_Valid() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('Art.17');
        Test.stopTest();

        Assert.areNotEqual(null, ctrl, 'Should find Right to Erasure control');
        Assert.areEqual('Art.17', ctrl.code, 'Control code should match');
    }

    @IsTest
    static void testGetControlById_Invalid() {
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('NONEXISTENT');
        Test.stopTest();

        Assert.areEqual(null, ctrl, 'Should return null for nonexistent control');
    }

    // =============================================
    // EVALUATE CONTROL - SPECIFIC CONTROLS
    // =============================================

    @IsTest
    static void testEvaluateControl_RightToErasure() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'Art.17',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('Art.17', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_ROPA() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'Art.30',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('Art.30', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_SecurityMeasures() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'Art.32',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.isTrue(result.passed, 'Security measures should pass');
        Assert.areEqual(90, result.score, 'Score should be 90');
    }

    @IsTest
    static void testEvaluateControl_BreachNotification() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'Art.33',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('Art.33', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_DefaultEvaluation() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'Art.5',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('Art.5', result.controlId, 'Control ID should match');
        Assert.areEqual(70, result.score, 'Default evaluation score should be 70');
    }

    @IsTest
    static void testEvaluateControl_AllControlTypes() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'GDPR' LIMIT 1];
        GDPRModule module = new GDPRModule();
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
