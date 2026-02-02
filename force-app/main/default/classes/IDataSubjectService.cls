/**
 * Interface for data subject rights services (GDPR, CCPA)
 * Provides standardized methods for handling data subject access, rectification, erasure, and portability requests
 * 
 * @author Elaro
 * @version 3.0
 */
public interface IDataSubjectService {
    /**
     * Handle data subject access request (GDPR Article 15, CCPA "Know" request)
     * @param requestId The data subject request record ID
     * @param dataSubjectId The data subject identifier (Contact, Lead, etc.)
     * @return Map containing access request response details
     */
    Map<String, Object> handleAccessRequest(Id requestId, Id dataSubjectId);
    
    /**
     * Handle data rectification request (GDPR Article 16)
     * @param requestId The rectification request record ID
     * @param corrections Map of field names to corrected values
     * @return Map containing rectification result
     */
    Map<String, Object> handleRectificationRequest(Id requestId, Map<String, Object> corrections);
    
    /**
     * Handle data erasure request (GDPR Article 17, CCPA "Delete" request)
     * @param requestId The erasure request record ID
     * @param dataSubjectId The data subject identifier
     * @param reason Erasure reason or legal basis
     * @return Map containing erasure result and affected records
     */
    Map<String, Object> handleErasureRequest(Id requestId, Id dataSubjectId, String reason);
    
    /**
     * Handle data portability request (GDPR Article 20)
     * @param requestId The portability request record ID
     * @param dataSubjectId The data subject identifier
     * @param format Export format (JSON, CSV, XML)
     * @return Map containing portable data export
     */
    Map<String, Object> handlePortabilityRequest(Id requestId, Id dataSubjectId, String format);
    
    /**
     * Verify identity of data subject making request
     * @param dataSubjectId The data subject identifier
     * @param verificationData Map of verification information
     * @return Boolean indicating successful verification
     */
    Boolean verifyIdentity(Id dataSubjectId, Map<String, Object> verificationData);
}
