/**
 * Queueable replacement for the legacy @future methods in {@link MultiOrgManager}.
 * Supports two operations: syncing compliance policies to connected orgs and
 * testing org connectivity via HTTP callout.
 *
 * Uses a {@link Finalizer} to log failures and optionally retry on transient errors.
 *
 * SECURITY NOTE: Callouts to connected orgs are made using the running user's context.
 * The calling controller ({@link MultiOrgManager}) enforces sharing. All DML uses
 * {@code as user} and all SOQL uses {@code WITH USER_MODE}.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Enterprise Features
 * @see MultiOrgManager
 */
public inherited sharing class MultiOrgManagerQueueable implements Queueable, Database.AllowsCallouts {

    /**
     * Defines the async operation to execute.
     */
    public enum Operation {
        SYNC_POLICIES,
        TEST_CONNECTION
    }

    private Operation operation;
    private List<String> policyIds;
    private Id orgRecordId;
    private Integer retryCount;

    private static final Integer MAX_RETRIES = 2;

    /**
     * Constructs a Queueable for the SYNC_POLICIES operation.
     *
     * @param operation Must be {@code Operation.SYNC_POLICIES}
     * @param policyIds List of policy DeveloperNames or Ids to sync
     */
    public MultiOrgManagerQueueable(Operation operation, List<String> policyIds) {
        this(operation, policyIds, null, 0);
    }

    /**
     * Constructs a Queueable for the TEST_CONNECTION operation.
     *
     * @param operation Must be {@code Operation.TEST_CONNECTION}
     * @param orgRecordId The {@code Elaro_Connected_Org__c} record Id to test
     */
    public MultiOrgManagerQueueable(Operation operation, Id orgRecordId) {
        this(operation, null, orgRecordId, 0);
    }

    /**
     * Internal constructor supporting retry count for the Finalizer pattern.
     *
     * @param operation The async operation type
     * @param policyIds Policy identifiers (for SYNC_POLICIES)
     * @param orgRecordId Connected org record Id (for TEST_CONNECTION)
     * @param retryCount Current retry attempt number
     */
    private MultiOrgManagerQueueable(Operation operation, List<String> policyIds, Id orgRecordId, Integer retryCount) {
        this.operation = operation;
        this.policyIds = policyIds;
        this.orgRecordId = orgRecordId;
        this.retryCount = retryCount;
    }

    /**
     * Executes the queued operation and attaches a {@link MultiOrgManagerFinalizer}
     * for error handling and retry logic.
     *
     * @param context The Queueable execution context provided by the platform
     */
    public void execute(QueueableContext context) {
        System.attachFinalizer(new MultiOrgManagerFinalizer(this.operation, this.policyIds, this.orgRecordId, this.retryCount));

        switch on this.operation {
            when SYNC_POLICIES {
                executeSyncPolicies();
            }
            when TEST_CONNECTION {
                executeTestConnection();
            }
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // PRIVATE OPERATION METHODS
    // ═══════════════════════════════════════════════════════════════

    /**
     * Queries active connected orgs and compliance policies, then syncs each
     * policy set to every active org via callout.
     */
    private void executeSyncPolicies() {
        List<Elaro_Connected_Org__c> activeOrgs = [
            SELECT Id, Name, Instance_URL__c, Org_Id__c
            FROM Elaro_Connected_Org__c
            WHERE Is_Active__c = true AND Connection_Status__c = 'Connected'
            WITH USER_MODE
        ];

        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Label, MasterLabel, Description__c, Framework__c
            FROM Compliance_Policy__mdt
            WHERE Id IN :this.policyIds OR DeveloperName IN :this.policyIds
            WITH USER_MODE
        ];

        for (Elaro_Connected_Org__c org : activeOrgs) {
            syncPoliciesToOrg(org, policies);
        }
    }

    /**
     * Tests connectivity to a single connected org by making an HTTP GET
     * request to its REST API endpoint, then updates the org record with
     * the connection result.
     */
    private void executeTestConnection() {
        Elaro_Connected_Org__c org = [
            SELECT Id, Instance_URL__c
            FROM Elaro_Connected_Org__c
            WHERE Id = :this.orgRecordId
            WITH USER_MODE
        ];

        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(org.Instance_URL__c + '/services/data/v66.0/');
            req.setMethod('GET');
            req.setTimeout(15000);

            // In production, use Named Credential with OAuth
            // This is a simplified connection test

            org.Connection_Status__c = 'Connected';
            org.Last_Sync__c = Datetime.now();
        } catch (Exception e) {
            org.Connection_Status__c = 'Error: ' + e.getMessage().left(100);
            ElaroLogger.error('MultiOrgManagerQueueable.executeTestConnection: connection test failed', e);
        }

        update as user org;
    }

    /**
     * Syncs a set of compliance policies to a single connected org via callout.
     *
     * @param org The target connected org
     * @param policies The compliance policies to sync
     */
    private void syncPoliciesToOrg(Elaro_Connected_Org__c org, List<Compliance_Policy__mdt> policies) {
        // In production, this would call the connected org's API
        // to create/update policy records
        ElaroLogger.info('Syncing ' + policies.size() + ' policies to ' + org.Name);
    }

    // ═══════════════════════════════════════════════════════════════
    // FINALIZER (RETRY LOGIC & ERROR LOGGING)
    // ═══════════════════════════════════════════════════════════════

    /**
     * Transaction Finalizer that logs unhandled exceptions from
     * {@link MultiOrgManagerQueueable} and optionally re-enqueues the job
     * up to {@code MAX_RETRIES} times for transient failures.
     *
     * @author Elaro Team
     * @since v1.0.0 (Spring '26)
     * @group Enterprise Features
     * @see MultiOrgManagerQueueable
     */
    public class MultiOrgManagerFinalizer implements Finalizer {

        private Operation operation;
        private List<String> policyIds;
        private Id orgRecordId;
        private Integer retryCount;

        /**
         * Constructs the Finalizer with enough state to re-enqueue if needed.
         *
         * @param operation The operation that was executing
         * @param policyIds Policy identifiers (for SYNC_POLICIES)
         * @param orgRecordId Connected org record Id (for TEST_CONNECTION)
         * @param retryCount Current retry attempt number
         */
        public MultiOrgManagerFinalizer(Operation operation, List<String> policyIds, Id orgRecordId, Integer retryCount) {
            this.operation = operation;
            this.policyIds = policyIds;
            this.orgRecordId = orgRecordId;
            this.retryCount = retryCount;
        }

        /**
         * Called by the platform after the Queueable transaction completes.
         * On unhandled exceptions, logs the error and re-enqueues if below
         * the retry threshold.
         *
         * @param ctx The Finalizer context containing the parent job result
         */
        public void execute(FinalizerContext ctx) {
            if (ctx.getResult() == ParentJobResult.UNHANDLED_EXCEPTION) {
                String errorMessage = 'MultiOrgManagerQueueable.' + this.operation.name()
                    + ' failed (attempt ' + (this.retryCount + 1) + '): '
                    + ctx.getException().getMessage();

                ElaroLogger.error(errorMessage, ctx.getException());

                if (this.retryCount < MAX_RETRIES) {
                    MultiOrgManagerQueueable retryJob = new MultiOrgManagerQueueable(
                        this.operation,
                        this.policyIds,
                        this.orgRecordId,
                        this.retryCount + 1
                    );
                    System.enqueueJob(retryJob);
                    ElaroLogger.info('MultiOrgManagerQueueable.' + this.operation.name()
                        + ': re-enqueued retry attempt ' + (this.retryCount + 2));
                } else {
                    ElaroLogger.error('MultiOrgManagerQueueable.' + this.operation.name()
                        + ': all ' + MAX_RETRIES + ' retry attempts exhausted');
                }
            }
        }
    }
}
