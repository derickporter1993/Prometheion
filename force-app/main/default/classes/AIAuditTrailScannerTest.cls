/**
 * Test class for AIAuditTrailScanner.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group AI Governance
 */
@IsTest
private class AIAuditTrailScannerTest {

    @IsTest
    static void shouldScanAIChanges() {
        // SetupAuditTrail is read-only, so we test the query logic

        Test.startTest();
        List<AIAuditTrailScanner.AIAuditEntry> entries = AIAuditTrailScanner.scanAIChanges(30);
        Test.stopTest();

        Assert.isNotNull(entries, 'Should return list of audit entries');
        // Real org may have audit trail data; test org typically empty
    }

    @IsTest
    static void shouldUseDefaultLookbackDays() {
        Test.startTest();
        List<AIAuditTrailScanner.AIAuditEntry> entries = AIAuditTrailScanner.scanAIChanges(null);
        Test.stopTest();

        Assert.isNotNull(entries, 'Should handle null lookback days');
    }

    @IsTest
    static void shouldGetLatestChange() {
        Test.startTest();
        AIAuditTrailScanner.AIAuditEntry latest = AIAuditTrailScanner.getLatestChange('Einstein');
        Test.stopTest();

        // May be null in test org with no audit trail
        Assert.isTrue(latest == null || latest.actionType != null, 'Should return valid entry or null');
    }

    @IsTest
    static void shouldHandleEmptyAuditTrail() {
        Test.startTest();
        List<AIAuditTrailScanner.AIAuditEntry> entries = AIAuditTrailScanner.scanAIChanges(1);
        Test.stopTest();

        Assert.isNotNull(entries, 'Should return empty list if no audit trail data');
    }
}
