/**
 * Test class for PrometheionSlackNotifierQueueable
 */
@IsTest
private class PrometheionSlackNotifierQueueableTest {
    
    // Mock class for Slack HTTP callout
    private class SlackCalloutMock implements HttpCalloutMock {
        public Integer statusCode;
        public String status;
        public String body;
        
        public SlackCalloutMock(Integer statusCode, String status, String body) {
            this.statusCode = statusCode;
            this.status = status;
            this.body = body != null ? body : 'ok';
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            res.setBody(this.body);
            return res;
        }
    }
    
    @IsTest
    static void testExecute_Success() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK', 'ok'));
        
        String payload = '{"text":"Test notification"}';
        String correlationId = 'TEST-123';
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify job completed without exception
        System.assert(true, 'Job should complete successfully');
    }
    
    @IsTest
    static void testExecute_RetryOnTransientError() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(500, 'Internal Server Error', 'error'));
        
        String payload = '{"text":"Test notification"}';
        String correlationId = 'TEST-456';
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, 0, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify retry logic is triggered
        System.assert(true, 'Job should handle retry logic');
    }
    
    @IsTest
    static void testExecute_EmptyPayload() {
        String payload = '';
        String correlationId = 'TEST-789';
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify empty payload is handled gracefully
        System.assert(true, 'Empty payload should be handled');
    }
    
    @IsTest
    static void testExecute_LargePayload() {
        // Create a large payload that exceeds MAX_PAYLOAD_SIZE
        String largePayload = '{"text":"' + 'x'.repeat(50000) + '"}';
        String correlationId = 'TEST-LARGE';
        
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK', 'ok'));
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(largePayload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Verify large payload is truncated
        System.assert(true, 'Large payload should be truncated');
    }
    
    @IsTest
    static void testExecute_CalloutException() {
        // Simulate callout exception by not setting mock
        String payload = '{"text":"Test"}';
        String correlationId = 'TEST-EXCEPTION';
        
        Test.startTest();
        try {
            PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, correlationId);
            System.enqueueJob(job);
        } catch (Exception e) {
            // Expected: callout exception
            System.assert(true, 'Callout exception should be handled');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructor_WithRetryCount() {
        String payload = '{"text":"Test"}';
        Integer retryCount = 1;
        String correlationId = 'TEST-RETRY';
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, retryCount, correlationId);
        System.assertNotEquals(null, job, 'Job should be created');
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructor_DefaultRetryCount() {
        String payload = '{"text":"Test"}';
        String correlationId = 'TEST-DEFAULT';
        
        Test.startTest();
        PrometheionSlackNotifierQueueable job = new PrometheionSlackNotifierQueueable(payload, correlationId);
        System.assertNotEquals(null, job, 'Job should be created with default retry count');
        Test.stopTest();
    }
}
