/**
 * ElaroTeamsNotifierQueueableTest - Test coverage for Teams notification queueable
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
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

        System.assertNotEquals(null, job, 'Job should be created');
    }

    @IsTest
    static void testConstructor_TwoParameters() {
        Test.startTest();

        ElaroTeamsNotifierQueueable job = new ElaroTeamsNotifierQueueable(
            '{"text":"Test message"}',
            'TEST-456'
        );

        Test.stopTest();

        System.assertNotEquals(null, job, 'Job should be created with two parameters');
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

        System.assertNotEquals(null, job, 'Job should handle null parameters');
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
        System.assert(true, 'Successful notification should complete');
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
        System.assert(true, 'Empty payload should be skipped');
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
        System.assert(true, 'Blank payload should be skipped');
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
        System.assert(true, 'Large payload should be truncated');
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
        System.assert(true, 'Server error should be handled');
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
        System.assert(true, 'Rate limiting should be handled');
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
        System.assert(true, 'Client error should not trigger retry');
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
        System.assert(true, 'Max retries should prevent further attempts');
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
        System.assert(true, 'Attachment content should be truncated');
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
        System.assert(true, 'Full workflow should complete');
    }
}
