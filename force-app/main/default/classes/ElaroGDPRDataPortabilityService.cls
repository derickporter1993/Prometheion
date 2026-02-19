/**
 * GDPRDataPortabilityService - GDPR Article 20 Right to Data Portability
 *
 * Exports all personal data in machine-readable format (JSON).
 * Generates comprehensive data package for data subject access requests.
 *
 * Compliance Coverage:
 * - GDPR Article 20: Right to Data Portability
 * - GDPR Article 15: Right of Access
 *
 * @author Elaro
 * @version 1.0
 * @since v3.1.0 (Spring '26)
 * @group Compliance Framework
 */
public with sharing class ElaroGDPRDataPortabilityService {

    /**
     * Generate complete data export for a Contact
     * @param contactId - Contact ID to export data for
     * @return JSON string containing all personal data
     */
    @AuraEnabled
    public static String exportContactData(Id contactId) {
        Contact subject = getContactWithAllFields(contactId);

        Map<String, Object> dataPackage = new Map<String, Object>();

        // Personal Information
        dataPackage.put('personalInformation', buildContactData(subject));

        // Related Cases
        dataPackage.put('cases', getCases(contactId));

        // Related Opportunities
        dataPackage.put('opportunities', getOpportunities(contactId));

        // Activity History
        dataPackage.put('tasks', getTasks(contactId));
        dataPackage.put('events', getEvents(contactId));

        // Files and Attachments
        dataPackage.put('files', getFiles(contactId));

        // Consent Records
        dataPackage.put('consents', getConsents(contactId));

        // GDPR Requests History
        dataPackage.put('gdprRequests', getGDPRRequests(contactId));

        // Metadata
        dataPackage.put('exportMetadata', new Map<String, Object>{
            'exportDate' => System.now(),
            'exportedBy' => UserInfo.getUserEmail(),
            'dataSubjectId' => contactId,
            'format' => 'JSON',
            'version' => '1.0',
            'gdprArticle' => 'Article 20 - Right to Data Portability'
        });

        // Log the export request
        logDataExport(contactId, subject.Email);

        return JSON.serializePretty(dataPackage);
    }

    /**
     * Get Contact with all accessible fields dynamically
     */
    private static Contact getContactWithAllFields(Id contactId) {
        List<String> fieldNames = new List<String>();
        for (Schema.SObjectField field : Schema.SObjectType.Contact.fields.getMap().values()) {
            Schema.DescribeFieldResult dfr = field.getDescribe();
            if (dfr.isAccessible()) {
                fieldNames.add(dfr.getName());
            }
        }

        String query = 'SELECT ' + String.join(fieldNames, ',')
            + ' FROM Contact WHERE Id = :contactId WITH USER_MODE LIMIT 1';
        Map<String, Object> binds = new Map<String, Object>{ 'contactId' => contactId };
        List<Contact> contacts = Database.queryWithBinds(query, binds, AccessLevel.USER_MODE);

        if (contacts.isEmpty()) {
            throw new GDPRException('Contact not found');
        }
        return contacts[0];
    }

    /**
     * Build sanitized contact data map
     */
    private static Map<String, Object> buildContactData(Contact c) {
        Map<String, Object> contactMap = (Map<String, Object>)JSON.deserializeUntyped(
            JSON.serialize(c)
        );

        // Remove system fields
        contactMap.remove('attributes');
        contactMap.remove('SystemModstamp');
        contactMap.remove('LastModifiedById');
        contactMap.remove('CreatedById');
        contactMap.remove('IsDeleted');

        return contactMap;
    }

    /**
     * Get related Cases
     */
    private static List<Map<String, Object>> getCases(Id contactId) {
        List<Case> cases = [
            SELECT Id, CaseNumber, Subject, Status, CreatedDate,
                   Description, Priority, Type, Origin
            FROM Case
            WHERE ContactId = :contactId
            WITH USER_MODE
        ];
        return convertToMapList(cases);
    }

    /**
     * Get related Opportunities
     */
    private static List<Map<String, Object>> getOpportunities(Id contactId) {
        List<Opportunity> opps = [
            SELECT Id, Name, StageName, Amount, CloseDate,
                   Description, CreatedDate, Type
            FROM Opportunity
            WHERE ContactId = :contactId
            WITH USER_MODE
        ];
        return convertToMapList(opps);
    }

    /**
     * Get related Tasks
     */
    private static List<Map<String, Object>> getTasks(Id contactId) {
        List<Task> tasks = [
            SELECT Id, Subject, Status, Priority, ActivityDate,
                   Description, CreatedDate, Type
            FROM Task
            WHERE WhoId = :contactId
            WITH USER_MODE
        ];
        return convertToMapList(tasks);
    }

    /**
     * Get related Events
     */
    private static List<Map<String, Object>> getEvents(Id contactId) {
        List<Event> events = [
            SELECT Id, Subject, StartDateTime, EndDateTime,
                   Description, CreatedDate, Type
            FROM Event
            WHERE WhoId = :contactId
            WITH USER_MODE
        ];
        return convertToMapList(events);
    }

    /**
     * Get file metadata (not content for security)
     */
    private static List<Map<String, Object>> getFiles(Id contactId) {
        List<ContentDocumentLink> docLinks = [
            SELECT ContentDocument.Title, ContentDocument.FileType,
                   ContentDocument.CreatedDate, ContentDocument.ContentSize
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :contactId
            WITH USER_MODE
        ];

        List<Map<String, Object>> files = new List<Map<String, Object>>();
        for (ContentDocumentLink cdl : docLinks) {
            files.add(new Map<String, Object>{
                'fileName' => cdl.ContentDocument.Title,
                'fileType' => cdl.ContentDocument.FileType,
                'uploadDate' => cdl.ContentDocument.CreatedDate,
                'fileSizeBytes' => cdl.ContentDocument.ContentSize
            });
        }
        return files;
    }

    /**
     * Get consent records
     */
    private static List<Map<String, Object>> getConsents(Id contactId) {
        List<Consent__c> consents = [
            SELECT Id, Name, Consent_Type__c, Consent_Given__c,
                   Consent_Date__c, Consent_Withdrawn__c, Withdrawal_Date__c,
                   Consent_Version__c, Consent_Source__c
            FROM Consent__c
            WHERE Contact__c = :contactId
            WITH USER_MODE
        ];
        return convertToMapList(consents);
    }

    /**
     * Get GDPR request history
     */
    private static List<Map<String, Object>> getGDPRRequests(Id contactId) {
        String contactIdStr = String.valueOf(contactId);
        List<GDPR_Erasure_Request__c> requests = [
            SELECT Id, Name, Request_Date__c, Status__c,
                   Request_Reason__c, Completion_Date__c
            FROM GDPR_Erasure_Request__c
            WHERE Contact_Id__c = :contactIdStr
            WITH USER_MODE
        ];
        return convertToMapList(requests);
    }

    /**
     * Convert SObject list to Map list for JSON
     */
    private static List<Map<String, Object>> convertToMapList(List<SObject> records) {
        List<Map<String, Object>> result = new List<Map<String, Object>>();
        for (SObject record : records) {
            Map<String, Object> recordMap = (Map<String, Object>)
                JSON.deserializeUntyped(JSON.serialize(record));
            recordMap.remove('attributes');
            result.add(recordMap);
        }
        return result;
    }

    /**
     * Log data export for audit trail
     */
    private static void logDataExport(Id contactId, String email) {
        EventBus.publish(new GDPR_Data_Export_Event__e(
            Contact_Id__c = contactId,
            Contact_Email__c = email,
            Export_Date__c = System.now(),
            Exported_By__c = UserInfo.getUserId()
        ));
    }

    // GDPRException moved to shared class: ElaroGDPRException
    // For backwards compatibility, create an alias
    public class GDPRException extends ElaroGDPRException {}
}
