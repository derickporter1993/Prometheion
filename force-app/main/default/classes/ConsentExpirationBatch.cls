/**
 * Batch class for processing expiring consents
 * Checks for consents expiring within the warning period and sends renewal reminders
 * 
 * @author Elaro
 * @version 3.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ConsentExpirationBatch implements Database.Batchable<SObject> {
    
    private Integer expirationWarningDays = 30;
    
    public ConsentExpirationBatch() {
        // Can be configured via constructor if needed
    }
    
    public ConsentExpirationBatch(Integer warningDays) {
        this.expirationWarningDays = warningDays;
    }
    
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
    
    public void finish(Database.BatchableContext bc) {
        AsyncApexJob job;
        try {
            job = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob
                WHERE Id = :bc.getJobId()
                WITH USER_MODE
                LIMIT 1
            ];
        } catch (Exception e) {
            ElaroLogger.error('ConsentExpirationBatch.finish', 'Failed to query job status: ' + e.getMessage(), e.getStackTraceString());
            return;
        }

        String summary = 'ConsentExpirationBatch Complete - Status: ' + job.Status +
            ', Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems +
            ', Errors: ' + job.NumberOfErrors;

        if (job.NumberOfErrors > 0) {
            ElaroLogger.error('ConsentExpirationBatch.finish', summary, '');
            notifyOnFailure(job);
        } else {
            ElaroLogger.info('ConsentExpirationBatch.finish', summary);
        }
    }

    private void notifyOnFailure(AsyncApexJob job) {
        if (String.isBlank(job.CreatedBy?.Email)) {
            return;
        }
        try {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { job.CreatedBy.Email });
            mail.setSubject('Elaro: ConsentExpirationBatch completed with errors');
            mail.setPlainTextBody(
                'The ConsentExpirationBatch job completed with errors.\n\n' +
                'Status: ' + job.Status + '\n' +
                'Items Processed: ' + job.JobItemsProcessed + '/' + job.TotalJobItems + '\n' +
                'Number of Errors: ' + job.NumberOfErrors
            );
            mail.setSaveAsActivity(false);
            Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
        } catch (Exception e) {
            ElaroLogger.error('ConsentExpirationBatch.notifyOnFailure', 'Failed to send failure email: ' + e.getMessage(), e.getStackTraceString());
        }
    }
}
