/**
 * Tests for {@link HealthCheckScanner} covering Tooling API response parsing,
 * risk type filtering, and empty result handling.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see HealthCheckScanner
 */
@IsTest(testFor=HealthCheckScanner.class)
private class HealthCheckScannerTest {

    private class HealthCheckMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);

            String query = req.getEndpoint();
            if (query.contains('SecurityHealthCheckRisks')) {
                res.setBody('{"size":3,"totalSize":3,"done":true,"records":['
                    + '{"RiskType":"HIGH_RISK","Setting":"PasswordComplexity","SettingGroup":"Password Policies","OrgValue":"No restriction","StandardValue":"Must contain alpha and numeric"},'
                    + '{"RiskType":"MEDIUM_RISK","Setting":"SessionTimeout","SettingGroup":"Session Settings","OrgValue":"24 Hours","StandardValue":"2 Hours"},'
                    + '{"RiskType":"INFORMATIONAL","Setting":"LoginIpRanges","SettingGroup":"Network Access","OrgValue":"Configured","StandardValue":"Configured"}'
                    + ']}');
            } else {
                res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{"Id":"0Aq000000000001","Score":65}]}');
            }
            return res;
        }
    }

    private class EmptyResultMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":0,"totalSize":0,"done":true,"records":[]}');
            return res;
        }
    }

    @IsTest
    static void shouldParseScoreAndFilterInformational() {
        Test.setMock(HttpCalloutMock.class, new HealthCheckMock());

        Test.startTest();
        HealthCheckScanner.ScanResult result = new HealthCheckScanner().scan();
        Test.stopTest();

        Assert.areEqual(65, result.nativeScore, 'Native score should be 65');
        Assert.areEqual(2, result.findings.size(),
            'Should have 2 findings (INFORMATIONAL filtered out)');

        ScanFinding highRisk = result.findings[0];
        Assert.areEqual('HIGH_RISK', highRisk.severity, 'First finding should be HIGH_RISK');
        Assert.areEqual('PasswordComplexity', highRisk.setting, 'Setting should be PasswordComplexity');
        Assert.areEqual('SecurityHealthCheck', highRisk.category, 'Category should match');
    }

    @IsTest
    static void shouldHandleEmptyResults() {
        Test.setMock(HttpCalloutMock.class, new EmptyResultMock());

        Test.startTest();
        HealthCheckScanner.ScanResult result = new HealthCheckScanner().scan();
        Test.stopTest();

        Assert.areEqual(0, result.nativeScore, 'Score should default to 0 with no records');
        Assert.isTrue(result.findings.isEmpty(), 'Findings should be empty');
    }

    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('{"errorCode":"SERVER_ERROR","message":"Tooling API unavailable"}');
            return res;
        }
    }

    @IsTest
    static void shouldThrowOnToolingApiError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());

        Test.startTest();
        try {
            new HealthCheckScanner().scan();
            Assert.fail('Should have thrown AuraHandledException on Tooling API error');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Internal Server Error')
                || e.getMessage().contains('Tooling API'),
                'Error should reference API failure: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldInitializeScanResultDefaults() {
        Test.startTest();
        HealthCheckScanner.ScanResult result = new HealthCheckScanner.ScanResult();
        Test.stopTest();

        Assert.areEqual(0, result.nativeScore, 'Default nativeScore should be 0');
        Assert.isNotNull(result.findings, 'Default findings list should be initialized');
        Assert.isTrue(result.findings.isEmpty(), 'Default findings list should be empty');
    }
}
