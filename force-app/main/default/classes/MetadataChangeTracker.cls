/**
 * MetadataChangeTracker
 * 
 * Track all metadata changes for compliance (vs Strongpoint)
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class MetadataChangeTracker {
    
    /**
     * Track a metadata change
     * @param changeType CREATE, UPDATE, or DELETE
     * @param metadataType Type of metadata (CustomObject, ApexClass, etc.)
     * @param metadataName Name of the metadata
     * @param metadataId Salesforce ID if applicable
     * @param changeDetails JSON string with before/after values
     * @return Created Metadata_Change__c record ID
     */
    @AuraEnabled
    public static String trackChange(String changeType, String metadataType, String metadataName, String metadataId, String changeDetails) {
        if (String.isBlank(changeType) || String.isBlank(metadataType) || String.isBlank(metadataName)) {
            throw new IllegalArgumentException('Change type, metadata type, and metadata name are required');
        }
        
        Metadata_Change__c change = new Metadata_Change__c(
            Change_Type__c = changeType,
            Metadata_Type__c = metadataType,
            Metadata_Name__c = metadataName,
            Metadata_Id__c = metadataId,
            Changed_By__c = UserInfo.getUserId(),
            Change_Date__c = System.now(),
            Change_Details__c = changeDetails,
            Risk_Level__c = calculateRiskLevel(metadataType, changeType)
        );
        
        try {
            insert change;
            return change.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Error tracking change: ' + e.getDmlMessage(0));
        }
    }
    
    /**
     * Calculate risk level for a metadata change
     */
    private static String calculateRiskLevel(String metadataType, String changeType) {
        // High-risk metadata types
        Set<String> highRiskTypes = new Set<String>{
            'PermissionSet', 'Profile', 'SharingRule', 'CustomObject', 'ApexClass', 'Flow'
        };
        
        // DELETE is always high risk
        if (changeType == 'DELETE') {
            return 'HIGH';
        }
        
        if (highRiskTypes.contains(metadataType)) {
            return changeType == 'CREATE' ? 'MEDIUM' : 'HIGH';
        }
        
        return 'LOW';
    }
    
    /**
     * Get recent metadata changes
     */
    @AuraEnabled(cacheable=true)
    public static List<Metadata_Change__c> getRecentChanges(Integer limitSize) {
        Integer limit = Math.max(1, Math.min(limitSize, 100));
        
        return [
            SELECT Id, Change_Type__c, Metadata_Type__c, Metadata_Name__c, 
                   Changed_By__c, Change_Date__c, Risk_Level__c, Impact_Analysis__c
            FROM Metadata_Change__c
            WITH SECURITY_ENFORCED
            ORDER BY Change_Date__c DESC
            LIMIT :limit
        ];
    }
}
