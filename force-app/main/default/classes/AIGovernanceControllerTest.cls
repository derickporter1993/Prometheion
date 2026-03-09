/**
 * Test class for AIGovernanceController.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest
private class AIGovernanceControllerTest {

    @TestSetup
    static void makeData() {
        AI_System_Registry__c system = new AI_System_Registry__c();
        system.Name = 'Test AI System';
        system.System_Type__c = 'Einstein Prediction';
        system.Detection_Method__c = 'Metadata API Scan';
        system.Risk_Level__c = 'High';
        system.Status__c = 'Active';
        system.Use_Case_Description__c = 'Test system for unit tests';
        insert as user system;
    }

    @IsTest
    static void shouldDiscoverAISystems() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIGovernanceController.discoverAISystems();
        Test.stopTest();

        Assert.isNotNull(systems, 'Should return list of discovered systems');
    }

    @IsTest
    static void shouldRegisterAISystem() {
        AIDetectionEngine.AISystemMetadata metadata = new AIDetectionEngine.AISystemMetadata();
        metadata.systemType = 'Einstein Bot';
        metadata.systemName = 'NewBot001';
        metadata.detectionMethod = 'Metadata API Scan';

        String metadataJson = JSON.serialize(metadata);

        Test.startTest();
        Id systemId = AIGovernanceController.registerAISystem(metadataJson, 'Customer support bot');
        Test.stopTest();

        Assert.isNotNull(systemId, 'Should return created system ID');

        AI_System_Registry__c created = [
            SELECT Id, Name, System_Type__c, Risk_Level__c
            FROM AI_System_Registry__c
            WHERE Id = :systemId
            WITH USER_MODE
        ];

        Assert.areEqual('NewBot001', created.Name, 'System name should match');
        Assert.areEqual('Einstein Bot', created.System_Type__c, 'System type should match');
        Assert.isNotNull(created.Risk_Level__c, 'Risk level should be set');
    }

    @IsTest
    static void shouldGetRegisteredSystems() {
        Test.startTest();
        List<AI_System_Registry__c> systems = AIGovernanceController.getRegisteredSystems();
        Test.stopTest();

        Assert.isTrue(systems.size() >= 1, 'Should return at least one system from test data');
    }

    @IsTest
    static void shouldGetGovernanceSummary() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        AIGovernanceController.DashboardSummary summary = AIGovernanceController.getGovernanceSummary();
        Test.stopTest();

        Assert.isNotNull(summary, 'Should return dashboard summary');
        Assert.isNotNull(summary.complianceScore, 'Should have compliance score');
        Assert.isNotNull(summary.gaps, 'Should have gaps list');
        Assert.isTrue(summary.totalSystems >= 0, 'Total systems should be non-negative');
    }

    @IsTest
    static void shouldRecordOversightDecision() {
        AI_System_Registry__c system = [SELECT Id FROM AI_System_Registry__c LIMIT 1];

        Test.startTest();
        Id oversightId = AIGovernanceController.recordOversightDecision(
            system.Id,
            'AI suggested: Approve loan application',
            'Reject',
            'Insufficient credit history'
        );
        Test.stopTest();

        Assert.isNotNull(oversightId, 'Should return created oversight record ID');

        AI_Human_Oversight_Record__c oversight = [
            SELECT Id, Human_Decision__c, Justification__c
            FROM AI_Human_Oversight_Record__c
            WHERE Id = :oversightId
            WITH USER_MODE
        ];

        Assert.areEqual('Reject', oversight.Human_Decision__c, 'Decision should match');
        Assert.areEqual('Insufficient credit history', oversight.Justification__c, 'Justification should match');
    }

    @IsTest
    static void shouldGetAIAuditTrail() {
        Test.startTest();
        List<AIAuditTrailScanner.AIAuditEntry> trail = AIGovernanceController.getAIAuditTrail(30);
        Test.stopTest();

        Assert.isNotNull(trail, 'Should return audit trail list');
    }

    @IsTest
    static void shouldGetAILicenses() {
        Test.startTest();
        List<AILicenseDetector.AILicenseAssignment> licenses = AIGovernanceController.getAILicenses();
        Test.stopTest();

        Assert.isNotNull(licenses, 'Should return license list');
    }

    @IsTest
    static void shouldUpdateRiskLevel() {
        AI_System_Registry__c system = [SELECT Id, Risk_Level__c FROM AI_System_Registry__c LIMIT 1];

        Test.startTest();
        AI_System_Registry__c updated = AIGovernanceController.updateRiskLevel(system.Id, 'Minimal');
        Test.stopTest();

        Assert.areEqual('Minimal', updated.Risk_Level__c, 'Risk level should be updated');
    }

    @IsTest
    static void shouldSuspendUnacceptableRiskSystems() {
        AI_System_Registry__c system = [SELECT Id FROM AI_System_Registry__c LIMIT 1];

        Test.startTest();
        AI_System_Registry__c updated = AIGovernanceController.updateRiskLevel(system.Id, 'Unacceptable');
        Test.stopTest();

        Assert.areEqual('Suspended', updated.Status__c, 'Unacceptable risk systems should be suspended');
    }

    @IsTest
    static void shouldHandleRegisterAISystemError() {
        String invalidJson = 'INVALID_JSON';

        try {
            Test.startTest();
            AIGovernanceController.registerAISystem(invalidJson, 'Test');
            Test.stopTest();
            Assert.fail('Should throw AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Failed to register'), 'Should have error message');
        }
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
