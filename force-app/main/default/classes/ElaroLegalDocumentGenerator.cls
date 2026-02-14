public with sharing class ElaroLegalDocumentGenerator {
    private static final String RATE_LIMIT_PARTITION = 'ElaroRateLimit';
    private static final Integer RATE_LIMIT_MAX_CALLS = 10;
    private static final Integer RATE_LIMIT_WINDOW_SECONDS = 60;

    @AuraEnabled
    public static String generateLegalAttestation(String framework, Date startDate, Date endDate) {
        // Rate limiting check
        if (!checkRateLimit('ElaroLegalDocumentGenerator')) {
            throw new AuraHandledException('Rate limit exceeded. Please wait before generating another evidence pack.');
        }

        // Input validation
        if (String.isBlank(framework)) {
            throw new AuraHandledException('Framework cannot be blank');
        }
        if (!ElaroConstants.isValidFramework(framework)) {
            throw new AuraHandledException('Unsupported framework: ' + framework + '. Supported frameworks: ' + ElaroConstants.SUPPORTED_FRAMEWORKS);
        }
        if (startDate == null) {
            throw new AuraHandledException('Start date cannot be null');
        }
        if (endDate == null) {
            throw new AuraHandledException('End date cannot be null');
        }
        if (startDate > endDate) {
            throw new AuraHandledException('Start date cannot be after end date');
        }

        try {
            // Generate compliance evidence pack
            String documentContent = generateEvidencePackContent(framework, startDate, endDate);

            // Validate CRUD access for ContentVersion
            ElaroSecurityUtils.validateCRUDAccess('ContentVersion', ElaroSecurityUtils.DmlOperation.INSERT);
            
            // Validate FLS for ContentVersion fields
            List<String> requiredFields = new List<String>{
                'Title', 'PathOnClient', 'VersionData', 'IsMajorVersion'
            };
            ElaroSecurityUtils.validateFLSAccess('ContentVersion', requiredFields, true);
            
            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = framework + '_Evidence_Pack_' + System.today().format();
            cv.PathOnClient = cv.Title + '.txt';
            cv.VersionData = Blob.valueOf(documentContent);
            cv.IsMajorVersion = true;
            
            // Strip inaccessible fields before insert
            List<SObject> accessibleContent = ElaroSecurityUtils.stripInaccessibleFields(
                AccessType.CREATABLE,
                new List<SObject>{cv}
            );
            if (accessibleContent.isEmpty()) {
                throw new AuraHandledException('Insufficient field-level security access for ContentVersion');
            }
            insert as user accessibleContent;
            cv = (ContentVersion)accessibleContent[0];

            // Get ContentDocumentId
            if (!ElaroSecurityUtils.hasReadAccess('ContentVersion')) {
                throw new AuraHandledException('Insufficient access to ContentVersion');
            }
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH USER_MODE];

            // Audit logging for evidence pack generation
            logAuditEvent('EVIDENCE_PACK_GENERATED', framework, startDate, endDate, cv.ContentDocumentId);

            return cv.ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating evidence pack: ' + e.getMessage());
        }
    }

    /**
     * Check rate limit using Cache.OrgPartition
     * Returns true if within limit, false if limit exceeded
     */
    private static Boolean checkRateLimit(String key) {
        try {
            Cache.OrgPartition orgPart = Cache.Org.getPartition(RATE_LIMIT_PARTITION);
            String cacheKey = key + '_' + String.valueOf(System.now().getTime() / (RATE_LIMIT_WINDOW_SECONDS * 1000));
            Integer currentCount = (Integer)orgPart.get(cacheKey);

            if (currentCount == null) {
                currentCount = 0;
            }

            if (currentCount >= RATE_LIMIT_MAX_CALLS) {
                return false;
            }

            orgPart.put(cacheKey, currentCount + 1, RATE_LIMIT_WINDOW_SECONDS);
            return true;
        } catch (Exception e) {
            // If cache partition doesn't exist, allow the call but log warning
            ElaroLogger.warn('ElaroLegalDocumentGenerator: Rate limit check failed, allowing call: ' + e.getMessage());
            return true;
        }
    }

    /**
     * Log audit event for compliance tracking
     */
    private static void logAuditEvent(String action, String framework, Date startDate, Date endDate, String documentId) {
        try {
            if (Schema.sObjectType.Elaro_Audit_Log__c.isCreateable()) {
                Elaro_Audit_Log__c auditLog = new Elaro_Audit_Log__c(
                    Action__c = action,
                    User__c = UserInfo.getUserId(),
                    Timestamp__c = System.now(),
                    Details__c = 'Framework: ' + framework + ', Period: ' + startDate + ' to ' + endDate + ', DocumentId: ' + documentId
                );
                insert as user auditLog;
            }
        } catch (Exception e) {
            // Don't fail the main operation if audit logging fails
            ElaroLogger.warn('ElaroLegalDocumentGenerator: Failed to log audit event: ' + e.getMessage());
        }
    }

    private static String generateEvidencePackContent(String framework, Date startDate, Date endDate) {
        // Validate read access
        if (!ElaroSecurityUtils.hasReadAccess('Elaro_Compliance_Graph__b')) {
            throw new AuraHandledException('Insufficient access to Compliance Graph');
        }
        
        // Build content using String concatenation (StringBuilder not available in Apex)
        String content = 'COMPLIANCE EVIDENCE PACK\n';
        content += '========================\n\n';
        content += 'Framework: ' + framework + '\n';
        content += 'Generated: ' + System.now() + '\n';
        content += 'Period: ' + startDate + ' to ' + endDate + '\n\n';

        // Query compliance graph entries
        List<Elaro_Compliance_Graph__b> entries = [
            SELECT Graph_Node_Id__c, Entity_Type__c, Risk_Score__c, Drift_Category__c,
                   Timestamp__c, Human_Adjudicated__c
            FROM Elaro_Compliance_Graph__b
            WHERE Compliance_Framework__c = :framework
            AND Timestamp__c >= :startDate
            AND Timestamp__c <= :endDate
            WITH USER_MODE
            ORDER BY Timestamp__c DESC
            LIMIT 1000
        ];

        content += 'Total Events: ' + entries.size() + '\n\n';
        content += 'DETAILED AUDIT LOG\n';
        content += '==================\n\n';

        for (Elaro_Compliance_Graph__b entry : entries) {
            content += 'Node: ' + entry.Graph_Node_Id__c + '\n';
            content += 'Type: ' + entry.Entity_Type__c + '\n';
            content += 'Risk: ' + entry.Risk_Score__c + '/10\n';
            content += 'Category: ' + entry.Drift_Category__c + '\n';
            content += 'Timestamp: ' + entry.Timestamp__c + '\n';
            content += 'Human Reviewed: ' + entry.Human_Adjudicated__c + '\n';
            content += '---\n\n';
        }

        return content;
    }
}
