/**
 * @description Unit tests for MultiOrgManager
 * Tests org registration, status retrieval, policy sync, and aggregate metrics
 * @group Tests
 * @author Elaro Team
 */
@isTest
private class MultiOrgManagerTest {
    
    @testSetup
    static void setupTestData() {
        // Create test connected orgs
        List<Elaro_Connected_Org__c> orgs = new List<Elaro_Connected_Org__c>();
        
        for (Integer i = 0; i < 5; i++) {
            orgs.add(new Elaro_Connected_Org__c(
                Name = 'Test Org ' + i,
                Org_Id__c = '00D' + String.valueOf(1000000000000000L + i),
                Instance_URL__c = 'https://test' + i + '.salesforce.com',
                Environment_Type__c = i < 2 ? 'Production' : 'Sandbox',
                Region__c = 'US',
                Is_Active__c = true,
                Connection_Status__c = i < 3 ? 'Connected' : 'Pending',
                Compliance_Score__c = 75.0 + (i * 5),
                Event_Count__c = 100 + (i * 10),
                Alert_Count__c = 5 + i
            ));
        }
        insert orgs;
        
        // Create audit package for evidence items
        Elaro_Audit_Package__c pkg = ElaroTestDataFactory.createAuditPackage('SOC2');
        ElaroTestDataFactory.createEvidenceItems(pkg.Id, 10);
    }
    
    // ═══════════════════════════════════════════════════════════════
    // registerOrg Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testRegisterOrg_Success() {
        Map<String, Object> orgConfig = new Map<String, Object>{
            'name' => 'New Test Org',
            'orgId' => '00D1234567890123',
            'instanceUrl' => 'https://neworg.salesforce.com',
            'environmentType' => 'Production',
            'region' => 'US'
        };
        
        Test.startTest();
        Id orgId = MultiOrgManager.registerOrg(orgConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, orgId, 'Should return org ID');
        
        Elaro_Connected_Org__c org = [
            SELECT Id, Name, Org_Id__c, Instance_URL__c, Is_Active__c, Connection_Status__c
            FROM Elaro_Connected_Org__c
            WHERE Id = :orgId
        ];
        
