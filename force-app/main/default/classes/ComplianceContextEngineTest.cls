/**
 * Tests for ComplianceContextEngine including framework summary aggregation,
 * overview calculation, action loading, gap retrieval, and orchestration
 * data enrichment.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Command Center
 * @see ComplianceContextEngine
 * @see OrchestrationService
 */
@IsTest(testFor=ComplianceContextEngine.class)
private class ComplianceContextEngineTest {

    @TestSetup
    static void makeData() {
        // Create compliance gaps across frameworks
        List<Compliance_Gap__c> gaps = new List<Compliance_Gap__c>();
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_CC6.1',
            Gap_Description__c = 'MFA not enforced',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Detected_Date__c = Datetime.now()
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'SOC2',
            Policy_Reference__c = 'SOC2_CC7.2',
            Gap_Description__c = 'Access logs not reviewed',
            Severity__c = 'HIGH',
            Status__c = 'IN_PROGRESS',
            Detected_Date__c = Datetime.now().addDays(-5)
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'HIPAA',
            Policy_Reference__c = 'HIPAA_164.312',
            Gap_Description__c = 'PHI not encrypted',
            Severity__c = 'CRITICAL',
            Status__c = 'OPEN',
            Detected_Date__c = Datetime.now().addDays(-2)
        ));
        gaps.add(new Compliance_Gap__c(
            Framework__c = 'GDPR',
            Policy_Reference__c = 'GDPR_Art33',
            Gap_Description__c = 'Breach notification not configured',
            Severity__c = 'HIGH',
            Status__c = 'REMEDIATED',
            Detected_Date__c = Datetime.now().addDays(-30),
            Actual_Remediation_Date__c = Date.today().addDays(-10)
        ));
        insert as user gaps;

        // Create a compliance score record
        Compliance_Score__c score = new Compliance_Score__c(
            Org_ID__c = UserInfo.getOrganizationId(),
            Entity_Type__c = 'Organization',
            Entity_Id__c = UserInfo.getOrganizationId(),
            Risk_Score__c = 3.5,
            Framework_Scores__c = '{"SOC2": 72, "HIPAA": 55, "GDPR": 81}',
            Calculated_At__c = Datetime.now()
        );
        insert as user score;
    }

    @IsTest
    static void shouldBuildFullContext() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        Assert.isNotNull(ctx, 'Context should not be null');
        Assert.isNotNull(ctx.contextTimestamp, 'Timestamp should be set');
        Assert.isNotNull(ctx.overview, 'Overview should not be null');
        Assert.isNotNull(ctx.frameworkSummaries, 'Framework summaries should not be null');
        Assert.isNotNull(ctx.recentGaps, 'Recent gaps should not be null');
        Assert.isNotNull(ctx.prioritizedActions, 'Prioritized actions should not be null');
    }

    @IsTest
    static void shouldBuildFrameworkSummariesFromScores() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        Assert.isTrue(ctx.frameworkSummaries.size() >= 3,
            'Should have at least 3 framework summaries (SOC2, HIPAA, GDPR), got: '
            + ctx.frameworkSummaries.size());

        // Verify scores were parsed
        Boolean foundSoc2 = false;
        for (ComplianceContextEngine.FrameworkSummary fs : ctx.frameworkSummaries) {
            if (fs.framework == 'SOC2') {
                foundSoc2 = true;
                Assert.areEqual(72, fs.score, 'SOC2 score should be 72');
            }
        }
        Assert.isTrue(foundSoc2, 'Should find SOC2 in framework summaries');
    }

    @IsTest
    static void shouldCalculateOverviewMetrics() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        ComplianceContextEngine.ComplianceOverview ov = ctx.overview;
        Assert.isTrue(ov.overallScore >= 0 && ov.overallScore <= 100,
            'Overall score should be 0-100, got: ' + ov.overallScore);
        Assert.isTrue(ov.totalGaps >= 4, 'Should have at least 4 total gaps');
        Assert.isTrue(ov.criticalGaps >= 2, 'Should have at least 2 critical gaps');
        Assert.isTrue(ov.openGaps >= 2, 'Should have at least 2 open gaps');
        Assert.isNotNull(ov.riskRating, 'Risk rating should not be null');
    }

    @IsTest
    static void shouldLoadRecentGaps() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        // Only OPEN and IN_PROGRESS gaps should appear
        Assert.isTrue(ctx.recentGaps.size() >= 3,
            'Should have at least 3 recent open/in-progress gaps, got: ' + ctx.recentGaps.size());

        for (ComplianceContextEngine.GapSummary gs : ctx.recentGaps) {
            Assert.isTrue(
                gs.status == 'OPEN' || gs.status == 'IN_PROGRESS',
                'Recent gaps should only be OPEN or IN_PROGRESS, got: ' + gs.status
            );
            Assert.isNotNull(gs.gapId, 'Gap ID should not be null');
            Assert.isNotNull(gs.framework, 'Framework should not be null');
        }
    }

    @IsTest
    static void shouldLoadPrioritizedActionsFromMetadata() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        List<ComplianceContextEngine.ComplianceActionItem> actions = engine.getActionsByFramework('SOC2');
        Test.stopTest();

        // Actions come from Compliance_Action__mdt — count depends on deployed records
        Assert.isNotNull(actions, 'Actions list should not be null');
    }

    @IsTest
    static void shouldHandleEmptyOrg() {
        // Delete all test data
        delete as user [SELECT Id FROM Compliance_Gap__c WITH USER_MODE];
        delete as user [SELECT Id FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        Assert.isNotNull(ctx, 'Context should not be null even with no data');
        Assert.areEqual(0, ctx.overview.overallScore, 'Score should be 0 with no data');
        Assert.areEqual(0, ctx.overview.totalGaps, 'Total gaps should be 0');
        Assert.isTrue(ctx.recentGaps.isEmpty(), 'Recent gaps should be empty');
    }

    @IsTest
    static void shouldHandleMalformedFrameworkScores() {
        // Update score to have malformed JSON
        Compliance_Score__c score = [
            SELECT Id, Framework_Scores__c FROM Compliance_Score__c WITH USER_MODE LIMIT 1
        ];
        score.Framework_Scores__c = 'not-valid-json';
        update as user score;

        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        // Should not throw — gracefully degrades
        Assert.isNotNull(ctx, 'Context should handle malformed JSON gracefully');
        Assert.areEqual(0, ctx.overview.overallScore,
            'Score should be 0 when JSON is malformed');
    }

    // ═══════════════════════════════════════════════════════════════
    // ORCHESTRATION ENRICHMENT TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldEnrichContextWithOrchestrationData() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        // lastScanTimestamp should be set because we have Compliance_Score__c data
        Assert.isNotNull(ctx.lastScanTimestamp,
            'Last scan timestamp should be populated from Compliance_Score__c');

        // registeredFrameworks should come from ComplianceServiceFactory
        Assert.isNotNull(ctx.registeredFrameworks,
            'Registered frameworks should not be null');
        Assert.isFalse(ctx.registeredFrameworks.isEmpty(),
            'Registered frameworks should contain entries from ComplianceServiceFactory');

        // Verify known frameworks are in the list
        Set<String> fwSet = new Set<String>(ctx.registeredFrameworks);
        Assert.isTrue(fwSet.contains('HIPAA'),
            'Registered frameworks should include HIPAA');
        Assert.isTrue(fwSet.contains('SOC2'),
            'Registered frameworks should include SOC2');
    }

    @IsTest
    static void shouldHandleOrchestrationEnrichmentWithNoScores() {
        delete as user [SELECT Id FROM Compliance_Score__c WITH USER_MODE];

        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        ComplianceContextEngine.ComplianceContext ctx = engine.buildContext();
        Test.stopTest();

        // lastScanTimestamp should be null when no scores exist
        Assert.isNull(ctx.lastScanTimestamp,
            'Last scan timestamp should be null when no Compliance_Score__c records exist');

        // registeredFrameworks should still be populated from ComplianceServiceFactory
        Assert.isNotNull(ctx.registeredFrameworks,
            'Registered frameworks should not be null even without scores');
        Assert.isFalse(ctx.registeredFrameworks.isEmpty(),
            'Registered frameworks should still be populated from factory');
    }

    // ═══════════════════════════════════════════════════════════════
    // DTO DEFAULT TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldInitializeDTODefaults() {
        ComplianceContextEngine.ComplianceContext ctx = new ComplianceContextEngine.ComplianceContext();
        Assert.isNotNull(ctx.frameworkSummaries, 'frameworkSummaries should default to empty list');
        Assert.isNotNull(ctx.prioritizedActions, 'prioritizedActions should default to empty list');
        Assert.isNotNull(ctx.recentGaps, 'recentGaps should default to empty list');
        Assert.isNotNull(ctx.overview, 'overview should default to new instance');
        Assert.isNotNull(ctx.registeredFrameworks,
            'registeredFrameworks should default to empty list');

        ComplianceContextEngine.ComplianceOverview ov = new ComplianceContextEngine.ComplianceOverview();
        Assert.areEqual(0, ov.overallScore, 'overallScore should default to 0');
        Assert.areEqual(0, ov.totalGaps, 'totalGaps should default to 0');

        ComplianceContextEngine.FrameworkSummary fs = new ComplianceContextEngine.FrameworkSummary();
        Assert.areEqual(0, fs.score, 'score should default to 0');
        Assert.areEqual('Unknown', fs.status, 'status should default to Unknown');

        ComplianceContextEngine.ComplianceActionItem item = new ComplianceContextEngine.ComplianceActionItem();
        Assert.isTrue(item.isRelevant, 'isRelevant should default to true');

        ComplianceContextEngine.GapSummary gs = new ComplianceContextEngine.GapSummary();
        Assert.isNull(gs.gapId, 'gapId should default to null');
    }

    // ═══════════════════════════════════════════════════════════════
    // PLATFORM CACHE TESTS
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void shouldReturnActionsFromCacheOnSecondCall() {
        Test.startTest();
        ComplianceContextEngine engine = new ComplianceContextEngine();
        // First call populates cache
        ComplianceContextEngine.ComplianceContext ctx1 = engine.buildContext();
        // Second call should read from cache
        ComplianceContextEngine.ComplianceContext ctx2 = engine.buildContext();
        Test.stopTest();

        Assert.isNotNull(ctx1.prioritizedActions,
            'First call should return actions');
        Assert.isNotNull(ctx2.prioritizedActions,
            'Second call should return actions from cache');
        Assert.areEqual(ctx1.prioritizedActions.size(), ctx2.prioritizedActions.size(),
            'Cached actions should match original actions count');
    }
}
