/**
 * Integration tests for {@link HealthCheckController} covering the full scan
 * orchestration, feature flag gating, and error handling.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see HealthCheckController
 */
@IsTest(testFor=HealthCheckController.class)
private class HealthCheckControllerTest {

    /**
     * Mock that handles both SecurityHealthCheck/Risks and SecuritySettings
     * Tooling API queries in a single test context.
     */
    private class FullScanMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String endpoint = req.getEndpoint();
            if (endpoint.contains('SecurityHealthCheckRisks')) {
                res.setBody('{"size":1,"totalSize":1,"done":true,"records":['
                    + '{"RiskType":"HIGH_RISK","Setting":"PasswordComplexity",'
                    + '"SettingGroup":"Password Policies",'
                    + '"OrgValue":"No restriction","StandardValue":"Must contain alpha and numeric"}'
                    + ']}');
            } else if (endpoint.contains('SecurityHealthCheck')) {
                res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{"Id":"0Aq000000000001","Score":72}]}');
            } else if (endpoint.contains('SecuritySettings')) {
                res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{'
                    + '"Id":"0DU000000000001","Metadata":{"sessionSettings":{'
                    + '"requireHttps":true,"lockSessionsToIp":true,'
                    + '"enableXssProtection":true,"enableClickjackNonsetupSFDC":true,'
                    + '"enableCspOnEmail":true,"sessionTimeout":"TWO_HOURS"'
                    + '}}}]}');
            } else {
                res.setBody('{"size":0,"totalSize":0,"done":true,"records":[]}');
            }
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"errorCode":"SERVER_ERROR","message":"test error"}');
            return res;
        }
    }

    @IsTest
    static void shouldRunFullScanSuccessfully() {
        Test.setMock(HttpCalloutMock.class, new FullScanMock());

        Test.startTest();
        HealthCheckResult result = HealthCheckController.runFullScan();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.overallScore >= 0 && result.overallScore <= 100,
            'Overall score should be between 0 and 100, got: ' + result.overallScore);
        Assert.isNotNull(result.findings, 'Findings should not be null');
        Assert.isNotNull(result.recommendations, 'Recommendations should not be null');
        Assert.isNotNull(result.scanTimestamp, 'Scan timestamp should be set');
        Assert.isNotNull(result.categoryScores, 'Category scores should not be null');

        Assert.isTrue(result.categoryScores.containsKey('SecurityHealthCheck'),
            'Should have SecurityHealthCheck category');
        Assert.isTrue(result.categoryScores.containsKey('MFA'),
            'Should have MFA category');
        Assert.isTrue(result.categoryScores.containsKey('Permissions'),
            'Should have Permissions category');
        Assert.isTrue(result.categoryScores.containsKey('Session'),
            'Should have Session category');
        Assert.isTrue(result.categoryScores.containsKey('AuditTrail'),
            'Should have AuditTrail category');
    }

    @IsTest
    static void shouldThrowWhenFeatureDisabled() {
        Health_Check_Feature_Flags__c flags = Health_Check_Feature_Flags__c.getOrgDefaults();
        flags.Health_Check_Enabled__c = false;
        upsert flags;

        Test.startTest();
        try {
            HealthCheckController.runFullScan();
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('disabled'),
                'Error should mention disabled: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldHandleToolingApiError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        try {
            HealthCheckController.runFullScan();
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Unable to complete')
                || e.getMessage().contains('Tooling API'),
                'Should have user-friendly error message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldReturnTimestamp() {
        Datetime before = Datetime.now();

        Test.startTest();
        Datetime result = HealthCheckController.getLastScanTimestamp();
        Test.stopTest();

        Datetime after = Datetime.now();
        Assert.isNotNull(result, 'Timestamp should not be null');
        Assert.isTrue(result >= before && result <= after,
            'Timestamp should be within test window');
    }
}
