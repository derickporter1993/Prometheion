/**
 * Tests for {@link SessionSettingsScanner} covering all session setting evaluations,
 * null handling, and empty response scenarios.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see SessionSettingsScanner
 */
@IsTest(testFor=SessionSettingsScanner.class)
private class SessionSettingsScannerTest {

    private class AllSecureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{'
                + '"Id":"0DU000000000001","Metadata":{"sessionSettings":{'
                + '"requireHttps":true,'
                + '"lockSessionsToIp":true,'
                + '"enableXssProtection":true,'
                + '"enableClickjackNonsetupSFDC":true,'
                + '"enableCspOnEmail":true,'
                + '"sessionTimeout":"TWO_HOURS"'
                + '}}}]}');
            return res;
        }
    }

    private class AllInsecureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{'
                + '"Id":"0DU000000000001","Metadata":{"sessionSettings":{'
                + '"requireHttps":false,'
                + '"lockSessionsToIp":false,'
                + '"enableXssProtection":false,'
                + '"enableClickjackNonsetupSFDC":false,'
                + '"enableCspOnEmail":false,'
                + '"sessionTimeout":"TWENTY_FOUR_HOURS"'
                + '}}}]}');
            return res;
        }
    }

    private class EmptyRecordsMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":0,"totalSize":0,"done":true,"records":[]}');
            return res;
        }
    }

    private class NullMetadataMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{'
                + '"Id":"0DU000000000001","Metadata":null}]}');
            return res;
        }
    }

    @IsTest
    static void shouldScorePerfectWhenAllSecure() {
        Test.setMock(HttpCalloutMock.class, new AllSecureMock());

        Test.startTest();
        SessionSettingsScanner.SessionResult result = new SessionSettingsScanner().scan();
        Test.stopTest();

        Assert.areEqual(100, result.score, 'Fully secure settings should score 100');
        Assert.isTrue(result.findings.isEmpty(),
            'No findings expected for secure configuration');
    }

    @IsTest
    static void shouldPenalizeInsecureSettings() {
        Test.setMock(HttpCalloutMock.class, new AllInsecureMock());

        Test.startTest();
        SessionSettingsScanner.SessionResult result = new SessionSettingsScanner().scan();
        Test.stopTest();

        Assert.isTrue(result.score < 100, 'Score should be penalized for insecure settings');
        Assert.isFalse(result.findings.isEmpty(), 'Should have findings for insecure settings');

        Boolean foundHttps = false;
        Boolean foundXss = false;
        for (ScanFinding finding : result.findings) {
            Assert.areEqual('Session', finding.category, 'Category should be Session');
            if (finding.setting == 'Require HTTPS') {
                foundHttps = true;
            }
            if (finding.setting == 'XSS Protection') {
                foundXss = true;
            }
        }
        Assert.isTrue(foundHttps, 'Should flag missing HTTPS');
        Assert.isTrue(foundXss, 'Should flag missing XSS protection');
    }

    @IsTest
    static void shouldHandleEmptyRecords() {
        Test.setMock(HttpCalloutMock.class, new EmptyRecordsMock());

        Test.startTest();
        SessionSettingsScanner.SessionResult result = new SessionSettingsScanner().scan();
        Test.stopTest();

        Assert.areEqual(50, result.score, 'Should default to 50 on empty records');
        Assert.areEqual(1, result.findings.size(), 'Should have one finding for empty records');
    }

    @IsTest
    static void shouldHandleNullMetadata() {
        Test.setMock(HttpCalloutMock.class, new NullMetadataMock());

        Test.startTest();
        SessionSettingsScanner.SessionResult result = new SessionSettingsScanner().scan();
        Test.stopTest();

        Assert.areEqual(50, result.score, 'Should default to 50 on null Metadata');
    }

    @IsTest
    static void shouldInitializeResultDefaults() {
        SessionSettingsScanner.SessionResult result =
            new SessionSettingsScanner.SessionResult();
        Assert.areEqual(100, result.score, 'Default score should be 100');
        Assert.isNotNull(result.findings, 'Findings should be initialized');
    }
}
