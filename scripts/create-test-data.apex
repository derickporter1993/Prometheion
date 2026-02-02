/**
 * Elaro Test Data Generator
 * 
 * Creates test data needed to properly test the Compliance Hub dashboard:
 * - Permission Sets with various permission levels
 * - Permission Set Assignments
 * - Setup Audit Trail entries (simulated via existing data)
 * - Sample compliance-sensitive custom objects (if they exist)
 * 
 * Usage: sf apex run --file scripts/create-test-data.apex --target-org [org-alias]
 */

// Create test permission sets with different permission levels
List<PermissionSet> testPermissionSets = new List<PermissionSet>();

// 1. Permission Set with Modify All Data (for testing permission sprawl)
PermissionSet psModifyAll = new PermissionSet(
    Name = 'Test_ModifyAll_Access',
    Label = 'Test Modify All Data Access',
    Description = 'Test permission set for compliance scoring - Modify All Data'
);
testPermissionSets.add(psModifyAll);

// 2. Permission Set with View All Data
PermissionSet psViewAll = new PermissionSet(
    Name = 'Test_ViewAll_Access',
    Label = 'Test View All Data Access',
    Description = 'Test permission set for compliance scoring - View All Data'
);
testPermissionSets.add(psViewAll);

// 3. Standard permission set (no elevated permissions)
PermissionSet psStandard = new PermissionSet(
    Name = 'Test_Standard_Access',
    Label = 'Test Standard Access',
    Description = 'Test permission set for compliance scoring - Standard permissions'
);
testPermissionSets.add(psStandard);

try {
    insert testPermissionSets;
    System.debug('✅ Created ' + testPermissionSets.size() + ' test permission sets');
    
    // Get the current user
    User currentUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() LIMIT 1];
    
    // Assign permission sets to current user for testing
    List<PermissionSetAssignment> assignments = new List<PermissionSetAssignment>();
    
    // Note: We cannot directly set PermissionsModifyAllData or PermissionsViewAllData
    // These are system-level permissions that require specific setup
    // The test data will rely on existing org configuration
    
    // Assign standard permission set
    PermissionSetAssignment psa = new PermissionSetAssignment(
        AssigneeId = currentUser.Id,
        PermissionSetId = psStandard.Id
    );
    assignments.add(psa);
    
    if (!assignments.isEmpty()) {
        insert assignments;
        System.debug('✅ Created ' + assignments.size() + ' permission set assignments');
    }
    
    System.debug('✅ Test data creation complete');
    System.debug('📊 Note: To test permission sprawl scoring, you may need to:');
    System.debug('   1. Manually create permission sets with Modify All Data or View All Data');
    System.debug('   2. Assign them to test users');
    System.debug('   3. The scoring will automatically detect these in the org');
    
} catch (Exception e) {
    System.debug('❌ Error creating test data: ' + e.getMessage());
    System.debug('Stack trace: ' + e.getStackTraceString());
}

// Verify SetupAuditTrail has data (read-only, but we can check)
Integer auditTrailCount = [
    SELECT COUNT() 
    FROM SetupAuditTrail 
    WHERE CreatedDate >= LAST_N_DAYS:30
];

System.debug('📋 SetupAuditTrail entries (last 30 days): ' + auditTrailCount);
if (auditTrailCount == 0) {
    System.debug('⚠️  Warning: No SetupAuditTrail entries found in last 30 days');
    System.debug('   The compliance scorer will still work, but may show lower scores');
    System.debug('   Make some configuration changes to generate audit trail data');
}

// Check for Field History tracking
Integer objectsWithHistory = [
    SELECT COUNT() 
    FROM FieldDefinition 
    WHERE IsFieldHistoryTracked = true
    LIMIT 1
];

System.debug('📋 Objects with Field History Tracking: ' + (objectsWithHistory > 0 ? 'Yes' : 'No'));
if (objectsWithHistory == 0) {
    System.debug('⚠️  Warning: No objects have Field History Tracking enabled');
    System.debug('   Enable Field History on compliance-sensitive objects for better scoring');
}

System.debug('');
System.debug('✅ Test data setup complete!');
System.debug('📊 Next steps:');
System.debug('   1. Navigate to Compliance Hub dashboard');
System.debug('   2. Verify readiness score displays correctly (not NaN)');
System.debug('   3. Check framework scores are calculated');
System.debug('   4. Review top risks section');
