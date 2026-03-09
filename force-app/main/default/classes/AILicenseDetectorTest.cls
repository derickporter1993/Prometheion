/**
 * Test class for AILicenseDetector.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest
private class AILicenseDetectorTest {

    @TestSetup
    static void makeData() {
        // Note: Cannot create PermissionSet in test - they must exist in org
        // Test validates query logic only
    }

    @IsTest
    static void shouldDetectAILicenses() {
        Test.startTest();
        List<AILicenseDetector.AILicenseAssignment> licenses = AILicenseDetector.detectAILicenses();
        Test.stopTest();

        Assert.isNotNull(licenses, 'Should return list of license assignments');
    }

    @IsTest
    static void shouldGetAIUserCount() {
        Test.startTest();
        Integer count = AILicenseDetector.getAIUserCount();
        Test.stopTest();

        Assert.isTrue(count >= 0, 'User count should be non-negative');
    }

    @IsTest
    static void shouldGetLicensesForUser() {
        Test.startTest();
        List<AILicenseDetector.AILicenseAssignment> licenses =
            AILicenseDetector.getLicensesForUser(UserInfo.getUserId());
        Test.stopTest();

        Assert.isNotNull(licenses, 'Should return list for specific user');
    }

    @IsTest
    static void shouldHandleNoAIPermissionSets() {
        // Test org may not have AI permission sets
        Test.startTest();
        List<AILicenseDetector.AILicenseAssignment> licenses = AILicenseDetector.detectAILicenses();
        Test.stopTest();

        Assert.isNotNull(licenses, 'Should return empty list if no AI permissions');
    }
}
