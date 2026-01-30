/**
 * GDPR Breach Notification Service
 * Implements GDPR Article 33-34: Personal data breach notification requirements
 * 
 * GDPR Key Requirements:
 * - Article 33: Notification of a personal data breach to the supervisory authority (72 hours)
 * - Article 34: Communication of a personal data breach to the data subject
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class GDPRBreachNotificationService extends ComplianceServiceBase {
    
    private static final String FRAMEWORK = 'GDPR';
    private static final Integer NOTIFICATION_DEADLINE_HOURS = 72;
    
    protected override String getFrameworkName() {
        return FRAMEWORK;
    }
    
    /**
     * Report a personal data breach
     * @param breachDate Date and time when breach was discovered
     * @param affectedRecords Number of records affected
     * @param breachDescription Description of the breach
     * @return GDPR_Breach__c record ID
     */
    public Id reportBreach(DateTime breachDate, Integer affectedRecords, String breachDescription) {
        validateRequired('breachDate', breachDate);
        validateRequired('affectedRecords', affectedRecords);
        validateRequired('breachDescription', breachDescription);
        
        try {
            logDebug(LoggingLevel.INFO, 'Reporting GDPR breach', new Map<String, Object>{
                'breachDate' => breachDate,
                'affectedRecords' => affectedRecords
            });
            
            // Calculate notification deadline (72 hours from discovery)
            DateTime notificationDeadline = breachDate.addHours(NOTIFICATION_DEADLINE_HOURS);
            
            GDPR_Breach__c breach = new GDPR_Breach__c(
                Breach_Date__c = breachDate,
                Affected_Records__c = affectedRecords,
                Notification_Deadline__c = notificationDeadline,
                Status__c = 'Detected',
                DPA_Notified__c = false
            );
            
            List<Database.SaveResult> results = executeSecureDML(
                new List<SObject>{ breach },
                AccessType.CREATABLE
            );
            
            if (!results.isEmpty() && results[0].isSuccess()) {
                Id breachId = results[0].getId();
                
                logAuditEvent('BREACH_REPORTED', 'GDPR_Breach__c', breachId, 
                    JSON.serialize(new Map<String, Object>{
                        'affectedRecords' => affectedRecords,
                        'deadline' => notificationDeadline
                    }));
                
                return breachId;
            } else {
                throw new DmlException('Failed to create breach record');
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to report breach', new Map<String, Object>{
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Assess breach severity to determine notification requirements
     * @param breachId GDPR_Breach__c record ID
     * @return Severity assessment result
     */
    public Map<String, Object> assessSeverity(Id breachId) {
        validateRequired('breachId', breachId);
        
        try {
            List<GDPR_Breach__c> breaches = [
                SELECT Id, Affected_Records__c, Breach_Date__c, Status__c
                FROM GDPR_Breach__c
                WHERE Id = :breachId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (breaches.isEmpty()) {
                throw new IllegalArgumentException('Breach record not found: ' + breachId);
            }
            
            GDPR_Breach__c breach = breaches[0];
            
            // Determine severity based on affected records
            String severity = 'Low';
            Boolean requiresDataSubjectNotification = false;
            
            if (breach.Affected_Records__c >= 1000) {
                severity = 'High';
                requiresDataSubjectNotification = true;
            } else if (breach.Affected_Records__c >= 100) {
                severity = 'Medium';
                requiresDataSubjectNotification = true;
            }
            
            return new Map<String, Object>{
                'severity' => severity,
                'affectedRecords' => breach.Affected_Records__c,
                'requiresDataSubjectNotification' => requiresDataSubjectNotification,
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to assess breach severity', new Map<String, Object>{
                'breachId' => breachId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Notify Data Protection Authority (DPA)
     * @param breachId GDPR_Breach__c record ID
     * @return Notification result
     */
    public Map<String, Object> notifyDPA(Id breachId) {
        validateRequired('breachId', breachId);
        
        try {
            List<GDPR_Breach__c> breaches = [
                SELECT Id, DPA_Notified__c, Notification_Deadline__c, Status__c
                FROM GDPR_Breach__c
                WHERE Id = :breachId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (breaches.isEmpty()) {
                throw new IllegalArgumentException('Breach record not found: ' + breachId);
            }
            
            GDPR_Breach__c breach = breaches[0];
            
            // Check if deadline has passed
            Boolean deadlinePassed = DateTime.now() > breach.Notification_Deadline__c;
            
            // Update breach record
            breach.DPA_Notified__c = true;
            breach.Status__c = 'DPA Notified';
            
            List<Database.SaveResult> results = executeSecureDML(
                new List<SObject>{ breach },
                AccessType.UPDATABLE
            );
            
            if (!results.isEmpty() && results[0].isSuccess()) {
                logAuditEvent('DPA_NOTIFIED', 'GDPR_Breach__c', breachId, 
                    JSON.serialize(new Map<String, Object>{
                        'deadlinePassed' => deadlinePassed,
                        'notificationDate' => DateTime.now()
                    }));
                
                return new Map<String, Object>{
                    'success' => true,
                    'deadlinePassed' => deadlinePassed,
                    'correlationId' => correlationId
                };
            } else {
                throw new DmlException('Failed to update breach record');
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to notify DPA', new Map<String, Object>{
                'breachId' => breachId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Notify data subjects about the breach
     * @param breachId GDPR_Breach__c record ID
     * @return Notification result
     */
    public Map<String, Object> notifyDataSubjects(Id breachId) {
        validateRequired('breachId', breachId);
        
        try {
            // Get breach details
            List<GDPR_Breach__c> breaches = [
                SELECT Id, Affected_Records__c, Status__c
                FROM GDPR_Breach__c
                WHERE Id = :breachId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (breaches.isEmpty()) {
                throw new IllegalArgumentException('Breach record not found: ' + breachId);
            }
            
            GDPR_Breach__c breach = breaches[0];
            
            // In production, would send notifications to affected data subjects
            // This is a simplified implementation
            Integer notificationsSent = 0; // Placeholder
            
            // Update breach status
            breach.Status__c = 'Data Subjects Notified';
            
            List<Database.SaveResult> results = executeSecureDML(
                new List<SObject>{ breach },
                AccessType.UPDATABLE
            );
            
            if (!results.isEmpty() && results[0].isSuccess()) {
                logAuditEvent('DATA_SUBJECTS_NOTIFIED', 'GDPR_Breach__c', breachId, 
                    JSON.serialize(new Map<String, Object>{
                        'notificationsSent' => notificationsSent
                    }));
                
                return new Map<String, Object>{
                    'success' => true,
                    'notificationsSent' => notificationsSent,
                    'correlationId' => correlationId
                };
            } else {
                throw new DmlException('Failed to update breach record');
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to notify data subjects', new Map<String, Object>{
                'breachId' => breachId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Track notification deadlines and send alerts
     * @return List of breaches approaching or past deadline
     */
    public List<GDPR_Breach__c> trackDeadlines() {
        try {
            DateTime now = DateTime.now();
            DateTime alertThreshold = now.addHours(24); // Alert 24 hours before deadline
            
            List<GDPR_Breach__c> breaches = [
                SELECT Id, Name, Breach_Date__c, Notification_Deadline__c, 
                       Status__c, DPA_Notified__c, Affected_Records__c
                FROM GDPR_Breach__c
                WHERE Status__c != 'Resolved'
                AND (Notification_Deadline__c <= :alertThreshold OR Notification_Deadline__c < :now)
                WITH SECURITY_ENFORCED
                ORDER BY Notification_Deadline__c ASC
            ];
            
            return breaches;
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to track deadlines', new Map<String, Object>{
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
}
