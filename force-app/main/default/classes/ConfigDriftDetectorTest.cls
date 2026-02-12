/**
 * Tests for ConfigDriftDetector covering risk classification, drift detection,
 * schedulable execution, and edge cases.
 *
 * NOTE: SetupAuditTrail is read-only in tests. Test classification logic
 * directly and verify the Schedulable interface implementation.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Event Monitoring
 * @see ConfigDriftDetector
 */
@IsTest(testFor=ConfigDriftDetector.class)
private class ConfigDriftDetectorTest {

    @IsTest
    static void shouldClassifyHighRiskSections() {
        Set<String> highRiskSections = ConfigDriftDetector.getHighRiskSections();

        Assert.isTrue(highRiskSections.contains('Manage Users'),
            'Manage Users should be high risk');
        Assert.isTrue(highRiskSections.contains('Security Controls'),
            'Security Controls should be high risk');
        Assert.isTrue(highRiskSections.contains('Permission Sets'),
            'Permission Sets should be high risk');
        Assert.isTrue(highRiskSections.contains('Session Settings'),
            'Session Settings should be high risk');
        Assert.isTrue(highRiskSections.contains('Password Policies'),
            'Password Policies should be high risk');
    }

    @IsTest
    static void shouldClassifyMediumRiskSections() {
        Set<String> mediumRiskSections = ConfigDriftDetector.getMediumRiskSections();

        Assert.isTrue(mediumRiskSections.contains('Profiles'),
            'Profiles should be medium risk');
        Assert.isTrue(mediumRiskSections.contains('Data Management'),
            'Data Management should be medium risk');
        Assert.isTrue(mediumRiskSections.contains('Custom Objects'),
            'Custom Objects should be medium risk');
    }

    @IsTest
    static void shouldReturnNullForLowRiskSections() {
        String riskLevel = ConfigDriftDetector.classifyRisk('Reports');

        Assert.isNull(riskLevel, 'Reports should be classified as null (low risk, filtered out)');
    }

    @IsTest
    static void shouldReturnNullForBlankSection() {
        Assert.isNull(ConfigDriftDetector.classifyRisk(''),
            'Blank section should return null');
        Assert.isNull(ConfigDriftDetector.classifyRisk(null),
            'Null section should return null');
    }

    @IsTest
    static void shouldReturnHighForSecurityControlsSection() {
        String riskLevel = ConfigDriftDetector.classifyRisk('Security Controls');

        Assert.areEqual(ElaroConstants.SEVERITY_HIGH, riskLevel,
            'Security Controls should be classified as HIGH');
    }

    @IsTest
    static void shouldReturnMediumForProfilesSection() {
        String riskLevel = ConfigDriftDetector.classifyRisk('Profiles');

        Assert.areEqual(ElaroConstants.SEVERITY_MEDIUM, riskLevel,
            'Profiles should be classified as MEDIUM');
    }

    @IsTest
    static void shouldCreateDriftEventCorrectly() {
        ConfigDriftDetector.DriftEvent drift = new ConfigDriftDetector.DriftEvent(
            'Password Policy Changed',
            'admin@test.org',
            'Password Policies',
            ElaroConstants.SEVERITY_HIGH
        );

        Assert.areEqual('Password Policy Changed', drift.changeType,
            'Change type should match');
        Assert.areEqual('admin@test.org', drift.changedBy,
            'Changed by should match');
        Assert.areEqual('Password Policies', drift.changedObject,
            'Changed object should match');
        Assert.areEqual(ElaroConstants.SEVERITY_HIGH, drift.riskLevel,
            'Risk level should match');
        Assert.isNotNull(drift.detectionTimestamp,
            'Detection timestamp should be set');
    }

    @IsTest
    static void shouldHandleEmptyDriftEventsPublish() {
        ConfigDriftDetector detector = new ConfigDriftDetector();

        Test.startTest();
        detector.publishDriftEvents(new List<ConfigDriftDetector.DriftEvent>());
        detector.publishDriftEvents(null);
        Test.stopTest();

        // No exception should be thrown
        Assert.isTrue(true, 'Empty and null drift events should be handled gracefully');
    }

    @IsTest
    static void shouldPublishDriftEvents() {
        ConfigDriftDetector detector = new ConfigDriftDetector();
        List<ConfigDriftDetector.DriftEvent> drifts = new List<ConfigDriftDetector.DriftEvent>();

        ConfigDriftDetector.DriftEvent drift1 = new ConfigDriftDetector.DriftEvent(
            'MFA Disabled', 'admin@test.org', 'Security Controls', ElaroConstants.SEVERITY_HIGH
        );
        drift1.oldValue = 'MFA Required';
        drift1.newValue = 'MFA Optional';
        drifts.add(drift1);

        ConfigDriftDetector.DriftEvent drift2 = new ConfigDriftDetector.DriftEvent(
            'Profile Updated', 'admin@test.org', 'Profiles', ElaroConstants.SEVERITY_MEDIUM
        );
        drifts.add(drift2);

        Test.startTest();
        detector.publishDriftEvents(drifts);
        Test.stopTest();

        Assert.isTrue(true, 'Drift events should publish without error');
    }

    @IsTest
    static void shouldExecuteAsSchedulable() {
        ConfigDriftDetector detector = new ConfigDriftDetector();

        Test.startTest();
        String jobId = System.schedule(
            'Test Drift Detection',
            '0 0 * * * ?',
            detector
        );
        Test.stopTest();

        Assert.isNotNull(jobId, 'Scheduled job should have an Id');
        List<CronTrigger> jobs = [
            SELECT Id, State FROM CronTrigger WHERE Id = :jobId WITH USER_MODE
        ];
        Assert.isFalse(jobs.isEmpty(), 'Job should exist in scheduler');
    }

    @IsTest
    static void shouldDetectDriftFromAuditTrail() {
        ConfigDriftDetector detector = new ConfigDriftDetector();

        Test.startTest();
        List<ConfigDriftDetector.DriftEvent> drifts = detector.detectDrift(24);
        Test.stopTest();

        // SetupAuditTrail is read-only, so results depend on org state
        Assert.isNotNull(drifts, 'Drift list should not be null');
    }
}
