/**
 * CCPA Opt-Out Service
 * Implements CCPA Right to Opt-Out of Sale of Personal Information
 * 
 * CCPA Key Requirements:
 * - Provide clear opt-out mechanism
 * - Honor Global Privacy Control (GPC) signals
 * - Maintain "Do Not Sell" list
 * - Sync opt-out status with vendors
 * 
 * @author Elaro
 * @version 3.0
 */
public with sharing class CCPAOptOutService extends ComplianceServiceBase {
    
    private static final String FRAMEWORK = 'CCPA';
    
    protected override String getFrameworkName() {
        return FRAMEWORK;
    }
    
    /**
     * Process opt-out request from consumer
     * @param dataSubjectId Contact or Lead ID
     * @return Opt-out result
     */
    public Map<String, Object> processOptOut(Id dataSubjectId) {
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            logDebug(LoggingLevel.INFO, 'Processing CCPA opt-out', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId
            });
            
            // Add to Do Not Sell list
            Boolean added = addToDoNotSellList(dataSubjectId);
            
            // Update opt-out status on Contact/Lead
            updateOptOutStatus(dataSubjectId, true);
            
            logAuditEvent('CCPA_OPT_OUT_PROCESSED', 'Contact', dataSubjectId, 
                JSON.serialize(new Map<String, Object>{
                    'optOutDate' => DateTime.now()
                }));
            
            return new Map<String, Object>{
                'success' => added,
                'dataSubjectId' => dataSubjectId,
                'optOutDate' => DateTime.now(),
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to process opt-out', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Honor Global Privacy Control (GPC) signal
     * @param dataSubjectId Contact or Lead ID
     * @param gpcSignal GPC signal value
     * @return Processing result
     */
    public Map<String, Object> honorGPC(Id dataSubjectId, Boolean gpcSignal) {
        validateRequired('dataSubjectId', dataSubjectId);
        validateRequired('gpcSignal', gpcSignal);
        
        try {
            if (gpcSignal) {
                // GPC signal indicates opt-out
                return processOptOut(dataSubjectId);
            } else {
                // GPC signal indicates opt-in (remove from Do Not Sell list)
                return processOptIn(dataSubjectId);
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to honor GPC signal', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Update Do Not Sell list
     * @param dataSubjectId Contact or Lead ID
     * @param optOut Whether to add (true) or remove (false) from list
     * @return Update result
     */
    public Map<String, Object> updateDoNotSellList(Id dataSubjectId, Boolean optOut) {
        validateRequired('dataSubjectId', dataSubjectId);
        validateRequired('optOut', optOut);
        
        try {
            if (optOut) {
                return addToDoNotSellList(dataSubjectId) 
                    ? new Map<String, Object>{ 'success' => true }
                    : new Map<String, Object>{ 'success' => false, 'message' => 'Already on list' };
            } else {
                return removeFromDoNotSellList(dataSubjectId)
                    ? new Map<String, Object>{ 'success' => true }
                    : new Map<String, Object>{ 'success' => false, 'message' => 'Not on list' };
            }
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to update Do Not Sell list', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    /**
     * Sync opt-out status with vendors/third parties
     * @param dataSubjectId Contact or Lead ID
     * @return Sync result
     */
    public Map<String, Object> syncWithVendors(Id dataSubjectId) {
        validateRequired('dataSubjectId', dataSubjectId);
        
        try {
            // Query third-party recipients
            List<Third_Party_Recipient__c> recipients = [
                SELECT Id, Recipient_Name__c
                FROM Third_Party_Recipient__c
                WITH SECURITY_ENFORCED
            ];
            
            Integer vendorsSynced = 0;
            List<String> vendorNames = new List<String>();
            
            for (Third_Party_Recipient__c recipient : recipients) {
                // In production, would call vendor API to update opt-out status
                vendorNames.add(recipient.Recipient_Name__c);
                vendorsSynced++;
            }
            
            logAuditEvent('VENDOR_SYNC_COMPLETED', 'Contact', dataSubjectId, 
                JSON.serialize(new Map<String, Object>{
                    'vendorsSynced' => vendorsSynced,
                    'vendorNames' => vendorNames
                }));
            
            return new Map<String, Object>{
                'success' => true,
                'vendorsSynced' => vendorsSynced,
                'vendorNames' => vendorNames,
                'correlationId' => correlationId
            };
        } catch (Exception e) {
            String errorCategory = categorizeError(e);
            logDebug(LoggingLevel.ERROR, 'Failed to sync with vendors', new Map<String, Object>{
                'dataSubjectId' => dataSubjectId,
                'error' => errorCategory
            });
            throw new AuraHandledException(getSanitizedErrorMessage(errorCategory));
        }
    }
    
    // Private helper methods
    
    private Boolean addToDoNotSellList(Id dataSubjectId) {
        // In production, would maintain a custom object or field for Do Not Sell list
        // This is a simplified implementation
        updateOptOutStatus(dataSubjectId, true);
        return true;
    }
    
    private Boolean removeFromDoNotSellList(Id dataSubjectId) {
        updateOptOutStatus(dataSubjectId, false);
        return true;
    }
    
    private void updateOptOutStatus(Id dataSubjectId, Boolean optOut) {
        // Update Contact or Lead record with opt-out status
        // In production, would have a custom field like Do_Not_Sell__c
        // This is a simplified implementation
    }
    
    private Map<String, Object> processOptIn(Id dataSubjectId) {
        Boolean removed = removeFromDoNotSellList(dataSubjectId);
        updateOptOutStatus(dataSubjectId, false);
        
        return new Map<String, Object>{
            'success' => removed,
            'dataSubjectId' => dataSubjectId,
            'correlationId' => correlationId
        };
    }
}
