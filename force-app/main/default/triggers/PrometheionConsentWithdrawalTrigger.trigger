/**
 * ConsentWithdrawalTrigger - GDPR Article 7 Consent Withdrawal Processing
 *
 * Automatically processes consent withdrawal by:
 * - Cascading opt-out to related records
 * - Creating audit trail via Platform Events
 * - Triggering data processing restrictions
 *
 * @author Prometheion
 * @version 1.0
 */
trigger PrometheionConsentWithdrawalTrigger on Consent__c (after update) {

    List<Consent__c> withdrawnConsents = new List<Consent__c>();

    for (Consent__c consent : Trigger.new) {
        Consent__c oldConsent = Trigger.oldMap.get(consent.Id);

        // Check if consent was just withdrawn
        if (consent.Consent_Withdrawn__c == true &&
            oldConsent.Consent_Withdrawn__c == false) {
            withdrawnConsents.add(consent);
        }
    }

    if (!withdrawnConsents.isEmpty()) {
        PrometheionConsentWithdrawalHandler.processWithdrawals(withdrawnConsents);
    }
}
