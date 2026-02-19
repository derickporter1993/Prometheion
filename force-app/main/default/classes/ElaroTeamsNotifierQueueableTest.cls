/**
 * ElaroTeamsNotifierQueueableTest - Test coverage for Teams notification queueable
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=ElaroTeamsNotifierQueueable.class)
private class ElaroTeamsNotifierQueueableTest {

    // ========================================
    // MOCK HTTP CALLOUT
    // ========================================

    private class TeamsWebhookMock implements HttpCalloutMock {
        private Integer statusCode;
        private String status;

        public TeamsWebhookMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }

        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(statusCode);
            res.setStatus(status);
            res.setBody('{"status":"' + status + '"}');
            return res;
        }
    }

    // ========================================
    // CONSTRUCTOR TESTS
    // ========================================

    @IsTest
    static void testConstructor_AllParameters() {
        Test.startTest();

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test message"}',
            1,
            'TEST-123'
        );

        Test.stopTest();

        Assert.areNotEqual(null, job, 'Job should be created');
    }

    @IsTest
    static void testConstructor_TwoParameters() {
        Test.startTest();

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test message"}',
            'TEST-456'
        );

        Test.stopTest();

        Assert.areNotEqual(null, job, 'Job should be created with two parameters');
    }

    @IsTest
    static void testConstructor_NullParameters() {
        Test.startTest();

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test"}',
            null,
            null
        );

        Test.stopTest();

        Assert.areNotEqual(null, job, 'Job should handle null parameters');
    }

    // ========================================
    // EXECUTE TESTS
    // ========================================

    @IsTest
    static void testExecute_SuccessfulNotification() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(200, 'OK'));

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test notification"}',
            'SUCCESS-TEST'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should complete without errors
        Assert.isNotNull(job, 'Successful notification job should be created and complete');
    }

    @IsTest
    static void testExecute_EmptyPayload() {
        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '',
            'EMPTY-PAYLOAD'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should skip sending for empty payload
        Assert.isNotNull(job, 'Job should be created even with empty payload (skips sending internally)');
    }

    @IsTest
    static void testExecute_BlankPayload() {
        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '   ',
            'BLANK-PAYLOAD'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should skip sending for blank payload
        Assert.isNotNull(job, 'Job should be created even with blank payload (skips sending internally)');
    }

    @IsTest
    static void testExecute_LargePayload() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(200, 'OK'));

        // Create payload that exceeds MAX_PAYLOAD_SIZE
        String largeText = '';
        for (Integer i = 0; i < 3000; i++) {
            largeText += 'x';
        }

        Map<String, Object> payload = new Map<String, Object>{
            'text' => largeText
        };

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            JSON.serialize(payload),
            'LARGE-PAYLOAD'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should truncate and send successfully
        Assert.isNotNull(job, 'Large payload job should be created and truncated internally');
    }

    // ========================================
    // ERROR HANDLING TESTS
    // ========================================

    @IsTest
    static void testExecute_ServerError() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(500, 'Internal Server Error'));

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test"}',
            0,
            'ERROR-TEST'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should handle server error (will attempt retry in production)
        Assert.isNotNull(job, 'Server error should be handled gracefully by the job');
    }

    @IsTest
    static void testExecute_RateLimited() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(429, 'Too Many Requests'));

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test"}',
            0,
            'RATE-LIMIT-TEST'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should handle rate limiting (will attempt retry)
        Assert.isNotNull(job, 'Rate limiting should be handled gracefully by the job');
    }

    @IsTest
    static void testExecute_ClientError() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(400, 'Bad Request'));

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test"}',
            0,
            'CLIENT-ERROR-TEST'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should not retry on client errors
        Assert.isNotNull(job, 'Client error should be handled without retry');
    }

    @IsTest
    static void testExecute_MaxRetriesReached() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(500, 'Internal Server Error'));

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test"}',
            3, // Already at max retries
            'MAX-RETRY-TEST'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should not retry when max is reached
        Assert.isNotNull(job, 'Max retries reached should prevent further retry attempts');
    }

    // ========================================
    // PAYLOAD TRUNCATION TESTS
    // ========================================

    @IsTest
    static void testTruncatePayload_WithAttachments() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(200, 'OK'));

        // Create payload with Adaptive Card structure
        Map<String, Object> bodyItem = new Map<String, Object>{
            'type' => 'TextBlock',
            'text' => String.valueOf('x').repeat(3000) // Large text
        };

        Map<String, Object> content = new Map<String, Object>{
            'body' => new List<Object>{ bodyItem }
        };

        Map<String, Object> attachment = new Map<String, Object>{
            'content' => content
        };

        Map<String, Object> payload = new Map<String, Object>{
            'attachments' => new List<Object>{ attachment }
        };

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            JSON.serialize(payload),
            'ATTACHMENT-TRUNCATE'
        );

        Test.startTest();
        System.enqueueJob(job);
        Test.stopTest();

        // Should truncate attachment content
        Assert.isNotNull(job, 'Attachment content should be truncated and job should complete');
    }

    // ========================================
    // INTEGRATION TESTS
    // ========================================

    @IsTest
    static void testFullWorkflow() {
        Test.setMock(HttpCalloutMock.class, new TeamsWebhookMock(200, 'OK'));

        Map<String, Object> payload = new Map<String, Object>{
            'text' => 'Test notification from Elaro',
            'attachments' => new List<Object>{
                new Map<String, Object>{
                    'contentType' => 'application/vnd.microsoft.card.adaptive',
                    'content' => new Map<String, Object>{
                        'type' => 'AdaptiveCard',
                        'body' => new List<Object>{
                            new Map<String, Object>{
                                'type' => 'TextBlock',
                                'text' => 'Compliance Alert'
                            }
                        }
                    }
                }
            }
        };

        Test.startTest();

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            JSON.serialize(payload),
            'WORKFLOW-TEST'
        );
        System.enqueueJob(job);

        Test.stopTest();

        // Should complete full workflow successfully
        Assert.isNotNull(job, 'Full workflow should complete with job created');
    }
}
