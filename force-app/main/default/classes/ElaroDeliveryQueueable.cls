/**
 * Queueable implementation for asynchronous Slack delivery of audit package notifications.
 * Replaces the legacy {@code @future(callout=true)} pattern in {@link ElaroDeliveryService}
 * with a Queueable that supports retry logic via a Transaction Finalizer.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Export &amp; Delivery
 * @see ElaroDeliveryService
 * @see ElaroLogger
 */
public inherited sharing class ElaroDeliveryQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_RETRIES = 3;

    private final String packageId;
    private final String channel;
    private final Integer retryCount;

    /**
     * Constructs a new delivery queueable for Slack notification.
     *
     * @param packageId The ID of the Elaro_Audit_Package__c record to notify about
     * @param channel The Slack channel to post the notification to
     */
    public ElaroDeliveryQueueable(String packageId, String channel) {
        this(packageId, channel, 0);
    }

    /**
     * Constructs a new delivery queueable with a specific retry count.
     *
     * @param packageId The ID of the Elaro_Audit_Package__c record to notify about
     * @param channel The Slack channel to post the notification to
     * @param retryCount The current retry attempt number (0 = first attempt)
     */
    public ElaroDeliveryQueueable(String packageId, String channel, Integer retryCount) {
        this.packageId = packageId;
        this.channel = channel;
        this.retryCount = retryCount ?? 0;
    }

    /**
     * Executes the Slack notification callout for the specified audit package.
     * Attaches a {@link DeliveryFinalizer} to handle retry logic on unhandled exceptions.
     *
     * @param ctx The QueueableContext provided by the platform
     */
    public void execute(QueueableContext ctx) {
        System.attachFinalizer(new DeliveryFinalizer(this.packageId, this.channel, this.retryCount));

        // Query package details
        Elaro_Audit_Package__c pkg = [
            SELECT Id, Package_Name__c, Framework__c, Status__c
            FROM Elaro_Audit_Package__c
            WHERE Id = :packageId
            WITH USER_MODE
            LIMIT 1
        ];

        // Build Slack Block Kit message
        Map&lt;String, Object&gt; slackMessage = buildSlackMessage(pkg, this.channel);

        // Send to Slack webhook via Named Credential
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:Elaro_Slack_Webhook');
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(slackMessage));
        req.setTimeout(30000);

        if (!Test.isRunningTest()) {
            Http http = new Http();
            HttpResponse res = http.send(req);

            if (res.getStatusCode() != 200) {
                ElaroLogger.error(
                    'ElaroDeliveryQueueable.execute: Slack notification failed: ' + res.getBody()
                );
            }
        }
    }

    /**
     * Builds a Slack Block Kit message payload for the given audit package.
     *
     * @param pkg The audit package record containing package details
     * @param slackChannel The target Slack channel
     * @return A map representing the Slack Block Kit message structure
     */
    private Map&lt;String, Object&gt; buildSlackMessage(Elaro_Audit_Package__c pkg, String slackChannel) {
        List&lt;Object&gt; blocks = new List&lt;Object&gt;{
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'header',
                'text' =&gt; new Map&lt;String, Object&gt;{
                    'type' =&gt; 'plain_text',
                    'text' =&gt; '📋 Audit Package Generated',
                    'emoji' =&gt; true
                }
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'section',
                'fields' =&gt; new List&lt;Object&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Package:*\n' + pkg.Package_Name__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Framework:*\n' + pkg.Framework__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Status:*\n' + pkg.Status__c
                    },
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; '*Generated:*\n' + Datetime.now().format()
                    }
                }
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'divider'
            },
            new Map&lt;String, Object&gt;{
                'type' =&gt; 'context',
                'elements' =&gt; new List&lt;Object&gt;{
                    new Map&lt;String, Object&gt;{
                        'type' =&gt; 'mrkdwn',
                        'text' =&gt; 'Sent from *Elaro Compliance Platform*'
                    }
                }
            }
        };

        return new Map&lt;String, Object&gt;{
            'channel' =&gt; slackChannel,
            'blocks' =&gt; blocks
        };
    }

    /**
     * Transaction Finalizer that handles retry logic for failed Slack delivery attempts.
     * Re-enqueues the {@link ElaroDeliveryQueueable} up to {@code MAX_RETRIES} times
     * when an unhandled exception occurs during execution.
     *
     * @author Elaro Team
     * @since v1.0.0 (Spring '26)
     * @group Export &amp; Delivery
     * @see ElaroDeliveryQueueable
     */
    public class DeliveryFinalizer implements Finalizer {

        private final String packageId;
        private final String channel;
        private final Integer retryCount;

        /**
         * Constructs a finalizer with the context needed to re-enqueue a retry.
         *
         * @param packageId The audit package ID
         * @param channel The Slack channel
         * @param retryCount The current retry attempt number
         */
        public DeliveryFinalizer(String packageId, String channel, Integer retryCount) {
            this.packageId = packageId;
            this.channel = channel;
            this.retryCount = retryCount;
        }

        /**
         * Handles the completion of the parent Queueable job. If the job failed with
         * an unhandled exception and the retry limit has not been reached, re-enqueues
         * the delivery job. Otherwise, logs the final failure.
         *
         * @param ctx The FinalizerContext provided by the platform
         */
        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                String errorMessage = ctx.getException()?.getMessage() ?? 'Unknown error';

                if (this.retryCount &lt; MAX_RETRIES) {
                    ElaroLogger.error(
                        'ElaroDeliveryQueueable.DeliveryFinalizer: Slack delivery failed (attempt '
                        + (this.retryCount + 1) + '/' + MAX_RETRIES + '): ' + errorMessage
                        + '. Retrying...'
                    );
                    System.enqueueJob(
                        new ElaroDeliveryQueueable(this.packageId, this.channel, this.retryCount + 1)
                    );
                } else {
                    ElaroLogger.error(
                        'ElaroDeliveryQueueable.DeliveryFinalizer: Slack delivery failed after '
                        + MAX_RETRIES + ' retries for package ' + this.packageId + ': ' + errorMessage
                    );
                }
            }
        }
    }
}
