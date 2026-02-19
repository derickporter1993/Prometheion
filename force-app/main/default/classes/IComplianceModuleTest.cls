/**
 * Integration tests for {@link IComplianceModule} verifying that concrete module
 * implementations fulfill the interface contract. Tests the factory registration
 * pattern via {@link ComplianceServiceFactory} and validates that HIPAAModule,
 * SOC2Module, and GDPRModule implement all required interface methods correctly.
 *
 * @author Elaro Team
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 * @see IComplianceModule
 * @see ComplianceServiceFactory
 * @see HIPAAModule
 * @see SOC2Module
 * @see GDPRModule
 */
@IsTest(testFor=IComplianceModule.class)
private class IComplianceModuleTest {

    @IsTest
    static void shouldReturnFrameworkNameAndVersionForAllModules() {
        HIPAAModule hipaa = new HIPAAModule();
        SOC2Module soc2 = new SOC2Module();
        GDPRModule gdpr = new GDPRModule();

        Test.startTest();
        String hipaaName = hipaa.getFrameworkName();
        String hipaaVersion = hipaa.getFrameworkVersion();
        String soc2Name = soc2.getFrameworkName();
        String soc2Version = soc2.getFrameworkVersion();
        String gdprName = gdpr.getFrameworkName();
        String gdprVersion = gdpr.getFrameworkVersion();
        Test.stopTest();

        Assert.areEqual('HIPAA', hipaaName, 'HIPAA module should return HIPAA as framework name');
        Assert.isNotNull(hipaaVersion, 'HIPAA module should return a non-null version');
        Assert.areEqual('SOC2', soc2Name, 'SOC2 module should return SOC2 as framework name');
        Assert.isNotNull(soc2Version, 'SOC2 module should return a non-null version');
        Assert.areEqual('GDPR', gdprName, 'GDPR module should return GDPR as framework name');
        Assert.isNotNull(gdprVersion, 'GDPR module should return a non-null version');
    }

    @IsTest
    static void shouldReturnNonEmptyControlsForAllModules() {
        HIPAAModule hipaa = new HIPAAModule();
        SOC2Module soc2 = new SOC2Module();
        GDPRModule gdpr = new GDPRModule();

        Test.startTest();
        List<IComplianceModule.Control> hipaaControls = hipaa.getControls();
        List<IComplianceModule.Control> soc2Controls = soc2.getControls();
        List<IComplianceModule.Control> gdprControls = gdpr.getControls();
        Test.stopTest();

        Assert.isNotNull(hipaaControls, 'HIPAA controls should not be null');
        Assert.isFalse(hipaaControls.isEmpty(), 'HIPAA should have at least one control');

        Assert.isNotNull(soc2Controls, 'SOC2 controls should not be null');
        Assert.isFalse(soc2Controls.isEmpty(), 'SOC2 should have at least one control');

        Assert.isNotNull(gdprControls, 'GDPR controls should not be null');
        Assert.isFalse(gdprControls.isEmpty(), 'GDPR should have at least one control');

        // Verify control structure completeness
        for (IComplianceModule.Control ctrl : hipaaControls) {
            Assert.isNotNull(ctrl.code, 'HIPAA control code should not be null');
            Assert.isNotNull(ctrl.name, 'HIPAA control name should not be null');
            Assert.isNotNull(ctrl.severity, 'HIPAA control severity should not be null');
        }
    }

    @IsTest
    static void shouldReturnControlByIdAndNullForInvalidId() {
        HIPAAModule hipaa = new HIPAAModule();
        SOC2Module soc2 = new SOC2Module();

        Test.startTest();
        IComplianceModule.Control hipaaCtrl = hipaa.getControlById('164.312(a)');
        IComplianceModule.Control hipaaNull = hipaa.getControlById('INVALID_CONTROL_ID');
        IComplianceModule.Control soc2Ctrl = soc2.getControlById('CC6.1');
        IComplianceModule.Control soc2Null = soc2.getControlById('NONEXISTENT');
        Test.stopTest();

        Assert.isNotNull(hipaaCtrl, 'Should find HIPAA control 164.312(a)');
        Assert.areEqual('164.312(a)', hipaaCtrl.code, 'Control code should match 164.312(a)');
        Assert.isNull(hipaaNull, 'Should return null for invalid HIPAA control ID');

        Assert.isNotNull(soc2Ctrl, 'Should find SOC2 control CC6.1');
        Assert.areEqual('CC6.1', soc2Ctrl.code, 'Control code should match CC6.1');
        Assert.isNull(soc2Null, 'Should return null for invalid SOC2 control ID');
    }

    @IsTest
    static void shouldCalculateScoreAsZeroForNullAuditPackageId() {
        HIPAAModule hipaa = new HIPAAModule();
        SOC2Module soc2 = new SOC2Module();
        GDPRModule gdpr = new GDPRModule();

        Test.startTest();
        Decimal hipaaScore = hipaa.calculateScore(null);
        Decimal soc2Score = soc2.calculateScore(null);
        Decimal gdprScore = gdpr.calculateScore(null);
        Test.stopTest();

        Assert.areEqual(0, hipaaScore, 'HIPAA score should be 0 for null audit package');
        Assert.areEqual(0, soc2Score, 'SOC2 score should be 0 for null audit package');
        Assert.areEqual(0, gdprScore, 'GDPR score should be 0 for null audit package');
    }

