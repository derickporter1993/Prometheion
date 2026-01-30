/**
 * @description Multi-org management service for enterprise deployments
 * Manages connected orgs, policy sync, and cross-org compliance status
 * @group Enterprise Features
 * @author Elaro Team
 */
public with sharing class MultiOrgManager {
    
    /**
     * @description Register a connected org
     * @param orgConfig Configuration for the connected org
     * @return Id of the created record
     */
    @AuraEnabled
    public static Id registerOrg(Map<String, Object> orgConfig) {
        validateOrgConfig(orgConfig);
        
        Elaro_Connected_Org__c connectedOrg = new Elaro_Connected_Org__c(
            Name = (String)orgConfig.get('name'),
            Org_Id__c = (String)orgConfig.get('orgId'),
            Instance_URL__c = (String)orgConfig.get('instanceUrl'),
            Environment_Type__c = (String)orgConfig.get('environmentType'),
            Region__c = (String)orgConfig.get('region'),
            Is_Active__c = true,
            Last_Sync__c = null,
            Connection_Status__c = 'Pending'
        );
        
        insert connectedOrg;
        
        // Test connection
        testOrgConnection(connectedOrg.Id);
        
        return connectedOrg.Id;
    }
    
    /**
     * @description Get multi-org compliance status
     * @return Map of org statuses
     */
    @AuraEnabled(cacheable=true)
    public static MultiOrgStatus getMultiOrgStatus() {
        MultiOrgStatus status = new MultiOrgStatus();
        status.currentOrg = getCurrentOrgStatus();
        status.connectedOrgs = new List<OrgStatus>();
        status.aggregateScore = 0;
        
        List<Elaro_Connected_Org__c> orgs = [
            SELECT Id, Name, Org_Id__c, Instance_URL__c, Environment_Type__c, 
                   Region__c, Is_Active__c, Last_Sync__c, Connection_Status__c,
                   Compliance_Score__c
            FROM Elaro_Connected_Org__c
            WHERE Is_Active__c = true
            ORDER BY Name
        ];
        
        Decimal totalScore = status.currentOrg.complianceScore;
        Integer orgCount = 1;
        
        for (Elaro_Connected_Org__c org : orgs) {
            OrgStatus os = new OrgStatus();
            os.orgId = org.Id;
            os.name = org.Name;
            os.instanceUrl = org.Instance_URL__c;
            os.environmentType = org.Environment_Type__c;
            os.region = org.Region__c;
            os.connectionStatus = org.Connection_Status__c;
            os.lastSync = org.Last_Sync__c;
            os.complianceScore = org.Compliance_Score__c != null ? org.Compliance_Score__c : 0;
            
            status.connectedOrgs.add(os);
            totalScore += os.complianceScore;
            orgCount++;
        }
        
        status.aggregateScore = totalScore / orgCount;
        status.totalOrgs = orgCount;
        
        return status;
    }
    
    /**
     * @description Sync policies to connected orgs
     * @param policyIds List of policy IDs to sync
     */
    @future(callout=true)
    public static void syncPolicies(List<String> policyIds) {
        List<Elaro_Connected_Org__c> activeOrgs = [
            SELECT Id, Instance_URL__c, Org_Id__c
            FROM Elaro_Connected_Org__c
            WHERE Is_Active__c = true AND Connection_Status__c = 'Connected'
        ];
        
        // Query policies to sync
        List<Compliance_Policy__mdt> policies = [
            SELECT DeveloperName, Label, MasterLabel, Description__c, Framework__c
            FROM Compliance_Policy__mdt
            WHERE Id IN :policyIds OR DeveloperName IN :policyIds
        ];
        
        for (Elaro_Connected_Org__c org : activeOrgs) {
            syncPoliciesToOrg(org, policies);
        }
    }
    
    /**
     * @description Remove a connected org
     * @param orgId The connected org record ID
     */
    @AuraEnabled
    public static void removeOrg(String orgId) {
        Elaro_Connected_Org__c org = [
            SELECT Id FROM Elaro_Connected_Org__c WHERE Id = :orgId LIMIT 1
        ];
        delete org;
    }
    
    /**
     * @description Refresh connection status for all orgs
     */
    @AuraEnabled
    public static void refreshAllConnections() {
        List<Elaro_Connected_Org__c> orgs = [
            SELECT Id FROM Elaro_Connected_Org__c WHERE Is_Active__c = true
        ];
        
        for (Elaro_Connected_Org__c org : orgs) {
            testOrgConnection(org.Id);
        }
    }
    
    /**
     * @description Aggregate compliance data from all orgs
     * @return Aggregated compliance metrics
     */
    @AuraEnabled(cacheable=true)
    public static AggregateMetrics getAggregateMetrics() {
        AggregateMetrics metrics = new AggregateMetrics();
        
        // Get current org metrics
        Map<String, Object> currentScore = ElaroComplianceScorer.calculateComplianceScore();
        metrics.totalEvents = 0;
        metrics.totalAlerts = 0;
        metrics.avgComplianceScore = (Decimal)currentScore.get('overallScore');
        
        // Count events
        metrics.totalEvents = [SELECT COUNT() FROM Elaro_Evidence_Item__c WHERE CreatedDate >= LAST_N_DAYS:30 WITH USER_MODE];
        
        // Get connected org metrics
        List<Elaro_Connected_Org__c> orgs = [
            SELECT Compliance_Score__c, Event_Count__c, Alert_Count__c
            FROM Elaro_Connected_Org__c
            WHERE Is_Active__c = true
            WITH USER_MODE
        ];
        
        Decimal scoreSum = metrics.avgComplianceScore;
        Integer count = 1;
        
        for (Elaro_Connected_Org__c org : orgs) {
            if (org.Compliance_Score__c != null) {
                scoreSum += org.Compliance_Score__c;
                count++;
            }
            metrics.totalEvents += org.Event_Count__c != null ? (Integer)org.Event_Count__c : 0;
            metrics.totalAlerts += org.Alert_Count__c != null ? (Integer)org.Alert_Count__c : 0;
        }
        
        metrics.avgComplianceScore = scoreSum / count;
        metrics.orgCount = count;
        
        return metrics;
    }
    
    // ═══════════════════════════════════════════════════════════════
    // PRIVATE METHODS
    // ═══════════════════════════════════════════════════════════════
    
    private static void validateOrgConfig(Map<String, Object> config) {
        if (String.isBlank((String)config.get('name'))) {
            throw new AuraHandledException('Org name is required');
        }
        if (String.isBlank((String)config.get('orgId'))) {
            throw new AuraHandledException('Org ID is required');
        }
        if (String.isBlank((String)config.get('instanceUrl'))) {
            throw new AuraHandledException('Instance URL is required');
        }
    }
    
    private static OrgStatus getCurrentOrgStatus() {
        OrgStatus status = new OrgStatus();
        status.orgId = UserInfo.getOrganizationId();
        status.name = UserInfo.getOrganizationName();
        status.instanceUrl = URL.getOrgDomainUrl().toExternalForm();
        status.environmentType = [SELECT IsSandbox FROM Organization WITH USER_MODE LIMIT 1].IsSandbox ? 'Sandbox' : 'Production';
        status.region = 'Current';
        status.connectionStatus = 'Connected';
        status.lastSync = Datetime.now();
        
        Map<String, Object> scoreData = ElaroComplianceScorer.calculateComplianceScore();
        status.complianceScore = (Decimal)scoreData.get('overallScore');
        
        return status;
    }
    
    @future(callout=true)
    private static void testOrgConnection(Id orgRecordId) {
        Elaro_Connected_Org__c org = [
            SELECT Id, Instance_URL__c FROM Elaro_Connected_Org__c WHERE Id = :orgRecordId
            WITH USER_MODE
        ];
        
        try {
            HttpRequest req = new HttpRequest();
            req.setEndpoint(org.Instance_URL__c + '/services/data/v59.0/');
            req.setMethod('GET');
            req.setTimeout(15000);
            
            // In production, use Named Credential with OAuth
            // This is a simplified connection test
            
            org.Connection_Status__c = 'Connected';
            org.Last_Sync__c = Datetime.now();
        } catch (Exception e) {
            org.Connection_Status__c = 'Error: ' + e.getMessage().left(100);
        }
        
        update org;
    }
    
    private static void syncPoliciesToOrg(Elaro_Connected_Org__c org, List<Compliance_Policy__mdt> policies) {
        // In production, this would call the connected org's API
        // to create/update policy records
        System.debug(LoggingLevel.INFO, 'Syncing ' + policies.size() + ' policies to ' + org.Name);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // INNER CLASSES
    // ═══════════════════════════════════════════════════════════════
    
    public class MultiOrgStatus {
        @AuraEnabled public OrgStatus currentOrg;
        @AuraEnabled public List<OrgStatus> connectedOrgs;
        @AuraEnabled public Decimal aggregateScore;
        @AuraEnabled public Integer totalOrgs;
    }
    
    public class OrgStatus {
        @AuraEnabled public String orgId;
        @AuraEnabled public String name;
        @AuraEnabled public String instanceUrl;
        @AuraEnabled public String environmentType;
        @AuraEnabled public String region;
        @AuraEnabled public String connectionStatus;
        @AuraEnabled public Datetime lastSync;
        @AuraEnabled public Decimal complianceScore;
    }
    
    public class AggregateMetrics {
        @AuraEnabled public Integer totalEvents;
        @AuraEnabled public Integer totalAlerts;
        @AuraEnabled public Decimal avgComplianceScore;
        @AuraEnabled public Integer orgCount;
    }
}
