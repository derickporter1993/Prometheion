/**
 * Tests for RuleEngineEventBridge covering forward integration (Rule Engine to
 * Event Monitoring), reverse integration (Event Monitoring to Rule Engine),
 * full pipeline execution, and edge cases.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see RuleEngineEventBridge
 */
@IsTest
private class RuleEngineEventBridgeTest {

    // =========================================================================
    // Forward Integration: publishGapsAsAlerts
    // =========================================================================

    @IsTest
    static void shouldPublishGapsAsAlerts() {
        IComplianceModule module = new HIPAAModule();

        List<IComplianceModule.Gap> gaps = new List<IComplianceModule.Gap>();

        IComplianceModule.Gap gap1 = new IComplianceModule.Gap();
        gap1.id = 'GAP-164.312(a)';
        gap1.controlId = '164.312(a)';
        gap1.controlCode = '164.312(a)';
        gap1.controlName = 'Access Control';
        gap1.description = 'Excessive admin permissions found';
        gap1.severity = ElaroConstants.SEVERITY_HIGH;
        gap1.recommendation = 'Implement least privilege';
        gap1.riskScore = 7.5;
        gaps.add(gap1);

        IComplianceModule.Gap gap2 = new IComplianceModule.Gap();
        gap2.id = 'GAP-164.312(b)';
        gap2.controlId = '164.312(b)';
        gap2.controlCode = '164.312(b)';
        gap2.controlName = 'Audit Controls';
        gap2.description = 'Audit trail gaps detected';
        gap2.severity = ElaroConstants.SEVERITY_MEDIUM;
        gap2.riskScore = 5.0;
        gaps.add(gap2);

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.publishGapsAsAlerts(module, gaps);
        Test.stopTest();

        Assert.areEqual(2, findings.size(), 'Should produce 2 findings from 2 gaps');
        Assert.areEqual('HIPAA', findings[0].framework,
            'Framework should be HIPAA from module');
        Assert.areEqual('164.312(a)', findings[0].controlReference,
            'Control reference should match gap controlCode');
        Assert.areEqual(ElaroConstants.SEVERITY_HIGH, findings[0].severity,
            'Severity should match gap severity');
        Assert.areEqual('IComplianceModule', findings[0].sourceSystem,
            'Source system should be IComplianceModule');
        Assert.areEqual(ComplianceAlertPublisher.ALERT_TYPE_FINDING, findings[0].alertType,
            'Alert type should be FINDING');
    }

    @IsTest
    static void shouldHandleEmptyGaps() {
        IComplianceModule module = new HIPAAModule();

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.publishGapsAsAlerts(module, new List<IComplianceModule.Gap>());
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Empty gaps should return empty findings');
    }

