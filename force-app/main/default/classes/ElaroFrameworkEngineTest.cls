/**
 * Tests for ElaroFrameworkEngine
 *
 * Validates framework requirement retrieval and entity-to-requirement mapping
 * across SOC2, HIPAA, SOX, and generic frameworks.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 * @see ElaroFrameworkEngine
 */
@IsTest(testFor=ElaroFrameworkEngine.class)
private class ElaroFrameworkEngineTest {

    @IsTest
    static void shouldReturnEmptyListForBlankFramework() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements('');
        Test.stopTest();

        Assert.isNotNull(reqs, 'Result should never be null');
        Assert.areEqual(0, reqs.size(), 'Blank framework should return empty requirements list');
    }

    @IsTest
    static void shouldReturnEmptyListForNullFramework() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements(null);
        Test.stopTest();

        Assert.isNotNull(reqs, 'Result should never be null');
        Assert.areEqual(0, reqs.size(), 'Null framework should return empty requirements list');
    }

    @IsTest
    static void shouldReturnSOC2Requirements() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements('SOC2');
        Test.stopTest();

        Assert.areEqual(3, reqs.size(), 'SOC2 should return 3 requirements');
        Assert.areEqual('SOC2-CC6.1', reqs[0].code, 'First SOC2 requirement code should be SOC2-CC6.1');
        Assert.areEqual('PERMISSION_SET', reqs[0].entityType, 'First SOC2 requirement entity type should be PERMISSION_SET');
        Assert.areEqual('SOC2-CC6.2', reqs[1].code, 'Second SOC2 requirement code should be SOC2-CC6.2');
        Assert.areEqual('SOC2-CC6.6', reqs[2].code, 'Third SOC2 requirement code should be SOC2-CC6.6');
        Assert.areEqual('USER', reqs[2].entityType, 'Third SOC2 requirement entity type should be USER');
    }

    @IsTest
    static void shouldReturnHIPAARequirements() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements('HIPAA');
        Test.stopTest();

        Assert.areEqual(2, reqs.size(), 'HIPAA should return 2 requirements');
        Assert.areEqual('HIPAA-164.308', reqs[0].code, 'First HIPAA requirement code should be HIPAA-164.308');
        Assert.areEqual('HIPAA-164.312', reqs[1].code, 'Second HIPAA requirement code should be HIPAA-164.312');
        Assert.areEqual('FIELD_LEVEL_SECURITY', reqs[1].entityType,
            'Second HIPAA requirement entity type should be FIELD_LEVEL_SECURITY');
    }

    @IsTest
    static void shouldReturnSOXRequirements() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements('SOX');
        Test.stopTest();

        Assert.areEqual(1, reqs.size(), 'SOX should return 1 requirement');
        Assert.areEqual('SOX-404', reqs[0].code, 'SOX requirement code should be SOX-404');
        Assert.areEqual('SETUP_AUDIT_TRAIL', reqs[0].entityType,
            'SOX requirement entity type should be SETUP_AUDIT_TRAIL');
    }

    @IsTest
    static void shouldReturnGenericRequirementsForUnknownFramework() {
        Test.startTest();
        List<ElaroFrameworkEngine.FrameworkRequirement> reqs =
            ElaroFrameworkEngine.getFrameworkRequirements('CUSTOM_FRAMEWORK');
        Test.stopTest();

        Assert.areEqual(2, reqs.size(), 'Unknown framework should return 2 generic requirements');
        Assert.areEqual('CUSTOM_FRAMEWORK-001', reqs[0].code,
            'First generic requirement should use framework name as prefix');
        Assert.areEqual('PERMISSION_SET', reqs[0].entityType,
            'First generic requirement entity type should be PERMISSION_SET');
        Assert.areEqual('CUSTOM_FRAMEWORK-002', reqs[1].code,
            'Second generic requirement should use framework name as prefix');
        Assert.areEqual('SETUP_AUDIT_TRAIL', reqs[1].entityType,
            'Second generic requirement entity type should be SETUP_AUDIT_TRAIL');
    }

    @IsTest
    static void shouldMapPermissionSetEntityToSOC2Requirements() {
        Test.startTest();
        List<String> codes = ElaroFrameworkEngine.mapEntityToRequirements(
            'PERMISSION_SET', 'testId', 'SOC2');
        Test.stopTest();

        Assert.areEqual(2, codes.size(),
            'PERMISSION_SET entity should match 2 SOC2 requirements (CC6.1 and CC6.2)');
        Assert.isTrue(codes.contains('SOC2-CC6.1'),
            'PERMISSION_SET should map to SOC2-CC6.1');
        Assert.isTrue(codes.contains('SOC2-CC6.2'),
            'PERMISSION_SET should map to SOC2-CC6.2');
    }

    @IsTest
    static void shouldMapUserEntityToSOC2Requirements() {
        Test.startTest();
        List<String> codes = ElaroFrameworkEngine.mapEntityToRequirements(
            'USER', 'testUserId', 'SOC2');
        Test.stopTest();

        Assert.areEqual(1, codes.size(), 'USER entity should match 1 SOC2 requirement');
        Assert.areEqual('SOC2-CC6.6', codes[0], 'USER should map to SOC2-CC6.6');
    }

    @IsTest
    static void shouldReturnEmptyListWhenNoEntityTypeMatches() {
        Test.startTest();
        List<String> codes = ElaroFrameworkEngine.mapEntityToRequirements(
            'NONEXISTENT_TYPE', 'someId', 'SOC2');
        Test.stopTest();

        Assert.isNotNull(codes, 'Result should never be null');
        Assert.areEqual(0, codes.size(),
            'Non-matching entity type should return empty requirement codes list');
    }

    @IsTest
    static void shouldReturnEmptyCodesForBlankFrameworkInMapping() {
        Test.startTest();
        List<String> codes = ElaroFrameworkEngine.mapEntityToRequirements(
            'PERMISSION_SET', 'testId', '');
        Test.stopTest();

        Assert.isNotNull(codes, 'Result should never be null');
        Assert.areEqual(0, codes.size(),
            'Blank framework should yield no requirement codes');
    }

    @IsTest
    static void shouldInitializeMetadataMapInConstructor() {
        Test.startTest();
        ElaroFrameworkEngine.FrameworkRequirement req =
            new ElaroFrameworkEngine.FrameworkRequirement('TEST-001', 'Test description', 'CUSTOM');
        Test.stopTest();

        Assert.areEqual('TEST-001', req.code, 'Code should be set by constructor');
        Assert.areEqual('Test description', req.description, 'Description should be set by constructor');
        Assert.areEqual('CUSTOM', req.entityType, 'EntityType should be set by constructor');
        Assert.isNotNull(req.metadata, 'Metadata map should be initialized (not null)');
        Assert.areEqual(0, req.metadata.size(), 'Metadata map should be empty on construction');
    }
}
