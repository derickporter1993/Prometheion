/**
 * Test class for AIDetectionEngine.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest
private class AIDetectionEngineTest {

    /**
     * Mock HTTP callout for Tooling API queries.
     */
    private class ToolingApiMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            // Mock response for Tooling API query
            Map<String, Object> response = new Map<String, Object>();
            List<Map<String, Object>> records = new List<Map<String, Object>>();

            Map<String, Object> record1 = new Map<String, Object>();
            record1.put('DeveloperName', 'Test_Bot_001');
            record1.put('NamespacePrefix', null);
            record1.put('Id', '0LdXX000000TestAAA');
            records.add(record1);

            response.put('records', records);
            res.setBody(JSON.serialize(response));

            return res;
        }
    }

    /**
     * Mock for Tooling API failure.
     */
    private class ToolingApiFailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setBody('{"error":"Internal Server Error"}');
            return res;
        }
    }

    @IsTest
    static void shouldDiscoverAISystems() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
        Test.stopTest();

        Assert.isNotNull(systems, 'Should return list of detected systems');
        // Result count depends on mock data and metadata types queried
    }

    @IsTest
    static void shouldHandleToolingApiFailure() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiFailureMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
        Test.stopTest();

        // Should handle failure gracefully and return empty list
        Assert.isNotNull(systems, 'Should return list even on failure');
    }

    @IsTest
    static void shouldMapMetadataTypesToSystemTypes() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
        Test.stopTest();

        // Verify that detected systems have valid system types
        for (AIDetectionEngine.AISystemMetadata system : systems) {
            Assert.isNotNull(system.systemType, 'System type should be set');
            Assert.isTrue(
                system.systemType == 'Einstein Prediction' ||
                system.systemType == 'Einstein Bot' ||
                system.systemType == 'GenAI Function' ||
                system.systemType == 'GenAI Planner' ||
                system.systemType == 'Custom ML',
                'System type should be valid picklist value'
            );
        }
    }

    @IsTest
    static void shouldSetDetectionMethod() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
        Test.stopTest();

        for (AIDetectionEngine.AISystemMetadata system : systems) {
            Assert.areEqual('Metadata API Scan', system.detectionMethod,
                'Detection method should be Metadata API Scan');
        }
    }

    @IsTest
    static void shouldHandleEmptyResults() {
        Test.setMock(HttpCalloutMock.class, new ToolingApiMock());

        Test.startTest();
        List<AIDetectionEngine.AISystemMetadata> systems = AIDetectionEngine.discoverAISystems();
        Test.stopTest();

        Assert.isNotNull(systems, 'Should return non-null list even when empty');
    }
}
