/**
 * ElaroAuditPackageGenerator
 * 
 * Generates audit packages for compliance frameworks with evidence collection
 * 
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ElaroAuditPackageGenerator {
    
    /**
     * Generate audit package for a framework and date range
     * @param framework Framework name
     * @param packageName Package name
     * @param startDate Audit period start
     * @param endDate Audit period end
     * @return Created audit package ID
     */
    @AuraEnabled
    public static String generateAuditPackage(String framework, String packageName, Date startDate, Date endDate) {
        // Input validation
        if (String.isBlank(framework)) {
            throw new AuraHandledException('Framework cannot be blank');
        }
        if (String.isBlank(packageName)) {
            throw new AuraHandledException('Package name cannot be blank');
        }
        if (startDate == null || endDate == null) {
            throw new AuraHandledException('Start date and end date are required');
        }
        if (startDate > endDate) {
            throw new AuraHandledException('Start date must be before end date');
        }
        
        // Validate CRUD access
        ElaroSecurityUtils.validateCRUDAccess('Elaro_Audit_Package__c',
            ElaroSecurityUtils.DmlOperation.DML_INSERT);
        
        // Create audit package
        Elaro_Audit_Package__c auditPackage = new Elaro_Audit_Package__c(
            Package_Name__c = packageName,
            Framework__c = framework,
            Status__c = 'DRAFT',
            Audit_Period_Start__c = startDate,
            Audit_Period_End__c = endDate,
            Created_By__c = UserInfo.getUserId(),
            Last_Modified_By__c = UserInfo.getUserId()
        );
        
        try {
            insert as user auditPackage;
            
            // Generate framework mappings
            generateFrameworkMappings(auditPackage.Id, framework);
            
            // Collect evidence items
            collectEvidenceItems(auditPackage.Id, framework, startDate, endDate);
            
            return auditPackage.Id;
        } catch (DmlException e) {
            throw new AuraHandledException('Error creating audit package: ' + ElaroSecurityUtils.getSafeDmlMessage(e));
        }
    }
    
    /**
     * Generate framework mappings for the audit package
     */
    private static void generateFrameworkMappings(Id auditPackageId, String framework) {
        // Get framework requirements from ElaroFrameworkEngine
        List<ElaroFrameworkEngine.FrameworkRequirement> requirements = 
            ElaroFrameworkEngine.getFrameworkRequirements(framework);
        
        if (requirements == null || requirements.isEmpty()) {
            return;
        }
        
        ElaroSecurityUtils.validateCRUDAccess('Elaro_Framework_Mapping__c',
            ElaroSecurityUtils.DmlOperation.DML_INSERT);
        
        List<Elaro_Framework_Mapping__c> mappings = new List<Elaro_Framework_Mapping__c>();
        
        for (ElaroFrameworkEngine.FrameworkRequirement req : requirements) {
            mappings.add(new Elaro_Framework_Mapping__c(
                Audit_Package__c = auditPackageId,
                Framework__c = framework,
                Requirement_Code__c = req.code,
                Requirement_Description__c = req.description,
                Entity_Type__c = req.entityType,
                Is_Active__c = true,
                Mapping_Metadata__c = JSON.serialize(req.metadata)
            ));
        }
        
        if (!mappings.isEmpty()) {
            insert as user mappings;
        }
    }
    
    /**
     * Collect evidence items for the audit package
     */
    private static void collectEvidenceItems(Id auditPackageId, String framework, Date startDate, Date endDate) {
        // Use EvidenceCollectionService to collect evidence
        List<Compliance_Evidence__c> evidenceList = EvidenceCollectionService.collectEvidence(
            framework, startDate, endDate);
        
        if (evidenceList == null || evidenceList.isEmpty()) {
            return;
        }
        
        ElaroSecurityUtils.validateCRUDAccess('Elaro_Evidence_Item__c',
            ElaroSecurityUtils.DmlOperation.DML_INSERT);
        
        List<Elaro_Evidence_Item__c> evidenceItems = new List<Elaro_Evidence_Item__c>();
        
        for (Compliance_Evidence__c evidence : evidenceList) {
            evidenceItems.add(new Elaro_Evidence_Item__c(
                Audit_Package__c = auditPackageId,
                Evidence_Type__c = evidence.Evidence_Type__c,
                Evidence_Date__c = evidence.Evidence_Date__c,
                Description__c = evidence.Description__c,
                Evidence_Data__c = evidence.Evidence_Data__c,
                File_Reference__c = evidence.File_Reference__c,
                Status__c = 'COLLECTED'
            ));
        }
        
        if (!evidenceItems.isEmpty()) {
            insert as user evidenceItems;
        }
    }
}
