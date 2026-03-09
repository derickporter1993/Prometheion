/**
 * Tests for CommandCenterController including context loading, gap updates,
 * severity counts, activity feed, and orchestration integration methods.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Command Center
 * @see CommandCenterController
 * @see OrchestrationService
 */
@IsTest
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
        Assert.isFalse(actions.isEmpty(),
            'Should return actions for SOC2 framework');
        Assert.areEqual('SOC2', actions[0].framework,
            'First action should belong to SOC2 framework');
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

    @IsTest
    static void shouldExecuteCreateCaseAction() {
        Compliance_Gap__c gap = [
            SELECT Id FROM Compliance_Gap__c
            WHERE Status__c = 'OPEN' WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        String caseId = CommandCenterController.executeComplianceAction(
            'CREATE_CASE',
            String.valueOf(gap.Id),
            '{"priority":"High"}'
        );
        Test.stopTest();

        Assert.isNotNull(caseId, 'Should return case ID');

        // Verify case was created
        List<Case> cases = [
            SELECT Id, Priority FROM Case
            WHERE Id = :caseId WITH USER_MODE
        ];
        Assert.areEqual(1, cases.size(), 'Case should be created');
        Assert.areEqual('High', cases[0].Priority, 'Priority should be High');
    }

    @IsTest
    static void shouldHandleExecuteActionWithNullParams() {
        Compliance_Gap__c gap = [
            SELECT Id FROM Compliance_Gap__c
            WHERE Status__c = 'OPEN' WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        String caseId = CommandCenterController.executeComplianceAction(
            'CREATE_CASE',
            String.valueOf(gap.Id),
            null
        );
        Test.stopTest();

        Assert.isNotNull(caseId, 'Should handle null params gracefully');
    }

    @IsTest
    static void shouldRejectUnsupportedActionType() {
        Compliance_Gap__c gap = [
            SELECT Id FROM Compliance_Gap__c
            WHERE Status__c = 'OPEN' WITH USER_MODE LIMIT 1
        ];

        Test.startTest();
        try {
            CommandCenterController.executeComplianceAction(
                'UNSUPPORTED_ACTION',
                String.valueOf(gap.Id),
                '{}'
            );
            Assert.fail('Should throw exception for unsupported action');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('not yet implemented'),
                'Should indicate action is not implemented');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectBlankActionType() {
        Test.startTest();
        try {
            CommandCenterController.executeComplianceAction(
                '',
                'someId',
                '{}'
            );
            Assert.fail('Should throw exception for blank action type');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('required'),
                'Should indicate action type is required');
        }
        Test.stopTest();
    }

    // ═══════════════════════════════════════════════════════════════
    // ORCHESTRATION INTEGRATION TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldTriggerOrchestrationScan() {
        Test.startTest();
        OrchestrationService.ScanResult result =
            CommandCenterController.triggerOrchestrationScan();
        Test.stopTest();

        Assert.isNotNull(result, 'Scan result should not be null');
        Assert.isNotNull(result.scanId, 'Scan ID should be generated');
        Assert.isTrue(result.scanId.startsWith('SCAN-'),
            'Scan ID should have SCAN- prefix');
        Assert.isNotNull(result.frameworkResults,
            'Framework results should not be null');
    }

    @IsTest
    static void shouldTriggerFrameworkScanForSpecificFrameworks() {
        List<String> frameworks = new List<String>{ 'SOC2', 'HIPAA' };

        Test.startTest();
        OrchestrationService.ScanResult result =
            CommandCenterController.triggerFrameworkScan(frameworks);
        Test.stopTest();

        Assert.isNotNull(result, 'Scan result should not be null');
        Assert.areEqual(2, result.requestedFrameworks.size(),
            'Should have 2 requested frameworks');
    }

    @IsTest
    static void shouldRejectNullFrameworksInTriggerFrameworkScan() {
        Test.startTest();
        try {
            CommandCenterController.triggerFrameworkScan(null);
            Assert.fail('Should throw AuraHandledException for null frameworks');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('At least one framework'),
                'Error should indicate frameworks are required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldRejectEmptyFrameworksInTriggerFrameworkScan() {
        Test.startTest();
        try {
            CommandCenterController.triggerFrameworkScan(new List<String>());
            Assert.fail('Should throw AuraHandledException for empty frameworks');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('At least one framework'),
                'Error should indicate frameworks are required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldGetOrchestrationProgress() {
        Test.startTest();
        OrchestrationService.ScanProgress progress =
            CommandCenterController.getOrchestrationProgress('SCAN-TEST-123');
        Test.stopTest();

        Assert.isNotNull(progress, 'Scan progress should not be null');
        Assert.areEqual('SCAN-TEST-123', progress.scanId,
            'Scan ID should match requested ID');
        Assert.isNotNull(progress.status, 'Status should be set');
    }

    @IsTest
    static void shouldRejectBlankScanIdInGetProgress() {
        Test.startTest();
        try {
            CommandCenterController.getOrchestrationProgress('');
            Assert.fail('Should throw AuraHandledException for blank scan ID');
        } catch (AuraHandledException e) {
            Assert.isTrue(e.getMessage().contains('Scan ID is required'),
                'Error should indicate scan ID is required');
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldGetRegisteredFrameworks() {
        Test.startTest();
        List<String> frameworks = CommandCenterController.getRegisteredFrameworks();
        Test.stopTest();

        Assert.isNotNull(frameworks, 'Frameworks list should not be null');
        Assert.isFalse(frameworks.isEmpty(),
            'Should have at least one registered framework');
        // Verify known frameworks are present
        Set<String> frameworkSet = new Set<String>(frameworks);
        Assert.isTrue(frameworkSet.contains('HIPAA'),
            'Should contain HIPAA framework');
        Assert.isTrue(frameworkSet.contains('SOC2'),
            'Should contain SOC2 framework');
    }

    @IsTest
    static void shouldIncludeOrchestrationDataInContext() {
        Test.startTest();
        ComplianceContextEngine.ComplianceContext ctx =
            CommandCenterController.getComplianceContext();
        Test.stopTest();

        Assert.isNotNull(ctx.lastScanTimestamp,
            'Last scan timestamp should be populated from orchestration data');
        Assert.isNotNull(ctx.registeredFrameworks,
            'Registered frameworks should be populated from orchestration data');
        Assert.isFalse(ctx.registeredFrameworks.isEmpty(),
            'Registered frameworks should not be empty');
    }
}
