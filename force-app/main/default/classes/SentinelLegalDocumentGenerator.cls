public with sharing class SentinelLegalDocumentGenerator {
    @AuraEnabled
    public static String generateLegalAttestation(String framework, Date startDate, Date endDate) {
        try {
            // Generate compliance evidence pack
            String documentContent = generateEvidencePackContent(framework, startDate, endDate);

            // Create ContentVersion
            ContentVersion cv = new ContentVersion();
            cv.Title = framework + '_Evidence_Pack_' + System.today().format();
            cv.PathOnClient = cv.Title + '.txt';
            cv.VersionData = Blob.valueOf(documentContent);
            cv.IsMajorVersion = true;
            insert cv;

            // Get ContentDocumentId
            cv = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
            return cv.ContentDocumentId;
        } catch (Exception e) {
            throw new AuraHandledException('Error generating evidence pack: ' + e.getMessage());
        }
    }

    private static String generateEvidencePackContent(String framework, Date startDate, Date endDate) {
        StringBuilder content = new StringBuilder();
        content.append('COMPLIANCE EVIDENCE PACK\n');
        content.append('========================\n\n');
        content.append('Framework: ' + framework + '\n');
        content.append('Generated: ' + System.now() + '\n');
        content.append('Period: ' + startDate + ' to ' + endDate + '\n\n');

        // Query compliance graph entries
        List<Sentinel_Compliance_Graph__b> entries = [
            SELECT Graph_Node_Id__c, Entity_Type__c, Risk_Score__c, Drift_Category__c,
                   Timestamp__c, Human_Adjudicated__c
            FROM Sentinel_Compliance_Graph__b
            WHERE Compliance_Framework__c = :framework
            AND Timestamp__c >= :startDate
            AND Timestamp__c <= :endDate
            ORDER BY Timestamp__c DESC
            LIMIT 1000
        ];

        content.append('Total Events: ' + entries.size() + '\n\n');
        content.append('DETAILED AUDIT LOG\n');
        content.append('==================\n\n');

        for (Sentinel_Compliance_Graph__b entry : entries) {
            content.append('Node: ' + entry.Graph_Node_Id__c + '\n');
            content.append('Type: ' + entry.Entity_Type__c + '\n');
            content.append('Risk: ' + entry.Risk_Score__c + '/10\n');
            content.append('Category: ' + entry.Drift_Category__c + '\n');
            content.append('Timestamp: ' + entry.Timestamp__c + '\n');
            content.append('Human Reviewed: ' + entry.Human_Adjudicated__c + '\n');
            content.append('---\n\n');
        }

        return content.toString();
    }
}
