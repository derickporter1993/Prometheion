/**
 * Tests for {@link AuditTrailScanner} covering high-risk section classification
 * and result defaults. SetupAuditTrail is read-only so classification logic
 * is tested via the extracted static method.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see AuditTrailScanner
 */
@IsTest(testFor=AuditTrailScanner.class)
private class AuditTrailScannerTest {

    @IsTest
    static void shouldClassifyHighRiskSections() {
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Manage Users'),
            'Manage Users should be high risk'
        );
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Security Controls'),
            'Security Controls should be high risk'
        );
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Sharing Rules'),
            'Sharing Rules should be high risk'
        );
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Permission Sets'),
            'Permission Sets should be high risk'
        );
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Session Settings'),
            'Session Settings should be high risk'
        );
        Assert.isTrue(
            AuditTrailScanner.isHighRiskSection('Connected Apps'),
            'Connected Apps should be high risk'
        );
    }

    @IsTest
    static void shouldClassifyNonHighRiskSections() {
        Assert.isFalse(
            AuditTrailScanner.isHighRiskSection('Reports'),
            'Reports should not be high risk'
        );
        Assert.isFalse(
            AuditTrailScanner.isHighRiskSection('Custom Objects'),
            'Custom Objects should not be high risk'
        );
        Assert.isFalse(
            AuditTrailScanner.isHighRiskSection('Workflow'),
            'Workflow should not be high risk'
        );
    }

    @IsTest
    static void shouldHandleNullSection() {
        Assert.isFalse(
            AuditTrailScanner.isHighRiskSection(null),
            'Null section should return false'
        );
    }

    @IsTest
    static void shouldHandleEmptySection() {
        Assert.isFalse(
            AuditTrailScanner.isHighRiskSection(''),
            'Empty section should return false'
        );
    }

    @IsTest
    static void shouldInitializeResultDefaults() {
        AuditTrailScanner.AuditResult result = new AuditTrailScanner.AuditResult();
        Assert.areEqual(100, result.score, 'Default score should be 100');
        Assert.isNotNull(result.findings, 'Findings should be initialized');
        Assert.isTrue(result.findings.isEmpty(), 'Findings should start empty');
    }

    @IsTest
    static void shouldScanWithoutError() {
        Test.startTest();
        AuditTrailScanner.AuditResult result = new AuditTrailScanner().scan();
        Test.stopTest();

        Assert.isNotNull(result, 'Result should not be null');
        Assert.isTrue(result.score >= 0 && result.score <= 100,
            'Score should be between 0 and 100, got: ' + result.score);
    }
}
