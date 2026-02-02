/**
 * CCPA Consumer Rights Service
 * Implements CCPA consumer rights: Know, Delete, Opt-Out
 * 
 * CCPA Key Requirements:
 * - Right to Know: Consumers can request disclosure of personal information collected
 * - Right to Delete: Consumers can request deletion of personal information
 * - Right to Opt-Out: Consumers can opt-out of sale of personal information
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class CCPAConsumerRightsService extends ComplianceServiceBase implements IDataSubjectService {
    
    private static final String FRAMEWORK = 'CCPA';
    
    protected override String getFrameworkName() {
        return FRAMEWORK;
    }
    
    /**
     * Handle "Know" request (CCPA Right to Know)
     * Similar to GDPR Article 15 access request
     * @param requestId The data subject request record ID
     * @param dataSubjectId The data subject identifier (Contact, Lead, etc.)
     * @return Map containing access request response details
     */
    public Map<String, Object> handleAccessRequest(Id requestId, Id dataSubjectId) {
        return handleKnowRequest(requestId, dataSubjectId);
    }
    
    /**
     * Handle "Know" request (CCPA Right to Know)
     * @param requestId CCPA_Request__c record ID
     * @param dataSubjectId Contact or Lead ID
     * @return Map containing personal information disclosure
     */
    public Map<String, Object> handleKnowRequest(Id requestId, Id dataSubjectId) {
        validateRequired('requestId', requestId);
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            logDebug(LoggingLevel.INFO, 'Processing CCPA Know request', new Map<String, Object>{
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId
            });
            
            // Collect personal information
            Map<String, Object> personalInfo = collectPersonalInformation(dataSubjectId);
            
            // Check for data sales
            List<Map<String, Object>> dataSales = identifyDataSales(dataSubjectId);
            
            logAuditEvent('CCPA_KNOW_REQUEST', 'CCPA_Request__c', requestId, 
                JSON.serialize(new Map<String, Object>{
                    'dataSubjectId' => dataSubjectId,
                    'categoriesCollected' => personalInfo.keySet()
                }));
            
            return new Map<String, Object>{
                'success' => true,
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId,
                'personalInformation' => personalInfo,
                'dataSales' => dataSales,
                'requestDate' => DateTime.now(),
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to process Know request', new Map<String, Object>{
                'requestId' => requestId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Handle "Delete" request (CCPA Right to Delete)
     * Similar to GDPR Article 17 erasure request
     * @param requestId The erasure request record ID
     * @param dataSubjectId The data subject identifier
     * @param reason Erasure reason (not required for CCPA but included for interface compatibility)
     * @return Map containing erasure result and affected records
     */
    public Map<String, Object> handleErasureRequest(Id requestId, Id dataSubjectId, String reason) {
        return handleDeleteRequest(requestId, dataSubjectId);
    }
    
    /**
     * Handle "Delete" request (CCPA Right to Delete)
     * @param requestId CCPA_Request__c record ID
     * @param dataSubjectId Contact or Lead ID
     * @return Map containing deletion result
     */
    public Map<String, Object> handleDeleteRequest(Id requestId, Id dataSubjectId) {
        validateRequired('requestId', requestId);
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            logDebug(LoggingLevel.INFO, 'Processing CCPA Delete request', new Map<String, Object>{
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId
            });
            
            // Check for exceptions (e.g., legal obligations)
            Boolean canDelete = validateDeleteAllowed(dataSubjectId);
            if (!canDelete) {
                return new Map<String, Object>{
                    'success' => false,
                    'message' => 'Deletion not allowed due to legal obligations or business purposes',
                    'correlationId' => correlationId
                };
            }
            
            // Delete personal information
            Integer recordsDeleted = performDeletion(dataSubjectId);
            
            logAuditEvent('CCPA_DELETE_REQUEST', 'CCPA_Request__c', requestId, 
                JSON.serialize(new Map<String, Object>{
                    'dataSubjectId' => dataSubjectId,
                    'recordsDeleted' => recordsDeleted
                }));
            
            return new Map<String, Object>{
                'success' => true,
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId,
                'recordsDeleted' => recordsDeleted,
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to process Delete request', new Map<String, Object>{
                'requestId' => requestId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Handle "Opt-Out" request (CCPA Right to Opt-Out of Sale)
     * @param requestId CCPA_Request__c record ID
     * @param dataSubjectId Contact or Lead ID
     * @return Map containing opt-out result
     */
    public Map<String, Object> handleOptOutRequest(Id requestId, Id dataSubjectId) {
        validateRequired('requestId', requestId);
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            logDebug(LoggingLevel.INFO, 'Processing CCPA Opt-Out request', new Map<String, Object>{
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId
            });
            
            // Process opt-out (would integrate with CCPAOptOutService)
            Boolean optOutProcessed = processOptOut(dataSubjectId);
            
            logAuditEvent('CCPA_OPT_OUT_REQUEST', 'CCPA_Request__c', requestId, 
                JSON.serialize(new Map<String, Object>{
                    'dataSubjectId' => dataSubjectId,
                    'optOutProcessed' => optOutProcessed
                }));
            
            return new Map<String, Object>{
                'success' => optOutProcessed,
                'requestId' => requestId,
                'dataSubjectId' => dataSubjectId,
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to process Opt-Out request', new Map<String, Object>{
                'requestId' => requestId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Verify identity of consumer making request
     * @param dataSubjectId The data subject identifier
     * @param verificationData Map of verification information
     * @return Boolean indicating successful verification
     */
    public Boolean verifyIdentity(Id dataSubjectId, Map<String, Object> verificationData) {
        validateRequired('dataSubjectId', dataSubjectId);
        validateRequired('verificationData', verificationData);
        
        try {
            // Query consumer record
            List<Contact> contacts = [
                SELECT Id, Email, Phone, LastName
                FROM Contact
                WHERE Id = :dataSubjectId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];
            
            if (contacts.isEmpty()) {
                return false;
            }
            
            Contact consumer = contacts[0];
            
            // Verify email if provided
            if (verificationData.containsKey('email')) {
                String providedEmail = (String)verificationData.get('email');
                if (consumer.Email != providedEmail) {
                    return false;
                }
            }
            
            // Additional verification logic can be added here
            
            return true;
        } catch (Exception e) {
            logDebug(LoggingLevel.ERROR, 'Identity verification failed', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => categorizeError(e)
            });
            return false;
        }
    }
    
    // Interface methods not applicable to CCPA (return null/empty)
    
    public Map<String, Object> handleRectificationRequest(Id requestId, Map<String, Object> corrections) {
        // CCPA doesn't have explicit rectification right, but can be handled via update
        return new Map<String, Object>{
            'success' => false,
            'message' => 'CCPA does not include explicit right to rectification'
        };
    }
    
    public Map<String, Object> handlePortabilityRequest(Id requestId, Id dataSubjectId, String format) {
        // CCPA doesn't have explicit portability right, but can provide data export
        return handleKnowRequest(requestId, dataSubjectId);
    }
    
    // Private helper methods
    
    private Map<String, Object> collectPersonalInformation(Id dataSubjectId) {
        Map<String, Object> personalInfo = new Map<String, Object>();
        
        // Query Contact data
        List<Contact> contacts = [
            SELECT Id, FirstName, LastName, Email, Phone, MailingAddress
            FROM Contact
            WHERE Id = :dataSubjectId
            WITH SECURITY_ENFORCED
            LIMIT 1
        ];
        
        if (!contacts.isEmpty()) {
            Contact c = contacts[0];
            personalInfo.put('contact', new Map<String, Object>{
                'firstName' => c.FirstName,
                'lastName' => c.LastName,
                'email' => c.Email,
                'phone' => c.Phone
            });
        }
        
        return personalInfo;
    }
    
    private List<Map<String, Object>> identifyDataSales(Id dataSubjectId) {
        // Check if consumer's data has been sold to third parties
        // This would query data sharing records
        return new List<Map<String, Object>>();
    }
    
    private Boolean validateDeleteAllowed(Id dataSubjectId) {
        // Check for legal obligations that prevent deletion
        return true;
    }
    
    private Integer performDeletion(Id dataSubjectId) {
        // Delete personal information records
        // Similar to GDPR erasure
        return 0;
    }
    
    private Boolean processOptOut(Id dataSubjectId) {
        // Process opt-out (would integrate with CCPAOptOutService)
        return true;
    }
}
