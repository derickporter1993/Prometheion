/**
 * Service for managing shareable Trust Center links with token generation,
 * expiration validation, and access tracking.
 *
 * @author Elaro Team
 * @since v1.0.0 (Spring '26)
 * @group Trust Center
 * @see Trust_Center_Link__c
 * @see TrustCenterGuestController
 */
public inherited sharing class TrustCenterLinkService {

    /**
     * Creates a new shareable Trust Center link with UUID token.
     *
     * @param accessTier Access tier (Public, Email_Gated, NDA_Required)
     * @param expirationDays Number of days until link expires (default 30)
     * @param createdFor Optional company/individual name for audit trail
     * @return Newly created Trust_Center_Link__c record
     * @throws DmlException if insert fails
     */
    public Trust_Center_Link__c createLink(
        String accessTier,
        Integer expirationDays,
        String createdFor
    ) {
        Integer days = expirationDays ?? 30;
        String tier = accessTier ?? 'Public';

        Trust_Center_Link__c link = new Trust_Center_Link__c(
            Link_Token__c = generateUuid(),
            Access_Tier__c = tier,
            Expiration_Date__c = Datetime.now().addDays(days),
            Created_For__c = createdFor,
            Is_Active__c = true,
            Access_Count__c = 0
        );

        insert as user link;

        ElaroLogger.info('TrustCenterLinkService.createLink',
            'Created link ' + link.Link_Token__c + ' for ' + (createdFor ?? 'anonymous'));

        return link;
    }

    /**
     * Validates a link token and returns the link record if valid.
     *
     * SECURITY CRITICAL: This is the primary access control for Trust Center.
     * Validates: token exists, is active, and not expired.
     *
     * @param token UUID token from URL parameter
     * @return Trust_Center_Link__c if valid, null if invalid
     */
    public Trust_Center_Link__c validateToken(String token) {
        if (String.isBlank(token)) {
            return null;
        }

        List<Trust_Center_Link__c> links = [
            SELECT Id, Link_Token__c, Access_Tier__c, Expiration_Date__c,
                   Is_Active__c, Access_Count__c
            FROM Trust_Center_Link__c
            WHERE Link_Token__c = :token
            WITH USER_MODE
            LIMIT 1
        ];

        if (links.isEmpty()) {
            return null;
        }

        Trust_Center_Link__c link = links[0];

        // Validate active and not expired
        if (!link.Is_Active__c || link.Expiration_Date__c < Datetime.now()) {
            return null;
        }

        return link;
    }

    /**
     * Increments access count and updates last accessed timestamp.
     *
     * @param linkId Trust_Center_Link__c record ID
     */
    public void recordAccess(Id linkId) {
        if (linkId == null) {
            return;
        }

        Trust_Center_Link__c link = [
            SELECT Id, Access_Count__c
            FROM Trust_Center_Link__c
            WHERE Id = :linkId
            WITH USER_MODE
            LIMIT 1
        ];

        link.Access_Count__c = (link.Access_Count__c ?? 0) + 1;
        link.Last_Accessed_Date__c = Datetime.now();

        update as user link;
    }

    /**
     * Revokes a link by setting Is_Active__c = false.
     *
     * @param linkId Trust_Center_Link__c record ID
     * @throws DmlException if update fails
     */
    public void revokeLink(Id linkId) {
        if (linkId == null) {
            return;
        }

        Trust_Center_Link__c link = [
            SELECT Id, Is_Active__c
            FROM Trust_Center_Link__c
            WHERE Id = :linkId
            WITH USER_MODE
            LIMIT 1
        ];

        link.Is_Active__c = false;
        update as user link;

        ElaroLogger.info('TrustCenterLinkService.revokeLink',
            'Revoked link ' + linkId);
    }

    /**
     * Generates a UUID v4 token using Crypto.getRandomUUID().
     *
     * @return UUID string (36 characters)
     */
    @TestVisible
    private String generateUuid() {
        return Crypto.getRandomUUID().toString();
    }

    /**
     * Retrieves all active links for admin dashboard.
     *
     * @return List of all active Trust_Center_Link__c records
     */
    public List<Trust_Center_Link__c> getActiveLinks() {
        return [
            SELECT Id, Name, Link_Token__c, Access_Tier__c,
                   Expiration_Date__c, Access_Count__c, Created_For__c,
                   Last_Accessed_Date__c, CreatedDate
            FROM Trust_Center_Link__c
            WHERE Is_Active__c = true
            ORDER BY CreatedDate DESC
            WITH USER_MODE
            LIMIT 1000
        ];
    }
}
