@IsTest(testFor=ElaroChangeAdvisor.class)
private class ElaroChangeAdvisorTest {
    
    @isTest
    static void testAnalyzeProposedChange_GrantAdmin() {
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'userCount' => 5
        };
        
        Test.startTest();
        ElaroChangeAdvisor.ChangeImpact impact = 
            ElaroChangeAdvisor.analyzeProposedChange('GRANT_ADMIN_PERMISSION', proposedConfig);
        Test.stopTest();
        
        Assert.areNotEqual(null, impact, 'Should return impact analysis');
        Assert.areNotEqual(null, impact.frameworkImpact, 'Should have framework impact');
        Assert.isTrue(impact.overallImpact < 0, 'Should show negative impact');
        Assert.areNotEqual(null, impact.alternatives, 'Should provide alternatives');
        Assert.isTrue(!impact.alternatives.isEmpty(), 'Should have at least one alternative');
    }
    
    @isTest
    static void testAnalyzeProposedChange_ModifySharing() {
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'sharingLevel' => 'Public Read/Write'
        };
        
        Test.startTest();
        ElaroChangeAdvisor.ChangeImpact impact = 
            ElaroChangeAdvisor.analyzeProposedChange('MODIFY_SHARING_RULE', proposedConfig);
        Test.stopTest();
        
        Assert.areNotEqual(null, impact, 'Should return impact analysis');
        Assert.isTrue(impact.frameworkImpact.containsKey('HIPAA'), 'Should include HIPAA impact');
    }
    
    @isTest
    static void testAnalyzeProposedChange_AssignPermissionSet() {
        // Create a permission set with Modify All Data
        PermissionSet ps = new PermissionSet(
            Name = 'Test_Modify_All',
            Label = 'Test Modify All'
        );
        insert as user ps;
        
        // Note: Can't set PermissionsModifyAllData in test, but we can test the logic
        Map<String, Object> proposedConfig = new Map<String, Object>{
            'permissionSetId' => ps.Id
        };
        
        Test.startTest();
        ElaroChangeAdvisor.ChangeImpact impact = 
            ElaroChangeAdvisor.analyzeProposedChange('ASSIGN_PERMISSION_SET', proposedConfig);
        Test.stopTest();
        
        Assert.areNotEqual(null, impact, 'Should return impact analysis');
    }
}

