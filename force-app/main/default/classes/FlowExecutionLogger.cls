public with sharing class FlowExecutionLogger {
    // Rate limiting constants
    private static final String RATE_LIMIT_PARTITION = 'ElaroRateLimit';
    private static final Integer RATE_LIMIT_MAX_CALLS = 100;
    private static final Integer RATE_LIMIT_WINDOW_SECONDS = 60;

    public class LogInput {
        @InvocableVariable(required=true) public String flowName;
        @InvocableVariable public Id primaryRecordId;
        @InvocableVariable(required=true) public String status;
        @InvocableVariable public Integer cpu;
        @InvocableVariable public Integer soql;
        @InvocableVariable public Integer dml;
    }
    @InvocableMethod(label='Log Flow Execution')
    public static void logInvocable(List<LogInput> inputs) {
        // Validate CRUD access
        ElaroSecurityUtils.validateCRUDAccess('Flow_Execution__c', ElaroSecurityUtils.DmlOperation.INSERT);
        
        // Validate FLS for required fields
        List<String> requiredFields = new List<String>{
            'Flow_Name__c', 'Status__c', 'CPU__c', 'SOQL__c', 'DML__c', 'Run_Time__c'
        };
        ElaroSecurityUtils.validateFLSAccess('Flow_Execution__c', requiredFields, true);
        
        List<Flow_Execution__c> toInsert = new List<Flow_Execution__c>();
        for (LogInput i : inputs) {
            toInsert.add(new Flow_Execution__c(
                Flow_Name__c = i.flowName,
                Primary_Record__c = i.primaryRecordId,
                Status__c = i.status,
                CPU__c = i.cpu, SOQL__c = i.soql, DML__c = i.dml,
                Run_Time__c = System.now()
            ));
        }
        
        if (!toInsert.isEmpty()) {
            // Strip inaccessible fields before insert
            List<SObject> accessibleRecords = ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.CREATABLE,
                toInsert
            );
            if (!accessibleRecords.isEmpty()) {
                insert accessibleRecords;
            }
        }
    }
    /**
     * Logs a single flow execution record from an LWC context. Validates inputs (non-blank flow name and status,
     * max 255 characters each), enforces per-user rate limiting (100 calls per 60-second window),
     * then delegates to the bulkified logInvocable method for CRUD/FLS-safe insertion.
     *
     * @param flowName Name of the flow that was executed (required, max 255 chars)
     * @param primaryRecordId Optional record ID associated with the flow execution
     * @param status Execution status (e.g., 'Success', 'Fault') (required, max 255 chars)
     * @param cpu CPU time consumed in milliseconds
     * @param soql Number of SOQL queries consumed
     * @param dml Number of DML statements consumed
     * @throws AuraHandledException When flowName or status is blank, exceeds length limits, or rate limit is exceeded
     */
    @AuraEnabled
    public static void log(String flowName, Id primaryRecordId, String status, Integer cpu, Integer soql, Integer dml) {
        // Input validation - non-null, non-empty
        if (String.isBlank(flowName)) {
            throw new AuraHandledException('Flow name cannot be blank');
        }
        if (String.isBlank(status)) {
            throw new AuraHandledException('Status cannot be blank');
        }
        // Reasonable length validation to prevent oversized payloads
        if (flowName.length() > 255) {
            throw new AuraHandledException('Flow name exceeds maximum length of 255 characters');
        }
        if (status.length() > 255) {
            throw new AuraHandledException('Status exceeds maximum length of 255 characters');
        }

        // Rate limiting check
        checkRateLimit();

        LogInput input = new LogInput();
        input.flowName = flowName;
        input.primaryRecordId = primaryRecordId;
        input.status = status;
        input.cpu = cpu;
        input.soql = soql;
        input.dml = dml;
        logInvocable(new List<LogInput>{ input });
    }

    private static void checkRateLimit() {
        String userId = UserInfo.getUserId();
        String cacheKey = 'FlowLogger_' + userId.substring(0, 15);

        try {
            Cache.OrgPartition partition = Cache.Org.getPartition(RATE_LIMIT_PARTITION);
            Integer callCount = (Integer) partition.get(cacheKey);

            if (callCount == null) {
                partition.put(cacheKey, 1, RATE_LIMIT_WINDOW_SECONDS);
            } else if (callCount >= RATE_LIMIT_MAX_CALLS) {
                throw new AuraHandledException('Rate limit exceeded. Please try again later.');
            } else {
                partition.put(cacheKey, callCount + 1, RATE_LIMIT_WINDOW_SECONDS);
            }
        } catch (Cache.CacheException e) {
            // If cache partition doesn't exist, log warning but don't block
            ElaroLogger.warn('[FlowExecutionLogger] Rate limit cache unavailable: ' + e.getMessage());
        }
    }
}
