public with sharing class ElaroLegalDocumentGenerator {
    @AuraEnabled
    public static String generateLegalAttestation(String framework, Date startDate, Date endDate) {
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
            insert accessibleContent;
            cv = (ContentVersion)accessibleContent[0];

            // Get ContentDocumentId
            if (!ElaroSecurityUtils.hasReadAccess('ContentVersion')) {
                throw new AuraHandledException('Insufficient access to ContentVersion');
            }
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id WITH SECURITY_ENFORCED];
            return cv.ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating evidence pack: ' + e.getMessage());
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
            WITH SECURITY_ENFORCED
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