    @IsTest
    static void shouldHandleNullGaps() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.publishGapsAsAlerts(null, null);
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Null gaps should return empty findings');
    }

    @IsTest
    static void shouldHandleNullModuleWithGaps() {
        List<IComplianceModule.Gap> gaps = new List<IComplianceModule.Gap>();
        IComplianceModule.Gap gap = new IComplianceModule.Gap();
        gap.controlCode = 'TEST-1';
        gap.description = 'Test gap';
        gap.severity = ElaroConstants.SEVERITY_LOW;
        gaps.add(gap);

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.publishGapsAsAlerts(null, gaps);
        Test.stopTest();

        Assert.areEqual(1, findings.size(), 'Should produce 1 finding');
        Assert.areEqual('UNKNOWN', findings[0].framework,
            'Null module should default to UNKNOWN framework');
    }

    // =========================================================================
    // Forward Integration: publishControlResultAsAlert
    // =========================================================================

    @IsTest
    static void shouldPublishNonCompliantControlResult() {
        IComplianceModule.ControlResult result = new IComplianceModule.ControlResult();
        result.controlId = '164.312(a)';
        result.passed = false;
        result.score = 20;
        result.status = 'NON_COMPLIANT';
        result.finding = 'Access controls not properly configured';

        Test.startTest();
        RuleEngineEventBridge.ComplianceFinding finding =
            RuleEngineEventBridge.publishControlResultAsAlert('HIPAA', '164.312(a)', result);
        Test.stopTest();

        Assert.isNotNull(finding, 'Non-compliant result should produce a finding');
        Assert.areEqual('HIPAA', finding.framework, 'Framework should match');
        Assert.areEqual('164.312(a)', finding.controlReference, 'Control reference should match');
        Assert.areEqual(ElaroConstants.SEVERITY_HIGH, finding.severity,
            'NON_COMPLIANT should map to HIGH severity');
    }

    @IsTest
    static void shouldReturnNullForPassingControlResult() {
        IComplianceModule.ControlResult result = new IComplianceModule.ControlResult();
        result.controlId = '164.312(e)';
        result.passed = true;
        result.score = 100;
        result.status = 'COMPLIANT';

        Test.startTest();
        RuleEngineEventBridge.ComplianceFinding finding =
            RuleEngineEventBridge.publishControlResultAsAlert('HIPAA', '164.312(e)', result);
        Test.stopTest();

        Assert.isNull(finding, 'Passing control result should not produce a finding');
    }

    @IsTest
    static void shouldReturnNullForNullControlResult() {
        Test.startTest();
        RuleEngineEventBridge.ComplianceFinding finding =
            RuleEngineEventBridge.publishControlResultAsAlert('SOC2', 'CC6.1', null);
        Test.stopTest();

        Assert.isNull(finding, 'Null control result should return null');
    }

    @IsTest
    static void shouldPublishPartialControlResult() {
        IComplianceModule.ControlResult result = new IComplianceModule.ControlResult();
        result.controlId = '164.308(a)(5)';
        result.passed = false;
        result.score = 60;
        result.status = 'PARTIAL';
        result.finding = 'Training program partially implemented';

        Test.startTest();
        RuleEngineEventBridge.ComplianceFinding finding =
            RuleEngineEventBridge.publishControlResultAsAlert('HIPAA', '164.308(a)(5)', result);
        Test.stopTest();

        Assert.isNotNull(finding, 'Partial result should produce a finding');
        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM, finding.severity,
            'PARTIAL should map to MEDIUM severity');
    }

    // =========================================================================
    // Reverse Integration: convertBreachAnalysesToFindings
    // =========================================================================

    @IsTest
    static void shouldConvertBreachAnalysesToFindings() {
        List<BreachPatternMatcher.PatternAnalysis> analyses =
            new List<BreachPatternMatcher.PatternAnalysis>();

        BreachPatternMatcher.PatternAnalysis analysis1 =
            new BreachPatternMatcher.PatternAnalysis('Brute Force Login');
        analysis1.severity = ElaroConstants.SEVERITY_CRITICAL;
        analysis1.userId = '005000000000001AAA';
        analysis1.matchedEventCount = 5;
        analysis1.timeWindowMinutes = 15;
        analysis1.threatScore = 9.2;
        analysis1.matchedEventTypes = new List<String>{'LOGIN_FAILURE', 'LOGIN_FAILURE', 'ACCOUNT_LOCKOUT'};
        analyses.add(analysis1);

        BreachPatternMatcher.PatternAnalysis analysis2 =
            new BreachPatternMatcher.PatternAnalysis('HIPAA PHI Exfiltration');
        analysis2.severity = ElaroConstants.SEVERITY_HIGH;
        analysis2.userId = '005000000000002AAA';
        analysis2.matchedEventCount = 3;
        analysis2.threatScore = 7.0;
        analyses.add(analysis2);

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertBreachAnalysesToFindings(analyses);
        Test.stopTest();

        Assert.areEqual(2, findings.size(), 'Should produce 2 findings');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2, findings[0].framework,
            'Generic pattern should default to SOC2');
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA, findings[1].framework,
            'Pattern with HIPAA in name should map to HIPAA');
        Assert.areEqual(ComplianceAlertPublisher.ALERT_TYPE_BREACH, findings[0].alertType,
            'Alert type should be BREACH');
        Assert.areEqual('BreachPatternMatcher', findings[0].sourceSystem,
            'Source system should be BreachPatternMatcher');
        Assert.areEqual(9.2, findings[0].riskScore,
            'Risk score should match threat score');
    }

    @IsTest
    static void shouldHandleEmptyBreachAnalyses() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertBreachAnalysesToFindings(
                new List<BreachPatternMatcher.PatternAnalysis>()
            );
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Empty analyses should return empty findings');
    }

    @IsTest
    static void shouldHandleNullBreachAnalyses() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertBreachAnalysesToFindings(null);
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Null analyses should return empty findings');
    }

    // =========================================================================
    // Reverse Integration: convertDriftEventsToFindings
    // =========================================================================

    @IsTest
    static void shouldConvertDriftEventsToFindings() {
        List<ConfigDriftDetector.DriftEvent> drifts =
            new List<ConfigDriftDetector.DriftEvent>();

        ConfigDriftDetector.DriftEvent drift1 = new ConfigDriftDetector.DriftEvent(
            'MFA Disabled', 'admin@test.org', 'Security Controls', ElaroConstants.SEVERITY_HIGH
        );
        drift1.oldValue = 'MFA Required';
        drift1.newValue = 'MFA Optional';
        drifts.add(drift1);

        ConfigDriftDetector.DriftEvent drift2 = new ConfigDriftDetector.DriftEvent(
            'Permission Set Modified', 'admin@test.org', 'Permission Sets', ElaroConstants.SEVERITY_HIGH
        );
        drifts.add(drift2);

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertDriftEventsToFindings(drifts);
        Test.stopTest();

        Assert.areEqual(2, findings.size(), 'Should produce 2 findings from 2 drifts');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2, findings[0].framework,
            'Security Controls drift should map to SOC2');
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA, findings[1].framework,
            'Permission Sets drift should map to HIPAA');
        Assert.areEqual(ComplianceAlertPublisher.ALERT_TYPE_DRIFT, findings[0].alertType,
            'Alert type should be DRIFT');
        Assert.areEqual('ConfigDriftDetector', findings[0].sourceSystem,
            'Source system should be ConfigDriftDetector');
    }

    @IsTest
    static void shouldHandleEmptyDriftEvents() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertDriftEventsToFindings(
                new List<ConfigDriftDetector.DriftEvent>()
            );
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Empty drifts should return empty findings');
    }

    @IsTest
    static void shouldHandleNullDriftEvents() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.convertDriftEventsToFindings(null);
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Null drifts should return empty findings');
    }

    // =========================================================================
    // Full Pipeline: publishFindingsAsAlerts
    // =========================================================================

    @IsTest
    static void shouldPublishFindingsAsAlerts() {
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            new List<RuleEngineEventBridge.ComplianceFinding>();

        RuleEngineEventBridge.ComplianceFinding f1 =
            new RuleEngineEventBridge.ComplianceFinding(
                'SOC2', 'CC6.1', ElaroConstants.SEVERITY_HIGH, 'Test finding 1'
            );
        findings.add(f1);

        RuleEngineEventBridge.ComplianceFinding f2 =
            new RuleEngineEventBridge.ComplianceFinding(
                'HIPAA', '164.312(a)', ElaroConstants.SEVERITY_CRITICAL, 'Test finding 2'
            );
        findings.add(f2);

        Test.startTest();
        List<Database.SaveResult> results =
            RuleEngineEventBridge.publishFindingsAsAlerts(findings);
        Test.stopTest();

        Assert.areEqual(2, results.size(), 'Should return 2 save results');
        for (Database.SaveResult sr : results) {
            Assert.isTrue(sr.isSuccess(), 'Each finding should publish successfully');
        }
    }

    @IsTest
    static void shouldHandleEmptyFindingsPublish() {
        Test.startTest();
        List<Database.SaveResult> results =
            RuleEngineEventBridge.publishFindingsAsAlerts(
                new List<RuleEngineEventBridge.ComplianceFinding>()
            );
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Empty findings should return empty results');
    }

    @IsTest
    static void shouldHandleNullFindingsPublish() {
        Test.startTest();
        List<Database.SaveResult> results =
            RuleEngineEventBridge.publishFindingsAsAlerts(null);
        Test.stopTest();

        Assert.isTrue(results.isEmpty(), 'Null findings should return empty results');
    }

    // =========================================================================
    // Full Pipeline: detectAndPublishDriftFindings
    // =========================================================================

    @IsTest
    static void shouldExecuteDriftPipeline() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.detectAndPublishDriftFindings(24);
        Test.stopTest();

        // SetupAuditTrail is read-only in tests so results depend on org state
        Assert.isNotNull(findings, 'Findings should not be null');
    }

    @IsTest
    static void shouldHandleNullHoursBackInDriftPipeline() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.detectAndPublishDriftFindings(null);
        Test.stopTest();

        Assert.isNotNull(findings, 'Null hoursBack should default to 1 and not throw');
    }

    // =========================================================================
    // Full Pipeline: analyzeAndPublishBreachFindings
    // =========================================================================

    @IsTest
    static void shouldExecuteBreachPipeline() {
        Datetime now = System.now();
        List<EventCorrelationEngine.SecurityEvent> events =
            new List<EventCorrelationEngine.SecurityEvent>{
                new EventCorrelationEngine.SecurityEvent('LOGIN', 'user1', now.addMinutes(-10)),
                new EventCorrelationEngine.SecurityEvent('ACCESS', 'user1', now.addMinutes(-5)),
                new EventCorrelationEngine.SecurityEvent('EXPORT', 'user1', now)
            };

        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.analyzeAndPublishBreachFindings(events);
        Test.stopTest();

        Assert.isNotNull(findings, 'Findings should not be null');
    }

    @IsTest
    static void shouldHandleNullEventsInBreachPipeline() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.analyzeAndPublishBreachFindings(null);
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Null events should return empty findings');
    }

    // =========================================================================
    // Helper Method Tests
    // =========================================================================

    @IsTest
    static void shouldMapControlStatusToSeverity() {
        Assert.areEqual(ElaroConstants.SEVERITY_HIGH,
            RuleEngineEventBridge.mapControlStatusToSeverity('NON_COMPLIANT'),
            'NON_COMPLIANT should map to HIGH');
        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM,
            RuleEngineEventBridge.mapControlStatusToSeverity('PARTIAL'),
            'PARTIAL should map to MEDIUM');
        Assert.areEqual(ElaroConstants.SEVERITY_LOW,
            RuleEngineEventBridge.mapControlStatusToSeverity('NOT_APPLICABLE'),
            'NOT_APPLICABLE should map to LOW');
        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM,
            RuleEngineEventBridge.mapControlStatusToSeverity(null),
            'Null status should default to MEDIUM');
        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM,
            RuleEngineEventBridge.mapControlStatusToSeverity('COMPLIANT'),
            'COMPLIANT should default to MEDIUM');
    }

    @IsTest
    static void shouldInferFrameworkFromPattern() {
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA,
            RuleEngineEventBridge.inferFrameworkFromPattern('HIPAA PHI Exfiltration'),
            'Pattern with HIPAA should infer HIPAA');
        Assert.areEqual(ElaroConstants.FRAMEWORK_PCI_DSS,
            RuleEngineEventBridge.inferFrameworkFromPattern('PCI Cardholder Data Breach'),
            'Pattern with PCI should infer PCI_DSS');
        Assert.areEqual(ElaroConstants.FRAMEWORK_GDPR,
            RuleEngineEventBridge.inferFrameworkFromPattern('GDPR Data Subject Violation'),
            'Pattern with GDPR should infer GDPR');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2,
            RuleEngineEventBridge.inferFrameworkFromPattern('Generic Attack Pattern'),
            'Generic pattern should default to SOC2');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2,
            RuleEngineEventBridge.inferFrameworkFromPattern(null),
            'Null pattern should default to SOC2');
    }

    @IsTest
    static void shouldInferFrameworkFromDrift() {
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA,
            RuleEngineEventBridge.inferFrameworkFromDrift('Permission Sets'),
            'Permission Sets drift should infer HIPAA');
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA,
            RuleEngineEventBridge.inferFrameworkFromDrift('Sharing Rules'),
            'Sharing Rules drift should infer HIPAA');
        Assert.areEqual(ElaroConstants.FRAMEWORK_HIPAA,
            RuleEngineEventBridge.inferFrameworkFromDrift('Manage Users'),
            'Manage Users drift should infer HIPAA');
        Assert.areEqual(ElaroConstants.FRAMEWORK_PCI_DSS,
            RuleEngineEventBridge.inferFrameworkFromDrift('Network Access'),
            'Network Access drift should infer PCI_DSS');
        Assert.areEqual(ElaroConstants.FRAMEWORK_PCI_DSS,
            RuleEngineEventBridge.inferFrameworkFromDrift('Connected Apps'),
            'Connected Apps drift should infer PCI_DSS');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2,
            RuleEngineEventBridge.inferFrameworkFromDrift('Security Controls'),
            'Security Controls drift should default to SOC2');
        Assert.areEqual(ElaroConstants.FRAMEWORK_SOC2,
            RuleEngineEventBridge.inferFrameworkFromDrift(null),
            'Null section should default to SOC2');
    }

    @IsTest
    static void shouldSanitizeForReference() {
        Assert.areEqual('Access_Control',
            RuleEngineEventBridge.sanitizeForReference('Access Control'),
            'Spaces should be replaced with underscores');
        Assert.areEqual('CC6_1',
            RuleEngineEventBridge.sanitizeForReference('CC6.1'),
            'Dots should be replaced with underscores');
        Assert.areEqual('UNKNOWN',
            RuleEngineEventBridge.sanitizeForReference(null),
            'Null should return UNKNOWN');
        Assert.areEqual('UNKNOWN',
            RuleEngineEventBridge.sanitizeForReference(''),
            'Empty should return UNKNOWN');
    }

    @IsTest
    static void shouldBuildGapSummary() {
        IComplianceModule.Gap gap = new IComplianceModule.Gap();
        gap.controlName = 'Access Control';
        gap.description = 'Excessive admin permissions';
        gap.recommendation = 'Implement least privilege';

        String summary = RuleEngineEventBridge.buildGapSummary(gap);

        Assert.isTrue(summary.contains('Access Control'),
            'Summary should contain control name');
        Assert.isTrue(summary.contains('Excessive admin permissions'),
            'Summary should contain description');
        Assert.isTrue(summary.contains('Implement least privilege'),
            'Summary should contain recommendation');
    }

    @IsTest
    static void shouldBuildGapSummaryWithMinimalData() {
        IComplianceModule.Gap gap = new IComplianceModule.Gap();
        gap.description = 'A gap';

        String summary = RuleEngineEventBridge.buildGapSummary(gap);

        Assert.areEqual('A gap', summary, 'Summary should be just the description');
    }

    @IsTest
    static void shouldBuildBreachSummary() {
        BreachPatternMatcher.PatternAnalysis analysis =
            new BreachPatternMatcher.PatternAnalysis('Brute Force');
        analysis.matchedEventCount = 5;
        analysis.timeWindowMinutes = 15;
        analysis.threatScore = 8.5;

        String summary = RuleEngineEventBridge.buildBreachSummary(analysis);

        Assert.isTrue(summary.contains('Brute Force'),
            'Summary should contain pattern name');
        Assert.isTrue(summary.contains('5 events'),
            'Summary should contain event count');
        Assert.isTrue(summary.contains('15 min'),
            'Summary should contain time window');
        Assert.isTrue(summary.contains('8.5'),
            'Summary should contain threat score');
    }

    @IsTest
    static void shouldBuildDriftSummary() {
        ConfigDriftDetector.DriftEvent drift = new ConfigDriftDetector.DriftEvent(
            'MFA Disabled', 'admin@test.org', 'Security Controls', ElaroConstants.SEVERITY_HIGH
        );
        drift.oldValue = 'Required';
        drift.newValue = 'Optional';

        String summary = RuleEngineEventBridge.buildDriftSummary(drift);

        Assert.isTrue(summary.contains('MFA Disabled'),
            'Summary should contain change type');
        Assert.isTrue(summary.contains('Security Controls'),
            'Summary should contain changed object');
        Assert.isTrue(summary.contains('admin@test.org'),
            'Summary should contain changed by');
        Assert.isTrue(summary.contains('Required'),
            'Summary should contain old value');
        Assert.isTrue(summary.contains('Optional'),
            'Summary should contain new value');
    }

    // =========================================================================
    // ComplianceFinding Constructor Tests
    // =========================================================================

    @IsTest
    static void shouldConstructComplianceFinding() {
        RuleEngineEventBridge.ComplianceFinding finding =
            new RuleEngineEventBridge.ComplianceFinding(
                'SOC2', 'CC6.1', ElaroConstants.SEVERITY_HIGH, 'Test finding'
            );

        Assert.areEqual('SOC2', finding.framework, 'Framework should match');
        Assert.areEqual('CC6.1', finding.controlReference, 'Control reference should match');
        Assert.areEqual(ElaroConstants.SEVERITY_HIGH, finding.severity, 'Severity should match');
        Assert.areEqual('Test finding', finding.findingSummary, 'Summary should match');
        Assert.areEqual(ComplianceAlertPublisher.ALERT_TYPE_FINDING, finding.alertType,
            'Default alert type should be FINDING');
        Assert.isNotNull(finding.detectedAt, 'Detected time should be set');
    }

    @IsTest
    static void shouldDefaultSeverityInComplianceFinding() {
        RuleEngineEventBridge.ComplianceFinding finding =
            new RuleEngineEventBridge.ComplianceFinding(
                'SOC2', 'CC6.1', null, 'Test finding'
            );

        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM, finding.severity,
            'Null severity should default to MEDIUM');
    }

    // =========================================================================
    // publishViolationsAsAlerts
    // =========================================================================

    @IsTest
    static void shouldHandleNullServiceInViolationsPublish() {
        Test.startTest();
        List<RuleEngineEventBridge.ComplianceFinding> findings =
            RuleEngineEventBridge.publishViolationsAsAlerts(null);
        Test.stopTest();

        Assert.isTrue(findings.isEmpty(), 'Null service should return empty findings');
    }
}
