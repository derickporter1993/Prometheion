/**
 * Test class for SOC2Module
 * Covers all IComplianceModule interface methods and internal evaluation logic
 * for SOC 2 Trust Service Criteria (CC6, CC7, CC8, CC9)
 * @group Tests
 * @author Elaro Team
 */
@IsTest(testFor=SOC2Module.class)
private class SOC2ModuleTest {

    @TestSetup
    static void setupTestData() {
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('SOC2');

        List<Elaro_Evidence_Item__c> items = new List<Elaro_Evidence_Item__c>();

        // Generic evidence items for evaluation branches
        for (Integer i = 0; i < 10; i++) {
            items.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = pkg.Id,
                Evidence_Type__c = 'Login',
                Evidence_Date__c = Date.today().addDays(-i),
                Description__c = 'SOC2 evidence item ' + i,
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
        SOC2Module module = new SOC2Module();

        Test.startTest();
        String name = module.getFrameworkName();
        Test.stopTest();

        Assert.areEqual('SOC2', name, 'Framework name should be SOC2');
    }

    @IsTest
    static void testGetFrameworkVersion() {
        SOC2Module module = new SOC2Module();

        Test.startTest();
        String version = module.getFrameworkVersion();
        Test.stopTest();

        Assert.areEqual('2017', version, 'Framework version should be 2017');
    }

    @IsTest
    static void testGetControls() {
        SOC2Module module = new SOC2Module();

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
            Assert.areNotEqual(null, ctrl.severity, 'Control severity should not be null');
        }
        Assert.isTrue(families.contains('CC6'), 'Should include CC6 (Logical/Physical Access)');
        Assert.isTrue(families.contains('CC7'), 'Should include CC7 (System Operations)');
    }

    // =============================================
    // CALCULATE SCORE
    // =============================================

    @IsTest
    static void testCalculateScore_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        Decimal score = module.calculateScore(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null');
        Assert.isTrue(score >= 0, 'Score should be >= 0');
    }

    @IsTest
    static void testCalculateScore_NullAuditPackageId() {
        SOC2Module module = new SOC2Module();

        Test.startTest();
        Decimal score = module.calculateScore(null);
        Test.stopTest();

        Assert.areEqual(0, score, 'Score should be 0 for null audit package');
    }

    @IsTest
    static void testCalculateScore_NoEvidence() {
        Elaro_Audit_Package__c cleanPkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Empty SOC2 Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user cleanPkg;

        SOC2Module module = new SOC2Module();

        Test.startTest();
        Decimal score = module.calculateScore(cleanPkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, score, 'Score should not be null even without evidence');
        Assert.isTrue(score >= 0, 'Score should be non-negative');
    }

    // =============================================
    // IDENTIFY GAPS
    // =============================================

    @IsTest
    static void testIdentifyGaps_WithAuditPackage() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');
        for (IComplianceModule.Gap gap : gaps) {
            Assert.isTrue(gap.id.startsWith('GAP-SOC2-'), 'Gap ID should start with GAP-SOC2-');
            Assert.areNotEqual(null, gap.controlCode, 'Gap controlCode should not be null');
            Assert.areNotEqual(null, gap.severity, 'Gap severity should not be null');
            Assert.areNotEqual(null, gap.recommendation, 'Gap recommendation should not be null');
        }
    }

    @IsTest
    static void testIdentifyGaps_NoEvidence() {
        Elaro_Audit_Package__c cleanPkg = new Elaro_Audit_Package__c(
            Package_Name__c = 'Clean SOC2 Package',
            Framework__c = 'SOC2',
            Status__c = 'DRAFT',
            Audit_Period_Start__c = Date.today().addDays(-30),
            Audit_Period_End__c = Date.today()
        );
        insert as user cleanPkg;

        SOC2Module module = new SOC2Module();

        Test.startTest();
        List<IComplianceModule.Gap> gaps = module.identifyGaps(cleanPkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, gaps, 'Gaps list should not be null');
        Assert.isTrue(gaps.size() > 0, 'Should identify gaps when no evidence present');
    }

    // =============================================
    // GENERATE REPORT
    // =============================================

    @IsTest
    static void testGenerateReport() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        Blob report = module.generateReport(pkg.Id);
        Test.stopTest();

        Assert.areNotEqual(null, report, 'Report should not be null');
        Assert.areEqual('SOC2 Report', report.toString(), 'Should return test report content');
    }

    // =============================================
    // GET CONTROL BY ID
    // =============================================

    @IsTest
    static void testGetControlById_Valid() {
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('CC6.1');
        Test.stopTest();

        Assert.areNotEqual(null, ctrl, 'Should find Logical Access Security control');
        Assert.areEqual('CC6.1', ctrl.code, 'Control code should match');
    }

    @IsTest
    static void testGetControlById_Invalid() {
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.Control ctrl = module.getControlById('NONEXISTENT');
        Test.stopTest();

        Assert.areEqual(null, ctrl, 'Should return null for nonexistent control');
    }

    @IsTest
    static void testGetControlById_AllControls() {
        SOC2Module module = new SOC2Module();
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
    static void testEvaluateControl_LogicalAccess() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'CC6.1',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('CC6.1', result.controlId, 'Control ID should match');
        Assert.areNotEqual(null, result.status, 'Status should not be null');
        Assert.areNotEqual(null, result.finding, 'Finding should not be null');
    }

    @IsTest
    static void testEvaluateControl_SystemMonitoring() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'CC7.2',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('CC7.2', result.controlId, 'Control ID should match');
    }

    @IsTest
    static void testEvaluateControl_IncidentResponse() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'CC7.4',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('CC7.4', result.controlId, 'Control ID should match');
        Assert.isTrue(result.passed, 'Incident response should pass');
        Assert.areEqual(80, result.score, 'Score should be 80');
    }

    @IsTest
    static void testEvaluateControl_ChangeManagement() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'CC8.1',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('CC8.1', result.controlId, 'Control ID should match');
        Assert.isTrue(result.passed, 'Change management should pass');
        Assert.areEqual(90, result.score, 'Score should be 90');
    }

    @IsTest
    static void testEvaluateControl_DefaultEvaluation() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();

        Test.startTest();
        IComplianceModule.ControlResult result = module.evaluateControl(
            'CC6.2',
            new Map<String, Object>{ 'auditPackageId' => pkg.Id }
        );
        Test.stopTest();

        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.areEqual('CC6.2', result.controlId, 'Control ID should match');
        Assert.areEqual(75, result.score, 'Default score should be 75');
    }

    @IsTest
    static void testEvaluateControl_AllControlTypes() {
        Elaro_Audit_Package__c pkg = [SELECT Id FROM Elaro_Audit_Package__c WHERE Framework__c = 'SOC2' LIMIT 1];
        SOC2Module module = new SOC2Module();
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
    // BULK OPERATIONS
    // =============================================

    @IsTest
    static void testBulkEvaluateControls() {
        List<Elaro_Audit_Package__c> packages = new List<Elaro_Audit_Package__c>();
        for (Integer i = 0; i < 5; i++) {
            packages.add(new Elaro_Audit_Package__c(
                Package_Name__c = 'Bulk SOC2 Package ' + i,
                Framework__c = 'SOC2',
                Status__c = 'DRAFT',
                Audit_Period_Start__c = Date.today().addDays(-30),
                Audit_Period_End__c = Date.today()
            ));
        }
        insert as user packages;

        SOC2Module module = new SOC2Module();

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
