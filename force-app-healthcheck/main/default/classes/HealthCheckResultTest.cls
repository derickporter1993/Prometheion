/**
 * Tests for {@link HealthCheckResult} covering default constructor initialization,
 * field access, JSON serialization round-trip, and property mutation.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see HealthCheckResult
 */
@IsTest(testFor = HealthCheckResult.class)
private class HealthCheckResultTest {

    @IsTest
    static void shouldInitializeOverallScoreToZero() {
        Test.startTest();
        HealthCheckResult result = new HealthCheckResult();
        Test.stopTest();

        Assert.areEqual(0, result.overallScore,
            'Default constructor should set overallScore to 0');
    }

    @IsTest
    static void shouldInitializeEmptyCollections() {
        Test.startTest();
        HealthCheckResult result = new HealthCheckResult();
        Test.stopTest();

        Assert.isNotNull(result.categoryScores,
            'categoryScores should be initialized, not null');
        Assert.isTrue(result.categoryScores.isEmpty(),
            'categoryScores should be empty by default');
        Assert.isNotNull(result.findings,
            'findings should be initialized, not null');
        Assert.isTrue(result.findings.isEmpty(),
            'findings should be empty by default');
        Assert.isNotNull(result.recommendations,
            'recommendations should be initialized, not null');
        Assert.isTrue(result.recommendations.isEmpty(),
            'recommendations should be empty by default');
    }

    @IsTest
    static void shouldInitializeScanTimestamp() {
        Datetime before = Datetime.now();

        Test.startTest();
        HealthCheckResult result = new HealthCheckResult();
        Test.stopTest();

        Datetime after = Datetime.now();
        Assert.isNotNull(result.scanTimestamp,
            'scanTimestamp should be set on construction');
        Assert.isTrue(result.scanTimestamp >= before && result.scanTimestamp <= after,
            'scanTimestamp should be within the test execution window');
    }

    @IsTest
    static void shouldInitializeMfaFieldsToZero() {
        Test.startTest();
        HealthCheckResult result = new HealthCheckResult();
        Test.stopTest();

        Assert.areEqual(0, result.mfaPercentage,
            'Default mfaPercentage should be 0');
        Assert.areEqual(0, result.totalUsers,
            'Default totalUsers should be 0');
        Assert.areEqual(0, result.mfaUsers,
            'Default mfaUsers should be 0');
    }

    @IsTest
    static void shouldAllowPropertyMutation() {
        HealthCheckResult result = new HealthCheckResult();

        Test.startTest();
        result.overallScore = 85;
        result.mfaPercentage = 72;
        result.totalUsers = 200;
        result.mfaUsers = 144;
        result.categoryScores.put('SecurityHealthCheck', 90);
        result.categoryScores.put('MFA', 72);
        result.findings.add(
            new ScanFinding('MFA', 'MFA Coverage', '72%', '100%', 'MEDIUM_RISK', 'MFA not fully deployed')
        );
        result.recommendations.add(
            new ScanRecommendation('Enable MFA', 'Deploy MFA org-wide', 'SecuritySession/home', 1, 'MFA')
        );
        Test.stopTest();

        Assert.areEqual(85, result.overallScore,
            'overallScore should reflect updated value');
        Assert.areEqual(72, result.mfaPercentage,
            'mfaPercentage should reflect updated value');
        Assert.areEqual(200, result.totalUsers,
            'totalUsers should reflect updated value');
        Assert.areEqual(144, result.mfaUsers,
            'mfaUsers should reflect updated value');
        Assert.areEqual(2, result.categoryScores.size(),
            'categoryScores should contain 2 entries');
        Assert.areEqual(1, result.findings.size(),
            'findings should contain 1 entry');
        Assert.areEqual(1, result.recommendations.size(),
            'recommendations should contain 1 entry');
    }

    @IsTest
    static void shouldSerializeToJsonAndDeserialize() {
        HealthCheckResult original = new HealthCheckResult();
        original.overallScore = 73;
        original.mfaPercentage = 60;
        original.totalUsers = 100;
        original.mfaUsers = 60;
        original.categoryScores.put('SecurityHealthCheck', 80);
        original.findings.add(
            new ScanFinding('Session', 'Timeout', '12h', '2h', 'HIGH_RISK', 'Session timeout too long')
        );

        Test.startTest();
        String jsonString = JSON.serialize(original);
        HealthCheckResult deserialized = (HealthCheckResult) JSON.deserialize(
            jsonString, HealthCheckResult.class
        );
        Test.stopTest();

        Assert.isNotNull(deserialized,
            'Deserialized result should not be null');
        Assert.areEqual(original.overallScore, deserialized.overallScore,
            'overallScore should survive serialization round-trip');
        Assert.areEqual(original.mfaPercentage, deserialized.mfaPercentage,
            'mfaPercentage should survive serialization round-trip');
        Assert.areEqual(original.totalUsers, deserialized.totalUsers,
            'totalUsers should survive serialization round-trip');
        Assert.areEqual(original.mfaUsers, deserialized.mfaUsers,
            'mfaUsers should survive serialization round-trip');
        Assert.areEqual(1, deserialized.findings.size(),
            'findings should survive serialization round-trip');
    }

    @IsTest
    static void shouldHandleLargeCategoryScoresMap() {
        HealthCheckResult result = new HealthCheckResult();

        Test.startTest();
        result.categoryScores.put('SecurityHealthCheck', 80);
        result.categoryScores.put('MFA', 60);
        result.categoryScores.put('Permissions', 70);
        result.categoryScores.put('Session', 90);
        result.categoryScores.put('AuditTrail', 50);
        Test.stopTest();

        Assert.areEqual(5, result.categoryScores.size(),
            'categoryScores should hold all 5 scanner categories');
        Assert.areEqual(80, result.categoryScores.get('SecurityHealthCheck'),
            'SecurityHealthCheck score should be 80');
        Assert.areEqual(50, result.categoryScores.get('AuditTrail'),
            'AuditTrail score should be 50');
    }
}
