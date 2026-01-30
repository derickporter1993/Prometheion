/**
 * GLBAPrivacyNoticeService - Gramm-Leach-Bliley Act Privacy Rule Implementation
 *
 * Manages privacy notice distribution and opt-out tracking for financial institutions.
 * Ensures compliance with annual notice requirements and consumer opt-out rights.
 *
 * Compliance Coverage:
 * - GLBA Privacy Rule (16 CFR Part 313)
 * - Initial Privacy Notice Requirements
 * - Annual Privacy Notice Requirements
 * - Opt-Out Notice Requirements
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroGLBAPrivacyNoticeService {

    private static final Integer OPT_OUT_DEADLINE_DAYS = 30;
    private static final Integer ANNUAL_NOTICE_INTERVAL_DAYS = 365;

    /**
     * Create and send initial privacy notice to new customer
     * Required when customer relationship is established
     * @param contactId - Contact ID of the new customer
     * @param accountId - Account ID (if applicable)
     * @param deliveryMethod - Method to deliver notice (Email, Mail, etc.)
     * @return Privacy_Notice__c record created
     */
    public static Privacy_Notice__c sendInitialNotice(
        Id contactId,
        Id accountId,
        String deliveryMethod
    ) {
        Privacy_Notice__c notice = new Privacy_Notice__c(
            Contact__c = contactId,
            Account__c = accountId,
            Notice_Type__c = 'Initial',
            Sent_Date__c = System.now(),
            Delivery_Method__c = deliveryMethod,
            Delivery_Status__c = 'Sent',
            Notice_Version__c = getCurrentNoticeVersion(),
            Opt_Out_Deadline__c = Date.today().addDays(OPT_OUT_DEADLINE_DAYS),
            Next_Annual_Notice_Due__c = Date.today().addDays(ANNUAL_NOTICE_INTERVAL_DAYS)
        );

        Database.insert(notice, AccessLevel.USER_MODE);

        // Publish compliance event
        publishNoticeEvent(notice, 'Initial Notice Sent');

        return notice;
    }

    /**
     * Send annual privacy notices to all active customers
     * Must be sent at least once every 12 months
     * @return List of Privacy_Notice__c records created
     */
    public static List<Privacy_Notice__c> sendAnnualNotices() {
        List<Privacy_Notice__c> notices = new List<Privacy_Notice__c>();

        // Find contacts due for annual notice
        List<Contact> contactsDue = [
            SELECT Id, AccountId, Email,
                   (SELECT Id, Next_Annual_Notice_Due__c
                    FROM Privacy_Notices__r
                    WHERE Notice_Type__c IN ('Initial', 'Annual')
                    ORDER BY Sent_Date__c DESC
                    LIMIT 1)
            FROM Contact
            WHERE Id IN (
                SELECT Contact__c FROM Privacy_Notice__c
                WHERE Next_Annual_Notice_Due__c <= TODAY
            )
            WITH USER_MODE
            LIMIT 200
        ];

        String noticeVersion = getCurrentNoticeVersion();
        Datetime now = System.now();

        for (Contact c : contactsDue) {
            notices.add(new Privacy_Notice__c(
                Contact__c = c.Id,
                Account__c = c.AccountId,
                Notice_Type__c = 'Annual',
                Sent_Date__c = now,
                Delivery_Method__c = String.isNotBlank(c.Email) ? 'Email' : 'Mail',
                Delivery_Status__c = 'Pending',
                Notice_Version__c = noticeVersion,
                Opt_Out_Deadline__c = Date.today().addDays(OPT_OUT_DEADLINE_DAYS),
                Next_Annual_Notice_Due__c = Date.today().addDays(ANNUAL_NOTICE_INTERVAL_DAYS)
            ));
        }

        if (!notices.isEmpty()) {
            Database.insert(notices, AccessLevel.USER_MODE);

            // Publish bulk event
            publishBulkNoticeEvent(notices, 'Annual Notices Scheduled');
        }

        return notices;
    }

    /**
     * Send revised privacy notice when policies change materially
     * @param contactIds - Set of Contact IDs to notify
     * @param revisionReason - Description of what changed
     * @return List of Privacy_Notice__c records created
     */
    public static List<Privacy_Notice__c> sendRevisedNotices(
        Set<Id> contactIds,
        String revisionReason
    ) {
        List<Privacy_Notice__c> notices = new List<Privacy_Notice__c>();

        List<Contact> contacts = [
            SELECT Id, AccountId, Email
            FROM Contact
            WHERE Id IN :contactIds
            WITH USER_MODE
        ];

        String noticeVersion = getCurrentNoticeVersion();
        Datetime now = System.now();

        for (Contact c : contacts) {
            notices.add(new Privacy_Notice__c(
                Contact__c = c.Id,
                Account__c = c.AccountId,
                Notice_Type__c = 'Revised',
                Sent_Date__c = now,
                Delivery_Method__c = String.isNotBlank(c.Email) ? 'Email' : 'Mail',
                Delivery_Status__c = 'Pending',
                Notice_Version__c = noticeVersion,
                Opt_Out_Deadline__c = Date.today().addDays(OPT_OUT_DEADLINE_DAYS)
            ));
        }

        if (!notices.isEmpty()) {
            Database.insert(notices, AccessLevel.USER_MODE);
            publishBulkNoticeEvent(notices, 'Revised Notices Sent: ' + revisionReason);
        }

        return notices;
    }

    /**
     * Process customer opt-out request
     * @param noticeId - Privacy_Notice__c record ID
     * @param optOutCategories - Categories customer is opting out of
     */
    public static void processOptOut(Id noticeId, List<String> optOutCategories) {
        Privacy_Notice__c notice = [
            SELECT Id, Contact__c, Account__c, Opt_Out_Deadline__c,
                   Customer_Opted_Out__c
            FROM Privacy_Notice__c
            WHERE Id = :noticeId
            WITH USER_MODE
            LIMIT 1
        ];

        // Validate opt-out is within deadline
        if (notice.Opt_Out_Deadline__c != null &&
            Date.today() > notice.Opt_Out_Deadline__c) {
            throw new GLBAComplianceException(
                'Opt-out deadline has passed. Customer must wait for next notice period.'
            );
        }

        notice.Customer_Opted_Out__c = true;
        notice.Opt_Out_Date__c = System.now();

        Database.update(notice, AccessLevel.USER_MODE);

        // Update contact with opt-out preference
        if (notice.Contact__c != null) {
            updateContactOptOutStatus(notice.Contact__c, optOutCategories);
        }

        publishNoticeEvent(notice, 'Customer Opted Out: ' + String.join(optOutCategories, ', '));
    }

    /**
     * Get contacts who haven't received required notices
     * @return List of Contact IDs missing required notices
     */
    @AuraEnabled(cacheable=true)
    public static List<Id> getContactsMissingNotices() {
        List<Id> missingNotices = new List<Id>();

        // Find contacts without any privacy notice
        List<Contact> contactsWithoutNotice = [
            SELECT Id
            FROM Contact
            WHERE Id NOT IN (
                SELECT Contact__c FROM Privacy_Notice__c
            )
            AND CreatedDate < LAST_N_DAYS:30
            WITH USER_MODE
            LIMIT 1000
        ];

        for (Contact c : contactsWithoutNotice) {
            missingNotices.add(c.Id);
        }

        return missingNotices;
    }

    /**
     * Get overdue annual notices
     * @return Count of overdue notices
     */
    @AuraEnabled(cacheable=true)
    public static Integer getOverdueNoticeCount() {
        return [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Next_Annual_Notice_Due__c < TODAY
            AND Notice_Type__c IN ('Initial', 'Annual')
            WITH USER_MODE
        ];
    }

    /**
     * Update delivery status of a notice
     * @param noticeId - Privacy_Notice__c record ID
     * @param status - New delivery status
     */
    public static void updateDeliveryStatus(Id noticeId, String status) {
        Privacy_Notice__c notice = new Privacy_Notice__c(
            Id = noticeId,
            Delivery_Status__c = status
        );

        Database.update(notice, AccessLevel.USER_MODE);
    }

    /**
     * Get compliance dashboard metrics
     * @return Map of metric name to value
     */
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getComplianceMetrics() {
        Map<String, Object> metrics = new Map<String, Object>();

        // Total notices sent this year
        metrics.put('totalNoticesThisYear', [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Sent_Date__c = THIS_YEAR
            WITH USER_MODE
        ]);

        // Opt-out rate
        Integer totalWithOptOut = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Opt_Out_Deadline__c != null
            WITH USER_MODE
        ];

        Integer optedOut = [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Customer_Opted_Out__c = true
            WITH USER_MODE
        ];

        metrics.put('optOutRate', totalWithOptOut > 0 ?
            (Decimal.valueOf(optedOut) / totalWithOptOut * 100).setScale(2) : 0);

        // Overdue notices
        metrics.put('overdueCount', getOverdueNoticeCount());

        // Pending deliveries
        metrics.put('pendingDeliveries', [
            SELECT COUNT()
            FROM Privacy_Notice__c
            WHERE Delivery_Status__c = 'Pending'
            WITH USER_MODE
        ]);

        return metrics;
    }

    /**
     * Get current privacy notice version from custom setting or metadata
     * @return Current notice version string
     */
    private static String getCurrentNoticeVersion() {
        // In production, this would read from Custom Metadata
        return 'v2024.1';
    }

    /**
     * Update contact's opt-out preferences
     * @param contactId - Contact ID to update
     * @param categories - Opt-out categories
     */
    private static void updateContactOptOutStatus(Id contactId, List<String> categories) {
        // Store opt-out preferences on contact
        // Implementation depends on custom fields defined
    }

    /**
     * Publish GLBA compliance event for single notice
     * @param notice - Privacy_Notice__c record
     * @param action - Action description
     */
    private static void publishNoticeEvent(Privacy_Notice__c notice, String action) {
        // Use generic Elaro_Raw_Event__e due to custom object limit
        Map<String, Object> eventData = new Map<String, Object>{
            'noticeId' => notice.Id,
            'contactId' => notice.Contact__c,
            'noticeType' => notice.Notice_Type__c,
            'action' => action,
            'userId' => UserInfo.getUserId()
        };

        EventBus.publish(new Elaro_Raw_Event__e(
            Event_Type__c = 'GLBA_COMPLIANCE',
            Event_Data__c = JSON.serialize(eventData),
            Timestamp__c = System.now()
        ));
    }

    /**
     * Publish GLBA compliance event for bulk notices
     * @param notices - List of Privacy_Notice__c records
     * @param action - Action description
     */
    private static void publishBulkNoticeEvent(List<Privacy_Notice__c> notices, String action) {
        List<Elaro_Raw_Event__e> events = new List<Elaro_Raw_Event__e>();
        String userId = UserInfo.getUserId();
        Datetime now = System.now();

        for (Privacy_Notice__c notice : notices) {
            Map<String, Object> eventData = new Map<String, Object>{
                'noticeId' => notice.Id,
                'contactId' => notice.Contact__c,
                'noticeType' => notice.Notice_Type__c,
                'action' => action,
                'userId' => userId
            };

            events.add(new Elaro_Raw_Event__e(
                Event_Type__c = 'GLBA_COMPLIANCE',
                Event_Data__c = JSON.serialize(eventData),
                Timestamp__c = now
            ));
        }

        if (!events.isEmpty()) {
            EventBus.publish(events);
        }
    }

    /**
     * Custom exception for GLBA compliance violations
     */
    public class GLBAComplianceException extends Exception {}
}
