/**
 * Test class for ElaroClaudeAPIMock
 * @group Tests
 * @see ElaroClaudeAPIMock
 */
@IsTest
private class ElaroClaudeAPIMockTest {
    
    @isTest
    static void testSuccessResponse() {
        Test.startTest();
        
        // Set up mock
        Test.setMock(HttpCalloutMock.class, ElaroClaudeAPIMock.success());
        
        // Make callout
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Claude_API');
        req.setMethod('POST');
        req.setBody('{"test": "request"}');
        
        HttpResponse res = new Http().send(req);
        
        Test.stopTest();
        
        // Verify response
        Assert.areEqual(200, res.getStatusCode(), 'Should return 200 for success');
        Assert.isTrue(res.getBody().contains('recommendation'), 'Should contain recommendation in response');
        Assert.isTrue(res.getBody().contains('claude-sonnet'), 'Should contain model information');
    }
    
    @isTest
    static void testErrorResponse() {
        Test.startTest();
        
        // Set up mock for error
        Test.setMock(HttpCalloutMock.class, ElaroClaudeAPIMock.error());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Claude_API');
        req.setMethod('POST');
        req.setBody('{"invalid": "request"}');
        
        HttpResponse res = new Http().send(req);
        
        Test.stopTest();
        
        // Verify error response
        Assert.areEqual(400, res.getStatusCode(), 'Should return 400 for error');
        Assert.isTrue(res.getBody().contains('invalid_request_error'), 'Should contain error type');
    }
    
    @isTest
    static void testRateLimitedResponse() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, ElaroClaudeAPIMock.rateLimited());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Claude_API');
        req.setMethod('POST');
        
        HttpResponse res = new Http().send(req);
        
        Test.stopTest();
        
        Assert.areEqual(429, res.getStatusCode(), 'Should return 429 for rate limit');
        Assert.isTrue(res.getBody().contains('rate_limit_error'), 'Should indicate rate limiting');
    }
    
    @isTest
    static void testTimeoutResponse() {
        Test.startTest();
        
        Test.setMock(HttpCalloutMock.class, ElaroClaudeAPIMock.timeout());
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Claude_API');
        req.setMethod('POST');
        
        HttpResponse res = new Http().send(req);
        
        Test.stopTest();
        
        Assert.areEqual(504, res.getStatusCode(), 'Should return 504 for timeout');
        Assert.isTrue(res.getBody().contains('timeout_error'), 'Should indicate timeout');
    }
    
    @isTest
    static void testCustomResponse() {
        Test.startTest();
        
        String customBody = '{"custom": "response"}';
        Test.setMock(HttpCalloutMock.class, new ElaroClaudeAPIMock(201, customBody));
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Claude_API');
        req.setMethod('POST');
        
        HttpResponse res = new Http().send(req);
        
        Test.stopTest();
        
        Assert.areEqual(201, res.getStatusCode(), 'Should return custom status code');
        Assert.areEqual(customBody, res.getBody(), 'Should return custom body');
    }
}
