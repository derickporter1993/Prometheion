/**
 * Tests for CommandCenterController including context loading, gap updates,
 * severity counts, and activity feed.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Command Center
 * @see CommandCenterController
 */
@IsTest(testFor=CommandCenterController.class)
private class CommandCenterControllerTest {

    @TestSetup
    static void makeData() {
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_CC6.1',
            Gap_Description__c = 'MFA not enforced for admin users',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Detected_Date__c = Datetime.now()
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_164.312',
            Gap_Description__c = 'PHI encryption gap',
            Severity__c = 'HIGH',
            Status__c = 'IN_PROGRESS',
            Detected_Date__c = Datetime.now().addDays(-3)
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'GDPR',
            Policy_Reference__c = 'GDPR_Art5',
            Gap_Description__c = 'Data retention policy missing',
            Severity__c = 'MEDIUM',
            Status__c = 'OPEN',
            Detected_Date__c = Datetime.now().addDays(-7)
        ));
        insert as user gaps;

        Compliance_Score__c score = new Compliance_Score__c(
            Org_ID__c = UserInfo.getOrganizationId(),
            Entity_Type__c = 'Organization',
            Entity_Id__c = UserInfo.getOrganizationId(),
            Risk_Score__c = 4.2,
            Framework_Scores__c = '{"SOC2": 68, "HIPAA": 52, "GDPR": 77}',
            Calculated_At__c = Datetime.now()
        );
        insert as user score;
    }

    @IsTest
    static void shouldGetComplianceContext() {
        Test.startTest();
        ComplianceContextEngine.ComplianceContext ctx =
            CommandCenterController.getComplianceContext();
        Test.stopTest();

        Assert.isNotNull(ctx, 'Context should not be null');
        Assert.isNotNull(ctx.overview, 'Overview should not be null');
        Assert.isTrue(ctx.overview.overallScore >= 0,
            'Overall score should be non-negative');
        Assert.isTrue(ctx.frameworkSummaries.size() >= 3,
            'Should have framework summaries');
    }

    @IsTest
    static void shouldGetActionsByFramework() {
        Test.startTest();
        List<ComplianceContextEngine.ComplianceActionItem> actions =
            CommandCenterController.getActionsByFramework('SOC2');
        Test.stopTest();

        Assert.isNotNull(actions, 'Actions should not be null');
        // Depends on CMT records deployed, so just verify no exception
    }

    @IsTest
    static void shouldUpdateGapStatus() {
        Compliance_Gap__c gap = [
            SELECT Id, Status__c FROM Compliance_Gap__c
            WHERE Status__c = 'OPEN' WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        CommandCenterController.updateGapStatus(gap.Id, 'REMEDIATED');
        Test.stopTest();

        Compliance_Gap__c updated = [
            SELECT Id, Status__c, Actual_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id WITH USER_MODE
        ];
        Assert.areEqual('REMEDIATED', updated.Status__c,
            'Status should be updated to REMEDIATED');
        Assert.areEqual(Date.today(), updated.Actual_Remediation_Date__c,
            'Remediation date should be set to today');
    }

    @IsTest
    static void shouldUpdateGapToInProgress() {
        Compliance_Gap__c gap = [
            SELECT Id FROM Compliance_Gap__c
            WHERE Status__c = 'OPEN' WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        CommandCenterController.updateGapStatus(gap.Id, 'IN_PROGRESS');
        Test.stopTest();

        Compliance_Gap__c updated = [
            SELECT Id, Status__c, Actual_Remediation_Date__c
            FROM Compliance_Gap__c
            WHERE Id = :gap.Id WITH USER_MODE
        ];
        Assert.areEqual('IN_PROGRESS', updated.Status__c, 'Status should be IN_PROGRESS');
        Assert.isNull(updated.Actual_Remediation_Date__c,
            'Remediation date should not be set for IN_PROGRESS');
    }

    @IsTest
    static void shouldGetGapCountsBySeverity() {
        Test.startTest();
        Map<String, Integer> counts = CommandCenterController.getGapCountsBySeverity();
        Test.stopTest();

        Assert.isNotNull(counts, 'Counts map should not be null');
        Assert.isTrue(counts.containsKey('CRITICAL'), 'Should have CRITICAL count');
        Assert.areEqual(1, counts.get('CRITICAL'), 'Should have 1 CRITICAL gap');
    }

    @IsTest
    static void shouldGetRecentActivity() {
        Test.startTest();
        List<CommandCenterController.ActivityItem> items =
            CommandCenterController.getRecentActivity(10);
        Test.stopTest();

        Assert.isNotNull(items, 'Activity items should not be null');
        Assert.isTrue(items.size() >= 3, 'Should have at least 3 activity items');

        // Verify sorted by timestamp descending
        if (items.size() >= 2) {
            Assert.isTrue(
                items[0].timestamp >= items[1].timestamp,
                'Items should be sorted most recent first'
            );
        }
    }

    @IsTest
    static void shouldLimitRecentActivity() {
        Test.startTest();
        List<CommandCenterController.ActivityItem> items =
            CommandCenterController.getRecentActivity(1);
        Test.stopTest();

        Assert.areEqual(1, items.size(), 'Should respect limit parameter');
    }

    @IsTest
    static void shouldHandleNullLimitInRecentActivity() {
        Test.startTest();
        List<CommandCenterController.ActivityItem> items =
            CommandCenterController.getRecentActivity(null);
        Test.stopTest();

        Assert.isNotNull(items, 'Should handle null limit gracefully');
    }

    @IsTest
    static void shouldSortActivityItemsByTimestamp() {
        CommandCenterController.ActivityItem older = new CommandCenterController.ActivityItem();
        older.timestamp = Datetime.now().addDays(-5);

        CommandCenterController.ActivityItem newer = new CommandCenterController.ActivityItem();
        newer.timestamp = Datetime.now();

        CommandCenterController.ActivityItem nullTime = new CommandCenterController.ActivityItem();

        // newer.compareTo(older) should be negative (newer sorts before older)
        Assert.isTrue(newer.compareTo(older) < 0,
            'Newer item should sort before older');
        Assert.isTrue(older.compareTo(newer) > 0,
            'Older item should sort after newer');
        Assert.areEqual(0, newer.compareTo(newer),
            'Same item should compare equal');
        Assert.isTrue(nullTime.compareTo(newer) > 0,
            'Null timestamp should sort after valid timestamp');
    }

    @IsTest
    static void shouldHandleGetContextWithNoData() {
        delete as user [SELECT Id FROM Compliance_Gap__c WITH USER_MODE];
        delete as user [SELECT Id FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        ComplianceContextEngine.ComplianceContext ctx =
            CommandCenterController.getComplianceContext();
        Test.stopTest();

        Assert.isNotNull(ctx, 'Should return context even with no data');
        Assert.areEqual(0, ctx.overview.totalGaps, 'Should have 0 gaps');
    }
}
