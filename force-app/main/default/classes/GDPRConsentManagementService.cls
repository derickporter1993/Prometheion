/**
 * GDPR Consent Management Service
 * Implements GDPR Article 6-7: Legal basis for processing, consent management
 * 
 * GDPR Key Requirements:
 * - Article 6: Lawfulness of processing (legal basis)
 * - Article 7: Conditions for consent
 * - Article 13/14: Information to be provided when collecting data
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class GDPRConsentManagementService extends ComplianceServiceBase {
    
    private static final String FRAMEWORK = 'GDPR';
    
    protected override String getFrameworkName() {
        return FRAMEWORK;
    }
    
    /**
     * Record consent for a data subject
     * @param dataSubjectId Contact or Lead ID
     * @param consentType Type of consent (e.g., 'Marketing', 'Analytics', 'Profiling')
     * @param consentGiven Whether consent was given
     * @param consentSource Source of consent (e.g., 'Web Form', 'Email', 'Phone')
     * @return Consent record ID
     */
    public Id recordConsent(Id dataSubjectId, String consentType, Boolean consentGiven, String consentSource) {
        validateRequired('dataSubjectId', dataSubjectId);
        validateRequired('consentType', consentType);
        validateRequired('consentGiven', consentGiven);
        validateRequired('consentSource', consentSource);
        
        try {
            logDebug(LoggingLevel.INFO, 'Recording consent', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'consentType' => consentType,
                'consentGiven' => consentGiven
            });
            
            Consent__c consent = new Consent__c(
                Contact__c = dataSubjectId,
                Consent_Type__c = consentType,
                Consent_Given__c = consentGiven,
                Consent_Date__c = Date.today(),
                Consent_Source__c = consentSource,
                Consent_Version__c = getCurrentConsentVersion(consentType)
            );
            
            List<Database.SaveResult> results = executeSecureDML(
                new List<SObject>{ consent },
                AccessType.CREATABLE
            );
            
            if (!results.isEmpty() && results[0].isSuccess()) {
                Id consentId = results[0].getId();
                
                logAuditEvent('CONSENT_RECORDED', 'Consent__c', consentId, 
                    JSON.serialize(new Map<String, Object>{
                        'dataSubjectId' => dataSubjectId,
                        'consentType' => consentType,
                        'consentGiven' => consentGiven
                    }));
                
                return consentId;
            } else {
                throw new DmlException('Failed to create consent record');
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to record consent', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Withdraw consent for a data subject
     * @param dataSubjectId Contact or Lead ID
     * @param consentType Type of consent to withdraw
     * @return Withdrawal confirmation
     */
    public Map<String, Object> withdrawConsent(Id dataSubjectId, String consentType) {
        validateRequired('dataSubjectId', dataSubjectId);
        validateRequired('consentType', consentType);
        
        try {
            logDebug(LoggingLevel.INFO, 'Withdrawing consent', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'consentType' => consentType
            });
            
            // Find active consent records
            List<Consent__c> consents = [
                SELECT Id, Consent_Given__c, Consent_Withdrawn__c
                FROM Consent__c
                WHERE Contact__c = :dataSubjectId
                AND Consent_Type__c = :consentType
                AND Consent_Given__c = true
                AND Consent_Withdrawn__c = false
                WITH SECURITY_ENFORCED
            ];
            
            if (consents.isEmpty()) {
                return new Map<String, Object>{
                    'success' => false,
                    'message' => 'No active consent found to withdraw'
                };
            }
            
            // Mark all matching consents as withdrawn
            for (Consent__c consent : consents) {
                consent.Consent_Withdrawn__c = true;
                consent.Withdrawal_Date__c = Date.today();
            }
            
            List<Database.SaveResult> results = executeSecureDML(consents, AccessType.UPDATABLE);
            
            Integer recordsUpdated = 0;
            for (Database.SaveResult result : results) {
                if (result.isSuccess()) {
                    recordsUpdated++;
                }
            }
            
            logAuditEvent('CONSENT_WITHDRAWN', 'Consent__c', dataSubjectId, 
                JSON.serialize(new Map<String, Object>{
                    'consentType' => consentType,
                    'recordsUpdated' => recordsUpdated
                }));
            
            return new Map<String, Object>{
                'success' => true,
                'recordsUpdated' => recordsUpdated,
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to withdraw consent', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Get consent history for a data subject
     * @param dataSubjectId Contact or Lead ID
     * @return List of consent records
     */
    public List<Consent__c> getConsentHistory(Id dataSubjectId) {
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            List<Consent__c> consents = [
                SELECT Id, Consent_Type__c, Consent_Given__c, Consent_Date__c,
                       Consent_Source__c, Consent_Withdrawn__c, Withdrawal_Date__c,
                       Consent_Version__c
                FROM Consent__c
                WHERE Contact__c = :dataSubjectId
                WITH SECURITY_ENFORCED
                ORDER BY Consent_Date__c DESC
            ];
            
            return consents;
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to retrieve consent history', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Validate consent basis for data processing activity
     * @param activityId Data Processing Activity ID
     * @param dataSubjectId Contact or Lead ID
     * @return Validation result with consent status
     */
    public Map<String, Object> validateConsentBasis(Id activityId, Id dataSubjectId) {
        validateRequired('activityId', activityId);
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            // Get data processing activity
            List<Data_Processing_Activity__c> activities = [
                SELECT Id, Legal_Basis__c, Activity_Name__c
                FROM Data_Processing_Activity__c
                WHERE Id = :activityId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (activities.isEmpty()) {
                return new Map<String, Object>{
                    'valid' => false,
                    'message' => 'Data processing activity not found'
                };
            }
            
            Data_Processing_Activity__c activity = activities[0];
            
            // If legal basis is consent, check for active consent
            if (activity.Legal_Basis__c == 'Consent') {
                List<Consent__c> activeConsents = [
                    SELECT Id, Consent_Type__c, Consent_Given__c
                    FROM Consent__c
                    WHERE Contact__c = :dataSubjectId
                    AND Consent_Given__c = true
                    AND Consent_Withdrawn__c = false
                    WITH SECURITY_ENFORCED
                ];
                
                Boolean hasActiveConsent = !activeConsents.isEmpty();
                
                return new Map<String, Object>{
                    'valid' => hasActiveConsent,
                    'legalBasis' => activity.Legal_Basis__c,
                    'hasActiveConsent' => hasActiveConsent,
                    'consentCount' => activeConsents.size()
                };
            } else {
                // Other legal bases don't require consent
                return new Map<String, Object>{
                    'valid' => true,
                    'legalBasis' => activity.Legal_Basis__c,
                    'requiresConsent' => false
                };
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to validate consent basis', new Map<String, Object>{
                'activityId' => activityId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    // Private helper methods
    
    private String getCurrentConsentVersion(String consentType) {
        // In production, would retrieve from custom metadata or settings
        return '1.0';
    }
}
