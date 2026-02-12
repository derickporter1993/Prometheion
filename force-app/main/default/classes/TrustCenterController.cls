/**
 * Internal admin controller for managing Trust Center links and viewing
 * materialized compliance data.
 *
 * SECURITY: with sharing enforces record-level security for internal users.
 * This controller is ONLY for authenticated Salesforce users with appropriate
 * permissions. Guest users NEVER access this controller.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 * @see TrustCenterLinkService
 * @see TrustCenterDataService
 */
public with sharing class TrustCenterController {

    /**
     * Retrieves all public-safe framework compliance views.
     *
     * @return List of Trust_Center_View__c records with Is_Public__c = true
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<Trust_Center_View__c> getPublicViews() {
        try {
            return [
                SELECT Id, Name, Framework__c, Compliance_Percentage__c,
                       Controls_Total__c, Controls_Compliant__c,
                       Last_Audit_Date__c, Certification_Status__c,
                       Badge_Image_URL__c
                FROM Trust_Center_View__c
                WHERE Is_Public__c = true
                ORDER BY Compliance_Percentage__c DESC
                WITH USER_MODE
                LIMIT 100
            ];
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterController.getPublicViews',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to retrieve compliance views. Please contact your administrator.'
            );
        }
    }

    /**
     * Creates a new shareable Trust Center link.
     *
     * @param accessTier Access tier (Public, Email_Gated, NDA_Required)
     * @param expirationDays Number of days until expiration
     * @param createdFor Optional company/individual name
     * @return Newly created Trust_Center_Link__c record with token
     * @throws AuraHandledException if creation fails
     */
    @AuraEnabled
    public static Trust_Center_Link__c createShareableLink(
        String accessTier,
        Integer expirationDays,
        String createdFor
    ) {
        try {
            TrustCenterLinkService service = new TrustCenterLinkService();
            return service.createLink(accessTier, expirationDays, createdFor);
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterController.createShareableLink',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to create shareable link. Please try again or contact your administrator.'
            );
        }
    }

    /**
     * Retrieves all active shareable links for admin dashboard.
     *
     * @return List of active Trust_Center_Link__c records
     * @throws AuraHandledException if query fails
     */
    @AuraEnabled(cacheable=true)
    public static List<Trust_Center_Link__c> getActiveLinks() {
        try {
            TrustCenterLinkService service = new TrustCenterLinkService();
            return service.getActiveLinks();
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterController.getActiveLinks',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to retrieve shareable links. Please contact your administrator.'
            );
        }
    }

    /**
     * Revokes a shareable link immediately.
     *
     * @param linkId Trust_Center_Link__c record ID
     * @throws AuraHandledException if revocation fails
     */
    @AuraEnabled
    public static void revokeLink(Id linkId) {
        try {
            TrustCenterLinkService service = new TrustCenterLinkService();
            service.revokeLink(linkId);
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterController.revokeLink',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to revoke link. Please contact your administrator.'
            );
        }
    }

    /**
     * Manually triggers compliance data aggregation (admin action).
     *
     * @throws AuraHandledException if aggregation fails
     */
    @AuraEnabled
    public static void triggerDataAggregation() {
        try {
            TrustCenterDataService service = new TrustCenterDataService();
            service.aggregateComplianceData();
        } catch (Exception e) {
            ElaroLogger.error('TrustCenterController.triggerDataAggregation',
                e.getMessage(), e.getStackTraceString());
            throw new AuraHandledException(
                'Unable to aggregate compliance data. Please contact your administrator.'
            );
        }
    }
}
