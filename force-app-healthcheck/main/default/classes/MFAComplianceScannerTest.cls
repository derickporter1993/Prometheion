/**
 * Tests for {@link MFAComplianceScanner} covering the calculation logic directly
 * since LoginHistory is read-only and cannot have test data created.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see MFAComplianceScanner
 */
@IsTest(testFor=MFAComplianceScanner.class)
private class MFAComplianceScannerTest {

    @IsTest
    static void shouldCalculateFullAdoption() {
        Integer result = MFAComplianceScanner.calculateAdoption(100, 100);
        Assert.areEqual(100, result, 'Full MFA adoption should be 100%');
    }

    @IsTest
    static void shouldCalculateZeroAdoption() {
        Integer result = MFAComplianceScanner.calculateAdoption(100, 0);
        Assert.areEqual(0, result, 'Zero MFA logins should be 0%');
    }

    @IsTest
    static void shouldCalculatePartialAdoption() {
        Integer result = MFAComplianceScanner.calculateAdoption(200, 150);
        Assert.areEqual(75, result, '150/200 should be 75%');
    }

    @IsTest
    static void shouldHandleZeroTotalLogins() {
        Integer result = MFAComplianceScanner.calculateAdoption(0, 0);
        Assert.areEqual(0, result, 'Zero total logins should return 0%');
    }

    @IsTest
    static void shouldHandleNullTotalLogins() {
        Integer result = MFAComplianceScanner.calculateAdoption(null, 50);
        Assert.areEqual(0, result, 'Null total logins should return 0%');
    }

    @IsTest
    static void shouldHandleNullMfaLogins() {
        Integer result = MFAComplianceScanner.calculateAdoption(100, null);
        Assert.areEqual(0, result, 'Null MFA logins should be treated as 0');
    }

    @IsTest
    static void shouldRoundCorrectly() {
        Integer result = MFAComplianceScanner.calculateAdoption(3, 1);
        Assert.areEqual(33, result, '1/3 should round to 33%');
    }

    @IsTest
    static void shouldInstantiateScannerAndResultClass() {
        MFAComplianceScanner scanner = new MFAComplianceScanner();
        Assert.isNotNull(scanner, 'Scanner should instantiate');

        MFAComplianceScanner.MFAResult mfaResult = new MFAComplianceScanner.MFAResult();
        Assert.areEqual(0, mfaResult.mfaPercentage, 'Default mfaPercentage should be 0');
        Assert.areEqual(0, mfaResult.totalLogins, 'Default totalLogins should be 0');
        Assert.areEqual(0, mfaResult.mfaLogins, 'Default mfaLogins should be 0');
        Assert.isNotNull(mfaResult.findings, 'Findings list should be initialized');
    }
}
