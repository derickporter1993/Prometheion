/**
 * ComplianceScoreCardController
 * 
 * Controller for Compliance ScoreCard LWC component
 * Provides framework details including mappings and evidence counts
 * 
 * @author Elaro
 * @version 1.0
 */
public with sharing class ComplianceScoreCardController {
    
    /**
     * Get framework details including mapping and evidence counts
     * @param framework Framework name
     * @return Framework details with counts
     */
    @AuraEnabled(cacheable=true)
    public static FrameworkDetails getFrameworkDetails(String framework) {
        if (String.isBlank(framework)) {
            throw new AuraHandledException('Framework cannot be blank');
        }
        
        // Validate framework is supported
        if (!ElaroConstants.isValidFramework(framework)) {
            throw new AuraHandledException('Unsupported framework: ' + framework);
        }
        
        FrameworkDetails details = new FrameworkDetails();
        details.framework = framework;
        
        // Count active framework mappings
        details.mappingCount = [
            SELECT COUNT()
            FROM Elaro_Framework_Mapping__c
            WHERE Framework__c = :framework
            AND Is_Active__c = true
            WITH USER_MODE
        ];
        
        // Count evidence items for this framework
        // Note: Evidence items are linked via Audit Package, so we need to query through the relationship
        Set<Id> auditPackageIds = new Set<Id>();
        for (Elaro_Audit_Package__c pkg : [
            SELECT Id
            FROM Elaro_Audit_Package__c
            WHERE Framework__c = :framework
            WITH USER_MODE
        ]) {
            auditPackageIds.add(pkg.Id);
        }
        
        details.evidenceCount = 0;
        if (!auditPackageIds.isEmpty()) {
            details.evidenceCount = [
                SELECT COUNT()
                FROM Elaro_Evidence_Item__c
                WHERE Audit_Package__c IN :auditPackageIds
                WITH USER_MODE
            ];
        }
        
        // Get most recent audit package
        List<Elaro_Audit_Package__c> recentPackages = [
            SELECT Id, Name, Package_Name__c, Status__c, 
                   Audit_Period_Start__c, Audit_Period_End__c, CreatedDate
            FROM Elaro_Audit_Package__c
            WHERE Framework__c = :framework
            WITH USER_MODE
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];
        
        if (!recentPackages.isEmpty()) {
            Elaro_Audit_Package__c pkg = recentPackages[0];
            details.latestAuditPackage = new AuditPackageSummary();
            details.latestAuditPackage.id = pkg.Id;
            details.latestAuditPackage.name = pkg.Package_Name__c;
            details.latestAuditPackage.status = pkg.Status__c;
            details.latestAuditPackage.periodStart = pkg.Audit_Period_Start__c;
            details.latestAuditPackage.periodEnd = pkg.Audit_Period_End__c;
            details.latestAuditPackage.createdDate = pkg.CreatedDate;
        }
        
        // Get framework requirements from ElaroFrameworkEngine
        List<ElaroFrameworkEngine.FrameworkRequirement> requirements = 
            ElaroFrameworkEngine.getFrameworkRequirements(framework);
        details.requirementCount = requirements != null ? requirements.size() : 0;
        
        return details;
    }
    
    /**
     * Framework Details wrapper
     */
    public class FrameworkDetails {
        @AuraEnabled public String framework;
        @AuraEnabled public Integer mappingCount;
        @AuraEnabled public Integer evidenceCount;
        @AuraEnabled public Integer requirementCount;
        @AuraEnabled public AuditPackageSummary latestAuditPackage;
    }
    
    /**
     * Audit Package Summary wrapper
     */
    public class AuditPackageSummary {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;
        @AuraEnabled public Date periodStart;
        @AuraEnabled public Date periodEnd;
        @AuraEnabled public DateTime createdDate;
    }
}
