/**
 * ConsentWithdrawalHandler - Processes GDPR consent withdrawals
 *
 * Handles the business logic for consent withdrawal including:
 * - Updating related Contact preferences
 * - Publishing audit events
 * - Triggering downstream data processing restrictions
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroConsentWithdrawalHandler {

    /**
     * Process consent withdrawals
     * @param withdrawnConsents - List of consents that were withdrawn
     */
    public static void processWithdrawals(List<Consent__c> withdrawnConsents) {
        Set<Id> contactIds = new Set<Id>();
        Map<Id, List<Consent__c>> consentsByContact = new Map<Id, List<Consent__c>>();

        // Group consents by contact
        for (Consent__c consent : withdrawnConsents) {
            contactIds.add(consent.Contact__c);
            if (!consentsByContact.containsKey(consent.Contact__c)) {
                consentsByContact.put(consent.Contact__c, new List<Consent__c>());
            }
            consentsByContact.get(consent.Contact__c).add(consent);
        }

        // Update contact preferences based on consent type
        updateContactPreferences(consentsByContact);

        // Publish withdrawal events for audit
        publishWithdrawalEvents(withdrawnConsents);

        // Create GDPR erasure requests for full withdrawal
        createErasureRequestsIfNeeded(withdrawnConsents);
    }

    /**
     * Update contact preferences based on withdrawn consent types
     * @param consentsByContact - Map of Contact ID to withdrawn consents
     */
    private static void updateContactPreferences(Map<Id, List<Consent__c>> consentsByContact) {
        List<Contact> contactsToUpdate = new List<Contact>();

        for (Id contactId : consentsByContact.keySet()) {
            Contact c = new Contact(Id = contactId);
            Boolean needsUpdate = false;

            for (Consent__c consent : consentsByContact.get(contactId)) {
                String consentType = consent.Consent_Type__c;

                // Handle different consent types
                if (consentType == 'Marketing') {
                    c.HasOptedOutOfEmail = true;
                    needsUpdate = true;
                } else if (consentType == 'Third Party Sharing') {
                    // If CCPA fields exist
                    c.put('CCPA_Do_Not_Sell__c', true);
                    c.put('CCPA_OptOut_Date__c', System.now());
                    needsUpdate = true;
                } else if (consentType == 'Data Processing') {
                    c.DoNotCall = true;
                    c.HasOptedOutOfEmail = true;
                    needsUpdate = true;
                }
            }

            if (needsUpdate) {
                contactsToUpdate.add(c);
            }
        }

        if (!contactsToUpdate.isEmpty()) {
            Database.update(contactsToUpdate, AccessLevel.USER_MODE);
        }
    }

    /**
     * Publish withdrawal events for immutable audit trail
     * @param withdrawnConsents - List of withdrawn consents
     */
    private static void publishWithdrawalEvents(List<Consent__c> withdrawnConsents) {
        List<GDPR_Erasure_Event__e> events = new List<GDPR_Erasure_Event__e>();
        String userId = UserInfo.getUserId();
        Datetime now = System.now();

        // Query Contact emails for the withdrawn consents
        Set<Id> contactIds = new Set<Id>();
        for (Consent__c consent : withdrawnConsents) {
            if (consent.Contact__c != null) {
                contactIds.add(consent.Contact__c);
            }
        }
        
        Map<Id, String> contactEmailMap = new Map<Id, String>();
        if (!contactIds.isEmpty()) {
            for (Contact c : [SELECT Id, Email FROM Contact WHERE Id IN :contactIds]) {
                contactEmailMap.put(c.Id, c.Email);
            }
        }

        for (Consent__c consent : withdrawnConsents) {
            String contactEmail = contactEmailMap.get(consent.Contact__c);
            events.add(new GDPR_Erasure_Event__e(
                Contact_Email__c = contactEmail != null ? contactEmail : '',
                Deletion_Date__c = now,
                Records_Deleted__c = String.valueOf(0),
                Audit_Log_Id__c = 'CONSENT-WITHDRAWAL-' + String.valueOf(consent.Id)
            ));
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    /**
     * Create erasure requests for contacts who withdrew all processing consent
     * @param withdrawnConsents - List of withdrawn consents
     */
    private static void createErasureRequestsIfNeeded(List<Consent__c> withdrawnConsents) {
        Set<Id> contactsForErasure = new Set<Id>();

        for (Consent__c consent : withdrawnConsents) {
            // Full data processing withdrawal triggers erasure request
            if (consent.Consent_Type__c == 'All Data Processing') {
                contactsForErasure.add(consent.Contact__c);
            }
        }

        if (contactsForErasure.isEmpty()) {
            return;
        }

        List<GDPR_Erasure_Request__c> erasureRequests = new List<GDPR_Erasure_Request__c>();

        for (Id contactId : contactsForErasure) {
            erasureRequests.add(new GDPR_Erasure_Request__c(
                Contact__c = contactId,
                Request_Reason__c = 'Consent withdrawal - All data processing consent revoked',
                Legal_Basis__c = 'Consent Withdrawal',
                Status__c = 'Pending',
                Requested_Date__c = System.now(),
                Requested_By__c = UserInfo.getUserId()
            ));
        }

        if (!erasureRequests.isEmpty()) {
            Database.insert(erasureRequests, AccessLevel.USER_MODE);

            System.debug(LoggingLevel.INFO,
                '[ConsentWithdrawalHandler] Created ' + erasureRequests.size() +
                ' erasure requests from consent withdrawals');
        }
    }
}
