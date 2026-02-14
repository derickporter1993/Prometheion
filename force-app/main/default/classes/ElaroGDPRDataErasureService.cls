/**
 * GDPRDataErasureService - GDPR Article 17 Right to Erasure Implementation
 *
 * Handles data subject deletion requests with full audit trail.
 * Ensures cascading deletion across related records and immutable
 * audit logging via Platform Events.
 *
 * Compliance Coverage:
 * - GDPR Article 17: Right to Erasure ("Right to be Forgotten")
 * - GDPR Article 30: Records of Processing Activities
 *
 * @author Elaro
 * @version 1.0
 */
public with sharing class ElaroGDPRDataErasureService {

    /**
     * Process GDPR deletion request for a Contact
     * @param contactId - ID of Contact to be erased
     * @param requestReason - Reason for deletion request
     * @return Deletion confirmation with audit trail ID
     */
    public static ErasureResult processErasureRequest(Id contactId, String requestReason) {
        // Validate contact exists
        List<Contact> contacts = [
            SELECT Id, Email, FirstName, LastName, AccountId
            FROM Contact
            WHERE Id = :contactId
            WITH USER_MODE
            LIMIT 1
        ];

        if (contacts.isEmpty()) {
            throw new GDPRException('Contact not found: ' + contactId);
        }

        Contact subject = contacts[0];
        String subjectEmail = subject.Email;

        // Validate first
        ValidationResult validation = validateForErasure(contactId);
        if (!validation.canErase) {
            throw new GDPRException('Erasure blocked: ' + String.join(validation.blockers, ', '));
        }

        // Create audit log BEFORE deletion (survives record deletion)
        GDPR_Erasure_Request__c auditLog = new GDPR_Erasure_Request__c(
            Contact_Email__c = subjectEmail,
            Contact_Id__c = String.valueOf(contactId),
            Request_Date__c = System.now(),
            Request_Reason__c = requestReason,
            Status__c = 'In Progress',
            Requested_By__c = UserInfo.getUserId()
        );
        Database.insert(auditLog, AccessLevel.USER_MODE);

        // Add savepoint for rollback
        Savepoint sp = Database.setSavepoint();

        // Cascade delete related records
        try {
            // Delete Cases
            List<Case> cases = [
                SELECT Id FROM Case
                WHERE ContactId = :contactId
                WITH USER_MODE
            ];
            if (!cases.isEmpty()) {
                Database.delete(cases, AccessLevel.USER_MODE);
            }

            // Delete Tasks
            List<Task> tasks = [
                SELECT Id FROM Task
                WHERE WhoId = :contactId
                WITH USER_MODE
            ];
            if (!tasks.isEmpty()) {
                Database.delete(tasks, AccessLevel.USER_MODE);
            }

            // Delete Events
            List<Event> events = [
                SELECT Id FROM Event
                WHERE WhoId = :contactId
                WITH USER_MODE
            ];
            if (!events.isEmpty()) {
                Database.delete(events, AccessLevel.USER_MODE);
            }

            // Delete ContentDocumentLinks (files)
            List<ContentDocumentLink> docLinks = [
                SELECT Id FROM ContentDocumentLink
                WHERE LinkedEntityId = :contactId
                WITH USER_MODE
            ];
            if (!docLinks.isEmpty()) {
                Database.delete(docLinks, AccessLevel.USER_MODE);
            }

            // Delete Consents
            List<Consent__c> consents = [
                SELECT Id FROM Consent__c
                WHERE Contact__c = :contactId
                WITH USER_MODE
            ];
            if (!consents.isEmpty()) {
                Database.delete(consents, AccessLevel.USER_MODE);
            }

            // Finally, delete the Contact
            Database.delete(subject, AccessLevel.USER_MODE);

            // Update audit log to completed
            auditLog.Status__c = 'Completed';
            auditLog.Completion_Date__c = System.now();
            auditLog.Records_Deleted__c = 1 + cases.size() + tasks.size() +
                events.size() + docLinks.size() + consents.size();
            Database.update(auditLog, AccessLevel.USER_MODE);

            // Publish Platform Event (immutable audit trail)
            EventBus.publish(new GDPR_Erasure_Event__e(
                Contact_Email__c = subjectEmail,
                Deletion_Date__c = System.now(),
                Audit_Log_Id__c = auditLog.Id,
                Records_Deleted__c = String.valueOf(auditLog.Records_Deleted__c)
            ));

            return new ErasureResult(true, auditLog.Id, 'Data successfully erased');

        } catch (Exception e) {
            // Rollback all changes
            Database.rollback(sp);

            // Log error
            insert as user new Integration_Error__c(
                Error_Type__c = 'GDPR_ERASURE_FAILURE',
                Error_Message__c = e.getMessage() != null ? e.getMessage().left(255) : 'Unknown error',
                Stack_Trace__c = e.getStackTraceString() != null ? e.getStackTraceString().left(32000) : '',
                Context__c = 'ContactId: ' + contactId,
                Timestamp__c = System.now()
            );

            // Update audit log to failed
            auditLog.Status__c = 'Failed';
            auditLog.Error_Message__c = e.getMessage();
            try {
                Database.update(auditLog, AccessLevel.USER_MODE);
            } catch (Exception updateError) {
                ElaroLogger.error( 'Failed to update audit log: ' + updateError.getMessage());
            }

            throw new GDPRException('Failed to complete erasure: ' + e.getMessage(), e);
        }
    }

    /**
     * Get status of deletion request
     */
    public static GDPR_Erasure_Request__c getErasureStatus(Id auditLogId) {
        List<GDPR_Erasure_Request__c> logs = [
            SELECT Id, Name, Status__c, Request_Date__c, Completion_Date__c,
                   Error_Message__c, Contact_Email__c, Records_Deleted__c,
                   Request_Reason__c, Requested_By__r.Name
            FROM GDPR_Erasure_Request__c
            WHERE Id = :auditLogId
            WITH USER_MODE
            LIMIT 1
        ];
        return logs.isEmpty() ? null : logs[0];
    }

    /**
     * Get all erasure requests for reporting
     */
    @AuraEnabled(cacheable=true)
    public static List<GDPR_Erasure_Request__c> getRecentErasureRequests(Integer limitSize) {
        List<GDPR_Erasure_Request__c> requests = [
            SELECT Id, Name, Status__c, Request_Date__c, Completion_Date__c,
                   Contact_Email__c, Records_Deleted__c, Request_Reason__c,
                   Requested_By__r.Name
            FROM GDPR_Erasure_Request__c
            WITH USER_MODE
            ORDER BY Request_Date__c DESC
            LIMIT :limitSize
        ];
        return requests;
    }

    /**
     * Validate if contact has active dependencies preventing deletion
     */
    public static ValidationResult validateForErasure(Id contactId) {
        ValidationResult result = new ValidationResult();
        result.canErase = true;
        result.blockers = new List<String>();

        // Check for open cases
        Integer openCases = [
            SELECT COUNT() FROM Case
            WHERE ContactId = :contactId
            AND IsClosed = false
            WITH USER_MODE
        ];
        if (openCases > 0) {
            result.blockers.add(openCases + ' open case(s) must be closed first');
        }

        // Check for active opportunities
        Integer activeOpps = [
            SELECT COUNT() FROM Opportunity
            WHERE ContactId = :contactId
            AND IsClosed = false
            WITH USER_MODE
        ];
        if (activeOpps > 0) {
            result.blockers.add(activeOpps + ' active opportunity(ies) must be closed first');
        }

        result.canErase = result.blockers.isEmpty();
        return result;
    }

    /**
     * Result class for erasure operations
     */
    public class ErasureResult {
        @AuraEnabled public Boolean success;
        @AuraEnabled public Id auditLogId;
        @AuraEnabled public String message;

        public ErasureResult(Boolean success, Id auditLogId, String message) {
            this.success = success;
            this.auditLogId = auditLogId;
            this.message = message;
        }
    }

    /**
     * Result class for validation
     */
    public class ValidationResult {
        @AuraEnabled public Boolean canErase;
        @AuraEnabled public List<String> blockers;
    }

    // GDPRException moved to shared class: ElaroGDPRException
    // For backwards compatibility, create an alias
    public class GDPRException extends ElaroGDPRException {}
}
