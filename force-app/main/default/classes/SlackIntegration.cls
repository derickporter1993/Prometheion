/**
 * Slack integration service for Elaro. Provides alert notifications, audit
 * package sharing, daily digest delivery, and custom messaging to Slack channels.
 *
 * All asynchronous callouts are delegated to {@link SlackIntegrationQueueable}
 * using the Queueable framework with duplicate signature prevention.
 * The private {@code sendToSlack} method is retained for any synchronous
 * callout contexts (e.g., when already inside a Queueable or Batch).
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Integrations
 * @see SlackIntegrationQueueable
 * @see ElaroLogger
 */
public with sharing class SlackIntegration {

    private static final String NAMED_CREDENTIAL = 'callout:Slack_Webhook';

    /**
     * Sends a compliance alert notification to Slack asynchronously.
     * Enqueues a {@link SlackIntegrationQueueable} with a duplicate signature
     * derived from the alert data to prevent duplicate sends.
     *
     * @param alertDataJson JSON-serialized alert data containing severity, alertId,
     *        eventType, riskScore, message, and eventId fields
     */
    public static void sendAlert(String alertDataJson) {
        AsyncOptions options = new AsyncOptions();
        options.setDuplicateSignature(
            new QueueableDuplicateSignature.Builder()
                .addString('SlackAlert:' + alertDataJson.hashCode())
                .build()
        );
        System.enqueueJob(
            new SlackIntegrationQueueable(
                SlackIntegrationQueueable.Operation.SEND_ALERT,
                alertDataJson,
                null
            ),
            options
        );
    }

    /**
     * Sends an audit package notification to Slack asynchronously.
     * Enqueues a {@link SlackIntegrationQueueable} with a duplicate signature
     * derived from the package ID to prevent duplicate notifications.
     *
     * @param packageId The Salesforce record ID of the Elaro_Audit_Package__c
     * @param channel The target Slack channel name
     */
    public static void sendAuditPackageNotification(String packageId, String channel) {
        AsyncOptions options = new AsyncOptions();
        options.setDuplicateSignature(
            new QueueableDuplicateSignature.Builder()
                .addString('SlackAuditPkg:' + packageId)
                .build()
        );
        System.enqueueJob(
            new SlackIntegrationQueueable(
                SlackIntegrationQueueable.Operation.SEND_AUDIT_PACKAGE,
                packageId,
                channel
            ),
            options
        );
    }

    /**
     * Sends a daily compliance digest to Slack asynchronously.
     * Enqueues a {@link SlackIntegrationQueueable} with a duplicate signature
     * based on today's date to prevent duplicate daily digests.
     *
     * @param digestJson JSON-serialized digest data containing complianceScore,
     *        statistics (totalEvents, highRiskEvents, resolvedEvents), and aiSummary
     */
    public static void sendDailyDigest(String digestJson) {
        AsyncOptions options = new AsyncOptions();
        options.setDuplicateSignature(
            new QueueableDuplicateSignature.Builder()
                .addString('SlackDigest:' + Date.today().format())
                .build()
        );
        System.enqueueJob(
            new SlackIntegrationQueueable(
                SlackIntegrationQueueable.Operation.SEND_DAILY_DIGEST,
                digestJson,
                null
            ),
            options
        );
    }

    /**
     * Sends a custom text message to the specified Slack channel.
     * Uses {@code sendToSlackImmediate} which enqueues a Queueable when
     * not already in an async context, or sends synchronously if already
     * inside a Queueable or Batch execution.
     *
     * @param channel Slack channel name
     * @param text Message text to send
     */
    public static void sendMessage(String channel, String text) {
        Map<String, Object> message = new Map<String, Object>{
            'channel' => channel,
            'text' => text
        };

        sendToSlackImmediate(message);
    }

    private static void sendToSlack(Map<String, Object> message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(message));
        req.setTimeout(30000);

        try {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                ElaroLogger.error( 'Slack send failed: ' + res.getBody());
            }
        } catch (Exception e) {
            ElaroLogger.error( 'Slack integration error: ' + e.getMessage());
        }
    }

    private static void sendToSlackImmediate(Map<String, Object> message) {
        if (!System.isQueueable() && !System.isBatch()) {
            System.enqueueJob(
                new SlackIntegrationQueueable(
                    SlackIntegrationQueueable.Operation.SEND_MESSAGE,
                    JSON.serialize(message),
                    null
                )
            );
        } else {
            sendToSlack(message);
        }
    }

    private static String getColorForSeverity(String severity) {
        Map<String, String> colors = new Map<String, String>{
            'CRITICAL' => '#c23934',
            'HIGH' => '#e87722',
            'MEDIUM' => '#f7b924',
            'LOW' => '#4bca81',
            'INFO' => '#2196f3'
        };
        return colors.containsKey(severity) ? colors.get(severity) : '#666666';
    }
}