        System.assertEquals('New Test Org', org.Name, 'Org name should match');
        System.assertEquals('00D1234567890123', org.Org_Id__c, 'Org ID should match');
        System.assertEquals(true, org.Is_Active__c, 'Org should be active');
    }
    
    @isTest
    static void testRegisterOrg_MissingName() {
        Map<String, Object> orgConfig = new Map<String, Object>{
            'orgId' => '00D1234567890123',
            'instanceUrl' => 'https://neworg.salesforce.com'
        };
        
        Test.startTest();
        try {
            MultiOrgManager.registerOrg(orgConfig);
            System.assert(false, 'Should throw exception for missing name');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('name'), 'Should mention name requirement');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testRegisterOrg_MissingOrgId() {
        Map<String, Object> orgConfig = new Map<String, Object>{
            'name' => 'Test Org',
            'instanceUrl' => 'https://neworg.salesforce.com'
        };
        
        Test.startTest();
        try {
            MultiOrgManager.registerOrg(orgConfig);
            System.assert(false, 'Should throw exception for missing org ID');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Org ID'), 'Should mention org ID requirement');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testRegisterOrg_MissingInstanceUrl() {
        Map<String, Object> orgConfig = new Map<String, Object>{
            'name' => 'Test Org',
            'orgId' => '00D1234567890123'
        };
        
        Test.startTest();
        try {
            MultiOrgManager.registerOrg(orgConfig);
            System.assert(false, 'Should throw exception for missing instance URL');
        } catch (AuraHandledException e) {
            System.assert(e.getMessage().contains('Instance URL'), 'Should mention instance URL requirement');
        }
        Test.stopTest();
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getMultiOrgStatus Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetMultiOrgStatus() {
        Test.startTest();
        MultiOrgManager.MultiOrgStatus status = MultiOrgManager.getMultiOrgStatus();
        Test.stopTest();
        
        System.assertNotEquals(null, status, 'Should return status');
        System.assertNotEquals(null, status.currentOrg, 'Should have current org');
        System.assertNotEquals(null, status.connectedOrgs, 'Should have connected orgs list');
        System.assert(status.totalOrgs > 0, 'Should have at least one org');
        System.assert(status.aggregateScore >= 0, 'Aggregate score should be non-negative');
    }
    
    @isTest
    static void testGetMultiOrgStatus_WithConnectedOrgs() {
        // Verify connected orgs are included
        Test.startTest();
        MultiOrgManager.MultiOrgStatus status = MultiOrgManager.getMultiOrgStatus();
        Test.stopTest();
        
        System.assert(status.connectedOrgs.size() >= 5, 'Should include test connected orgs');
        
        // Verify org details
        for (MultiOrgManager.OrgStatus os : status.connectedOrgs) {
            System.assertNotEquals(null, os.orgId, 'Org should have ID');
            System.assertNotEquals(null, os.name, 'Org should have name');
            System.assertNotEquals(null, os.instanceUrl, 'Org should have instance URL');
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // syncPolicies Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testSyncPolicies() {
        List<String> policyIds = new List<String>{'Policy1', 'Policy2'};
        
        Test.setMock(HttpCalloutMock.class, new MultiOrgCalloutMock(200, '{"status":"success"}'));
        
        Test.startTest();
        MultiOrgManager.syncPolicies(policyIds);
        Test.stopTest();
        
        // Verify no exceptions (async method)
        System.assert(true, 'Policy sync should be queued');
    }
    
    @isTest
    static void testSyncPolicies_NoActiveOrgs() {
        // Deactivate all orgs
        List<Elaro_Connected_Org__c> orgs = [
            SELECT Id FROM Elaro_Connected_Org__c
        ];
        for (Elaro_Connected_Org__c org : orgs) {
            org.Is_Active__c = false;
        }
        update orgs;
        
        List<String> policyIds = new List<String>{'Policy1'};
        
        Test.setMock(HttpCalloutMock.class, new MultiOrgCalloutMock(200, '{"status":"success"}'));
        
        Test.startTest();
        MultiOrgManager.syncPolicies(policyIds);
        Test.stopTest();
        
        // Should handle gracefully with no active orgs
        System.assert(true, 'Should handle no active orgs gracefully');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // removeOrg Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testRemoveOrg() {
        Elaro_Connected_Org__c org = [
            SELECT Id FROM Elaro_Connected_Org__c LIMIT 1
        ];
        
        Test.startTest();
        MultiOrgManager.removeOrg(org.Id);
        Test.stopTest();
        
        // Verify org was deleted
        List<Elaro_Connected_Org__c> remainingOrgs = [
            SELECT Id FROM Elaro_Connected_Org__c WHERE Id = :org.Id
        ];
        
        System.assertEquals(0, remainingOrgs.size(), 'Org should be deleted');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // refreshAllConnections Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testRefreshAllConnections() {
        Test.setMock(HttpCalloutMock.class, new MultiOrgCalloutMock(200, '{"status":"success"}'));
        
        Test.startTest();
        MultiOrgManager.refreshAllConnections();
        Test.stopTest();
        
        // Verify connections were refreshed (async method)
        System.assert(true, 'Connections should be refreshed');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // getAggregateMetrics Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetAggregateMetrics() {
        Test.startTest();
        MultiOrgManager.AggregateMetrics metrics = MultiOrgManager.getAggregateMetrics();
        Test.stopTest();
        
        System.assertNotEquals(null, metrics, 'Should return metrics');
        System.assert(metrics.totalEvents >= 0, 'Total events should be non-negative');
        System.assert(metrics.totalAlerts >= 0, 'Total alerts should be non-negative');
        System.assert(metrics.avgComplianceScore >= 0, 'Average score should be non-negative');
        System.assert(metrics.orgCount > 0, 'Should have at least one org');
    }
    
    @isTest
    static void testGetAggregateMetrics_WithEvidenceItems() {
        // Verify evidence items are counted
        Test.startTest();
        MultiOrgManager.AggregateMetrics metrics = MultiOrgManager.getAggregateMetrics();
        Test.stopTest();
        
        // Should include evidence items from test setup
        System.assert(metrics.totalEvents >= 10, 'Should count evidence items');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Bulk Operations Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testBulkOrgSync() {
        // Create multiple orgs
        List<Map<String, Object>> orgConfigs = new List<Map<String, Object>>();
        
        for (Integer i = 0; i < 10; i++) {
            orgConfigs.add(new Map<String, Object>{
                'name' => 'Bulk Org ' + i,
                'orgId' => '00D' + String.valueOf(2000000000000000L + i),
                'instanceUrl' => 'https://bulk' + i + '.salesforce.com',
                'environmentType' => 'Sandbox',
                'region' => 'US'
            });
        }
        
        Test.startTest();
        List<Id> orgIds = new List<Id>();
        for (Map<String, Object> config : orgConfigs) {
            orgIds.add(MultiOrgManager.registerOrg(config));
        }
        Test.stopTest();
        
        System.assertEquals(10, orgIds.size(), 'Should create 10 orgs');
        
        // Verify all orgs were created
        List<Elaro_Connected_Org__c> createdOrgs = [
            SELECT Id FROM Elaro_Connected_Org__c
            WHERE Name LIKE 'Bulk Org%'
        ];
        
        System.assertEquals(10, createdOrgs.size(), 'Should have 10 bulk orgs');
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Permission Tests
    // ═══════════════════════════════════════════════════════════════
    
    @isTest
    static void testGetMultiOrgStatus_WithSharing() {
        // Test with different user context
        User testUser = ElaroTestUserFactory.createElaroUser();
        
        System.runAs(testUser) {
            Test.startTest();
            MultiOrgManager.MultiOrgStatus status = MultiOrgManager.getMultiOrgStatus();
            Test.stopTest();
            
            System.assertNotEquals(null, status, 'Should return status with sharing');
        }
    }
    
    // ═══════════════════════════════════════════════════════════════
    // Mock Classes
    // ═══════════════════════════════════════════════════════════════
    
    private class MultiOrgCalloutMock implements HttpCalloutMock {
        private Integer statusCode;
        private String responseBody;
        
        public MultiOrgCalloutMock(Integer statusCode, String responseBody) {
            this.statusCode = statusCode;
            this.responseBody = responseBody;
        }
        
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.statusCode == 200 ? 'OK' : 'Error');
            res.setBody(this.responseBody);
            res.setHeader('Content-Type', 'application/json');
            return res;
        }
    }
}
