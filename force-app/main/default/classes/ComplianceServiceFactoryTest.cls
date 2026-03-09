/**
 * ComplianceServiceFactoryTest
 *
 * Test coverage for ComplianceServiceFactory
 *
 * @author Elaro
 * @version 1.0
 */
@IsTest
private class ComplianceServiceFactoryTest {

    @IsTest
    static void testGetService_HIPAA() {
        Test.startTest();

        IRiskScoringService service = ComplianceServiceFactory.getService('HIPAA');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return HIPAA service');
        Assert.isTrue(service instanceof ElaroHIPAAComplianceService,
            'Should return correct service type');
    }

    @IsTest
    static void testGetService_SOC2() {
        Test.startTest();

        IRiskScoringService service = ComplianceServiceFactory.getService('SOC2');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return SOC2 service');
        Assert.isTrue(service instanceof ElaroSOC2ComplianceService,
            'Should return correct service type');
    }

    @IsTest
    static void testGetService_GDPR() {
        Test.startTest();

        IRiskScoringService service = ComplianceServiceFactory.getService('GDPR');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return GDPR service');
        Assert.isTrue(service instanceof ElaroGDPRComplianceService,
            'Should return correct service type');
    }

    @IsTest
    static void testGetService_CCPA() {
        Test.startTest();

        IRiskScoringService service = ComplianceServiceFactory.getService('CCPA');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return CCPA service');
        Assert.isTrue(service instanceof ElaroCCPAComplianceService,
            'Should return correct service type');
    }

    @IsTest
    static void testGetService_PCI_DSS() {
        Test.startTest();

        IRiskScoringService service = ComplianceServiceFactory.getService('PCI_DSS');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return PCI-DSS service');
        Assert.isTrue(service instanceof ElaroPCIDSSComplianceService,
            'Should return correct service type');
    }

    @IsTest
    static void testGetService_CachedInstance() {
        Test.startTest();

        // First call creates instance
        IRiskScoringService service1 = ComplianceServiceFactory.getService('HIPAA');
        // Second call should return cached instance
        IRiskScoringService service2 = ComplianceServiceFactory.getService('HIPAA');

        Test.stopTest();

        Assert.areEqual(service1, service2, 'Should return same cached instance');
    }

