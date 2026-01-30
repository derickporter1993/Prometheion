/**
 * GLBAAnnualNoticeBatch - Batch job for GLBA annual privacy notice distribution
 *
 * Processes Privacy_Notice__c records that are due for annual notice renewal
 * and creates new annual notices for affected contacts.
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroGLBAAnnualNoticeBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer noticesSent = 0;
    private Integer errors = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'GLBA Batch start() - Job ID: ' + bc.getJobId());

        try {
            // Find contacts due for annual notice
            Date today = Date.today();
            return Database.getQueryLocator([
                SELECT Id, Contact__c, Account__c, Contact__r.Email,
                       Next_Annual_Notice_Due__c
                FROM Privacy_Notice__c
                WHERE Next_Annual_Notice_Due__c <= :today
                AND Notice_Type__c IN ('Initial', 'Annual')
                AND Contact__c != null
                WITH USER_MODE
                ORDER BY Next_Annual_Notice_Due__c ASC
            ]);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Query failed: ' + e.getMessage());
            SchedulerErrorHandler.logError('ElaroGLBAAnnualNoticeBatch.start', e);
            throw e;
        }
    }

    public void execute(Database.BatchableContext bc, List<Privacy_Notice__c> scope) {
        List<Privacy_Notice__c> newNotices = new List<Privacy_Notice__c>();
        Set<Id> processedContacts = new Set<Id>();

        for (Privacy_Notice__c oldNotice : scope) {
            // Skip if already processed this contact
            if (processedContacts.contains(oldNotice.Contact__c)) {
                continue;
            }
            processedContacts.add(oldNotice.Contact__c);

            try {
                // Create new annual notice
                newNotices.add(new Privacy_Notice__c(
                    Contact__c = oldNotice.Contact__c,
                    Account__c = oldNotice.Account__c,
                    Notice_Type__c = 'Annual',
                    Sent_Date__c = System.now(),
                    Delivery_Method__c = String.isNotBlank(oldNotice.Contact__r.Email) ? 'Email' : 'Mail',
                    Delivery_Status__c = 'Pending',
                    Notice_Version__c = 'v' + Date.today().year() + '.1',
                    Opt_Out_Deadline__c = Date.today().addDays(30),
                    Next_Annual_Notice_Due__c = Date.today().addDays(365)
                ));
                noticesSent++;
            } catch (Exception e) {
                errors++;
                System.debug(LoggingLevel.ERROR,
                    '[ElaroGLBAAnnualNoticeBatch] Error processing contact ' +
                    oldNotice.Contact__c + ': ' + e.getMessage());
            }
        }

        if (!newNotices.isEmpty()) {
            List<Database.SaveResult> results = Database.insert(newNotices, false);
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    errors++;
                    for (Database.Error err : results[i].getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Insert failed for notice ' + i + ': ' + err.getMessage());
                    }
                } else {
                    noticesSent++;
                }
            }

            // Publish compliance events using generic Elaro_Raw_Event__e
            List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
            Datetime now = System.now();
            String userId = UserInfo.getUserId();

            for (Privacy_Notice__c notice : newNotices) {
                Map<String, Object> eventData = new Map<String, Object>{
                    'noticeId' => notice.Id,
                    'contactId' => notice.Contact__c,
                    'noticeType' => 'Annual',
                    'action' => 'Annual Notice Scheduled',
                    'userId' => userId
                };

                events.add(new Elaro_Raw_Event__e(
                    Event_Type__c = 'GLBA_COMPLIANCE',
                    Event_Data__c = JSON.serialize(eventData),
                    Timestamp__c = now
                ));
            }
            EventBus.publish(events);
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'GLBA Batch finish() - Notices sent: ' + noticesSent + ', Errors: ' + errors);

        // Query job status
        AsyncApexJob job;
        try {
            job = [
                SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob
                WHERE Id = :bc.getJobId()
                LIMIT 1
            ];
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Failed to query job status: ' + e.getMessage());
            job = null;
        }

        // Build summary
        String summary = 'GLBA Annual Notice Batch Complete\n' +
            'Status: ' + (job != null ? job.Status : 'Unknown') + '\n' +
            'Items Processed: ' + (job != null ? job.JobItemsProcessed : 'Unknown') + '/' + (job != null ? job.TotalJobItems : 'Unknown') + '\n' +
            'Notices Sent: ' + noticesSent + '\n' +
            'Errors: ' + (errors + (job != null ? job.NumberOfErrors : 0));

        // Send summary email to compliance team
        if (job != null && String.isNotBlank(job.CreatedBy.Email)) {
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setToAddresses(new String[] { job.CreatedBy.Email });
            mail.setSubject('GLBA Annual Notice Batch Complete');
            mail.setPlainTextBody(summary);

            try {
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Failed to send notification email: ' + e.getMessage());
            }
        }

        System.debug(LoggingLevel.INFO,
            '[ElaroGLBAAnnualNoticeBatch] Completed. Sent: ' + noticesSent + ', Errors: ' + errors);
    }
}
