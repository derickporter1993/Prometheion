/**
 * Tests for {@link ProfilePermissionScanner} covering detection of over-provisioned
 * permissions. Tests run against actual org PermissionSets since this is a read-only scan.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ProfilePermissionScanner
 */
@IsTest(testFor=ProfilePermissionScanner.class)
private class ProfilePermissionScannerTest {

    @IsTest
    static void shouldReturnResultWithValidScore() {
        Test.startTest();
        ProfilePermissionScanner.PermissionResult result =
            new ProfilePermissionScanner().scan();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.score >= 0 && result.score <= 100,
            'Score should be between 0 and 100, got: ' + result.score);
        Assert.isNotNull(result.findings, 'Findings list should not be null');
    }

    @IsTest
    static void shouldNotFlagSystemAdminProfile() {
        Test.startTest();
        ProfilePermissionScanner.PermissionResult result =
            new ProfilePermissionScanner().scan();
        Test.stopTest();

        for (ScanFinding finding : result.findings) {
            Assert.isFalse(
                finding.setting.contains('System Administrator'),
                'System Administrator should not be flagged: ' + finding.setting
            );
        }
    }

    @IsTest
    static void shouldSetCategoryToPermissions() {
        Test.startTest();
        ProfilePermissionScanner.PermissionResult result =
            new ProfilePermissionScanner().scan();
        Test.stopTest();

        for (ScanFinding finding : result.findings) {
            Assert.areEqual('Permissions', finding.category,
                'Category should be Permissions');
        }
    }

    @IsTest
    static void shouldInitializeResultDefaults() {
        ProfilePermissionScanner.PermissionResult result =
            new ProfilePermissionScanner.PermissionResult();
        Assert.areEqual(100, result.score, 'Default score should be 100');
        Assert.isNotNull(result.findings, 'Findings should be initialized');
        Assert.isTrue(result.findings.isEmpty(), 'Findings should start empty');
    }
}
