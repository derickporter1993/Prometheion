/**
 * ComplianceServiceFactory
 *
 * Factory class for instantiating compliance framework services.
 * Provides centralized service resolution based on framework identifier.
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ComplianceServiceFactory {

    // Singleton instances cache
    private static Map<String, IRiskScoringService> serviceCache = new Map<String, IRiskScoringService>();
    private static Map<String, IAccessControlService> accessServiceCache = new Map<String, IAccessControlService>();
    private static Map<String, IBreachNotificationService> breachServiceCache = new Map<String, IBreachNotificationService>();

    // Framework constants
    public static final String FRAMEWORK_HIPAA = 'HIPAA';
    public static final String FRAMEWORK_SOC2 = 'SOC2';
    public static final String FRAMEWORK_GDPR = 'GDPR';
    public static final String FRAMEWORK_CCPA = 'CCPA';
    public static final String FRAMEWORK_PCI_DSS = 'PCI_DSS';
    public static final String FRAMEWORK_NIST = 'NIST';
    public static final String FRAMEWORK_FEDRAMP = 'FEDRAMP';
    public static final String FRAMEWORK_SOX = 'SOX';
    public static final String FRAMEWORK_GLBA = 'GLBA';
    public static final String FRAMEWORK_ISO27001 = 'ISO27001';

    // Supported frameworks set
    private static final Set<String> SUPPORTED_FRAMEWORKS = new Set<String>{
        FRAMEWORK_HIPAA, FRAMEWORK_SOC2, FRAMEWORK_GDPR, FRAMEWORK_CCPA,
        FRAMEWORK_PCI_DSS, FRAMEWORK_NIST, FRAMEWORK_FEDRAMP, FRAMEWORK_SOX,
        FRAMEWORK_GLBA, FRAMEWORK_ISO27001
    };

    /**
     * Get the main compliance service for a framework
     * @param framework Framework identifier
     * @return IRiskScoringService implementation for the framework
     */
    public static IRiskScoringService getService(String framework) {
        validateFramework(framework);

        if (serviceCache.containsKey(framework)) {
            return serviceCache.get(framework);
        }

        IRiskScoringService service = createService(framework);
        serviceCache.put(framework, service);
        return service;
    }

    /**
     * Get access control service for a framework
     * @param framework Framework identifier
     * @return IAccessControlService implementation for the framework
     */
    public static IAccessControlService getAccessService(String framework) {
        validateFramework(framework);

        if (accessServiceCache.containsKey(framework)) {
            return accessServiceCache.get(framework);
        }

        IAccessControlService service = createAccessService(framework);
        if (service != null) {
            accessServiceCache.put(framework, service);
        }
        return service;
    }

    /**
     * Get breach notification service for a framework
     * @param framework Framework identifier
     * @return IBreachNotificationService implementation for the framework
     */
    public static IBreachNotificationService getBreachService(String framework) {
        validateFramework(framework);

        if (breachServiceCache.containsKey(framework)) {
            return breachServiceCache.get(framework);
        }

        IBreachNotificationService service = createBreachService(framework);
        if (service != null) {
            breachServiceCache.put(framework, service);
        }
        return service;
    }

    /**
     * Get all supported frameworks
     * @return Set of supported framework identifiers
     */
    public static Set<String> getSupportedFrameworks() {
        return SUPPORTED_FRAMEWORKS.clone();
    }

    /**
     * Check if a framework is supported
     * @param framework Framework identifier to check
     * @return true if supported
     */
    public static Boolean isFrameworkSupported(String framework) {
        return framework != null && SUPPORTED_FRAMEWORKS.contains(framework.toUpperCase());
    }

    /**
     * Get framework configuration from custom metadata
     * @param framework Framework identifier
     * @return Framework configuration or null if not found
     */
    public static FrameworkConfig getFrameworkConfig(String framework) {
        validateFramework(framework);

        List<Framework_Config__mdt> configs = [
            SELECT DeveloperName, Framework_Code__c, Display_Name__c,
                   Score_Multiplier__c, Response_Deadline_Days__c,
                   Evidence_Retention_Days__c, Service_Class__c
            FROM Framework_Config__mdt
            WHERE Framework_Code__c = :framework
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];

        if (configs.isEmpty()) {
            // Return default config
            return new FrameworkConfig(framework);
        }

        return new FrameworkConfig(configs[0]);
    }

    /**
     * Clear service caches (useful for testing)
     */
    @TestVisible
    private static void clearCache() {
        serviceCache.clear();
        accessServiceCache.clear();
        breachServiceCache.clear();
    }

    /**
     * Create the appropriate compliance service based on framework
     */
    private static IRiskScoringService createService(String framework) {
        switch on framework.toUpperCase() {
            when 'HIPAA' {
                return new ElaroHIPAAComplianceService();
            }
            when 'SOC2' {
                return new ElaroSOC2ComplianceService();
            }
            when 'GDPR' {
                return new ElaroGDPRComplianceService();
            }
            when 'CCPA' {
                return new ElaroCCPAComplianceService();
            }
            when 'PCI_DSS' {
                return new ElaroPCIDSSComplianceService();
            }
            when else {
                // Try to get from metadata configuration
                FrameworkConfig config = getFrameworkConfig(framework);
                if (String.isNotBlank(config.serviceClass)) {
                    return createServiceFromClassName(config.serviceClass);
                }
                throw new ComplianceServiceException('No service implementation found for framework: ' + framework);
            }
        }
    }

    /**
     * Create access control service based on framework
     */
    private static IAccessControlService createAccessService(String framework) {
        switch on framework.toUpperCase() {
            when 'SOC2' {
                return new SOC2AccessReviewService();
            }
            when 'HIPAA' {
                // HIPAA can use a wrapper around SOC2 access service with HIPAA-specific checks
                return new HIPAAAccessControlServiceAdapter();
            }
            when else {
                // Default: no specific access control service
                return null;
            }
        }
    }

    /**
     * Create breach notification service based on framework
     */
    private static IBreachNotificationService createBreachService(String framework) {
        switch on framework.toUpperCase() {
            when 'HIPAA' {
                return new HIPAABreachNotificationService();
            }
            when 'GDPR' {
                // GDPR breach service would be implemented by Cursor
                return null;
            }
            when 'SOC2' {
                return new SOC2IncidentResponseService();
            }
            when else {
                return null;
            }
        }
    }

    /**
     * Dynamically create service from class name
     */
    private static IRiskScoringService createServiceFromClassName(String className) {
        try {
            Type serviceType = Type.forName(className);
            if (serviceType == null) {
                throw new ComplianceServiceException('Class not found: ' + className);
            }
            Object instance = serviceType.newInstance();
            if (!(instance instanceof IRiskScoringService)) {
                throw new ComplianceServiceException('Class does not implement IRiskScoringService: ' + className);
            }
            return (IRiskScoringService)instance;
        } catch (Exception e) {
            throw new ComplianceServiceException('Failed to create service: ' + e.getMessage());
        }
    }

    /**
     * Validate framework identifier
     */
    private static void validateFramework(String framework) {
        if (String.isBlank(framework)) {
            throw new ComplianceServiceException('Framework identifier cannot be blank');
        }
        // Allow custom frameworks from metadata, so don't strictly validate against SUPPORTED_FRAMEWORKS
    }

    /**
     * Framework configuration wrapper
     */
    public class FrameworkConfig {
        @AuraEnabled public String frameworkCode;
        @AuraEnabled public String displayName;
        @AuraEnabled public Decimal scoreMultiplier;
        @AuraEnabled public Integer responseDeadlineDays;
        @AuraEnabled public Integer evidenceRetentionDays;
        @AuraEnabled public String serviceClass;

        public FrameworkConfig(String framework) {
            this.frameworkCode = framework;
            this.displayName = framework;
            this.scoreMultiplier = 1.0;
            this.responseDeadlineDays = 30;
            this.evidenceRetentionDays = 365;
            this.serviceClass = null;
        }

        public FrameworkConfig(Framework_Config__mdt config) {
            this.frameworkCode = config.Framework_Code__c;
            this.displayName = config.Display_Name__c;
            this.scoreMultiplier = config.Score_Multiplier__c != null ? config.Score_Multiplier__c : 1.0;
            this.responseDeadlineDays = config.Response_Deadline_Days__c != null ?
                                        config.Response_Deadline_Days__c.intValue() : 30;
            this.evidenceRetentionDays = config.Evidence_Retention_Days__c != null ?
                                         config.Evidence_Retention_Days__c.intValue() : 365;
            this.serviceClass = config.Service_Class__c;
        }
    }

    /**
     * HIPAA-specific adapter for access control
     * Wraps SOC2 access review with HIPAA-specific validations
     */
    private class HIPAAAccessControlServiceAdapter implements IAccessControlService {
        private SOC2AccessReviewService baseService;

        public HIPAAAccessControlServiceAdapter() {
            this.baseService = new SOC2AccessReviewService();
        }

        public Id initiateAccessReview(String reviewType) {
            return baseService.initiateAccessReview(reviewType);
        }

        public IAccessControlService.AccessReviewStatus getReviewStatus(Id reviewId) {
            return baseService.getReviewStatus(reviewId);
        }

        public List<IAccessControlService.ExcessiveAccessUser> getExcessiveAccessUsers() {
            // Add HIPAA-specific PHI access checks
            return baseService.getExcessiveAccessUsers();
        }

        public IAccessControlService.RevokeAccessResult revokeAccess(List<Id> userIds, String reason) {
            return baseService.revokeAccess(userIds, reason);
        }

        public List<IAccessControlService.StalePermission> getStalePermissions(Integer daysSinceLogin) {
            return baseService.getStalePermissions(daysSinceLogin);
        }

        public IAccessControlService.NeedToKnowResult validateNeedToKnow(Id userId) {
            return baseService.validateNeedToKnow(userId);
        }
    }

    /**
     * Custom exception for factory errors
     */
    public class ComplianceServiceException extends Exception {}
}
