/**
 * Tests for {@link ScanFinding} covering parameterized construction,
 * default construction, field access, severity values, and JSON serialization.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Health Check
 * @see ScanFinding
 */
@IsTest(testFor = ScanFinding.class)
private class ScanFindingTest {

    @IsTest
    static void shouldConstructWithAllFields() {
        Test.startTest();
        ScanFinding finding = new ScanFinding(
            'SecurityHealthCheck',
            'Password Minimum Length',
            '8',
            '12',
            'HIGH_RISK',
            'Password minimum length is below recommended threshold'
        );
        Test.stopTest();

        Assert.areEqual('SecurityHealthCheck', finding.category,
            'category should match constructor argument');
        Assert.areEqual('Password Minimum Length', finding.setting,
            'setting should match constructor argument');
        Assert.areEqual('8', finding.currentValue,
            'currentValue should match constructor argument');
        Assert.areEqual('12', finding.recommendedValue,
            'recommendedValue should match constructor argument');
        Assert.areEqual('HIGH_RISK', finding.severity,
            'severity should match constructor argument');
        Assert.areEqual('Password minimum length is below recommended threshold',
            finding.description,
            'description should match constructor argument');
    }

    @IsTest
    static void shouldConstructWithDefaultConstructor() {
        Test.startTest();
        ScanFinding finding = new ScanFinding();
        Test.stopTest();

        Assert.isNull(finding.category,
            'Default constructor should leave category null');
        Assert.isNull(finding.setting,
            'Default constructor should leave setting null');
        Assert.isNull(finding.currentValue,
            'Default constructor should leave currentValue null');
        Assert.isNull(finding.recommendedValue,
            'Default constructor should leave recommendedValue null');
        Assert.isNull(finding.severity,
            'Default constructor should leave severity null');
        Assert.isNull(finding.description,
            'Default constructor should leave description null');
    }

    @IsTest
    static void shouldSupportHighRiskSeverity() {
        Test.startTest();
        ScanFinding finding = new ScanFinding(
            'SecurityHealthCheck', 'Test Setting', 'bad', 'good', 'HIGH_RISK', 'High risk finding'
        );
        Test.stopTest();

        Assert.areEqual('HIGH_RISK', finding.severity,
            'Should store HIGH_RISK severity');
    }

    @IsTest
    static void shouldSupportMediumRiskSeverity() {
        Test.startTest();
        ScanFinding finding = new ScanFinding(
            'MFA', 'MFA Coverage', '60%', '100%', 'MEDIUM_RISK', 'MFA not fully deployed'
        );
        Test.stopTest();

        Assert.areEqual('MEDIUM_RISK', finding.severity,
            'Should store MEDIUM_RISK severity');
    }

    @IsTest
    static void shouldSupportLowRiskSeverity() {
        Test.startTest();
        ScanFinding finding = new ScanFinding(
            'Session', 'Session Timeout', '4h', '2h', 'LOW_RISK', 'Session timeout slightly above recommended'
        );
        Test.stopTest();

        Assert.areEqual('LOW_RISK', finding.severity,
            'Should store LOW_RISK severity');
    }

    @IsTest
    static void shouldAllowFieldMutationAfterConstruction() {
        ScanFinding finding = new ScanFinding(
            'Permissions', 'Profile Count', '50', '20', 'MEDIUM_RISK', 'Too many profiles'
        );

        Test.startTest();
        finding.category = 'AuditTrail';
        finding.setting = 'Updated Setting';
        finding.severity = 'HIGH_RISK';
        Test.stopTest();

        Assert.areEqual('AuditTrail', finding.category,
            'category should be mutable after construction');
        Assert.areEqual('Updated Setting', finding.setting,
            'setting should be mutable after construction');
        Assert.areEqual('HIGH_RISK', finding.severity,
            'severity should be mutable after construction');
    }

    @IsTest
    static void shouldSerializeToJsonAndDeserialize() {
        ScanFinding original = new ScanFinding(
            'MFA', 'MFA Enrollment', '75%', '100%', 'MEDIUM_RISK', 'Not all users enrolled in MFA'
        );

        Test.startTest();
        String jsonString = JSON.serialize(original);
        ScanFinding deserialized = (ScanFinding) JSON.deserialize(jsonString, ScanFinding.class);
        Test.stopTest();

        Assert.isNotNull(deserialized,
            'Deserialized finding should not be null');
        Assert.areEqual(original.category, deserialized.category,
            'category should survive serialization round-trip');
        Assert.areEqual(original.setting, deserialized.setting,
            'setting should survive serialization round-trip');
        Assert.areEqual(original.currentValue, deserialized.currentValue,
            'currentValue should survive serialization round-trip');
        Assert.areEqual(original.recommendedValue, deserialized.recommendedValue,
            'recommendedValue should survive serialization round-trip');
        Assert.areEqual(original.severity, deserialized.severity,
            'severity should survive serialization round-trip');
        Assert.areEqual(original.description, deserialized.description,
            'description should survive serialization round-trip');
    }

    @IsTest
    static void shouldHandleNullConstructorArguments() {
        Test.startTest();
        ScanFinding finding = new ScanFinding(null, null, null, null, null, null);
        Test.stopTest();

        Assert.isNull(finding.category,
            'Null category argument should result in null field');
        Assert.isNull(finding.setting,
            'Null setting argument should result in null field');
        Assert.isNull(finding.severity,
            'Null severity argument should result in null field');
    }
}