    @IsTest
    static void shouldEvaluateControlAndReturnValidResult() {
        HIPAAModule hipaa = new HIPAAModule();

        Map<String, Object> context = new Map<String, Object>{
            'auditPackageId' => null
        };

        Test.startTest();
        IComplianceModule.ControlResult result = hipaa.evaluateControl(
            '164.312(e)', context
        );
        Test.stopTest();

        Assert.isNotNull(result, 'Control evaluation result should not be null');
        Assert.areEqual('164.312(e)', result.controlId, 'Result controlId should match requested control');
        Assert.isNotNull(result.status, 'Result status should not be null');
        Assert.isNotNull(result.finding, 'Result finding should not be null');
        Assert.isNotNull(result.evaluatedAt, 'Result evaluatedAt should be set');
    }

    @IsTest
    static void shouldGenerateReportBlobInTestContext() {
        HIPAAModule hipaa = new HIPAAModule();
        SOC2Module soc2 = new SOC2Module();
        GDPRModule gdpr = new GDPRModule();

        // Use a fake Id since we are in test context and the modules
        // return Blob.valueOf() when Test.isRunningTest() is true
        Id fakeId = '001000000000001AAA';

        Test.startTest();
        Blob hipaaReport = hipaa.generateReport(fakeId);
        Blob soc2Report = soc2.generateReport(fakeId);
        Blob gdprReport = gdpr.generateReport(fakeId);
        Test.stopTest();

        Assert.isNotNull(hipaaReport, 'HIPAA report blob should not be null');
        Assert.isTrue(hipaaReport.size() > 0, 'HIPAA report blob should have content');
        Assert.isNotNull(soc2Report, 'SOC2 report blob should not be null');
        Assert.isTrue(soc2Report.size() > 0, 'SOC2 report blob should have content');
        Assert.isNotNull(gdprReport, 'GDPR report blob should not be null');
        Assert.isTrue(gdprReport.size() > 0, 'GDPR report blob should have content');
    }

    @IsTest
    static void shouldVerifyFactoryReturnsServicesForSupportedFrameworks() {
        Test.startTest();
        Set<String> supportedFrameworks = ComplianceServiceFactory.getSupportedFrameworks();
        Boolean hipaaSupported = ComplianceServiceFactory.isFrameworkSupported('HIPAA');
        Boolean soc2Supported = ComplianceServiceFactory.isFrameworkSupported('SOC2');
        Boolean gdprSupported = ComplianceServiceFactory.isFrameworkSupported('GDPR');
        Boolean invalidSupported = ComplianceServiceFactory.isFrameworkSupported('INVALID');
        Boolean nullSupported = ComplianceServiceFactory.isFrameworkSupported(null);
        Test.stopTest();

        Assert.isNotNull(supportedFrameworks, 'Supported frameworks set should not be null');
        Assert.isFalse(supportedFrameworks.isEmpty(), 'Supported frameworks should not be empty');
        Assert.isTrue(hipaaSupported, 'HIPAA should be a supported framework');
        Assert.isTrue(soc2Supported, 'SOC2 should be a supported framework');
        Assert.isTrue(gdprSupported, 'GDPR should be a supported framework');
        Assert.isFalse(invalidSupported, 'INVALID should not be a supported framework');
        Assert.isFalse(nullSupported, 'null should not be a supported framework');
    }

    @IsTest
    static void shouldThrowWhenFactoryReceivesBlankFramework() {
        Test.startTest();
        try {
            ComplianceServiceFactory.getService('');
            Assert.fail('Should have thrown ComplianceServiceException for blank framework');
        } catch (ComplianceServiceFactory.ComplianceServiceException e) {
            Assert.isTrue(
                e.getMessage().contains('blank'),
                'Error should mention blank: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void shouldVerifyInnerClassDefaults() {
        Test.startTest();
        IComplianceModule.Control control = new IComplianceModule.Control();
        IComplianceModule.Gap gap = new IComplianceModule.Gap();
        IComplianceModule.ControlResult result = new IComplianceModule.ControlResult();
        Test.stopTest();

        // Control defaults
        Assert.isNotNull(control.relatedControls, 'Control relatedControls should be initialized');
        Assert.isNotNull(control.metadata, 'Control metadata should be initialized');
        Assert.isTrue(control.isRequired, 'Control isRequired should default to true');

        // Gap defaults
        Assert.areEqual('Open', gap.status, 'Gap status should default to Open');

        // ControlResult defaults
        Assert.isNotNull(result.evidenceIds, 'ControlResult evidenceIds should be initialized');
        Assert.isNotNull(result.evaluatedAt, 'ControlResult evaluatedAt should be initialized');
    }
}
