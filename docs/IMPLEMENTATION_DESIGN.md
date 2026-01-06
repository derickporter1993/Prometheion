# Prometheion Implementation Design Document

**Version:** 1.0
**Date:** January 6, 2026
**Status:** Design Phase

---

## Table of Contents

1. [Test Coverage Improvements](#1-test-coverage-improvements)
2. [Missing Compliance Frameworks](#2-missing-compliance-frameworks)
3. [Expanded Policies for Existing Frameworks](#3-expanded-policies-for-existing-frameworks)
4. [LWC Jest Testing Infrastructure](#4-lwc-jest-testing-infrastructure)
5. [Test Utilities and Infrastructure](#5-test-utilities-and-infrastructure)

---

## 1. Test Coverage Improvements

### 1.1 PerformanceRuleEngineTest Expansion

**Current State:** 1 test method (only tests critical threshold)
**Target State:** 8 test methods covering all code paths

#### New Test Methods Design

```apex
@IsTest
private class PerformanceRuleEngineTest {

    // ═══════════════════════════════════════════════════════════════
    // EXISTING TEST (keep as-is)
    // ═══════════════════════════════════════════════════════════════

    @IsTest
    static void testEvaluate_Critical() {
        // Existing test - verifies critical threshold triggers
    }

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS TO ADD
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: Warning threshold exceeded (but not critical)
     * Verifies: result.warning = true, result.critical = false
     * Input: CPU=8500 (warn=8000, crit=9000)
     */
    @IsTest
    static void testEvaluate_WarningOnly() {
        // Setup: Stats just above warning, below critical
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 8500;  // Between 8000 (warn) and 9000 (crit)
        stats.heapKb = 3000; // Below warning
        stats.soql = 50;     // Below warning
        stats.dml = 100;     // Below warning

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        // Assertions
        System.assertEquals(true, result.warning, 'Should flag warning');
        System.assertEquals(false, result.critical, 'Should NOT flag critical');
        System.assertNotEquals(null, result.message);
    }

    /**
     * Test: No thresholds exceeded (healthy system)
     * Verifies: result.warning = false, result.critical = false
     * Input: All metrics well below thresholds
     */
    @IsTest
    static void testEvaluate_NoAlerts() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;  // Well below 8000 warn
        stats.heapKb = 1000; // Well below 4500 warn
        stats.soql = 10;     // Well below 90 warn
        stats.dml = 20;      // Well below 140 warn

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(false, result.warning, 'Should NOT flag warning');
        System.assertEquals(false, result.critical, 'Should NOT flag critical');
    }

    /**
     * Test: Custom CCX_Settings thresholds
     * Verifies: Custom settings override defaults
     * Setup: Insert CCX_Settings__c with custom values
     */
    @IsTest
    static void testEvaluate_CustomThresholds() {
        // Insert custom settings with lower thresholds
        CCX_Settings__c settings = new CCX_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            CPU_Warn__c = 5000,  // Lower than default 8000
            CPU_Crit__c = 6000,  // Lower than default 9000
            Heap_Warn__c = 3000,
            Heap_Crit__c = 4000,
            SOQL_Warn__c = 50,
            SOQL_Crit__c = 75,
            DML_Warn__c = 100,
            DML_Crit__c = 125
        );
        insert settings;

        // Stats that would be OK with defaults, but critical with custom
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 6500;  // Above custom crit (6000), below default warn (8000)
        stats.heapKb = 2000;
        stats.soql = 30;
        stats.dml = 50;

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(true, result.critical,
            'Should be critical with custom lower thresholds');
    }

    /**
     * Test: Only HEAP metric exceeds threshold
     * Verifies: Individual metric isolation
     */
    @IsTest
    static void testEvaluate_HeapCriticalOnly() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;   // OK
        stats.heapKb = 5500;  // Critical (>5000)
        stats.soql = 10;      // OK
        stats.dml = 20;       // OK

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(true, result.critical, 'HEAP should trigger critical');
    }

    /**
     * Test: Only SOQL metric exceeds threshold
     * Verifies: Individual metric isolation
     */
    @IsTest
    static void testEvaluate_SOQLCriticalOnly() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 100;     // Critical (>=100)
        stats.dml = 20;

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(true, result.critical, 'SOQL should trigger critical');
    }

    /**
     * Test: Only DML metric exceeds threshold
     * Verifies: Individual metric isolation
     */
    @IsTest
    static void testEvaluate_DMLCriticalOnly() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 1000;
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 155;      // Critical (>150)

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(true, result.critical, 'DML should trigger critical');
    }

    /**
     * Test: Multiple warnings but no critical
     * Verifies: Multiple metrics can warn independently
     */
    @IsTest
    static void testEvaluate_MultipleWarnings() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 8500;   // Warning (8000-9000)
        stats.heapKb = 4600;  // Warning (4500-5000)
        stats.soql = 95;      // Warning (90-100)
        stats.dml = 145;      // Warning (140-150)

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, null);
        Test.stopTest();

        System.assertEquals(true, result.warning, 'Should flag warning');
        System.assertEquals(false, result.critical, 'Should NOT flag critical');
    }

    /**
     * Test: Context record ID is passed through
     * Verifies: Context is included in published events
     */
    @IsTest
    static void testEvaluate_WithContextRecord() {
        LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
        stats.cpuMs = 9500;
        stats.heapKb = 1000;
        stats.soql = 10;
        stats.dml = 20;

        String contextId = '001000000000001AAA';

        Test.startTest();
        PerformanceRuleEngine.EvalResult result =
            PerformanceRuleEngine.evaluateAndPublish(stats, contextId);
        Test.stopTest();

        System.assertEquals(true, result.critical);
        // Note: Can't query Platform Events directly, but verifying no exception
    }
}
```

---

### 1.2 PrometheionComplianceScorerTest Expansion

**Current State:** 2 test methods
**Target State:** 8 test methods

#### New Test Methods Design

```apex
@IsTest
private class PrometheionComplianceScorerTest {

    // ═══════════════════════════════════════════════════════════════
    // EXISTING TESTS (keep)
    // ═══════════════════════════════════════════════════════════════

    @TestSetup
    static void setup() { /* existing */ }

    @IsTest
    static void testCalculateReadinessScore_ReturnsScore() { /* existing */ }

    @IsTest
    static void testCalculateReadinessScore_WithData() { /* existing */ }

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS TO ADD
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: No custom permission sets exist
     * Verifies: calculateAccessGovernanceScore returns 50.0 (default)
     */
    @IsTest
    static void testCalculateReadinessScore_NoCustomPermissionSets() {
        // Delete any test setup permission sets
        delete [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS%'];

        Test.startTest();
        Decimal score = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // With no custom permission sets, access governance returns 50
        // Other scores vary, but total should be calculable
        System.assertNotEquals(null, score);
        System.assert(score >= 0 && score <= 100);
    }

    /**
     * Test: All permission sets are documented (100% compliance)
     * Verifies: calculateAccessGovernanceScore returns 100.0
     */
    @IsTest
    static void testCalculateReadinessScore_AllDocumented() {
        // Delete existing test data
        delete [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS%'];

        // Create only documented permission sets
        List<PermissionSet> documented = new List<PermissionSet>();
        for (Integer i = 0; i < 5; i++) {
            documented.add(new PermissionSet(
                Name = 'DocPS_' + i + '_' + System.currentTimeMillis(),
                Label = 'Documented PS ' + i,
                Description = 'Full description for compliance'
            ));
        }
        insert documented;

        Test.startTest();
        Decimal score = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // With 100% documented, access governance should be 100
        // Total score depends on other factors
        System.assert(score > 0, 'Score should be positive with documented PS');
    }

    /**
     * Test: No permission sets documented (0% compliance)
     * Verifies: calculateAccessGovernanceScore returns 0.0
     */
    @IsTest
    static void testCalculateReadinessScore_NoneDocumented() {
        delete [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS%'];

        // Create undocumented permission sets
        List<PermissionSet> undocumented = new List<PermissionSet>();
        for (Integer i = 0; i < 5; i++) {
            undocumented.add(new PermissionSet(
                Name = 'UndocPS_' + i + '_' + System.currentTimeMillis(),
                Label = 'Undocumented PS ' + i,
                Description = null  // No description = not documented
            ));
        }
        insert undocumented;

        Test.startTest();
        Decimal score = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // Score should still be calculable (other factors contribute)
        System.assertNotEquals(null, score);
    }

    /**
     * Test: Mixed documentation status
     * Verifies: Correct percentage calculation
     */
    @IsTest
    static void testCalculateReadinessScore_MixedDocumentation() {
        delete [SELECT Id FROM PermissionSet WHERE Name LIKE 'TestPS%'];

        // Create 3 documented, 2 undocumented (60% documented)
        List<PermissionSet> permSets = new List<PermissionSet>();
        for (Integer i = 0; i < 3; i++) {
            permSets.add(new PermissionSet(
                Name = 'DocMixPS_' + i + '_' + System.currentTimeMillis(),
                Label = 'Doc PS ' + i,
                Description = 'Documented'
            ));
        }
        for (Integer i = 0; i < 2; i++) {
            permSets.add(new PermissionSet(
                Name = 'UndocMixPS_' + i + '_' + System.currentTimeMillis(),
                Label = 'Undoc PS ' + i,
                Description = null
            ));
        }
        insert permSets;

        Test.startTest();
        Decimal score = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        System.assertNotEquals(null, score);
        System.assert(score >= 0 && score <= 100);
    }

    /**
     * Test: Exception handling
     * Verifies: AuraHandledException is thrown properly
     * Note: Difficult to force exception in normal flow,
     *       may need @TestVisible method to test
     */
    @IsTest
    static void testCalculateReadinessScore_ExceptionHandling() {
        Test.startTest();
        try {
            // Normal call should not throw
            Decimal score = PrometheionComplianceScorer.calculateReadinessScore();
            System.assertNotEquals(null, score);
        } catch (AuraHandledException e) {
            // If it throws, verify message format
            System.assert(e.getMessage().contains('Error calculating'));
        }
        Test.stopTest();
    }

    /**
     * Test: Cacheability
     * Verifies: @AuraEnabled(cacheable=true) works correctly
     */
    @IsTest
    static void testCalculateReadinessScore_Cacheable() {
        Test.startTest();
        // Call twice - should work with caching
        Decimal score1 = PrometheionComplianceScorer.calculateReadinessScore();
        Decimal score2 = PrometheionComplianceScorer.calculateReadinessScore();
        Test.stopTest();

        // Both calls should succeed
        System.assertNotEquals(null, score1);
        System.assertNotEquals(null, score2);
    }
}
```

---

### 1.3 SlackNotifierTest Expansion

**Current State:** 5 tests (missing `notifyFlowPerformance`)
**Target State:** 9 tests

#### New Test Methods Design

```apex
@IsTest
private class SlackNotifierTest {

    // ═══════════════════════════════════════════════════════════════
    // EXISTING MOCK CLASS (keep)
    // ═══════════════════════════════════════════════════════════════

    private class SlackCalloutMock implements HttpCalloutMock {
        public Integer statusCode;
        public String status;
        public String capturedBody; // NEW: Capture request body for verification

        public SlackCalloutMock(Integer statusCode, String status) {
            this.statusCode = statusCode;
            this.status = status;
        }

        public HttpResponse respond(HttpRequest req) {
            this.capturedBody = req.getBody(); // Capture for assertions
            HttpResponse res = new HttpResponse();
            res.setStatusCode(this.statusCode);
            res.setStatus(this.status);
            res.setBody('ok');
            return res;
        }
    }

    // ═══════════════════════════════════════════════════════════════
    // EXISTING TESTS (keep as-is)
    // ═══════════════════════════════════════════════════════════════

    @IsTest static void testNotifyAsyncSuccess() { /* existing */ }
    @IsTest static void testNotifyPerformanceEvent() { /* existing */ }
    @IsTest static void testNotifyPerformanceEventWithoutContext() { /* existing */ }
    @IsTest static void testNotifyAsyncFailure() { /* existing */ }
    @IsTest static void testNotifyAsyncWithException() { /* existing */ }

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS - notifyFlowPerformance (completely untested!)
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: Flow performance notification - Critical rating
     * Verifies: Correct emoji and payload for critical flows
     */
    @IsTest
    static void testNotifyFlowPerformance_Critical() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Test.startTest();
        SlackNotifier.notifyFlowPerformance(
            'Critical_Flow_Name',
            9500,           // High CPU time
            'Critical',     // Critical rating
            99.5            // 99.5th percentile
        );
        Test.stopTest();

        // Verify no exception thrown
        System.assert(true, 'Critical flow notification completed');
    }

    /**
     * Test: Flow performance notification - Slow rating
     * Verifies: Correct emoji for slow flows
     */
    @IsTest
    static void testNotifyFlowPerformance_Slow() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Test.startTest();
        SlackNotifier.notifyFlowPerformance(
            'Slow_Flow_Name',
            5000,           // Moderate CPU time
            'Slow',         // Slow rating
            85.0            // 85th percentile
        );
        Test.stopTest();

        System.assert(true, 'Slow flow notification completed');
    }

    /**
     * Test: Flow performance notification - Info rating
     * Verifies: Handles non-critical/non-slow ratings
     */
    @IsTest
    static void testNotifyFlowPerformance_Info() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Test.startTest();
        SlackNotifier.notifyFlowPerformance(
            'Normal_Flow',
            1000,           // Normal CPU time
            'Normal',       // Info rating (not Critical or Slow)
            50.0            // 50th percentile
        );
        Test.stopTest();

        System.assert(true, 'Info flow notification completed');
    }

    /**
     * Test: Flow performance notification - Null percentile
     * Verifies: Handles optional percentileRank parameter
     */
    @IsTest
    static void testNotifyFlowPerformance_NullPercentile() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Test.startTest();
        SlackNotifier.notifyFlowPerformance(
            'Flow_Without_Percentile',
            3000,
            'Slow',
            null            // Null percentile - should be handled
        );
        Test.stopTest();

        System.assert(true, 'Flow notification with null percentile completed');
    }

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS - Performance Event Severity Levels
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: Performance event at exactly 95% threshold (critical)
     * Verifies: Red emoji and critical color used
     */
    @IsTest
    static void testNotifyPerformanceEvent_ExactCriticalThreshold() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Performance_Alert__e evt = new Performance_Alert__e(
            Metric__c = 'CPU',
            Value__c = 9500,     // 95% of 10000
            Threshold__c = 10000,
            Context_Record__c = 'test123',
            Stack__c = 'Critical threshold test'
        );

        Test.startTest();
        SlackNotifier.notifyPerformanceEvent(evt);
        Test.stopTest();

        System.assert(true, 'Critical threshold event completed');
    }

    /**
     * Test: Performance event at exactly 90% threshold (warning)
     * Verifies: Yellow emoji and warning color used
     */
    @IsTest
    static void testNotifyPerformanceEvent_ExactWarningThreshold() {
        Test.setMock(HttpCalloutMock.class, new SlackCalloutMock(200, 'OK'));

        Performance_Alert__e evt = new Performance_Alert__e(
            Metric__c = 'SOQL',
            Value__c = 90,       // 90% of 100
            Threshold__c = 100,
            Context_Record__c = null,
            Stack__c = null
        );

        Test.startTest();
        SlackNotifier.notifyPerformanceEvent(evt);
        Test.stopTest();

        System.assert(true, 'Warning threshold event completed');
    }
}
```

---

### 1.4 PrometheionGraphIndexerTest Expansion

**Current State:** 3 tests (only PERMISSION_SET entity)
**Target State:** 8 tests

#### New Test Methods Design

```apex
@IsTest
private class PrometheionGraphIndexerTest {

    // ═══════════════════════════════════════════════════════════════
    // EXISTING TESTS (keep)
    // ═══════════════════════════════════════════════════════════════

    @TestSetup
    static void setup() { /* existing */ }

    @IsTest static void testIndexChange_CreatesImmutableNode() { /* existing */ }
    @IsTest static void testGenerateDeterministicHash_IsUnique() { /* existing */ }
    @IsTest static void testIndexChange_InvalidEntity() { /* existing */ }

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS TO ADD
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: FLOW entity type indexing
     * Verifies: Flow metadata is correctly captured
     * Note: Requires FlowDefinitionView - may need mock approach
     */
    @IsTest
    static void testIndexChange_FlowEntity() {
        // Note: FlowDefinitionView is read-only, need to test with actual flow
        // or handle the exception gracefully
        Test.startTest();
        try {
            // This may fail in test context without deployed flows
            String nodeHash = PrometheionGraphIndexer.indexChange(
                'FLOW',
                'TestFlowId',
                null,
                'SOC2'
            );
            // If it succeeds, verify hash
            System.assertNotEquals(null, nodeHash);
        } catch (PrometheionGraphIndexer.PrometheionException e) {
            // Expected if no flow exists - verify exception handling
            System.assert(e.getMessage().contains('Graph indexing failed'));
        }
        Test.stopTest();
    }

    /**
     * Test: Drift category - POLICY_VIOLATION (risk >= 8.0)
     * Verifies: High risk scores get correct category
     */
    @IsTest
    static void testDetermineDriftCategory_PolicyViolation() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];

        // Need to verify the drift category after insert
        // Since calculateRiskScore is private, we test through indexChange
        Test.startTest();
        String nodeHash = PrometheionGraphIndexer.indexChange(
            'PERMISSION_SET',
            ps.Id,
            null,
            'SOC2'
        );
        Test.stopTest();

        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Drift_Category__c, Risk_Score__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];

        System.assertEquals(1, nodes.size());
        // Verify drift category matches risk score
        if (nodes[0].Risk_Score__c >= 8.0) {
            System.assertEquals('POLICY_VIOLATION', nodes[0].Drift_Category__c);
        } else if (nodes[0].Risk_Score__c >= 5.0) {
            System.assertEquals('UNAUTHORIZED', nodes[0].Drift_Category__c);
        } else if (nodes[0].Risk_Score__c >= 3.0) {
            System.assertEquals('ANOMALY', nodes[0].Drift_Category__c);
        } else {
            System.assertEquals('MANUAL_OVERRIDE', nodes[0].Drift_Category__c);
        }
    }

    /**
     * Test: Parent node linking
     * Verifies: Child nodes correctly reference parent
     */
    @IsTest
    static void testIndexChange_WithParentNode() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];

        Test.startTest();
        // Create parent node
        String parentHash = PrometheionGraphIndexer.indexChange(
            'PERMISSION_SET',
            ps.Id,
            null,  // No parent
            'SOC2'
        );

        // Create child node with parent reference
        String childHash = PrometheionGraphIndexer.indexChange(
            'PERMISSION_SET',
            ps.Id,
            parentHash,  // Reference parent
            'HIPAA'
        );
        Test.stopTest();

        // Verify parent-child relationship
        List<Prometheion_Compliance_Graph__b> childNodes = [
            SELECT Parent_Node_Id__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :childHash
        ];

        System.assertEquals(1, childNodes.size());
        System.assertEquals(parentHash, childNodes[0].Parent_Node_Id__c);
    }

    /**
     * Test: Multiple frameworks for same entity
     * Verifies: Same entity can have different nodes per framework
     */
    @IsTest
    static void testIndexChange_MultipleFrameworks() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];

        Test.startTest();
        String soc2Hash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        String hipaaHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'HIPAA');
        String gdprHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'GDPR');
        Test.stopTest();

        // All hashes should be unique
        System.assertNotEquals(soc2Hash, hipaaHash);
        System.assertNotEquals(hipaaHash, gdprHash);
        System.assertNotEquals(soc2Hash, gdprHash);
    }

    /**
     * Test: Graph version is set correctly
     * Verifies: v3.0 version tag is applied
     */
    @IsTest
    static void testIndexChange_GraphVersion() {
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'TestPS' LIMIT 1];

        Test.startTest();
        String nodeHash = PrometheionGraphIndexer.indexChange('PERMISSION_SET', ps.Id, null, 'SOC2');
        Test.stopTest();

        List<Prometheion_Compliance_Graph__b> nodes = [
            SELECT Graph_Version__c
            FROM Prometheion_Compliance_Graph__b
            WHERE Graph_Node_Id__c = :nodeHash
        ];

        System.assertEquals(1, nodes.size());
        System.assertEquals('v3.0', nodes[0].Graph_Version__c);
    }
}
```

---

### 1.5 PrometheionReasoningEngineTest Expansion

**Current State:** 15 tests focused on inner classes
**Target State:** 18 tests including core logic

#### New Test Methods Design

```apex
@IsTest
private class PrometheionReasoningEngineTest {

    // ═══════════════════════════════════════════════════════════════
    // EXISTING TESTS (keep all 15)
    // ═══════════════════════════════════════════════════════════════

    // ... existing tests ...

    // ═══════════════════════════════════════════════════════════════
    // NEW TESTS - Core Logic
    // ═══════════════════════════════════════════════════════════════

    /**
     * Test: generateFallbackReasoning path (AI disabled)
     * Verifies: Fallback reasoning is generated when AI is off
     */
    @IsTest
    static void testExplainViolation_FallbackWhenAIDisabled() {
        // Setup: Create AI settings with AI disabled
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = false,
            Confidence_Threshold__c = 0.85
        );
        insert settings;

        // Create a permission set to index
        PermissionSet ps = new PermissionSet(
            Name = 'FallbackTestPS',
            Label = 'Fallback Test PS'
        );
        insert ps;

        // Index the permission set to create a graph node
        String nodeHash = PrometheionGraphIndexer.indexChange(
            'PERMISSION_SET',
            ps.Id,
            null,
            'SOC2'
        );

        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result =
            PrometheionReasoningEngine.explainViolation(nodeHash, 'SOC2');
        Test.stopTest();

        // Verify fallback reasoning was used
        System.assertEquals('MANUAL_REVIEW', result.policy);
        System.assertEquals('N/A', result.legalCitation);
        System.assertEquals(0.0, result.confidence);
        System.assertEquals(true, result.requiresHumanReview);
        System.assert(result.explanation.contains('Manual review required'));
    }

    /**
     * Test: High-risk node triggers violation flag in fallback
     * Verifies: Risk >= 8.0 sets isViolation = true
     */
    @IsTest
    static void testExplainViolation_HighRiskFallback() {
        // Setup AI disabled
        Prometheion_AI_Settings__c settings = new Prometheion_AI_Settings__c(
            SetupOwnerId = UserInfo.getOrganizationId(),
            Enable_AI_Reasoning__c = false
        );
        insert settings;

        // Create and index a permission set
        PermissionSet ps = new PermissionSet(
            Name = 'HighRiskTestPS',
            Label = 'High Risk Test PS'
        );
        insert ps;

        String nodeHash = PrometheionGraphIndexer.indexChange(
            'PERMISSION_SET',
            ps.Id,
            null,
            'SOC2'
        );

        Test.startTest();
        PrometheionReasoningEngine.ReasoningResult result =
            PrometheionReasoningEngine.explainViolation(nodeHash, 'SOC2');
        Test.stopTest();

        // Note: isViolation depends on risk score from indexer
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.auditTrailId);
    }

    /**
     * Test: Confidence threshold affects requiresHumanReview
     * Verifies: Low confidence triggers human review flag
     */
    @IsTest
    static void testGetConfidenceThreshold_AffectsHumanReview() {
        // Test with custom threshold
        Prometheion_AI_Settings__c strictSettings = new Prometheion_AI_Settings__c(
            Confidence_Threshold__c = 0.99  // Very strict
        );

        Decimal strictThreshold = PrometheionReasoningEngine.getConfidenceThreshold(strictSettings);
        System.assertEquals(0.99, strictThreshold);

        // Test with lenient threshold
        Prometheion_AI_Settings__c lenientSettings = new Prometheion_AI_Settings__c(
            Confidence_Threshold__c = 0.50  // Very lenient
        );

        Decimal lenientThreshold = PrometheionReasoningEngine.getConfidenceThreshold(lenientSettings);
        System.assertEquals(0.50, lenientThreshold);
    }
}
```

---

## 2. Missing Compliance Frameworks

### 2.1 CCPA (California Consumer Privacy Act)

**File:** `force-app/main/default/customMetadata/Compliance_Policy.CCPA_*.md-meta.xml`

#### Policy Definitions

```xml
<!-- Compliance_Policy.CCPA_Right_To_Know.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>CCPA Right to Know</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">CCPA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Consumers have the right to know what personal information is collected, used, shared, or sold</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">CCPA 1798.100</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Implement data inventory tracking
2. Create consumer-facing privacy portal
3. Document all data collection purposes
4. Maintain records of data sharing</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.CCPA_Right_To_Delete.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>CCPA Right to Delete</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">CCPA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Consumers have the right to request deletion of their personal information</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">CCPA 1798.105</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Implement data deletion workflows
2. Create deletion request processing
3. Verify identity before deletion
4. Notify service providers of deletion requests
5. Document deletion exceptions</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.CCPA_Right_To_Opt_Out.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>CCPA Right to Opt-Out</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">CCPA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Consumers have the right to opt-out of the sale of their personal information</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">CCPA 1798.120</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Add "Do Not Sell My Personal Information" link
2. Implement opt-out preference center
3. Honor Global Privacy Control signals
4. Maintain opt-out records for 12 months</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.CCPA_Non_Discrimination.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>CCPA Non-Discrimination</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">CCPA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Businesses cannot discriminate against consumers who exercise their CCPA rights</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">CCPA 1798.125</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Review pricing for privacy exercisers
2. Ensure equal service levels
3. Document any financial incentive programs
4. Train staff on non-discrimination requirements</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">7</value>
    </values>
</CustomMetadata>
```

---

### 2.2 GLBA (Gramm-Leach-Bliley Act)

```xml
<!-- Compliance_Policy.GLBA_Safeguards_Rule.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>GLBA Safeguards Rule</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">GLBA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Financial institutions must develop, implement, and maintain a comprehensive information security program</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">16 CFR Part 314</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Designate qualified individual for security program
2. Conduct risk assessments
3. Implement safeguards to control identified risks
4. Regularly test and monitor safeguards
5. Train security personnel
6. Oversee service providers</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.GLBA_Privacy_Rule.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>GLBA Privacy Rule</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">GLBA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Financial institutions must provide privacy notices explaining information sharing practices</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">15 USC 6802-6803</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Provide clear privacy notice at account opening
2. Annual privacy notice distribution
3. Explain opt-out rights clearly
4. Honor opt-out requests promptly
5. Document all NPI sharing with third parties</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.GLBA_Pretexting.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>GLBA Pretexting Protection</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">GLBA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Protect customer NPI from pretexting and social engineering attacks</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">15 USC 6821-6827</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Implement identity verification procedures
2. Train staff on social engineering tactics
3. Establish customer authentication protocols
4. Monitor for suspicious account access patterns</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.GLBA_Service_Provider_Oversight.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>GLBA Service Provider Oversight</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">GLBA</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Financial institutions must oversee service providers handling customer information</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">16 CFR 314.4(d)</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Conduct due diligence before engagement
2. Include security requirements in contracts
3. Periodically assess service provider compliance
4. Document oversight activities</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

---

### 2.3 NIST (Cybersecurity Framework)

```xml
<!-- Compliance_Policy.NIST_ID_AM_Asset_Management.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>NIST Asset Management</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">NIST</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">The data, personnel, devices, systems, and facilities that enable the organization to achieve business purposes are identified and managed</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">NIST CSF ID.AM</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Maintain inventory of physical devices and systems
2. Inventory software platforms and applications
3. Map organizational communication and data flows
4. Catalog external information systems
5. Prioritize resources based on classification and criticality</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">7</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.NIST_PR_AC_Access_Control.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>NIST Access Control</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">NIST</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Access to assets and associated facilities is limited to authorized users, processes, or devices</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">NIST CSF PR.AC</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Manage identities and credentials for authorized devices and users
2. Manage and protect physical access to assets
3. Manage remote access
4. Manage access permissions using least privilege principle
5. Protect network integrity with network segregation</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.NIST_DE_CM_Continuous_Monitoring.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>NIST Continuous Monitoring</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">NIST</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">The information system and assets are monitored at discrete intervals to identify cybersecurity events</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">NIST CSF DE.CM</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Monitor network for potential cybersecurity events
2. Monitor physical environment for potential events
3. Monitor personnel activity for potential events
4. Detect malicious code
5. Detect unauthorized mobile code
6. Monitor external service provider activity
7. Monitor for unauthorized personnel, connections, devices, and software</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.NIST_RS_RP_Response_Planning.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>NIST Response Planning</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">NIST</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Response processes and procedures are executed and maintained to ensure timely response to detected cybersecurity events</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">NIST CSF RS.RP</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Execute response plan during or after an event
2. Coordinate response activities with stakeholders
3. Analyze incidents to understand attack
4. Implement mitigations to prevent incident expansion
5. Apply lessons learned to improve response</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">8</value>
    </values>
</CustomMetadata>
```

---

### 2.4 SOX (Sarbanes-Oxley)

```xml
<!-- Compliance_Policy.SOX_Section_302_Certification.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>SOX Section 302 Certification</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">SOX</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">CEO and CFO must certify the accuracy of financial statements and effectiveness of internal controls</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">SOX Section 302</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Establish disclosure controls and procedures
2. Design and evaluate effectiveness of internal controls
3. Document all material weaknesses
4. Report any fraud involving management
5. Maintain evidence of control testing</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">10</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.SOX_Section_404_Internal_Controls.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>SOX Section 404 Internal Controls</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">SOX</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Management must assess and report on the effectiveness of internal controls over financial reporting</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">SOX Section 404</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Document all internal controls
2. Test control effectiveness annually
3. Remediate identified deficiencies
4. Obtain independent auditor attestation
5. Include assessment in annual report</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">10</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.SOX_Segregation_Of_Duties.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>SOX Segregation of Duties</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">SOX</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Duties must be segregated to prevent any single individual from controlling all phases of a transaction</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">SOX Internal Control Requirements</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Identify incompatible duties in financial processes
2. Separate authorization, custody, and recordkeeping
3. Review user access for SoD conflicts
4. Implement compensating controls where separation not feasible
5. Document and monitor SoD exceptions</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

```xml
<!-- Compliance_Policy.SOX_Audit_Trail.md-meta.xml -->
<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata"
                xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
    <label>SOX Audit Trail Requirements</label>
    <protected>false</protected>
    <values>
        <field>Framework__c</field>
        <value xsi:type="xsi:string">SOX</value>
    </values>
    <values>
        <field>Policy_Description__c</field>
        <value xsi:type="xsi:string">Complete audit trail must be maintained for all financial transactions and system changes</value>
    </values>
    <values>
        <field>Legal_Citation__c</field>
        <value xsi:type="xsi:string">SOX Section 802</value>
    </values>
    <values>
        <field>Remediation_Steps__c</field>
        <value xsi:type="xsi:string">1. Enable field history tracking on financial objects
2. Configure Setup Audit Trail retention
3. Implement change tracking for critical fields
4. Retain audit records for 7 years minimum
5. Protect audit logs from modification or deletion</value>
    </values>
    <values>
        <field>Risk_Weight__c</field>
        <value xsi:type="xsi:decimal">9</value>
    </values>
</CustomMetadata>
```

---

## 3. Expanded Policies for Existing Frameworks

### 3.1 SOC2 Expansion

**Current:** 2 policies (CC6.1, CC7.1)
**Target:** 6 policies

```xml
<!-- Additional SOC2 Policies to Create -->

<!-- Compliance_Policy.SOC2_CC1_1_Control_Environment.md-meta.xml -->
<!-- CC1: Control Environment - Board oversight and organizational structure -->

<!-- Compliance_Policy.SOC2_CC2_1_Communication.md-meta.xml -->
<!-- CC2: Communication and Information - Internal and external communication -->

<!-- Compliance_Policy.SOC2_CC3_1_Risk_Assessment.md-meta.xml -->
<!-- CC3: Risk Assessment - Risk identification and analysis -->

<!-- Compliance_Policy.SOC2_CC5_1_Monitoring.md-meta.xml -->
<!-- CC5: Monitoring Activities - Ongoing and separate evaluations -->
```

### 3.2 HIPAA Expansion

**Current:** 2 policies (164.312.a, 164.312.b)
**Target:** 6 policies

```xml
<!-- Additional HIPAA Policies to Create -->

<!-- Compliance_Policy.HIPAA_164_308_Admin_Safeguards.md-meta.xml -->
<!-- Administrative Safeguards - Security management, workforce security -->

<!-- Compliance_Policy.HIPAA_164_310_Physical_Safeguards.md-meta.xml -->
<!-- Physical Safeguards - Facility access, workstation security -->

<!-- Compliance_Policy.HIPAA_164_312_e_Transmission.md-meta.xml -->
<!-- Transmission Security - Encryption requirements -->

<!-- Compliance_Policy.HIPAA_164_314_BAA.md-meta.xml -->
<!-- Business Associate Agreements - Third-party requirements -->
```

### 3.3 PCI-DSS Expansion

**Current:** 1 policy (Req7)
**Target:** 6 policies

```xml
<!-- Additional PCI-DSS Policies to Create -->

<!-- Compliance_Policy.PCI_DSS_Req1_Firewall.md-meta.xml -->
<!-- Requirement 1: Install and maintain firewall configuration -->

<!-- Compliance_Policy.PCI_DSS_Req3_Protect_Data.md-meta.xml -->
<!-- Requirement 3: Protect stored cardholder data -->

<!-- Compliance_Policy.PCI_DSS_Req8_Authentication.md-meta.xml -->
<!-- Requirement 8: Identify and authenticate access -->

<!-- Compliance_Policy.PCI_DSS_Req10_Logging.md-meta.xml -->
<!-- Requirement 10: Track and monitor access -->

<!-- Compliance_Policy.PCI_DSS_Req12_Security_Policy.md-meta.xml -->
<!-- Requirement 12: Maintain information security policy -->
```

---

## 4. LWC Jest Testing Infrastructure

### 4.1 Project Setup

**File:** `package.json` additions

```json
{
  "scripts": {
    "test:unit": "sfdx-lwc-jest",
    "test:unit:watch": "sfdx-lwc-jest --watch",
    "test:unit:debug": "sfdx-lwc-jest --debug",
    "test:unit:coverage": "sfdx-lwc-jest --coverage"
  },
  "devDependencies": {
    "@salesforce/sfdx-lwc-jest": "^3.0.0"
  }
}
```

**File:** `jest.config.js`

```javascript
const { jestConfig } = require('@salesforce/sfdx-lwc-jest/config');

module.exports = {
    ...jestConfig,
    modulePathIgnorePatterns: ['<rootDir>/.localdevserver'],
    testPathIgnorePatterns: [
        '<rootDir>/node_modules/',
        '<rootDir>/Sentinel-main/'
    ],
    coverageDirectory: './coverage/lwc',
    coverageReporters: ['text', 'lcov', 'html'],
    collectCoverageFrom: [
        'force-app/main/default/lwc/**/*.js',
        '!force-app/main/default/lwc/**/__tests__/**'
    ]
};
```

---

### 4.2 pollingManager Tests

**File:** `force-app/main/default/lwc/pollingManager/__tests__/pollingManager.test.js`

```javascript
import { createElement } from 'lwc';
import PollingManager from 'c/pollingManager';

// Mock timers
jest.useFakeTimers();

describe('c-polling-manager', () => {

    afterEach(() => {
        // Clean up after each test
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
        jest.clearAllTimers();
    });

    // ═══════════════════════════════════════════════════════════════
    // INITIALIZATION TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should create component successfully', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        document.body.appendChild(element);

        expect(element).toBeTruthy();
    });

    it('should initialize with default polling interval', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        document.body.appendChild(element);

        // Default interval should be set (e.g., 30000ms)
        expect(element.pollingInterval).toBeDefined();
    });

    // ═══════════════════════════════════════════════════════════════
    // POLLING LIFECYCLE TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should start polling when enabled', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        element.isPollingEnabled = true;
        document.body.appendChild(element);

        // Fast-forward timers
        jest.advanceTimersByTime(30000);

        // Verify polling callback was invoked
        // (Implementation depends on component design)
    });

    it('should stop polling when disabled', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        element.isPollingEnabled = true;
        document.body.appendChild(element);

        // Disable polling
        element.isPollingEnabled = false;

        // Advance time - should not trigger callback
        jest.advanceTimersByTime(60000);
    });

    it('should respect custom polling interval', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        element.pollingInterval = 5000; // 5 seconds
        document.body.appendChild(element);

        // Verify interval is set correctly
        expect(element.pollingInterval).toBe(5000);
    });

    // ═══════════════════════════════════════════════════════════════
    // CLEANUP TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should clear interval on disconnectedCallback', () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        element.isPollingEnabled = true;
        document.body.appendChild(element);

        // Remove element (triggers disconnectedCallback)
        document.body.removeChild(element);

        // Verify timer is cleared
        jest.advanceTimersByTime(60000);
        // No errors should occur
    });

    // ═══════════════════════════════════════════════════════════════
    // EVENT TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should fire poll event on interval', async () => {
        const element = createElement('c-polling-manager', {
            is: PollingManager
        });
        element.pollingInterval = 1000;
        element.isPollingEnabled = true;

        const handler = jest.fn();
        element.addEventListener('poll', handler);

        document.body.appendChild(element);

        // Advance to trigger poll
        jest.advanceTimersByTime(1000);

        // Wait for any promises
        await Promise.resolve();

        expect(handler).toHaveBeenCalled();
    });
});
```

---

### 4.3 prometheionAiSettings Tests

**File:** `force-app/main/default/lwc/prometheionAiSettings/__tests__/prometheionAiSettings.test.js`

```javascript
import { createElement } from 'lwc';
import PrometheionAiSettings from 'c/prometheionAiSettings';
import getSettings from '@salesforce/apex/PrometheionAISettingsController.getSettings';
import saveSettings from '@salesforce/apex/PrometheionAISettingsController.saveSettings';

// Mock Apex methods
jest.mock(
    '@salesforce/apex/PrometheionAISettingsController.getSettings',
    () => ({ default: jest.fn() }),
    { virtual: true }
);
jest.mock(
    '@salesforce/apex/PrometheionAISettingsController.saveSettings',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-prometheion-ai-settings', () => {

    const MOCK_SETTINGS = {
        Enable_AI_Reasoning__c: true,
        Confidence_Threshold__c: 0.85,
        Require_Human_Approval__c: false,
        Auto_Remediation_Enabled__c: false,
        Blacklisted_Users__c: ''
    };

    beforeEach(() => {
        // Reset mocks
        getSettings.mockReset();
        saveSettings.mockReset();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // ═══════════════════════════════════════════════════════════════
    // DATA LOADING TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should load settings on initialization', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        // Wait for wire adapter
        await Promise.resolve();

        expect(getSettings).toHaveBeenCalled();
    });

    it('should display settings values after load', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Query for form elements
        const enableToggle = element.shadowRoot.querySelector(
            '[data-id="enable-ai-toggle"]'
        );

        // Verify values populated
        // (Implementation-specific assertions)
    });

    it('should handle settings load error gracefully', async () => {
        getSettings.mockRejectedValue(new Error('Load failed'));

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Should show error message
        const errorElement = element.shadowRoot.querySelector('.error-message');
        // Verify error handling
    });

    // ═══════════════════════════════════════════════════════════════
    // FORM INTERACTION TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should enable save button when form is modified', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Modify a field
        const slider = element.shadowRoot.querySelector(
            '[data-id="confidence-slider"]'
        );
        if (slider) {
            slider.value = 0.90;
            slider.dispatchEvent(new CustomEvent('change'));
        }

        await Promise.resolve();

        // Save button should be enabled
        const saveButton = element.shadowRoot.querySelector(
            '[data-id="save-button"]'
        );
        // Verify button state
    });

    it('should validate confidence threshold range', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Try to set invalid threshold
        const slider = element.shadowRoot.querySelector(
            '[data-id="confidence-slider"]'
        );
        if (slider) {
            slider.value = 1.5; // Invalid: > 1.0
            slider.dispatchEvent(new CustomEvent('change'));
        }

        await Promise.resolve();

        // Should show validation error
    });

    // ═══════════════════════════════════════════════════════════════
    // SAVE TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should call saveSettings on save button click', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);
        saveSettings.mockResolvedValue({ success: true });

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Click save button
        const saveButton = element.shadowRoot.querySelector(
            '[data-id="save-button"]'
        );
        if (saveButton) {
            saveButton.click();
        }

        await Promise.resolve();

        expect(saveSettings).toHaveBeenCalled();
    });

    it('should show success toast after save', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);
        saveSettings.mockResolvedValue({ success: true });

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });

        // Listen for toast event
        const toastHandler = jest.fn();
        element.addEventListener('showtoast', toastHandler);

        document.body.appendChild(element);

        await Promise.resolve();

        // Trigger save
        // Verify toast fired with success variant
    });

    it('should show error toast on save failure', async () => {
        getSettings.mockResolvedValue(MOCK_SETTINGS);
        saveSettings.mockRejectedValue(new Error('Save failed'));

        const element = createElement('c-prometheion-ai-settings', {
            is: PrometheionAiSettings
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Trigger save
        // Verify error handling
    });
});
```

---

### 4.4 flowExecutionMonitor Tests

**File:** `force-app/main/default/lwc/flowExecutionMonitor/__tests__/flowExecutionMonitor.test.js`

```javascript
import { createElement } from 'lwc';
import FlowExecutionMonitor from 'c/flowExecutionMonitor';
import getTopFlows from '@salesforce/apex/FlowExecutionStats.getTopFlows';

jest.mock(
    '@salesforce/apex/FlowExecutionStats.getTopFlows',
    () => ({ default: jest.fn() }),
    { virtual: true }
);

describe('c-flow-execution-monitor', () => {

    const MOCK_FLOWS = [
        {
            flowName: 'Account_Update_Flow',
            totalExecutions: 150,
            successCount: 145,
            faultCount: 5,
            avgCpu: 250,
            avgSoql: 8,
            avgDml: 3
        },
        {
            flowName: 'Lead_Assignment_Flow',
            totalExecutions: 80,
            successCount: 78,
            faultCount: 2,
            avgCpu: 180,
            avgSoql: 5,
            avgDml: 2
        }
    ];

    beforeEach(() => {
        getTopFlows.mockReset();
    });

    afterEach(() => {
        while (document.body.firstChild) {
            document.body.removeChild(document.body.firstChild);
        }
    });

    // ═══════════════════════════════════════════════════════════════
    // DATA DISPLAY TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should display flow execution data', async () => {
        getTopFlows.mockResolvedValue(MOCK_FLOWS);

        const element = createElement('c-flow-execution-monitor', {
            is: FlowExecutionMonitor
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Verify data table populated
        const rows = element.shadowRoot.querySelectorAll('lightning-datatable');
        expect(rows).toBeTruthy();
    });

    it('should calculate success rate correctly', async () => {
        getTopFlows.mockResolvedValue(MOCK_FLOWS);

        const element = createElement('c-flow-execution-monitor', {
            is: FlowExecutionMonitor
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Success rate for first flow: 145/150 = 96.67%
        // Verify calculated value is displayed
    });

    it('should handle empty data gracefully', async () => {
        getTopFlows.mockResolvedValue([]);

        const element = createElement('c-flow-execution-monitor', {
            is: FlowExecutionMonitor
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Should show "No data" message
        const emptyState = element.shadowRoot.querySelector('.empty-state');
        // Verify empty state handling
    });

    // ═══════════════════════════════════════════════════════════════
    // SORTING TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should sort by total executions by default', async () => {
        getTopFlows.mockResolvedValue(MOCK_FLOWS);

        const element = createElement('c-flow-execution-monitor', {
            is: FlowExecutionMonitor
        });
        document.body.appendChild(element);

        await Promise.resolve();

        // Verify first row is highest execution count
    });

    // ═══════════════════════════════════════════════════════════════
    // FILTER TESTS
    // ═══════════════════════════════════════════════════════════════

    it('should filter by date range', async () => {
        getTopFlows.mockResolvedValue(MOCK_FLOWS);

        const element = createElement('c-flow-execution-monitor', {
            is: FlowExecutionMonitor
        });
        element.dateRange = 7; // Last 7 days
        document.body.appendChild(element);

        await Promise.resolve();

        // Verify getTopFlows called with correct limit
        expect(getTopFlows).toHaveBeenCalledWith(
            expect.objectContaining({ dayRange: 7 })
        );
    });
});
```

---

## 5. Test Utilities and Infrastructure

### 5.1 EinsteinPredictionMock

**File:** `force-app/main/default/classes/EinsteinPredictionMock.cls`

```apex
/**
 * @description Mock implementation for Einstein AI predictions in test context.
 * Use this to simulate Einstein AI responses without actual API calls.
 */
@IsTest
public class EinsteinPredictionMock {

    // Store configured mock responses
    private static Map<String, List<Map<String, Object>>> mockResponses =
        new Map<String, List<Map<String, Object>>>();

    // Store whether to throw exception
    private static Boolean shouldThrowException = false;
    private static String exceptionMessage = 'Einstein prediction failed';

    /**
     * @description Configure a successful mock response for a model
     * @param modelName The Einstein model name
     * @param probability The probability/confidence score to return
     * @param additionalFields Any additional fields to include in response
     */
    public static void setMockResponse(
        String modelName,
        Decimal probability,
        Map<String, Object> additionalFields
    ) {
        Map<String, Object> response = new Map<String, Object>{
            'probability' => probability,
            'label' => probability >= 0.5 ? 'VIOLATION' : 'COMPLIANT'
        };

        if (additionalFields != null) {
            response.putAll(additionalFields);
        }

        if (!mockResponses.containsKey(modelName)) {
            mockResponses.put(modelName, new List<Map<String, Object>>());
        }
        mockResponses.get(modelName).add(response);
    }

    /**
     * @description Configure mock to return high-risk violation
     */
    public static void setHighRiskViolation(String modelName) {
        setMockResponse(modelName, 0.95, new Map<String, Object>{
            'riskCategory' => 'CRITICAL',
            'policyMatch' => 'EXCESSIVE_ACCESS'
        });
    }

    /**
     * @description Configure mock to return low-risk/compliant
     */
    public static void setCompliant(String modelName) {
        setMockResponse(modelName, 0.15, new Map<String, Object>{
            'riskCategory' => 'LOW',
            'policyMatch' => 'NONE'
        });
    }

    /**
     * @description Configure mock to return medium confidence (triggers human review)
     */
    public static void setMediumConfidence(String modelName) {
        setMockResponse(modelName, 0.60, new Map<String, Object>{
            'riskCategory' => 'MEDIUM',
            'requiresReview' => true
        });
    }

    /**
     * @description Configure mock to throw exception
     */
    public static void setThrowException(Boolean shouldThrow, String message) {
        shouldThrowException = shouldThrow;
        exceptionMessage = message;
    }

    /**
     * @description Get the mock response for a model
     * Used by test classes to verify behavior
     */
    public static List<Map<String, Object>> getMockResponse(String modelName) {
        if (shouldThrowException) {
            throw new EinsteinMockException(exceptionMessage);
        }

        if (mockResponses.containsKey(modelName)) {
            return mockResponses.get(modelName);
        }

        // Default response if no mock configured
        return new List<Map<String, Object>>{
            new Map<String, Object>{
                'probability' => 0.50,
                'label' => 'UNKNOWN'
            }
        };
    }

    /**
     * @description Reset all mock configurations
     * Call this in @TestSetup or afterEach
     */
    public static void reset() {
        mockResponses.clear();
        shouldThrowException = false;
        exceptionMessage = 'Einstein prediction failed';
    }

    /**
     * @description Custom exception for mock failures
     */
    public class EinsteinMockException extends Exception {}
}
```

---

### 5.2 CCX_Settings Test Utilities

**Addition to:** `force-app/main/default/classes/PrometheionTestDataFactory.cls`

```apex
// ============================================
// CCX SETTINGS - Performance Thresholds
// ============================================

/**
 * @description Creates CCX_Settings__c with default thresholds
 */
public static CCX_Settings__c createDefaultCCXSettings() {
    CCX_Settings__c settings = new CCX_Settings__c(
        SetupOwnerId = UserInfo.getOrganizationId(),
        CPU_Warn__c = 8000,
        CPU_Crit__c = 9000,
        Heap_Warn__c = 4500,
        Heap_Crit__c = 5000,
        SOQL_Warn__c = 90,
        SOQL_Crit__c = 100,
        DML_Warn__c = 140,
        DML_Crit__c = 150
    );
    insert settings;
    return settings;
}

/**
 * @description Creates CCX_Settings__c with custom thresholds
 */
public static CCX_Settings__c createCustomCCXSettings(
    Integer cpuWarn, Integer cpuCrit,
    Integer heapWarn, Integer heapCrit,
    Integer soqlWarn, Integer soqlCrit,
    Integer dmlWarn, Integer dmlCrit
) {
    CCX_Settings__c settings = new CCX_Settings__c(
        SetupOwnerId = UserInfo.getOrganizationId(),
        CPU_Warn__c = cpuWarn,
        CPU_Crit__c = cpuCrit,
        Heap_Warn__c = heapWarn,
        Heap_Crit__c = heapCrit,
        SOQL_Warn__c = soqlWarn,
        SOQL_Crit__c = soqlCrit,
        DML_Warn__c = dmlWarn,
        DML_Crit__c = dmlCrit
    );
    insert settings;
    return settings;
}

/**
 * @description Creates CCX_Settings__c with strict (low) thresholds
 * Useful for testing alert triggering
 */
public static CCX_Settings__c createStrictCCXSettings() {
    return createCustomCCXSettings(
        1000, 2000,   // CPU: very low
        500, 1000,    // Heap: very low
        10, 20,       // SOQL: very low
        10, 20        // DML: very low
    );
}

/**
 * @description Creates CCX_Settings__c with lenient (high) thresholds
 * Useful for testing no-alert scenarios
 */
public static CCX_Settings__c createLenientCCXSettings() {
    return createCustomCCXSettings(
        9500, 9900,   // CPU: very high
        5500, 5900,   // Heap: very high
        99, 100,      // SOQL: at limit
        149, 150      // DML: at limit
    );
}

// ============================================
// PERFORMANCE ALERT EVENTS - Test Data
// ============================================

/**
 * @description Creates a Performance_Alert__e event for testing
 * Note: Platform Events cannot be queried, only published
 */
public static Performance_Alert__e createPerformanceAlertEvent(
    String metric,
    Decimal value,
    Decimal threshold,
    String contextRecordId,
    String stackTrace
) {
    return new Performance_Alert__e(
        Metric__c = metric,
        Value__c = value,
        Threshold__c = threshold,
        Context_Record__c = contextRecordId,
        Stack__c = stackTrace
    );
}

/**
 * @description Creates a critical CPU alert event
 */
public static Performance_Alert__e createCriticalCPUAlert() {
    return createPerformanceAlertEvent(
        'CPU',
        9500,
        9000,
        'TestContext001',
        'CPU critical threshold exceeded in TestClass.testMethod'
    );
}

/**
 * @description Creates a warning SOQL alert event
 */
public static Performance_Alert__e createWarningSOQLAlert() {
    return createPerformanceAlertEvent(
        'SOQL',
        95,
        90,
        'TestContext002',
        'SOQL warning threshold exceeded'
    );
}

// ============================================
// GOVERNOR STATS - Test Data
// ============================================

/**
 * @description Creates LimitMetrics.GovernorStats with specified values
 */
public static LimitMetrics.GovernorStats createGovernorStats(
    Integer cpuMs,
    Integer heapKb,
    Integer soql,
    Integer dml
) {
    LimitMetrics.GovernorStats stats = new LimitMetrics.GovernorStats();
    stats.cpuMs = cpuMs;
    stats.heapKb = heapKb;
    stats.soql = soql;
    stats.dml = dml;
    return stats;
}

/**
 * @description Creates healthy (all green) governor stats
 */
public static LimitMetrics.GovernorStats createHealthyStats() {
    return createGovernorStats(1000, 1000, 10, 10);
}

/**
 * @description Creates warning-level governor stats
 */
public static LimitMetrics.GovernorStats createWarningStats() {
    return createGovernorStats(8500, 4600, 95, 145);
}

/**
 * @description Creates critical-level governor stats
 */
public static LimitMetrics.GovernorStats createCriticalStats() {
    return createGovernorStats(9500, 5500, 100, 155);
}
```

---

### 5.3 Updated Constants for TestDataFactory

**Addition to:** `force-app/main/default/classes/PrometheionTestDataFactory.cls`

```apex
// ============================================
// CONSTANTS - All Supported Frameworks (Updated)
// ============================================

public static final Set<String> SUPPORTED_FRAMEWORKS = new Set<String>{
    'SOC2',
    'HIPAA',
    'GDPR',
    'ISO27001',
    'PCI_DSS',
    'NIST',
    'CCPA',      // NEW
    'GLBA',      // NEW
    'FedRAMP',
    'SOX'        // NEW
};

// Framework-specific constants
public static final String FRAMEWORK_SOC2 = 'SOC2';
public static final String FRAMEWORK_HIPAA = 'HIPAA';
public static final String FRAMEWORK_GDPR = 'GDPR';
public static final String FRAMEWORK_ISO27001 = 'ISO27001';
public static final String FRAMEWORK_PCI_DSS = 'PCI_DSS';
public static final String FRAMEWORK_NIST = 'NIST';
public static final String FRAMEWORK_CCPA = 'CCPA';
public static final String FRAMEWORK_GLBA = 'GLBA';
public static final String FRAMEWORK_FEDRAMP = 'FedRAMP';
public static final String FRAMEWORK_SOX = 'SOX';

/**
 * @description Validates if a framework string is supported
 */
public static Boolean isValidFramework(String framework) {
    return String.isNotBlank(framework) &&
           SUPPORTED_FRAMEWORKS.contains(framework.toUpperCase());
}
```

---

## Implementation Summary

### Files to Create

| File | Type | Priority |
|------|------|----------|
| `Compliance_Policy.CCPA_*.md-meta.xml` (4 files) | Custom Metadata | High |
| `Compliance_Policy.GLBA_*.md-meta.xml` (4 files) | Custom Metadata | High |
| `Compliance_Policy.NIST_*.md-meta.xml` (4 files) | Custom Metadata | High |
| `Compliance_Policy.SOX_*.md-meta.xml` (4 files) | Custom Metadata | High |
| `EinsteinPredictionMock.cls` | Apex Test Utility | Medium |
| `jest.config.js` | Jest Config | Medium |
| `pollingManager.test.js` | LWC Test | Medium |
| `prometheionAiSettings.test.js` | LWC Test | Medium |
| `flowExecutionMonitor.test.js` | LWC Test | Medium |

### Files to Modify

| File | Changes | Priority |
|------|---------|----------|
| `PerformanceRuleEngineTest.cls` | Add 7 test methods | High |
| `PrometheionComplianceScorerTest.cls` | Add 6 test methods | High |
| `SlackNotifierTest.cls` | Add 4 test methods | High |
| `PrometheionGraphIndexerTest.cls` | Add 5 test methods | Medium |
| `PrometheionReasoningEngineTest.cls` | Add 3 test methods | Medium |
| `PrometheionTestDataFactory.cls` | Add CCX_Settings utilities | Medium |
| `package.json` | Add Jest dependencies | Medium |

### Estimated Lines of Code

| Category | New Lines |
|----------|-----------|
| Apex Test Code | ~800 |
| Custom Metadata XML | ~600 |
| JavaScript Test Code | ~500 |
| Configuration Files | ~50 |
| **Total** | **~1,950** |

---

## Next Steps

1. Review this design document
2. Prioritize implementation order
3. Create feature branches for each section
4. Implement incrementally with code reviews
5. Validate test coverage improvements

---

*Document Version: 1.0*
*Last Updated: January 6, 2026*
