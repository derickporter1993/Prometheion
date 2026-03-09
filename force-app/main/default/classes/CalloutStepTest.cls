/**
 * Tests for CalloutStep: HttpCalloutMock for 200 success, 500 retry,
 * 400 no retry, max retries exceeded.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Async Framework
 * @see CalloutStep
 */
@IsTest
private class CalloutStepTest {

    private class TestCalloutStep extends CalloutStep {
        public Boolean responseHandled = false;
        public String responseBody;
        private Boolean finalized = false;

        public override HttpRequest buildRequest(StepContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.example.com/test');
            req.setMethod('GET');
            return req;
        }

        public override void handleResponse(HttpResponse res, StepContext ctx) {
            responseHandled = true;
            responseBody = res.getBody();
            ctx.put('calloutResult', res.getBody());
        }

        public override void finalize(StepContext ctx) {
            finalized = true;
        }

        public override String getName() {
            return 'TestCalloutStep';
        }
    }

    private class TestCalloutStepWithRetries extends CalloutStep {
        public Boolean responseHandled = false;

        public override HttpRequest buildRequest(StepContext ctx) {
            HttpRequest req = new HttpRequest();
            req.setEndpoint('https://api.example.com/test');
            req.setMethod('GET');
            return req;
        }

        public override void handleResponse(HttpResponse res, StepContext ctx) {
            responseHandled = true;
        }

        public override Integer getMaxRetries() {
            return 1;
        }

        public override void finalize(StepContext ctx) {}

        public override String getName() {
            return 'TestCalloutStepWithRetries';
        }
    }

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"ok"}');
            return res;
        }
    }

    private class ServerErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('Internal Server Error');
            return res;
        }
    }

    private class ClientErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(400);
            res.setBody('Bad Request');
            return res;
        }
    }

    @IsTest
    static void shouldHandleSuccessResponse() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        TestCalloutStep step = new TestCalloutStep();
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isTrue(step.responseHandled, 'Response handler should be called');
        Assert.areEqual('{"status":"ok"}', step.responseBody, 'Should receive response body');
        Assert.areEqual('{"status":"ok"}', ctx.getString('calloutResult'), 'Result should be in context');
    }

    @IsTest
    static void shouldRetryOnServerError() {
        Test.setMock(HttpCalloutMock.class, new ServerErrorMock());
        TestCalloutStep step = new TestCalloutStep();
        StepContext ctx = new StepContext();

        Test.startTest();
        step.execute(ctx);
        Test.stopTest();

        Assert.isFalse(step.responseHandled, 'Response handler should not be called on 500');
        Assert.areEqual(1, ctx.getInteger('calloutRetryCount'), 'Retry count should increment');
        Assert.isTrue(ctx.getBoolean('needsRestart'), 'Should flag for restart');
    }

    @IsTest
    static void shouldThrowOnClientError() {
        Test.setMock(HttpCalloutMock.class, new ClientErrorMock());
        TestCalloutStep step = new TestCalloutStep();
        StepContext ctx = new StepContext();

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            step.execute(ctx);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
            Assert.isTrue(e.getMessage().contains('400'), 'Exception should contain status code');
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw AuraHandledException on 4xx');
        Assert.areEqual(1, ctx.errorHistory.size(), 'Error should be recorded');
    }

    @IsTest
    static void shouldThrowAfterMaxRetries() {
        Test.setMock(HttpCalloutMock.class, new ServerErrorMock());
        TestCalloutStepWithRetries step = new TestCalloutStepWithRetries();
        StepContext ctx = new StepContext();
        ctx.put('calloutRetryCount', 1);

        Test.startTest();
        Boolean exceptionThrown = false;
        try {
            step.execute(ctx);
        } catch (AuraHandledException e) {
            exceptionThrown = true;
        }
        Test.stopTest();

        Assert.isTrue(exceptionThrown, 'Should throw after max retries exceeded');
        Assert.areEqual(1, ctx.errorHistory.size(), 'Error should be logged');
    }

    @IsTest
    static void shouldNotRestart() {
        TestCalloutStep step = new TestCalloutStep();

        Test.startTest();
        Boolean restart = step.shouldRestart();
        Test.stopTest();

        Assert.isFalse(restart, 'CalloutStep should never restart');
    }

    @IsTest
    static void shouldReturnCorrectName() {
        TestCalloutStep step = new TestCalloutStep();

        Test.startTest();
        String name = step.getName();
        Test.stopTest();

        Assert.areEqual('TestCalloutStep', name, 'Should return the step name');
    }

    @IsTest
    static void shouldReturnDefaultMaxRetries() {
        TestCalloutStep step = new TestCalloutStep();

        Test.startTest();
        Integer maxRetries = step.getMaxRetries();
        Test.stopTest();

        Assert.areEqual(2, maxRetries, 'Default max retries should be 2');
    }

    @IsTest
    static void shouldReturnCustomMaxRetries() {
        TestCalloutStepWithRetries step = new TestCalloutStepWithRetries();

        Test.startTest();
        Integer maxRetries = step.getMaxRetries();
        Test.stopTest();

        Assert.areEqual(1, maxRetries, 'Custom max retries should be 1');
    }
}
