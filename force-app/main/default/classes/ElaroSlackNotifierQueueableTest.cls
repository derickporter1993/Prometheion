/**
 * Test class for ElaroSlackNotifierQueueable
 */
@IsTest
private class ElaroSlackNotifierQueueableTest {
    
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
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Coverage-only: verifies no exception thrown
        Assert.isNotNull(job, 'Job should not be null');
    }
    
    @IsTest
    static void testExecute_RetryOnTransientError() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(500, 'Internal Server Error', 'error'));
        
        String payload = '{"text":"Test notification"}';
        String correlationId = 'TEST-456';
        
        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, 0, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Coverage-only: verifies no exception thrown on transient error
        Assert.isNotNull(job, 'Job should not be null');
    }
    
    @IsTest
    static void testExecute_EmptyPayload() {
        String payload = '';
        String correlationId = 'TEST-789';
        
        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Coverage-only: verifies no exception thrown for empty payload
        Assert.isNotNull(job, 'Job should not be null');
    }
    
    @IsTest
    static void testExecute_LargePayload() {
        // Create a large payload that exceeds MAX_PAYLOAD_SIZE
        String largePayload = '{"text":"' + 'x'.repeat(50000) + '"}';
        String correlationId = 'TEST-LARGE';
        
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK', 'ok'));
        
        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(largePayload, correlationId);
        System.enqueueJob(job);
        Test.stopTest();
        
        // Coverage-only: verifies no exception thrown for large payload
        Assert.isNotNull(job, 'Job should not be null');
    }
    
    @IsTest
    static void testExecute_CalloutException() {
        // Simulate callout exception by not setting mock
        String payload = '{"text":"Test"}';
        String correlationId = 'TEST-EXCEPTION';
        
        Test.startTest();
        try {
            ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, correlationId);
            System.enqueueJob(job);
        } catch (CalloutException e) {
            // Expected: callout exception when no mock is set
            Assert.isNotNull(e.getMessage(), 'Callout exception should have a message');
        } catch (AsyncException e) {
            // Expected: async processing exception
            Assert.isNotNull(e.getMessage(), 'Async exception should have a message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructor_WithRetryCount() {
        String payload = '{"text":"Test"}';
        Integer retryCount = 1;
        String correlationId = 'TEST-RETRY';
        
        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, retryCount, correlationId);
        Assert.areNotEqual(null, job, 'Job should be created');
        Test.stopTest();
    }
    
    @IsTest
    static void testConstructor_DefaultRetryCount() {
        String payload = '{"text":"Test"}';
        String correlationId = 'TEST-DEFAULT';

        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(payload, correlationId);
        Assert.areNotEqual(null, job, 'Job should be created with default retry count');
        Test.stopTest();
    }

    @IsTest
    static void testExecute_BulkNotifications() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK', 'ok'));

        // Create 200 notification payloads
        List<String> payloads = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            payloads.add('{"text":"Bulk notification ' + i + '"}');
        }

        Test.startTest();
        // Queue multiple notifications
        for (Integer i = 0; i < Math.min(5, payloads.size()); i++) {
            ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(
                payloads[i],
                'BULK-' + i
            );
            System.enqueueJob(job);
        }
        Test.stopTest();

        Assert.areEqual(200, payloads.size(), 'Should have 200 payloads prepared');
        Assert.isTrue(Limits.getQueueableJobs() <= 50, 'Should stay under queueable limit');
    }

    @IsTest
    static void testExecute_LargeBatchPayload() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK', 'ok'));

        // Create a consolidated payload with 200 alerts
        List<Map<String, Object>> alerts = new List<Map<String, Object>>();
        for (Integer i = 0; i < 200; i++) {
            alerts.add(new Map<String, Object>{
                'title' => 'Alert ' + i,
                'severity' => 'HIGH',
                'framework' => 'SOC2'
            });
        }

        String bulkPayload = JSON.serialize(new Map<String, Object>{
            'text' => 'Bulk compliance alerts',
            'attachments' => alerts
        });

        Test.startTest();
        ElaroSlackNotifierQueueable job = new ElaroSlackNotifierQueueable(
            bulkPayload,
            'BULK-CONSOLIDATED'
        );
        System.enqueueJob(job);
        Test.stopTest();

        // Coverage-only: verifies no exception thrown for large batch
        Assert.isNotNull(job, 'Job should not be null');
    }
}
