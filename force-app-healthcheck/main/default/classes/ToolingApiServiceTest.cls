/**
 * Tests for {@link ToolingApiService} covering success, error, and malformed responses.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ToolingApiService
 */
@IsTest(testFor=ToolingApiService.class)
private class ToolingApiServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            res.setBody('{"size":1,"totalSize":1,"done":true,"records":[{"Score":72}]}');
            return res;
        }
    }

    private class ErrorMock implements HttpCalloutMock {
        private final Integer statusCode;
        private final String status;

        public ErrorMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(statusCode);
            res.setStatus(status);
            res.setBody('{"errorCode":"INVALID_QUERY","message":"error"}');
            return res;
        }
    }

    @IsTest
    static void shouldReturnParsedResponseOnSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());

        Test.startTest();
        Map<String, Object> result = ToolingApiService.queryTooling(
            'SELECT Id, Score FROM SecurityHealthCheck'
        );
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        List<Object> records = (List<Object>) result.get('records');
        Assert.isNotNull(records, 'Records list should not be null');
        Assert.areEqual(1, records.size(), 'Should return one record');

        Map<String, Object> record = (Map<String, Object>) records[0];
        Assert.areEqual(72, ((Decimal) record.get('Score')).intValue(), 'Score should be 72');
    }

    @IsTest
    static void shouldThrowOnBadRequest() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock(400, 'Bad Request'));

        Test.startTest();
        try {
            ToolingApiService.queryTooling('SELECT BadField FROM BadObject');
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Bad Request'),
                'Error message should contain status: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldThrowOnServerError() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock(500, 'Internal Server Error'));

        Test.startTest();
        try {
            ToolingApiService.queryTooling('SELECT Id FROM SecurityHealthCheck');
            Assert.fail('Should have thrown AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(
                e.getMessage().contains('Internal Server Error'),
                'Error message should contain status: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}