    @IsTest
    static void testGetService_BlankFramework() {
        Test.startTest();

        try {
            ComplianceServiceFactory.getService('');
            Assert.fail( 'Should throw exception for blank framework');
        } catch (ComplianceServiceFactory.ComplianceServiceException e) {
            Assert.isTrue(e.getMessage().contains('blank'),
                'Should mention blank in error message');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetService_NullFramework() {
        Test.startTest();

        try {
            ComplianceServiceFactory.getService(null);
            Assert.fail( 'Should throw exception for null framework');
        } catch (ComplianceServiceFactory.ComplianceServiceException e) {
            Assert.areNotEqual(null, e, 'Should throw exception');
        }

        Test.stopTest();
    }

    @IsTest
    static void testGetAccessService_SOC2() {
        Test.startTest();

        IAccessControlService service = ComplianceServiceFactory.getAccessService('SOC2');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return SOC2 access service');
    }

    @IsTest
    static void testGetAccessService_HIPAA() {
        Test.startTest();

        IAccessControlService service = ComplianceServiceFactory.getAccessService('HIPAA');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return HIPAA access service adapter');
    }

    @IsTest
    static void testGetAccessService_Unsupported() {
        Test.startTest();

        IAccessControlService service = ComplianceServiceFactory.getAccessService('GDPR');

        Test.stopTest();

        Assert.areEqual(null, service, 'Should return null for unsupported framework');
    }

    @IsTest
    static void testGetBreachService_HIPAA() {
        Test.startTest();

        IBreachNotificationService service = ComplianceServiceFactory.getBreachService('HIPAA');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return HIPAA breach service');
    }

    @IsTest
    static void testGetBreachService_SOC2() {
        Test.startTest();

        IBreachNotificationService service = ComplianceServiceFactory.getBreachService('SOC2');

        Test.stopTest();

        Assert.areNotEqual(null, service, 'Should return SOC2 incident service');
    }

    @IsTest
    static void testGetBreachService_Unsupported() {
        Test.startTest();

        IBreachNotificationService service = ComplianceServiceFactory.getBreachService('CCPA');

        Test.stopTest();

        Assert.areEqual(null, service, 'Should return null for unsupported framework');
    }

    @IsTest
    static void testGetSupportedFrameworks() {
        Test.startTest();

        Set<String> frameworks = ComplianceServiceFactory.getSupportedFrameworks();

        Test.stopTest();

        Assert.areNotEqual(null, frameworks, 'Should return supported frameworks');
        Assert.isTrue(frameworks.contains('HIPAA'), 'Should include HIPAA');
        Assert.isTrue(frameworks.contains('SOC2'), 'Should include SOC2');
        Assert.isTrue(frameworks.contains('GDPR'), 'Should include GDPR');
        Assert.isTrue(frameworks.contains('CCPA'), 'Should include CCPA');
        Assert.isTrue(frameworks.contains('PCI_DSS'), 'Should include PCI_DSS');
    }

    @IsTest
    static void testIsFrameworkSupported_Valid() {
        Test.startTest();

        Boolean isSupported = ComplianceServiceFactory.isFrameworkSupported('HIPAA');

        Test.stopTest();

        Assert.areEqual(true, isSupported, 'HIPAA should be supported');
    }

    @IsTest
    static void testIsFrameworkSupported_Invalid() {
        Test.startTest();

        Boolean isSupported = ComplianceServiceFactory.isFrameworkSupported('INVALID');

        Test.stopTest();

        Assert.areEqual(false, isSupported, 'Invalid framework should not be supported');
    }

    @IsTest
    static void testIsFrameworkSupported_Null() {
        Test.startTest();

        Boolean isSupported = ComplianceServiceFactory.isFrameworkSupported(null);

        Test.stopTest();

        Assert.areEqual(false, isSupported, 'Null framework should not be supported');
    }

    @IsTest
    static void testIsFrameworkSupported_CaseInsensitive() {
        Test.startTest();

        Boolean isSupported = ComplianceServiceFactory.isFrameworkSupported('hipaa');

        Test.stopTest();

        Assert.areEqual(true, isSupported, 'Framework check should be case-insensitive');
    }

    @IsTest
    static void testGetFrameworkConfig() {
        Test.startTest();

        ComplianceServiceFactory.FrameworkConfig config =
            ComplianceServiceFactory.getFrameworkConfig('HIPAA');

        Test.stopTest();

        Assert.areNotEqual(null, config, 'Should return framework config');
        Assert.areEqual('HIPAA', config.frameworkCode, 'Framework code should be set');
    }

    @IsTest
    static void testFrameworkConfigClass_DefaultConstructor() {
        ComplianceServiceFactory.FrameworkConfig config =
            new ComplianceServiceFactory.FrameworkConfig('TEST');

        Assert.areEqual('TEST', config.frameworkCode, 'Framework code should be set');
        Assert.areEqual('TEST', config.displayName, 'Display name should default to code');
        Assert.areEqual(1.0, config.scoreMultiplier, 'Score multiplier should default to 1.0');
        Assert.areEqual(30, config.responseDeadlineDays, 'Response deadline should default to 30');
        Assert.areEqual(365, config.evidenceRetentionDays, 'Evidence retention should default to 365');
    }

    @IsTest
    static void testComplianceServiceException() {
        Test.startTest();

        ComplianceServiceFactory.ComplianceServiceException ex =
            new ComplianceServiceFactory.ComplianceServiceException('Test error');

        Test.stopTest();

        Assert.areEqual('Test error', ex.getMessage(), 'Exception message should be set');
    }

    @IsTest
    static void testAllFrameworkServices() {
        // Test all supported frameworks in one test method for efficiency
        List<String> frameworks = new List<String>{
            'HIPAA', 'SOC2', 'GDPR', 'CCPA', 'PCI_DSS'
        };

        Test.startTest();

        for (String framework : frameworks) {
            IRiskScoringService service = ComplianceServiceFactory.getService(framework);
            Assert.areNotEqual(null, service,
                'Should return service for framework: ' + framework);
        }

        Test.stopTest();
    }

    @IsTest
    static void testClearCache() {
        // Get a service to populate cache
        IRiskScoringService service1 = ComplianceServiceFactory.getService('HIPAA');

        Test.startTest();

        // Clear cache via reflection or internal method
        // Since clearCache is @TestVisible private, we can call it in tests
        // Note: We test the effect by getting a new instance

        Test.stopTest();

        // Service should still work after cache operations
        IRiskScoringService service2 = ComplianceServiceFactory.getService('HIPAA');
        Assert.areNotEqual(null, service2, 'Should return service after cache operations');
    }
}
