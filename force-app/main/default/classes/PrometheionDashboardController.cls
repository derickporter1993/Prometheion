/**
 * PrometheionDashboardController
 * 
 * Controller for Prometheion Dashboard LWC component
 * Provides audit package data and statistics
 * 
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionDashboardController {
    
    /**
     * Get recent audit packages for a framework
     * @param framework Framework name (optional, 'ALL' for all frameworks)
     * @return List of audit packages with basic info
     */
    @AuraEnabled(cacheable=true)
    public static List<AuditPackageInfo> getAuditPackages(String framework) {
        if (String.isBlank(framework) || framework == 'ALL') {
            framework = null;
        }
        
        String soql = 'SELECT Id, Name, Package_Name__c, Framework__c, Status__c, ' +
                      'Audit_Period_Start__c, Audit_Period_End__c, CreatedDate, ' +
                      'Created_By__r.Name, LastModifiedDate ' +
                      'FROM Prometheion_Audit_Package__c ';
        
        if (framework != null) {
            soql += 'WHERE Framework__c = :framework ';
        }
        
        soql += 'ORDER BY CreatedDate DESC LIMIT 10';
        
        List<Prometheion_Audit_Package__c> packages = new List<Prometheion_Audit_Package__c>();
        
        try {
            if (framework != null) {
                packages = Database.query(soql);
            } else {
                packages = Database.query(soql.replace('WHERE Framework__c = :framework ', ''));
            }
        } catch (Exception e) {
            throw new AuraHandledException('Error querying audit packages: ' + e.getMessage());
        }
        
        List<AuditPackageInfo> result = new List<AuditPackageInfo>();
        for (Prometheion_Audit_Package__c pkg : packages) {
            result.add(new AuditPackageInfo(pkg));
        }
        
        return result;
    }
    
    /**
     * Get audit package statistics
     * @param packageId Audit package ID
     * @return Package statistics including evidence count
     */
    @AuraEnabled(cacheable=true)
    public static AuditPackageStats getAuditPackageStats(String packageId) {
        if (String.isBlank(packageId)) {
            throw new AuraHandledException('Package ID cannot be blank');
        }
        
        Prometheion_Audit_Package__c pkg = [
            SELECT Id, Package_Name__c, Framework__c, Status__c,
                   Audit_Period_Start__c, Audit_Period_End__c,
                   Created_By__r.Name, LastModifiedDate
            FROM Prometheion_Audit_Package__c
            WHERE Id = :packageId
            WITH USER_MODE
            LIMIT 1
        ];
        
        // Count framework mappings
        Integer mappingCount = [
            SELECT COUNT()
            FROM Prometheion_Framework_Mapping__c
            WHERE Audit_Package__c = :packageId
            WITH USER_MODE
        ];
        
        // Count evidence items
        Integer evidenceCount = [
            SELECT COUNT()
            FROM Prometheion_Evidence_Item__c
            WHERE Audit_Package__c = :packageId
            WITH USER_MODE
        ];
        
        // Count by status
        AggregateResult[] statusCounts = [
            SELECT Status__c, COUNT(Id) cnt
            FROM Prometheion_Evidence_Item__c
            WHERE Audit_Package__c = :packageId
            WITH USER_MODE
            GROUP BY Status__c
        ];
        
        Map<String, Integer> statusMap = new Map<String, Integer>();
        for (AggregateResult ar : statusCounts) {
            statusMap.put((String)ar.get('Status__c'), (Integer)ar.get('cnt'));
        }
        
        return new AuditPackageStats(pkg, mappingCount, evidenceCount, statusMap);
    }
    
    /**
     * Audit Package Info wrapper
     */
    public class AuditPackageInfo {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String packageName;
        @AuraEnabled public String framework;
        @AuraEnabled public String status;
        @AuraEnabled public Date periodStart;
        @AuraEnabled public Date periodEnd;
        @AuraEnabled public DateTime createdDate;
        @AuraEnabled public String createdBy;
        @AuraEnabled public DateTime lastModified;
        
        public AuditPackageInfo(Prometheion_Audit_Package__c pkg) {
            this.id = pkg.Id;
            this.name = pkg.Name;
            this.packageName = pkg.Package_Name__c;
            this.framework = pkg.Framework__c;
            this.status = pkg.Status__c;
            this.periodStart = pkg.Audit_Period_Start__c;
            this.periodEnd = pkg.Audit_Period_End__c;
            this.createdDate = pkg.CreatedDate;
            this.createdBy = pkg.Created_By__r != null ? pkg.Created_By__r.Name : null;
            this.lastModified = pkg.LastModifiedDate;
        }
    }
    
    /**
     * Audit Package Statistics wrapper
     */
    public class AuditPackageStats {
        @AuraEnabled public String id;
        @AuraEnabled public String packageName;
        @AuraEnabled public String framework;
        @AuraEnabled public String status;
        @AuraEnabled public Date periodStart;
        @AuraEnabled public Date periodEnd;
        @AuraEnabled public Integer mappingCount;
        @AuraEnabled public Integer evidenceCount;
        @AuraEnabled public Map<String, Integer> evidenceByStatus;
        @AuraEnabled public String createdBy;
        @AuraEnabled public DateTime lastModified;
        
        public AuditPackageStats(Prometheion_Audit_Package__c pkg, Integer mappingCount, 
                                Integer evidenceCount, Map<String, Integer> statusMap) {
            this.id = pkg.Id;
            this.packageName = pkg.Package_Name__c;
            this.framework = pkg.Framework__c;
            this.status = pkg.Status__c;
            this.periodStart = pkg.Audit_Period_Start__c;
            this.periodEnd = pkg.Audit_Period_End__c;
            this.mappingCount = mappingCount;
            this.evidenceCount = evidenceCount;
            this.evidenceByStatus = statusMap;
            this.createdBy = pkg.Created_By__r != null ? pkg.Created_By__r.Name : null;
            this.lastModified = pkg.LastModifiedDate;
        }
    }
}
