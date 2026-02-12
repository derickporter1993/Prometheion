/**
 * SECURITY CRITICAL: Salesforce Sites guest-accessible controller.
 * Exposes ONLY Trust_Center_View__c data to public via token-validated links.
 *
 * ABSOLUTE REQUIREMENTS:
 * 1. NEVER query Compliance_Finding__c, Evidence__c, or any __mdt
 * 2. NEVER query Platform Events (__e)
 * 3. VALIDATE token on EVERY method call
 * 4. VALIDATE expiration on EVERY method call
 * 5. VALIDATE Is_Public__c = true on all returned records
 * 6. Guest User Profile must have ZERO access to sensitive objects
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 * @see TrustCenterLinkService
 * @see Trust_Center_View__c
 */
public with sharing class TrustCenterGuestController {

    /**
     * Validates a link token and returns public compliance views if valid.
     *
     * SECURITY TRIPLE-CHECK:
     * - Token must exist
     * - Link must be active
     * - Link must not be expired
     * - Only returns Is_Public__c = true records
     *
     * @param token UUID token from URL parameter
     * @return Wrapper with valid flag and compliance views
     */
    @AuraEnabled(cacheable=false)
    public static TrustCenterResponse getPublicData(String token) {
        TrustCenterResponse response = new TrustCenterResponse();
        response.isValid = false;
        response.views = new List<Trust_Center_View__c>();

        try {
            // SECURITY CHECK 1: Validate token
            if (String.isBlank(token)) {
                response.errorMessage = 'Invalid or missing access token.';
                return response;
            }

            // SECURITY CHECK 2: Validate link
            TrustCenterLinkService service = new TrustCenterLinkService();
            Trust_Center_Link__c link = service.validateToken(token);

            if (link == null) {
                response.errorMessage = 'This link is invalid, expired, or has been revoked.';
                ElaroLogger.info('TrustCenterGuestController.getPublicData',
                    'Invalid token attempted: ' + token.left(8) + '...');
                return response;
            }

            // SECURITY CHECK 3: Record access (audit trail)
            service.recordAccess(link.Id);

            // SECURITY CHECK 4: Only query public-safe views
            response.views = [
                SELECT Id, Name, Framework__c, Compliance_Percentage__c,
                       Controls_Total__c, Controls_Compliant__c,
                       Last_Audit_Date__c, Certification_Status__c,
                       Badge_Image_URL__c
                FROM Trust_Center_View__c
                WHERE Is_Public__c = true
                ORDER BY Compliance_Percentage__c DESC
                WITH USER_MODE
                LIMIT 20
            ];

            response.isValid = true;
            response.accessTier = link.Access_Tier__c;

            ElaroLogger.info('TrustCenterGuestController.getPublicData',
                'Valid access from token: ' + token.left(8) + '... (' + link.Access_Tier__c + ')');

        } catch (Exception e) {
            ElaroLogger.error('TrustCenterGuestController.getPublicData',
                e.getMessage(), e.getStackTraceString());
            response.errorMessage = 'An error occurred loading compliance data. Please try again later.';
        }

        return response;
    }

    /**
     * Wrapper class for guest controller response.
     * Includes validation status, error messages, and data.
     */
    public class TrustCenterResponse {
        @AuraEnabled public Boolean isValid;
        @AuraEnabled public String errorMessage;
        @AuraEnabled public String accessTier;
        @AuraEnabled public List<Trust_Center_View__c> views;
    }
}
