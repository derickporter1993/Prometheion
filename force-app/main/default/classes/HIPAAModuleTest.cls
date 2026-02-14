/**
 * @description Test class for HIPAAModule
 * Covers all IComplianceModule interface methods and internal evaluation logic
 * for HIPAA 164.308 (Administrative), 164.310 (Physical), 164.312 (Technical) safeguards
 * @group Tests
 * @author Elaro Team
 */
@IsTest
private class HIPAAModuleTest {

    @TestSetup
    static void setupTestData() {
        // Create audit package for HIPAA
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('HIPAA');

        // Create evidence items of various types to exercise evaluation branches
        List<Elaro_Evidence_Item__c> items = new List<Elaro_Evidence_Item__c>();

        // Access control evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'PermissionSet',
            Evidence_Date__c = Date.today(),
            Description__c = 'Permission set access review evidence',
            Status__c = 'COLLECTED'
        ));
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'AccessReview',
            Evidence_Date__c = Date.today(),
            Description__c = 'Quarterly access review documentation',
            Status__c = 'REVIEWED'
        ));

        // Incident evidence
        items.add(new Elaro_Evidence_Item__c(
            Audit_Package__c = pkg.Id,
            Evidence_Type__c = 'SecurityIncident',
            Evidence_Date__c = Date.today(),
            Description__c = 'Security incident response documentation',
            Status__c = 'COLLECTED'
        ));

        // Generic evidence items for general evaluation branches
        for (Integer i = 0; i < 10; i++) {
            items.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'Login',
                Evidence_Date__c = Date.today().addDays(-i),
                Description__c = 'General evidence item ' + i,
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
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        String name = module.getFrameworkName();
        Test.stopTest();

        Assert.areEqual('HIPAA', name, 'Framework name should be HIPAA');
    }

    @IsTest
    static void testGetFrameworkVersion() {
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        String version = module.getFrameworkVersion();
        Test.stopTest();

        Assert.areEqual('2013', version, 'Framework version should be 2013');
    }

    @IsTest
    static void testGetControls() {
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        List<IComplianceModule.Control> controls = module.getControls();
        Test.stopTest();

        Assert.areNotEqual(null, controls, 'Controls list should not be null');
        Assert.isTrue(controls.size() > 0, 'Should have at least one control');

        // Verify controls cover Administrative, Physical, and Technical safeguards
        Set<String> categories = new Set<String>();
        for (IComplianceModule.Control ctrl : controls) {
            categories.add(ctrl.category);
            Assert.areNotEqual(null, ctrl.code, 'Control code should not be null');
            Assert.areNotEqual(null, ctrl.name, 'Control name should not be null');
            Assert.areNotEqual(null, ctrl.severity, 'Control severity should not be null');
        }
        Assert.isTrue(categories.contains('Administrative'), 'Should include Administrative safeguards');
        Assert.isTrue(categories.contains('Physical'), 'Should include Physical safeguards');
        Assert.isTrue(categories.contains('Technical'), 'Should include Technical safeguards');
    }

    // =============================================
    // CALCULATE SCORE
    // =============================================

    @IsTest
    static void testCalculateScore_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        Decimal score = module.calculateScore(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null');
        Assert.isTrue(score >= 0, 'Score should be >= 0');
    }

    @IsTest
    static void testCalculateScore_NullAuditPackageId() {
        HIPAAModule module = new HIPAAModule();

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
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');

        // Verify gap structure
        for (IComplianceModule.Gap gap : gaps) {
            Assert.areNotEqual(null, gap.id, 'Gap id should not be null');
            Assert.areNotEqual(null, gap.controlCode, 'Gap controlCode should not be null');
            Assert.areNotEqual(null, gap.severity, 'Gap severity should not be null');
            Assert.areNotEqual(null, gap.recommendation, 'Gap recommendation should not be null');
        }
    }

    // =============================================
    // GENERATE REPORT
    // =============================================

    @IsTest
    static void testGenerateReport() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        Blob report = module.generateReport(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, report, 'Report should not be null');
        // In test context, it returns a mock blob
        Assert.areEqual('HIPAA Compliance Report', report.toString(), 'Should return test report content');
    }

    // =============================================
    // GET CONTROL BY ID
    // =============================================

    @IsTest
    static void testGetControlById_Valid() {
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('164.312(a)');
        Test.stopTest();

        Assert.areNotEqual(null, ctrl, 'Should find Access Control control');
        Assert.areEqual('164.312(a)', ctrl.code, 'Control code should match');
        Assert.areEqual('Access Control', ctrl.name, 'Control name should match');
    }

    @IsTest
    static void testGetControlById_Invalid() {
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('NONEXISTENT');
        Test.stopTest();

        Assert.areEqual(null, ctrl, 'Should return null for nonexistent control');
    }

    @IsTest
    static void testGetControlById_AllControls() {
        HIPAAModule module = new HIPAAModule();
        List<IComplianceModule.Control> controls = module.getControls();

        Test.startTest();
        for (IComplianceModule.Control ctrl : controls) {
            IComplianceModule.Control found = module.getControlById(ctrl.code);
            Assert.areNotEqual(null, found, 'Should find control by code: ' + ctrl.code);
        }
        Test.stopTest();
    }

    // =============================================
    // EVALUATE CONTROL - SPECIFIC CONTROLS
    // =============================================

    @IsTest
    static void testEvaluateControl_AccessControl() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.312(a)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.312(a)', result.controlId, 'Control ID should match');
        Assert.areNotEqual(null, result.status, 'Status should not be null');
        Assert.areNotEqual(null, result.finding, 'Finding should not be null');
        Assert.isTrue(result.score >= 0 && result.score <= 100, 'Score should be between 0 and 100');
    }

    @IsTest
    static void testEvaluateControl_AuditControls() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.312(b)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.312(b)', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_Authentication() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.312(d)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.312(d)', result.controlId, 'Control ID should match');
        Assert.isTrue(result.passed, 'Authentication control should pass by default');
        Assert.areEqual(85, result.score, 'Score should be 85');
    }

    @IsTest
    static void testEvaluateControl_TransmissionSecurity() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.312(e)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.312(e)', result.controlId, 'Control ID should match');
        Assert.isTrue(result.passed, 'Transmission security should pass (TLS enforced)');
        Assert.areEqual(100, result.score, 'Score should be 100');
        Assert.areEqual('COMPLIANT', result.status, 'Status should be COMPLIANT');
    }

    @IsTest
    static void testEvaluateControl_IncidentProcedures() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.308(a)(6)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.308(a)(6)', result.controlId, 'Control ID should match');
        Assert.isTrue(result.passed, 'Incident procedures should pass');
    }

    @IsTest
    static void testEvaluateControl_DefaultEvaluation() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();

        // Test a control that falls into the 'else' branch (e.g., 164.308(a)(2))
        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            '164.308(a)(2)',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('164.308(a)(2)', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_AllControlTypes() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'HIPAA' LIMIT 1];
        HIPAAModule module = new HIPAAModule();
        List<IComplianceModule.Control> controls = module.getControls();

        Test.startTest();
        for (IComplianceModule.Control ctrl : controls) {
            IComplianceModule.ControlResult result = module.evaluateControl(
                ctrl.code,
                new Map<String, Object>{ 'auditPackageId' => pkg.Id }
            );
            Assert.areNotEqual(null, result, 'Result should not be null for: ' + ctrl.code);
            Assert.areNotEqual(null, result.controlId, 'Control ID should be set for: ' + ctrl.code);
        }
        Test.stopTest();
    }

    // =============================================
    // IDENTIFY GAPS - WITHOUT EVIDENCE
    // =============================================

    @IsTest
    static void testIdentifyGaps_NoEvidence() {
        // Create a clean audit package with no evidence
        Elaro_Audit_Package__c cleanPkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Clean HIPAA Package',
            Framework__c = 'HIPAA',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user cleanPkg;

        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(cleanPkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');
        // Without evidence, more gaps should be identified
        Assert.isTrue(gaps.size() > 0, 'Should identify gaps when no evidence is present');

        // Verify gap properties
        for (IComplianceModule.Gap gap : gaps) {
            Assert.isTrue(gap.id.startsWith('GAP-'), 'Gap ID should start with GAP-');
            Assert.areNotEqual(null, gap.description, 'Gap description should not be null');
            Assert.areNotEqual(null, gap.riskScore, 'Gap risk score should not be null');
        }
    }

    // =============================================
    // CALCULATE SCORE - VARIATIONS
    // =============================================

    @IsTest
    static void testCalculateScore_NoEvidence() {
        Elaro_Audit_Package__c cleanPkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Empty HIPAA Package',
            Framework__c = 'HIPAA',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user cleanPkg;

        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        Decimal score = module.calculateScore(cleanPkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null even without evidence');
        Assert.isTrue(score >= 0, 'Score should be non-negative');
    }

    // =============================================
    // BULK OPERATIONS
    // =============================================

    @IsTest
    static void testBulkEvaluateControls() {
        // Create multiple audit packages to simulate bulk evaluation
        List<Elaro_Audit_Package__c> packages = new List<Elaro_Audit_Package__c>();
        for (Integer i = 0; i < 5; i++) {
            packages.add(new Elaro_Audit_Package__c(
                Package_Name__c = 'Bulk HIPAA Package ' + i,
                Framework__c = 'HIPAA',
                Status__c = 'DRAFT',
                Audit_Period_Start__c = Date.today().addDays(-30),
                Audit_Period_End__c = Date.today()
            ));
        }
        insert as user packages;

        HIPAAModule module = new HIPAAModule();

        Test.startTest();
        for (Elaro_Audit_Package__c pkg : packages) {
            Decimal score = module.calculateScore(pkg.Id);
            Assert.isTrue(score >= 0, 'Score should be non-negative for package: ' + pkg.Id);

            List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
            Assert.areNotEqual(null, gaps, 'Gaps should not be null for package: ' + pkg.Id);
        }
        Test.stopTest();
    }
}
