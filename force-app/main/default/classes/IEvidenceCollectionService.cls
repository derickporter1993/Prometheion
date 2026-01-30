/**
 * Interface for evidence collection services across compliance frameworks
 * Provides standardized methods for gathering, classifying, and documenting compliance evidence
 * 
 * @author Elaro
 * @version 3.0
 */
public interface IEvidenceCollectionService {
    /**
     * Collect evidence for a specific compliance control or requirement
     * @param controlId The compliance control identifier
     * @param framework The framework name (GDPR, CCPA, PCI-DSS, etc.)
     * @return Map of evidence items with metadata
     */
    Map<String, Object> collectEvidence(String controlId, String framework);
    
    /**
     * Classify data categories for inventory purposes
     * @param dataFields List of field definitions or data elements
     * @return Map of data categories with classification details
     */
    Map<String, Object> classifyDataCategories(List<Object> dataFields);
    
    /**
     * Map data flows between systems and third parties
     * @param sourceSystem Source system identifier
     * @param targetSystem Target system identifier (null for internal flows)
     * @return Data flow mapping with transfer details
     */
    Map<String, Object> mapDataFlows(String sourceSystem, String targetSystem);
    
    /**
     * Generate evidence report or documentation
     * @param reportType Type of report (ROPA, Data Inventory, etc.)
     * @param parameters Report generation parameters
     * @return Report content or file reference
     */
    Object generateEvidenceReport(String reportType, Map<String, Object> parameters);
}
