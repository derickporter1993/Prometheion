/**
 * GLBAAnnualNoticeBatch - Batch job for GLBA annual privacy notice distribution
 *
 * Processes Privacy_Notice__c records that are due for annual notice renewal
 * and creates new annual notices for affected contacts.
 *
 * @author Prometheion
 * @version 1.0
 */
public with sharing class PrometheionGLBAAnnualNoticeBatch implements Database.Batchable<SObject>, Database.Stateful {
    private Integer noticesSent = 0;
    private Integer errors = 0;

    public Database.QueryLocator start(Database.BatchableContext bc) {
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
                    '[PrometheionGLBAAnnualNoticeBatch] Error processing contact ' +
                    oldNotice.Contact__c + ': ' + e.getMessage());
            }
        }

        if (!newNotices.isEmpty()) {
            Database.insert(newNotices, AccessLevel.USER_MODE);

            // Publish compliance events using generic Prometheion_Raw_Event__e
            List<Prometheion_Raw_Event__e> events = new List<Prometheion_Raw_Event__e>();
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

                events.add(new Prometheion_Raw_Event__e(
                    Event_Type__c = 'GLBA_COMPLIANCE',
                    Event_Data__c = JSON.serialize(eventData),
                    Timestamp__c = now
                ));
            }
            EventBus.publish(events);
        }
    }

    public void finish(Database.BatchableContext bc) {
        // Send summary email to compliance team
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('GLBA Annual Notice Distribution Complete');
        mail.setPlainTextBody(
            'GLBA Annual Notice Distribution Summary:\n\n' +
            'Notices Sent: ' + noticesSent + '\n' +
            'Errors: ' + errors + '\n' +
            'Completed: ' + System.now().format()
        );
        // In production, would set toAddresses to compliance team
        // Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });

        System.debug(LoggingLevel.INFO,
            '[PrometheionGLBAAnnualNoticeBatch] Completed. Sent: ' + noticesSent + ', Errors: ' + errors);
    }
}
