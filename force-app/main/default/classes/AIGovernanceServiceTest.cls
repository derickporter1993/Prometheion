/**
 * Test class for AIGovernanceService.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest
private class AIGovernanceServiceTest {

    @TestSetup
    static void makeData() {
        // Create test AI system registrations
        List<AI_System_Registry__c> systems = new List<AI_System_Registry__c>();

        AI_System_Registry__c system1 = new AI_System_Registry__c();
        system1.Name = 'Test Einstein Prediction';
        system1.System_Type__c = 'Einstein Prediction';
        system1.Detection_Method__c = 'Metadata API Scan';
        system1.Risk_Level__c = 'High';
        system1.Status__c = 'Active';
        system1.Use_Case_Description__c = 'Test prediction system';
        systems.add(system1);

        AI_System_Registry__c system2 = new AI_System_Registry__c();
        system2.Name = 'Test Einstein Bot';
        system2.System_Type__c = 'Einstein Bot';
        system2.Detection_Method__c = 'License Detection';
        system2.Risk_Level__c = 'Limited';
        system2.Status__c = 'Active';
        system2.Use_Case_Description__c = 'Customer service bot';
        systems.add(system2);

        insert as user systems;
    }

    @IsTest
    static void shouldReturnFrameworkName() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        String name = service.getFrameworkName();
        Test.stopTest();

        Assert.areEqual('AI Governance', name, 'Framework name should be AI Governance');
    }

    @IsTest
    static void shouldReturnFrameworkVersion() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        String version = service.getFrameworkVersion();
        Test.stopTest();

        Assert.isTrue(version.contains('EU AI Act'), 'Version should reference EU AI Act');
        Assert.isTrue(version.contains('NIST AI RMF'), 'Version should reference NIST AI RMF');
    }

    @IsTest
    static void shouldReturnControls() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        List<IComplianceModule.Control> controls = service.getControls();
        Test.stopTest();

        Assert.isTrue(controls.size() > 0, 'Should return multiple controls');

        Boolean hasEUControls = false;
        Boolean hasRMFControls = false;

        for (IComplianceModule.Control ctrl : controls) {
            if (ctrl.category == 'EU AI Act') {
                hasEUControls = true;
            }
            if (ctrl.category == 'NIST AI RMF') {
                hasRMFControls = true;
            }
        }

        Assert.isTrue(hasEUControls, 'Should include EU AI Act controls');
        Assert.isTrue(hasRMFControls, 'Should include NIST AI RMF controls');
    }

    @IsTest
    static void shouldCalculateComplianceScore() {
        AIGovernanceService service = new AIGovernanceService();

        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        Decimal score = service.calculateScore(null);
        Test.stopTest();

        Assert.isTrue(score >= 0 && score <= 100, 'Score should be between 0 and 100');
    }

    @IsTest
    static void shouldIdentifyGaps() {
        AIGovernanceService service = new AIGovernanceService();

        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<IComplianceModule.Gap> gaps = service.identifyGaps(null);
        Test.stopTest();

        Assert.isNotNull(gaps, 'Should return list of gaps');
    }

    @IsTest
    static void shouldGenerateReport() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        Blob reportBlob = service.generateReport(null);
        Test.stopTest();

        Assert.isNotNull(reportBlob, 'Should generate report');
        String reportContent = reportBlob.toString();
        Assert.isTrue(reportContent.contains('AI Governance'), 'Report should contain framework name');
    }

    @IsTest
    static void shouldGetControlById() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        IComplianceModule.Control ctrl = service.getControlById('AI-001');
        Test.stopTest();

        Assert.isNotNull(ctrl, 'Should return control AI-001');
        Assert.areEqual('AI-001', ctrl.id, 'Control ID should match');
    }

    @IsTest
    static void shouldReturnNullForInvalidControlId() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        IComplianceModule.Control ctrl = service.getControlById('INVALID-999');
        Test.stopTest();

        Assert.isNull(ctrl, 'Should return null for invalid control ID');
    }

    @IsTest
    static void shouldEvaluateRegistryControl() {
        AIGovernanceService service = new AIGovernanceService();

        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        IComplianceModule.ControlResult result = service.evaluateControl('AI-001', new Map<String, Object>());
        Test.stopTest();

        Assert.isNotNull(result, 'Should return control result');
        Assert.areEqual('AI-001', result.controlId, 'Control ID should match');
        Assert.isNotNull(result.status, 'Status should be set');
    }

    @IsTest
    static void shouldEvaluateClassificationControl() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        IComplianceModule.ControlResult result = service.evaluateControl('AI-002', new Map<String, Object>());
        Test.stopTest();

        Assert.isNotNull(result, 'Should return control result');
        Assert.areEqual('AI-002', result.controlId, 'Control ID should match');
        Assert.isTrue(result.score >= 0 && result.score <= 100, 'Score should be valid');
    }

    @IsTest
    static void shouldHandleUnknownControlEvaluation() {
        AIGovernanceService service = new AIGovernanceService();

        Test.startTest();
        IComplianceModule.ControlResult result = service.evaluateControl('UNKNOWN-999', new Map<String, Object>());
        Test.stopTest();

        Assert.areEqual('NOT_APPLICABLE', result.status, 'Unknown control should be not applicable');
    }

    /**
     * Mock HTTP callout for Tooling API.
     */
    private class ToolingApiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            Map<String, Object> response = new Map<String, Object>();
            response.put('records', new List<Map<String, Object>>());
            res.setBody(JSON.serialize(response));

            return res;
        }
    }
}
