@isTest
private class PrometheionChangeAdvisorTest {
    
    @isTest
    static void testAnalyzeProposedChange_GrantAdmin() {
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'userCount' => 5
        };
        
        Test.startTest();
        PrometheionChangeAdvisor.ChangeImpact impact = 
            PrometheionChangeAdvisor.analyzeProposedChange('GRANT_ADMIN_PERMISSION', proposedConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, impact, 'Should return impact analysis');
        System.assertNotEquals(null, impact.frameworkImpact, 'Should have framework impact');
        System.assert(impact.overallImpact < 0, 'Should show negative impact');
        System.assertNotEquals(null, impact.alternatives, 'Should provide alternatives');
        System.assert(impact.alternatives.size() > 0, 'Should have at least one alternative');
    }
    
    @isTest
    static void testAnalyzeProposedChange_ModifySharing() {
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'sharingLevel' => 'Public Read/Write'
        };
        
        Test.startTest();
        PrometheionChangeAdvisor.ChangeImpact impact = 
            PrometheionChangeAdvisor.analyzeProposedChange('MODIFY_SHARING_RULE', proposedConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, impact, 'Should return impact analysis');
        System.assert(impact.frameworkImpact.containsKey('HIPAA'), 'Should include HIPAA impact');
    }
    
    @isTest
    static void testAnalyzeProposedChange_AssignPermissionSet() {
        // Create a permission set with Modify All Data
        PermissionSet ps = new PermissionSet(
            Name = 'Test_Modify_All',
            Label = 'Test Modify All'
        );
        insert ps;
        
        // Note: Can't set PermissionsModifyAllData in test, but we can test the logic
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'permissionSetId' => ps.Id
        };
        
        Test.startTest();
        PrometheionChangeAdvisor.ChangeImpact impact = 
            PrometheionChangeAdvisor.analyzeProposedChange('ASSIGN_PERMISSION_SET', proposedConfig);
        Test.stopTest();
        
        System.assertNotEquals(null, impact, 'Should return impact analysis');
    }
}

