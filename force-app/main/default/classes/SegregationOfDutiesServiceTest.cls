/**
 * SegregationOfDutiesServiceTest
 * 
 * Test class for SegregationOfDutiesService
 * 
 * @author Elaro
 * @version 1.0
 */
@IsTest(testFor=SegregationOfDutiesService.class)
private class SegregationOfDutiesServiceTest {
    
    @TestSetup
    static void setupTestData() {
        // Create test user
        User testUser = ComplianceTestDataFactory.createTestUser();
        insert testUser;
        
        // Create permission sets
        PermissionSet ps1 = new PermissionSet(Name = 'TestPS_Create', Label = 'Test PS Create');
        PermissionSet ps2 = new PermissionSet(Name = 'TestPS_ModifyAll', Label = 'Test PS Modify All');
        insert new List<PermissionSet>{ps1, ps2};
        
        // Assign permission sets to user
        insert new List<PermissionSetAssignment>{
            new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps1.Id),
            new PermissionSetAssignment(AssigneeId = testUser.Id, PermissionSetId = ps2.Id)
        };
    }
    
    @IsTest
    static void testDetectViolations_NoViolations() {
        User testUser = [SELECT Id FROM User WHERE Email LIKE '%@elaro.test' LIMIT 1];
        
        Test.startTest();
        List<SegregationOfDutiesService.SoDViolation> violations = 
            SegregationOfDutiesService.detectViolations(testUser.Id);
        Test.stopTest();
        
        // Should return empty list if no violations (permission sets don't have object permissions in test)
        Assert.areNotEqual(null, violations, 'Violations list should not be null');
    }
    
    @IsTest
    static void testDetectViolations_NullUserId() {
        Test.startTest();
        try {
            SegregationOfDutiesService.detectViolations(null);
            Assert.fail( 'Should have thrown IllegalArgumentException');
        } catch (IllegalArgumentException e) {
            Assert.isNotNull(e.getMessage(), 'Expected exception for null user ID should have a message');
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testRemediateViolation() {
        Test.startTest();
        String result = SegregationOfDutiesService.remediateViolation(
            UserInfo.getUserId(), 
            'test-violation-id', 
            'Remove conflicting permission'
        );
        Test.stopTest();
        
        Assert.areNotEqual(null, result, 'Result should not be null');
        Assert.isTrue(result.contains('remediated'), 'Result should indicate remediation');
    }
}
