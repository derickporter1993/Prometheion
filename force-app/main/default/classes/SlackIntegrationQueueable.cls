/**
 * Queueable implementation for all asynchronous Slack integration callouts.
 * Replaces legacy @future methods in {@link SlackIntegration} with a single
 * Queueable that dispatches to the correct operation via an enum.
 *
 * Implements {@code Database.AllowsCallouts} to permit HTTP callouts to Slack
 * webhooks during Queueable execution. Attaches a {@link SlackFinalizer} to
 * every execution for retry logic and structured error logging on failures.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Integrations
 * @see SlackIntegration
 * @see ElaroLogger
 */
public inherited sharing class SlackIntegrationQueueable implements Queueable, Database.AllowsCallouts {

    private static final String NAMED_CREDENTIAL = 'callout:Slack_Webhook';
    private static final Integer MAX_RETRY_ATTEMPTS = 2;

    /**
     * Defines the type of Slack operation to execute.
     */
    public enum Operation {
        SEND_ALERT,
        SEND_AUDIT_PACKAGE,
        SEND_DAILY_DIGEST,
        SEND_MESSAGE
    }

    private final Operation operation;
    private final String payload;
    private final String secondaryParam;
    private final Integer retryCount;

    /**
     * Constructs a new Queueable for the specified Slack operation.
     *
     * @param operation The type of Slack operation to execute
     * @param payload Primary JSON payload or serialized data for the operation
     * @param secondaryParam Optional secondary parameter (e.g., channel name for audit package)
     * @param retryCount Current retry attempt number (0 for first execution)
     */
    public SlackIntegrationQueueable(Operation operation, String payload, String secondaryParam, Integer retryCount) {
        this.operation = operation;
        this.payload = payload;
        this.secondaryParam = secondaryParam;
        this.retryCount = retryCount ?? 0;
    }

    /**
     * Constructs a new Queueable for the specified Slack operation with no retry count.
     *
     * @param operation The type of Slack operation to execute
     * @param payload Primary JSON payload or serialized data for the operation
     * @param secondaryParam Optional secondary parameter (e.g., channel name for audit package)
     */
    public SlackIntegrationQueueable(Operation operation, String payload, String secondaryParam) {
        this(operation, payload, secondaryParam, 0);
    }

    /**
     * Executes the Slack callout operation. Attaches a {@link SlackFinalizer} to handle
     * unhandled exceptions with retry logic and error logging.
     *
     * @param ctx The QueueableContext provided by the platform
     */
    public void execute(QueueableContext ctx) {
        System.attachFinalizer(new SlackFinalizer(this.operation, this.payload, this.secondaryParam, this.retryCount));

        switch on this.operation {
            when SEND_ALERT {
                executeSendAlert();
            }
            when SEND_AUDIT_PACKAGE {
                executeSendAuditPackage();
            }
            when SEND_DAILY_DIGEST {
                executeSendDailyDigest();
            }
            when SEND_MESSAGE {
                executeSendMessage();
            }
        }
    }

    /**
     * Builds and sends a compliance alert notification to Slack with severity-coded
     * color attachment, alert details, and a link back to the source record.
     */
    private void executeSendAlert() {
        Map<String, Object> alertData = (Map<String, Object>) JSON.deserializeUntyped(this.payload);

        String severity = (String) alertData.get('severity');
        String color = getColorForSeverity(severity);

        Map<String, Object> message = new Map<String, Object>{
            'attachments' => new List<Object>{
                new Map<String, Object>{
                    'color' => color,
                    'blocks' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'header',
                            'text' => new Map<String, Object>{
                                'type' => 'plain_text',
                                'text' => '\u26A0\uFE0F Elaro Compliance Alert',
                                'emoji' => true
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'section',
                            'fields' => new List<Object>{
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Severity:*\n' + severity},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Alert ID:*\n' + alertData.get('alertId')},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Event Type:*\n' + alertData.get('eventType')},
                                new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Risk Score:*\n' + alertData.get('riskScore')}
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'section',
                            'text' => new Map<String, Object>{
                                'type' => 'mrkdwn',
                                'text' => '*Details:*\n' + alertData.get('message')
                            }
                        },
                        new Map<String, Object>{
                            'type' => 'actions',
                            'elements' => new List<Object>{
                                new Map<String, Object>{
                                    'type' => 'button',
                                    'text' => new Map<String, Object>{'type' => 'plain_text', 'text' => 'View in Salesforce'},
                                    'url' => URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Elaro_Evidence_Item__c/' + alertData.get('eventId') + '/view'
                                }
                            }
                        }
                    }
                }
            }
        };

        sendToSlack(message);
    }

    /**
     * Queries the specified Audit Package record and sends a notification to the
     * designated Slack channel with package details and a direct link.
     */
    private void executeSendAuditPackage() {
        String packageId = this.payload;
        String channel = this.secondaryParam;

        Elaro_Audit_Package__c pkg = [
            SELECT Id, Name, Package_Name__c, Framework__c, Status__c
            FROM Elaro_Audit_Package__c
            WHERE Id = :packageId
            WITH USER_MODE
            LIMIT 1
        ];

        Map<String, Object> message = new Map<String, Object>{
            'channel' => channel,
            'blocks' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'header',
                    'text' => new Map<String, Object>{
                        'type' => 'plain_text',
                        'text' => '\uD83D\uDCCB Audit Package Generated'
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'fields' => new List<Object>{
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Package:*\n' + pkg.Package_Name__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Framework:*\n' + pkg.Framework__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Status:*\n' + pkg.Status__c},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Generated:*\n' + Datetime.now().format()}
                    }
                },
                new Map<String, Object>{
                    'type' => 'actions',
                    'elements' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'button',
                            'text' => new Map<String, Object>{'type' => 'plain_text', 'text' => 'View Package'},
                            'style' => 'primary',
                            'url' => URL.getOrgDomainUrl().toExternalForm() + '/lightning/r/Elaro_Audit_Package__c/' + packageId + '/view'
                        }
                    }
                }
            }
        };

        sendToSlack(message);
    }

    /**
     * Builds and sends a daily compliance digest message to Slack containing
     * score summary, event statistics, and an AI-generated summary.
     */
    private void executeSendDailyDigest() {
        Map<String, Object> digest = (Map<String, Object>) JSON.deserializeUntyped(this.payload);

        Map<String, Object> stats = (Map<String, Object>) digest.get('statistics');

        Map<String, Object> message = new Map<String, Object>{
            'blocks' => new List<Object>{
                new Map<String, Object>{
                    'type' => 'header',
                    'text' => new Map<String, Object>{
                        'type' => 'plain_text',
                        'text' => '\uD83D\uDCCA Daily Compliance Digest - ' + Date.today().format()
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'fields' => new List<Object>{
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Compliance Score:*\n' + digest.get('complianceScore') + '%'},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Total Events:*\n' + stats.get('totalEvents')},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*High Risk:*\n' + stats.get('highRiskEvents')},
                        new Map<String, Object>{'type' => 'mrkdwn', 'text' => '*Resolved:*\n' + stats.get('resolvedEvents')}
                    }
                },
                new Map<String, Object>{
                    'type' => 'section',
                    'text' => new Map<String, Object>{
                        'type' => 'mrkdwn',
                        'text' => '*AI Summary:*\n' + digest.get('aiSummary')
                    }
                },
                new Map<String, Object>{
                    'type' => 'divider'
                },
                new Map<String, Object>{
                    'type' => 'context',
                    'elements' => new List<Object>{
                        new Map<String, Object>{
                            'type' => 'mrkdwn',
                            'text' => 'Sent by Elaro Compliance Platform'
                        }
                    }
                }
            }
        };

        sendToSlack(message);
    }

    /**
     * Sends a simple text message to the specified Slack channel.
     */
    private void executeSendMessage() {
        Map<String, Object> message = (Map<String, Object>) JSON.deserializeUntyped(this.payload);
        sendToSlack(message);
    }

    /**
     * Sends the assembled message payload to the Slack webhook via HTTP POST.
     *
     * @param message The fully-constructed Slack Block Kit message
     */
    private void sendToSlack(Map<String, Object> message) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(NAMED_CREDENTIAL);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'application/json');
        req.setBody(JSON.serialize(message));
        req.setTimeout(30000);

        Http http = new Http();
        HttpResponse res = http.send(req);

        if (res.getStatusCode() != 200) {
            ElaroLogger.error('SlackIntegrationQueueable.sendToSlack: Slack send failed with status '
                + res.getStatusCode() + ': ' + res.getBody());
        }
    }

    /**
     * Returns the severity-to-color mapping for Slack attachment formatting.
     *
     * @param severity The severity level string (CRITICAL, HIGH, MEDIUM, LOW, INFO)
     * @return Hex color code for the Slack attachment sidebar
     */
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

    /**
     * Transaction Finalizer for Slack integration jobs. Logs failures via
     * {@link ElaroLogger} and optionally re-enqueues the job for retry
     * when the failure was caused by an unhandled exception.
     *
     * @author Elaro Team
     * @since v1.0.0 (Spring '26)
     * @group Integrations
     * @see SlackIntegrationQueueable
     */
    public class SlackFinalizer implements Finalizer {

        private final Operation operation;
        private final String payload;
        private final String secondaryParam;
        private final Integer retryCount;

        /**
         * Constructs the finalizer with the original job parameters for potential retry.
         *
         * @param operation The Slack operation type
         * @param payload The original payload
         * @param secondaryParam The original secondary parameter
         * @param retryCount The current retry attempt count
         */
        public SlackFinalizer(Operation operation, String payload, String secondaryParam, Integer retryCount) {
            this.operation = operation;
            this.payload = payload;
            this.secondaryParam = secondaryParam;
            this.retryCount = retryCount;
        }

        /**
         * Handles job completion. On unhandled exceptions, logs the error and
         * re-enqueues the job up to {@link SlackIntegrationQueueable#MAX_RETRY_ATTEMPTS} times.
         *
         * @param ctx The FinalizerContext provided by the platform
         */
        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                String errorMessage = ctx.getException()?.getMessage() ?? 'Unknown error';
                String stackTrace = ctx.getException()?.getStackTraceString() ?? '';

                ElaroLogger.error('SlackIntegrationQueueable.SlackFinalizer: '
                    + this.operation.name() + ' failed (attempt ' + (this.retryCount + 1) + '/'
                    + (MAX_RETRY_ATTEMPTS + 1) + '): ' + errorMessage + ' | Stack: ' + stackTrace);

                if (this.retryCount < MAX_RETRY_ATTEMPTS) {
                    System.enqueueJob(
                        new SlackIntegrationQueueable(
                            this.operation,
                            this.payload,
                            this.secondaryParam,
                            this.retryCount + 1
                        )
                    );
                    ElaroLogger.info('SlackIntegrationQueueable.SlackFinalizer: Re-enqueued '
                        + this.operation.name() + ' for retry attempt ' + (this.retryCount + 1));
                } else {
                    ElaroLogger.error('SlackIntegrationQueueable.SlackFinalizer: '
                        + this.operation.name() + ' exhausted all ' + MAX_RETRY_ATTEMPTS
                        + ' retry attempts. Giving up.');
                }
            }
        }
    }
}
