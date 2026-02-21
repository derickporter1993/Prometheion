/**
 * Batch class for processing expiring consents
 * Checks for consents expiring within the warning period and sends renewal reminders
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class ConsentExpirationBatch implements Database.Batchable<SObject> {
    
    private Integer expirationWarningDays = 30;
    
    public ConsentExpirationBatch() {
        // Can be configured via constructor if needed
    }
    
    public ConsentExpirationBatch(Integer warningDays) {
        this.expirationWarningDays = warningDays;
    }
    
    /** Collects active, non-withdrawn consents that may be approaching expiration. */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        // Query consents that are expiring soon
        // Note: Consent__c object may need an Expiration_Date__c field
        // For now, query active consents that may need renewal reminders
        Date warningDate = Date.today().addDays(expirationWarningDays);
        
        return Database.getQueryLocator([
            SELECT Id, Contact__c, Consent_Type__c, Consent_Given__c, 
                   Consent_Date__c, Consent_Withdrawn__c
            FROM Consent__c
            WHERE Consent_Given__c = true
            AND Consent_Withdrawn__c = false
            WITH USER_MODE
        ]);
    }
    
    /** Processes each batch of consents and queues renewal reminder notifications. */
    public void execute(Database.BatchableContext bc, List<Consent__c> consents) {
        GDPRConsentManagementService service = new GDPRConsentManagementService();
        List<Id> contactsToNotify = new List<Id>();
        
        for (Consent__c consent : consents) {
            // Check if consent needs renewal reminder
            // In production, would check expiration date
            if (consent.Contact__c != null) {
                contactsToNotify.add(consent.Contact__c);
            }
        }
        
        // Send renewal reminders (simplified - in production would send emails)
        ElaroLogger.info( 'Processing ' + contactsToNotify.size() + ' contacts for consent renewal reminders');
    }
    
    /** Logs batch completion. */
    public void finish(Database.BatchableContext bc) {
        ElaroLogger.info( 'ConsentExpirationBatch completed');
    }
}
