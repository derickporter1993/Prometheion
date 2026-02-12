/**
 * Queueable job that asynchronously creates a Jira issue from a Compliance Gap record.
 * Replaces the legacy {@code @future(callout=true)} pattern in {@link JiraIntegrationService}
 * with a retry-capable Queueable that uses a {@link Finalizer} for error handling.
 *
 * <p>This class implements {@code Database.AllowsCallouts} to permit HTTP callouts to
 * the Jira REST API within the async transaction. A {@link JiraIssueFinalizer} inner class
 * is attached to each execution to log unhandled exceptions and optionally re-enqueue
 * a single retry attempt.</p>
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Integrations
 * @see JiraIntegrationService
 * @see JiraIntegrationService.JiraIssue
 */
public inherited sharing class JiraIntegrationQueueable implements Queueable, Database.AllowsCallouts {

    private static final Integer MAX_RETRY_ATTEMPTS = 1;

    private final String gapId;
    private final String priority;
    private final Integer retryCount;

    /**
     * Constructs a new Queueable for creating a Jira issue.
     *
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     * @param priority Optional priority override (Highest, High, Medium, Low, Lowest)
     */
    public JiraIntegrationQueueable(String gapId, String priority) {
        this(gapId, priority, 0);
    }

    /**
     * Constructs a new Queueable with an explicit retry count (used internally by the Finalizer).
     *
     * @param gapId The Salesforce ID of the Compliance_Gap__c record
     * @param priority Optional priority override
     * @param retryCount The current retry attempt number (0 = first attempt)
     */
    public JiraIntegrationQueueable(String gapId, String priority, Integer retryCount) {
        this.gapId = gapId;
        this.priority = priority;
        this.retryCount = retryCount;
    }

    /**
     * Executes the asynchronous Jira issue creation. Attaches a {@link JiraIssueFinalizer}
     * to handle unhandled exceptions with retry logic.
     *
     * @param ctx The QueueableContext provided by the Apex runtime
     */
    public void execute(QueueableContext ctx) {
        System.attachFinalizer(new JiraIssueFinalizer(this.gapId, this.priority, this.retryCount));
        try {
            JiraIntegrationService.createIssue(this.gapId, this.priority);
        } catch (Exception e) {
            ElaroLogger.error('JiraIntegrationQueueable.execute: Failed to create Jira issue'
                + ' for gap ' + this.gapId, e);
        }
    }

    /**
     * Transaction Finalizer that handles unhandled exceptions from the Queueable execution.
     * If the parent job fails with an unhandled exception and the retry limit has not been
     * reached, re-enqueues a new {@link JiraIntegrationQueueable} for one additional attempt.
     *
     * @author Elaro Team
     * @since v1.0.0 (Spring '26)
     * @group Integrations
     * @see JiraIntegrationQueueable
     */
    public class JiraIssueFinalizer implements Finalizer {

        private final String gapId;
        private final String priority;
        private final Integer retryCount;

        /**
         * Constructs the Finalizer with the context needed for retry.
         *
         * @param gapId The Salesforce ID of the Compliance_Gap__c record
         * @param priority Optional priority override
         * @param retryCount The current retry attempt number from the parent job
         */
        public JiraIssueFinalizer(String gapId, String priority, Integer retryCount) {
            this.gapId = gapId;
            this.priority = priority;
            this.retryCount = retryCount;
        }

        /**
         * Executes after the parent Queueable completes. On unhandled exception,
         * logs the error and re-enqueues once if under the retry limit.
         *
         * @param ctx The FinalizerContext provided by the Apex runtime
         */
        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                Exception ex = ctx.getException();
                ElaroLogger.error('JiraIssueFinalizer.execute: Unhandled exception in'
                    + ' JiraIntegrationQueueable for gap ' + this.gapId
                    + ' (attempt ' + (this.retryCount + 1) + ')', ex);

                if (this.retryCount < MAX_RETRY_ATTEMPTS) {
                    System.enqueueJob(
                        new JiraIntegrationQueueable(this.gapId, this.priority, this.retryCount + 1)
                    );
                } else {
                    ElaroLogger.error('JiraIssueFinalizer.execute: Max retry attempts ('
                        + MAX_RETRY_ATTEMPTS + ') exhausted for gap ' + this.gapId
                        + '. Manual intervention required.');
                }
            }
        }
    }
}
